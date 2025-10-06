/* Link native Sub-issues: parent <- child
 * Inputs (via env):
 *   INPUT_PARENT_NUMBER | INPUT_PARENT_UID
 *   INPUT_CHILD_NUMBER  | INPUT_CHILD_UID
 *   INPUT_DRY_RUN  (default true)
 *   INPUT_APPLY    (default false)
 * Requires GITHUB_TOKEN + GITHUB_REPOSITORY
 */
function mustEnv(n){ const v=process.env[n]; if(!v) throw new Error(`${n} not set`); return v; }
function repo(){ const rr = mustEnv('GITHUB_REPOSITORY'); const [owner,repo] = rr.split('/'); return {owner,repo}; }
function seedMarker(uid){ return `<!-- seed-uid:${uid} -->`; }

/** Search issue by seed UID (two strategies: exact HTML comment → plain text fallback) */
async function searchIssueByUid(uid, token) {
  const { owner, repo: r } = repo();
  async function doSearch(q) {
    const url = `https://api.github.com/search/issues?q=${encodeURIComponent(q)}&per_page=1`;
    const res = await fetch(url, { headers: { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github+json' }});
    if (!res.ok) throw new Error(`Search HTTP ${res.status}: ${await res.text()}`);
    const j = await res.json();
    const it = j.items?.[0];
    return it ? { number: it.number } : null;
  }
  const q1 = `repo:${owner}/${r} "${seedMarker(uid)}" in:body is:issue`;
  let hit = await doSearch(q1);
  if (hit) return hit;
  const q2 = `repo:${owner}/${r} "seed-uid:${uid}" in:body is:issue`;
  hit = await doSearch(q2);
  return hit; // may be null
}

/** Get full issue to read its 'id' (needed by sub_issues endpoint) */
async function getIssueByNumber(num, token){
  const { owner, repo: r } = repo();
  const res = await fetch(`https://api.github.com/repos/${owner}/${r}/issues/${num}`, {
    headers: { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github+json' }
  });
  if (!res.ok) throw new Error(`Get issue #${num} HTTP ${res.status}: ${await res.text()}`);
  return await res.json(); // includes 'id' and 'number'
}

/** Link child to parent using REST: POST /repos/{o}/{r}/issues/{PARENT}/sub_issues { sub_issue_id } */
async function link(childNum, parentNum, token){
  const { owner, repo: r } = repo();

  // We need the child 'id' (not issue number)
  const child = await getIssueByNumber(childNum, token);
  const body = { sub_issue_id: child.id }; // required by Add sub-issue endpoint

  const res = await fetch(`https://api.github.com/repos/${owner}/${r}/issues/${parentNum}/sub_issues`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(body)
  });
  if (!res.ok) throw new Error(`Sub-issues link HTTP ${res.status}: ${await res.text()}`);
  return true;
}

async function main(){
  const token = mustEnv('GITHUB_TOKEN');

  const dryRun = (process.env.INPUT_DRY_RUN || '').toLowerCase() !== 'false'; // default true
  const apply  = (process.env.INPUT_APPLY   || '').toLowerCase() === 'true';  // default false

  let parentNum = parseInt(process.env.INPUT_PARENT_NUMBER || '', 10);
  let childNum  = parseInt(process.env.INPUT_CHILD_NUMBER  || '', 10);

  const parentUid = process.env.INPUT_PARENT_UID || '';
  const childUid  = process.env.INPUT_CHILD_UID  || '';

  if (!Number.isInteger(parentNum) && !parentUid) {
    const msg = 'Provide parent_number or parent_uid';
    if (dryRun) { console.log(`::warning::${msg}`); return; }
    throw new Error(msg);
  }
  if (!Number.isInteger(childNum)  && !childUid)  {
    const msg = 'Provide child_number or child_uid';
    if (dryRun) { console.log(`::warning::${msg}`); return; }
    throw new Error(msg);
  }

  // Resolve numbers from UIDs if needed
  if (!Number.isInteger(parentNum)) {
    const r = await searchIssueByUid(parentUid, token);
    if (!r) {
      const msg = `Parent not found for uid=${parentUid}`;
      if (dryRun) { console.log(`::warning::${msg}`); return; }
      throw new Error(msg);
    }
    parentNum = r.number;
  }
  if (!Number.isInteger(childNum)) {
    const r = await searchIssueByUid(childUid, token);
    if (!r) {
      const msg = `Child not found for uid=${childUid}`;
      if (dryRun) { console.log(`::warning::${msg}`); return; }
      throw new Error(msg);
    }
    childNum = r.number;
  }

  console.log(`::notice::hierarchy dry_run=${dryRun} apply=${apply} parent#=${parentNum} child#=${childNum}`);

  if (dryRun || !apply) {
    console.log(`::notice title=would-link::parent#=${parentNum} <- child#=${childNum}`);
    return;
  }

  await link(childNum, parentNum, token);
  console.log(`::notice title=linked::parent#=${parentNum} <- child#=${childNum}`);
}

main().catch(e => { console.log(`::error::${e.message || e}`); process.exit(1); });
