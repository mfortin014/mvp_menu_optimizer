"use strict";

/** List sub-issues on a parent issue (same-repo). */
async function listSubIssues({ octokit, owner, repo, parentIssueNumber, core }) {
  if (!octokit) throw new Error("octokit is required");
  const endpoint = "GET /repos/{owner}/{repo}/issues/{issue_number}/sub_issues";
  try {
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
  } catch (e) {
    const status = e?.status || e?.response?.status;
    if (status === 404 || status === 410) {
      core?.warning?.(
        `[sub-issues] parent issue #${parentIssueNumber} not available (status=${status}); skipping`
      );
      return null; // signal "unavailable"
    }
    throw e;
  }
}

/** Fetch an issue by number to get its numeric "id" (required by Sub-issues API). */
async function getIssueByNumber({ octokit, owner, repo, issueNumber }) {
  try {
    const r = await octokit.rest.issues.get({ owner, repo, issue_number: issueNumber });
    return { id: r.data.id, node_id: r.data.node_id, number: r.data.number, title: r.data.title };
  } catch (e) {
    const status = e?.status || e?.response?.status;
    if (status === 404 || status === 410) {
      // Deleted or not found → treat as non-fatal (skip)
      return null;
    }
    throw e;
  }
}

/** Low-level add call. Treat “already linked” (422) as success. */
async function addSubIssue({ octokit, owner, repo, parentIssueNumber, childIssueId, core }) {
  const endpoint = "POST /repos/{owner}/{repo}/issues/{issue_number}/sub_issues";
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
    const already =
      status === 422 &&
      /already\s+.*sub-issue|Validation\s+Failed/i.test(
        msg + " " + JSON.stringify(error?.response?.data || {})
      );
    if (already) {
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

/** Idempotent wrapper: pre-check or add; accepts child issue_number or id. */
async function addSubIssueIfMissing({
  octokit,
  owner,
  repo,
  parentIssueNumber,
  childIssueId,
  childIssueNumber,
  core,
}) {
  if (!childIssueId && !childIssueNumber) {
    throw new Error("Provide childIssueId or childIssueNumber");
  }
  let effectiveChildId = childIssueId;
  if (!effectiveChildId) {
    const child = await getIssueByNumber({ octokit, owner, repo, issueNumber: childIssueNumber });
    if (!child) {
      core?.warning?.(
        `[sub-issues] child issue #${childIssueNumber} not available (deleted/404); skipping`
      );
      return { ok: true, skipped: true, status: 410 };
    }
    effectiveChildId = child.id;
    core?.info?.(`[sub-issues] resolved child #${childIssueNumber} → issue_id=${effectiveChildId}`);
  }
  const current = await listSubIssues({ octokit, owner, repo, parentIssueNumber, core });
  if (current === null) {
    // parent unavailable (deleted/404)
    return { ok: true, skipped: true, status: 410 };
  }
  const exists = current.some((it) => Number(it.id) === Number(effectiveChildId));
  if (exists) {
    core?.notice?.(
      `[sub-issues] skip: already linked parent #${parentIssueNumber} ← child(issue_id=${effectiveChildId})`
    );
    return { ok: true, skipped: true, status: 200 };
  }
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

module.exports = { listSubIssues, getIssueByNumber, addSubIssue, addSubIssueIfMissing };
