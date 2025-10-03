// scripts/lib/resolve_by_uid.js
// v1 resolver: library-first, then fallback search via GraphQL.
// Optionally resolves the ProjectV2 item id if projectId is provided.

const path = require("path");
const { readJsonFile } = require("./json_io"); // scripts/lib/json_io.js
const {
  resolveByUidViaSearch,
  resolveProjectItemId,
} = require("./uid_resolver"); // scripts/lib/uid_resolver.js

/**
 * resolveIssueByUid
 * @param {Object} params
 * @param {*} params.core        - @actions/core (for logs)
 * @param {*} params.octokit     - from actions/github-script
 * @param {string} params.owner
 * @param {string} params.repo
 * @param {string} params.uid
 * @param {string} [params.libraryPath='.github/project-seeds/library.json']
 * @param {string} [params.projectId] - optional ProjectV2 node id; if provided, also resolves project_item_id
 * @returns {Promise<{issue_number:number, issue_node_id:string, project_item_id?:string}|null>}
 */
async function resolveIssueByUid({
  core,
  octokit,
  owner,
  repo,
  uid,
  libraryPath = ".github/project-seeds/library.json",
  projectId,
}) {
  // 1) library.json first
  try {
    const p = path.resolve(process.cwd(), libraryPath);
    const data = readJsonFile(p); // tolerant: {} if unreadable
    let records = [];
    if (Array.isArray(data)) records = data;
    else if (data && Array.isArray(data.records)) records = data.records;

    if (records.length) {
      const hit = records.find(
        (r) =>
          r &&
          typeof r.uid === "string" &&
          r.uid.toLowerCase() === uid.toLowerCase()
      );
      if (hit?.issue_number && hit?.issue_node_id) {
        core?.info?.(
          `[resolver] library hit uid=${uid} → #${hit.issue_number} (${hit.issue_node_id})`
        );
        const out = {
          issue_number: Number(hit.issue_number),
          issue_node_id: String(hit.issue_node_id),
        };
        if (projectId) {
          const itemId = await resolveProjectItemId({
            octokit,
            projectId,
            issueNodeId: out.issue_node_id,
          });
          if (itemId) out.project_item_id = itemId;
        }
        return out;
      }
      core?.info?.(
        `[resolver] library present but no entry for uid=${uid} — will fallback to search`
      );
    } else {
      core?.info?.(
        `[resolver] library empty or missing — will fallback to search`
      );
    }
  } catch (e) {
    core?.warning?.(`[resolver] library read error: ${e?.message || e}`);
  }

  // 2) Fallback search (GraphQL issues search)
  const viaSearch = await resolveByUidViaSearch({ octokit, owner, repo, uid });
  if (!viaSearch) {
    core?.info?.(`[resolver] no search hit for uid=${uid}`);
    return null;
  }

  const out = {
    issue_number: viaSearch.issue_number,
    issue_node_id: viaSearch.issue_node_id,
  };

  if (projectId) {
    const itemId = await resolveProjectItemId({
      octokit,
      projectId,
      issueNodeId: out.issue_node_id,
    });
    if (itemId) out.project_item_id = itemId;
  }

  return out;
}

module.exports = { resolveIssueByUid };
