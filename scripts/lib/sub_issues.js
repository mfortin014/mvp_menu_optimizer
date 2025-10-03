// scripts/lib/sub_issues.js
// Step 2: Minimal helper to create a native Sub-issue link (parent ← child).
// Idempotency checks will be added in Step 3.

"use strict";

/**
 * addSubIssue
 * Creates a native parent/child relationship using the Sub-issues API.
 *
 * @param {object} params
 * @param {*} params.octokit              - Authenticated Octokit (Actions provides in github-script)
 * @param {string} params.owner
 * @param {string} params.repo
 * @param {number} params.parentIssueNumber
 * @param {number} params.childIssueId    - The *Issue ID* (not the issue number). If you only have the number,
 *                                          fetch the issue first to get its `id`.
 * @param {*} [params.core]               - Optional @actions/core for logging
 * @returns {Promise<{ok:boolean, status:number, data?:any, error?:any}>}
 */
async function addSubIssue({
  octokit,
  owner,
  repo,
  parentIssueNumber,
  childIssueId,
  core,
}) {
  if (!octokit) throw new Error("octokit is required");
  if (!owner || !repo) throw new Error("owner/repo are required");
  if (!parentIssueNumber || typeof parentIssueNumber !== "number")
    throw new Error("parentIssueNumber (number) is required");
  if (!childIssueId || typeof childIssueId !== "number")
    throw new Error(
      "childIssueId (number) is required (this is the Issue ID, not the number)"
    );

  const endpoint =
    "POST /repos/{owner}/{repo}/issues/{issue_number}/sub_issues";

  try {
    const res = await octokit.request(endpoint, {
      owner,
      repo,
      issue_number: parentIssueNumber,
      sub_issue_id: childIssueId,
    });

    const status = res.status || 200;
    core?.notice?.(
      `[sub-issues] linked parent #${parentIssueNumber} ← child(issue_id=${childIssueId}) [status=${status}]`
    );
    return { ok: true, status, data: res.data };
  } catch (error) {
    // We’ll add idempotency handling in Step 3; for now just bubble up status/message.
    const status = error?.status || 500;
    core?.warning?.(
      `[sub-issues] link failed parent #${parentIssueNumber} ← child(issue_id=${childIssueId}) [status=${status}] ${
        error?.message || error
      }`
    );
    return { ok: false, status, error };
  }
}

module.exports = {
  addSubIssue,
};
