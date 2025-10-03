// scripts/lib/sub_issues.js
// Step 3: Idempotent Sub-issues linking helpers.
// - listSubIssues(): enumerate current sub-issues for a parent
// - getIssueByNumber(): fetch a single issue to obtain its numeric "id"
// - addSubIssueIfMissing(): no-op if already linked; else add; treats "already linked" errors as success

"use strict";

/**
 * List sub-issues on a parent issue (same-repo).
 * @returns {Promise<Array<{id:number,node_id:string,number?:number,title?:string}>>}
 */
async function listSubIssues({
  octokit,
  owner,
  repo,
  parentIssueNumber,
  core,
}) {
  if (!octokit) throw new Error("octokit is required");
  const endpoint = "GET /repos/{owner}/{repo}/issues/{issue_number}/sub_issues";
  const res = await octokit.request(endpoint, {
    owner,
    repo,
    issue_number: parentIssueNumber,
    per_page: 100,
  });
  const arr = Array.isArray(res.data) ? res.data : [];
  core?.info?.(
    `[sub-issues] parent #${parentIssueNumber} currently has ${arr.length} sub-issues`
  );
  return arr;
}

/**
 * Fetch an issue by number to obtain its numeric "id" (required by Sub-issues API).
 * @returns {Promise<{id:number, node_id:string, number:number, title:string}>}
 */
async function getIssueByNumber({ octokit, owner, repo, issueNumber }) {
  const r = await octokit.rest.issues.get({
    owner,
    repo,
    issue_number: issueNumber,
  });
  return {
    id: r.data.id,
    node_id: r.data.node_id,
    number: r.data.number,
    title: r.data.title,
  };
}

/**
 * Low-level "add" call (no guard).
 * @returns {Promise<{ok:boolean,status:number,data?:any,error?:any, skipped?:boolean}>}
 */
async function addSubIssue({
  octokit,
  owner,
  repo,
  parentIssueNumber,
  childIssueId,
  core,
}) {
  const endpoint =
    "POST /repos/{owner}/{repo}/issues/{issue_number}/sub_issues";
  try {
    const res = await octokit.request(endpoint, {
      owner,
      repo,
      issue_number: parentIssueNumber,
      sub_issue_id: childIssueId,
    });
    const status = res.status || 201;
    core?.notice?.(
      `[sub-issues] linked parent #${parentIssueNumber} ← child(issue_id=${childIssueId}) [status=${status}]`
    );
    return { ok: true, status, data: res.data };
  } catch (error) {
    const status = error?.status || 500;
    const msg = error?.message || "";
    // Treat "already linked" as success (GitHub returns 422 Validation Failed in that case)
    const isAlready =
      status === 422 &&
      /already\s+.*sub-issue|Validation\s+Failed/i.test(
        msg + " " + JSON.stringify(error?.response?.data || {})
      );
    if (isAlready) {
      core?.notice?.(
        `[sub-issues] already linked parent #${parentIssueNumber} ← child(issue_id=${childIssueId}); treating as success`
      );
      return { ok: true, status: 200, data: { already: true }, skipped: true };
    }
    core?.warning?.(
      `[sub-issues] link failed parent #${parentIssueNumber} ← child(issue_id=${childIssueId}) [status=${status}] ${msg}`
    );
    return { ok: false, status, error };
  }
}

/**
 * Idempotent link: pre-check existing sub-issues; skip if the child is already present.
 * Accepts either childIssueId or childIssueNumber (we'll fetch the id if number is provided).
 * @returns {Promise<{ok:boolean, skipped:boolean, status:number}>}
 */
async function addSubIssueIfMissing({
  octokit,
  owner,
  repo,
  parentIssueNumber,
  childIssueId, // preferred
  childIssueNumber, // if provided, we'll resolve to id
  core,
}) {
  if (!childIssueId && !childIssueNumber) {
    throw new Error("Provide childIssueId or childIssueNumber");
  }

  // If only number is given, fetch the numeric "id"
  let effectiveChildId = childIssueId;
  if (!effectiveChildId) {
    const child = await getIssueByNumber({
      octokit,
      owner,
      repo,
      issueNumber: childIssueNumber,
    });
    effectiveChildId = child.id;
    core?.info?.(
      `[sub-issues] resolved child #${childIssueNumber} → issue_id=${effectiveChildId}`
    );
  }

  // Pre-check: is child already a sub-issue of parent?
  const current = await listSubIssues({
    octokit,
    owner,
    repo,
    parentIssueNumber,
    core,
  });
  const exists = current.some(
    (it) => Number(it.id) === Number(effectiveChildId)
  );
  if (exists) {
    core?.notice?.(
      `[sub-issues] skip: already linked parent #${parentIssueNumber} ← child(issue_id=${effectiveChildId})`
    );
    return { ok: true, skipped: true, status: 200 };
  }

  // Attempt link
  const res = await addSubIssue({
    octokit,
    owner,
    repo,
    parentIssueNumber,
    childIssueId: effectiveChildId,
    core,
  });
  return { ok: !!res.ok, skipped: !!res.skipped, status: res.status || 200 };
}

module.exports = {
  listSubIssues,
  getIssueByNumber,
  addSubIssue, // raw call (kept for completeness)
  addSubIssueIfMissing, // idempotent wrapper
};
