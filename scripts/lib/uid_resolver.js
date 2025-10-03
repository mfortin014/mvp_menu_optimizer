// scripts/lib/uid_resolver.js
// Step 1: Single-source UID resolver for Automation B.
// Priority: 1) library.json lookup → 2) GitHub search fallback.
// No seeder wiring here (that’s Step 4).

"use strict";

const fs = require("fs");
const path = require("path");

/**
 * Read JSON file tolerantly.
 * Returns [] on missing/invalid; supports either array or {records:[...]} shapes.
 */
function readLibrary(libraryPath) {
  try {
    const p = path.resolve(process.cwd(), libraryPath);
    const raw = fs.readFileSync(p, "utf8");
    const data = JSON.parse(raw);
    if (Array.isArray(data)) return data;
    if (data && Array.isArray(data.records)) return data.records;
    return [];
  } catch (_) {
    return [];
  }
}

/**
 * Try to resolve from library.json
 * @returns { issue_number:number, issue_node_id:string } | null
 */
function resolveFromLibrary({ uid, libraryPath }) {
  const records = readLibrary(libraryPath);
  if (!records.length) return null;
  const hit = records.find(
    (r) =>
      r &&
      typeof r.uid === "string" &&
      r.uid.toLowerCase() === String(uid).toLowerCase()
  );
  if (hit?.issue_number && hit?.issue_node_id) {
    return {
      issue_number: Number(hit.issue_number),
      issue_node_id: String(hit.issue_node_id),
    };
  }
  return null;
}

/**
 * Fallback: search for the embedded "seed-uid:<uid>" marker in issue bodies.
 * Uses REST search API; filters out PRs.
 * @returns { issue_number:number, issue_node_id:string } | null
 */
async function resolveByUidViaSearch({ octokit, owner, repo, uid }) {
  const q = `repo:${owner}/${repo} is:issue in:body "seed-uid:${uid}"`;
  const res = await octokit.rest.search.issuesAndPullRequests({
    q,
    per_page: 5,
  });
  const issues = (res.data?.items || []).filter((i) => !i.pull_request);
  if (!issues.length) return null;

  const top = issues[0];
  // Optional extra fetch to confirm marker (defensive, but non-blocking)
  try {
    const full = await octokit.rest.issues.get({
      owner,
      repo,
      issue_number: top.number,
    });
    const body = full.data?.body || "";
    if (!body.includes(`seed-uid:${uid}`)) {
      // soft warning only; search hit is usually good enough
    }
  } catch (_) {}

  return { issue_number: top.number, issue_node_id: top.node_id };
}

/**
 * Public: resolveIssueByUid
 * Priority: library → search.
 * @param {object} params
 * @param {*} params.octokit
 * @param {string} params.owner
 * @param {string} params.repo
 * @param {string} params.uid
 * @param {string} [params.libraryPath=".github/project-seeds/library.json"]
 * @param {*} [params.core] - optional @actions/core for notices/warnings
 * @returns {Promise<{issue_number:number, issue_node_id:string}|null>}
 */
async function resolveIssueByUid({
  octokit,
  owner,
  repo,
  uid,
  libraryPath = ".github/project-seeds/library.json",
  core,
}) {
  // 1) library
  const lib = resolveFromLibrary({ uid, libraryPath });
  if (lib) {
    core?.notice?.(`[resolver] library hit uid=${uid} → #${lib.issue_number}`);
    return lib;
  } else {
    core?.info?.(
      `[resolver] no library entry for uid=${uid}; falling back to search`
    );
  }

  // 2) search
  const viaSearch = await resolveByUidViaSearch({ octokit, owner, repo, uid });
  if (!viaSearch) {
    core?.warning?.(`[resolver] no match for uid=${uid} (library+search)`);
    return null;
  }
  core?.notice?.(
    `[resolver] search hit uid=${uid} → #${viaSearch.issue_number} (${viaSearch.issue_node_id})`
  );
  return viaSearch;
}

module.exports = {
  resolveIssueByUid,
  resolveByUidViaSearch,
  // keep a named export for internal testing if you add tests later
  __internal: { readLibrary, resolveFromLibrary },
};
