/* Parse + route + dry-run search + optional apply (create + project add + field writes) */
import fs from 'node:fs';
import path from 'node:path';

/* ---------------- util ---------------- */
function seedMarker(uid){ return `<!-- seed-uid:${uid} -->`; }
function mustEnv(name){ const v = process.env[name]; if(!v) throw new Error(`${name} not set`); return v; }
function pickToken(){ return process.env.PROJECTS_TOKEN || process.env.GITHUB_TOKEN || ''; }
function repo(){ const rr = mustEnv('GITHUB_REPOSITORY'); const [owner,repo] = rr.split('/'); return {owner,repo}; }

/* ---------------- parsing ---------------- */
function parseHeader(md, file) {
  const m = md.trimStart().match(/^<!--([\s\S]*?)-->\s*/);
  if (!m) throw new Error(`Seed missing header comment: ${file}`);
  const headerRaw = m[1];
  const header = {};
  for (const line of headerRaw.split('\n')) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const idx = t.indexOf(':'); if (idx === -1) continue;
    const key = t.slice(0, idx).trim();
    let value = t.slice(idx + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) value = value.slice(1,-1);
    if (value.startsWith('[') && value.endsWith(']')) {
      try { header[key] = JSON.parse(value); }
      catch { throw new Error(`Invalid JSON array for key '${key}' in ${file}`); }
      continue;
    }
    header[key] = value;
  }
  if (!header.title) throw new Error(`Missing 'title' in ${file}`);
  if (!header.uid) throw new Error(`Missing 'uid' in ${file}`);
  for (const k of ['labels','assignees','children_uids']) {
    if (header[k] !== undefined && !Array.isArray(header[k])) {
      throw new Error(`'${k}' must be a JSON array in ${file}`);
    }
  }
  if (header.project && !['test','main'].includes(header.project)) {
    throw new Error(`'project' must be "test" or "main" in ${file}`);
  }
  return header;
}

function resolveProjectUrl(header, env) {
  if (header.project_url && header.project_url.trim()) return { url: header.project_url.trim(), source: 'seed.project_url' };
  if (header.project === 'test' && env.PROJECT_URL_TEST) return { url: env.PROJECT_URL_TEST, source: 'seed.project=test' };
  if (header.project === 'main' && env.PROJECT_URL) return { url: env.PROJECT_URL, source: 'seed.project=main' };
  if (env.PROJECT_URL) return { url: env.PROJECT_URL, source: 'env.PROJECT_URL' };
  throw new Error('No Project URL resolved (set PROJECT_URL or use project_url in seed)');
}

function listSeeds(glob) {
  if (!glob) return [];
  if (!glob.includes('*')) return fs.existsSync(glob) ? [glob] : [];
  const dir = path.dirname(glob);
  const ext = path.extname(glob) || '.md';
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir).filter(f => f.toLowerCase().endsWith(ext.toLowerCase())).map(f => path.join(dir, f));
}

