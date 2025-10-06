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

async function searchIssueByUid(uid, token) {
  const { owner, repo: r } = repo();
  const q = encodeURIComponent(`repo:${owner}/${r} "${seedMarker(uid)}" in:body is:issue`);
  const res = await fetch(`https://api.github.com/search/issues?q=${q}&per_page=1`, {
    headers: { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github+json' }
  });
  if (!res.ok) throw new Error(`Search HTTP ${res.status}: ${await res.text()}`);
  const j = await res.json();
  const it = j.items?.[0];
  if (!it) return null;
  return { number: it.number };
}

async function link(childNum, parentNum, token){
  const { owner, repo: r } = repo();
  // POST /repos/{owner}/{repo}/issues/{issue_number}/sub-issues
  const res = await fetch(`https://api.github.com/repos/${owner}/${r}/issues/${childNum}/sub-issues`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github+json', 'Content-Type': 'application/json' },
    body: JSON.stringify({ parent_issue_number: parentNum })
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

  if (!Number.isInteger(parentNum) && !parentUid) throw new Error('Provide parent_number or parent_uid');
  if (!Number.isInteger(childNum)  && !childUid)  throw new Error('Provide child_number or child_uid');

  // Resolve numbers from UIDs if needed
  if (!Number.isInteger(parentNum)) {
    const r = await searchIssueByUid(parentUid, token);
    if (!r) throw new Error(`Parent not found for uid=${parentUid}`);
    parentNum = r.number;
  }
  if (!Number.isInteger(childNum)) {
    const r = await searchIssueByUid(childUid, token);
    if (!r) throw new Error(`Child not found for uid=${childUid}`);
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