/* ---------------- GitHub helpers ---------------- */
async function ghSearchBySeedUid(uid, token) {
  if (!token) return { found:false, note:'no-token' };
  const { owner, repo: r } = repo();
  const q = encodeURIComponent(`repo:${owner}/${r} "${seedMarker(uid)}" in:body is:issue`);
  const res = await fetch(`https://api.github.com/search/issues?q=${q}&per_page=1`, {
    headers: { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github+json' }
  });
  if (!res.ok) throw new Error(`Search HTTP ${res.status}: ${await res.text()}`);
  const json = await res.json();
  const item = json.items?.[0];
  return item ? { found:true, number:item.number, nodeId:item.node_id } : { found:false };
}

async function ghCreateIssue(header, body, token) {
  const { owner, repo: r } = repo();
  const payload = {
    title: header.title,
    body,
    labels: header.labels || [],
    assignees: header.assignees || []
  };
  const res = await fetch(`https://api.github.com/repos/${owner}/${r}/issues`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github+json', 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
  if (!res.ok) throw new Error(`Create issue HTTP ${res.status}: ${await res.text()}`);
  const j = await res.json();
  return { number: j.number, nodeId: j.node_id };
}

async function gql(query, variables, token) {
  const res = await fetch('https://api.github.com/graphql', {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({ query, variables })
  });
  if (!res.ok) throw new Error(`GraphQL HTTP ${res.status}: ${await res.text()}`);
  const j = await res.json();
  if (j.errors?.length) throw new Error(`GraphQL: ${j.errors.map(e => e.message).join('; ')}`);
  return j.data;
}

async function resolveProjectNodeId(projectUrl, token) {
  const mu = projectUrl.match(/^https:\/\/github\.com\/users\/([^/]+)\/projects\/(\d+)/i);
  const mo = projectUrl.match(/^https:\/\/github\.com\/orgs\/([^/]+)\/projects\/(\d+)/i);
  if (!mu && !mo) throw new Error(`Unsupported Project URL: ${projectUrl}`);
  const numberRaw = mu?.[2] || mo?.[2];
  const number = parseInt(numberRaw, 10);
  if (!Number.isInteger(number)) throw new Error(`Invalid project number in URL: ${projectUrl}`);

  if (mu) {
    const login = mu[1];
    const qUser = `query($login:String!,$number:Int!){ user(login:$login){ projectV2(number:$number){ id } } }`;
    const dUser = await gql(qUser, { login, number }, token);
    const id = dUser.user?.projectV2?.id;
    if (id) return id;
  }

  if (mo) {
    const org = mo[1];
    const qOrg = `query($org:String!,$number:Int!){ organization(login:$org){ projectV2(number:$number){ id } } }`;
    const dOrg = await gql(qOrg, { org, number }, token);
    const id = dOrg.organization?.projectV2?.id;
    if (id) return id;
  }

  throw new Error(`Project not found for ${projectUrl}`);
}

async function projectAddItem(projectId, issueNodeId, token) {
  const m = `mutation($projectId:ID!,$itemId:ID!){
    addProjectV2ItemById(input:{projectId:$projectId, contentId:$itemId}){ item { id } }
  }`;
  const d = await gql(m, { projectId, itemId: issueNodeId }, token);
  return d.addProjectV2ItemById.item.id;
}

async function fetchFields(projectId, token) {
  const q = `query($id:ID!){
    node(id:$id){
      ... on ProjectV2 {
        fields(first:100){
          nodes{
            ... on ProjectV2FieldCommon { id name dataType }
            ... on ProjectV2SingleSelectField { id name dataType options { id name } }
          }
        }
      }
    }
  }`;
  const d = await gql(q, { id: projectId }, token);
  return d.node.fields.nodes || [];
}

async function writeField(projectId, itemId, field, value, token) {
  if (field.dataType === 'SINGLE_SELECT') {
    const opt = (field.options || []).find(o => (o.name||'').toLowerCase() === value.toLowerCase());
    if (!opt) return false;
    const m = `mutation($projectId:ID!,$itemId:ID!,$fieldId:ID!,$opt:String!){
      updateProjectV2ItemFieldValue(input:{
        projectId:$projectId,itemId:$itemId,fieldId:$fieldId,value:{ singleSelectOptionId:$opt }
      }){ clientMutationId } }`;
    await gql(m, { projectId, itemId, fieldId: field.id, opt: opt.id }, token);
    return true;
  } else {
    const m = `mutation($projectId:ID!,$itemId:ID!,$fieldId:ID!,$txt:String!){
      updateProjectV2ItemFieldValue(input:{
        projectId:$projectId,itemId:$itemId,fieldId:$fieldId,value:{ text:$txt }
      }){ clientMutationId } }`;
    await gql(m, { projectId, itemId, fieldId: field.id, txt: value }, token);
    return true;
  }
}

function plannedWritesFromHeader(h) {
  const map = [
    ['type','Type'],
    ['status','Status'],
    ['priority','Priority'],
    ['target','Target Release'],
    ['area','Area'],
    ['doc','Doc Link'],
    ['pr','PR Link'],
  ];
  const out = [];
  for (const [k, display] of map) {
    const v = (h[k]||'').toString().trim();
    if (v) out.push({ name: display, value: v });
  }
  return out;
}

/* ---------------- main ---------------- */
async function main() {
  const seedsGlob = process.env.INPUT_SEEDS_GLOB || '';
  const override = process.env.INPUT_PROJECT_URL_OVERRIDE || '';
  const dryRun = (process.env.INPUT_DRY_RUN || '').toLowerCase() !== 'false'; // default=true
  const apply = (process.env.INPUT_APPLY || '').toLowerCase() === 'true';     // default=false
  const tokenREST = process.env.GITHUB_TOKEN || '';
  const tokenGraph = pickToken();

  const files = listSeeds(seedsGlob);
  console.log(`::notice::parse-run files=${files.length} pattern="${seedsGlob}" dry_run=${dryRun} apply=${apply}`);

  for (const file of files) {
    const md = fs.readFileSync(file, 'utf8');
    const header = parseHeader(md, file);
    const route = override ? { url: override, source: 'override' } : resolveProjectUrl(header, process.env);

    // Search existing
    let existing = { found:false };
    try { existing = await ghSearchBySeedUid(header.uid, tokenREST); }
    catch (e) { console.log(`::warning::search failed for uid=${header.uid}: ${e.message || e}`); }

    if (existing.found) {
      console.log(`::notice title=seed::uid=${header.uid} title="${header.title}" route="${route.url}" source=${route.source} result=exists issue=#${existing.number}`);
      // Idempotency rule: do not modify existing in this step.
      continue;
    }

    if (!apply || dryRun) {
      console.log(`::notice title=seed::uid=${header.uid} title="${header.title}" route="${route.url}" source=${route.source} result=would-create`);
      continue;
    }

    // Apply: create + project add + field writes
    const body = `${seedMarker(header.uid)}\n\n${md.replace(/^<!--[\s\S]*?-->\s*/, '') || ('# ' + header.title)}`;
    const created = await ghCreateIssue(header, body, tokenREST);
    console.log(`::notice title=created::uid=${header.uid} issue=#${created.number}`);

    const projectId = await resolveProjectNodeId(route.url, tokenGraph);
    const itemId = await projectAddItem(projectId, created.nodeId, tokenGraph);
    console.log(`::notice title=project::uid=${header.uid} projectId=${projectId} itemId=${itemId}`);

    const fields = await fetchFields(projectId, tokenGraph);
    const want = plannedWritesFromHeader(header);
    let ok = 0;
    for (const w of want) {
      const f = fields.find(ff => (ff.name||'').toLowerCase() === w.name.toLowerCase());
      if (!f) continue;
      const wrote = await writeField(projectId, itemId, f, w.value, tokenGraph);
      if (wrote) ok++;
    }
    console.log(`::notice title=fields::uid=${header.uid} wrote=${ok}/${want.length}`);
  }
}

main().catch(e => { console.log(`::error::${e.message || e}`); process.exit(1); });
