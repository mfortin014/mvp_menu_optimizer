// scripts/lib/uid_resolver.js
// Host-agnostic stubs to be called from actions/github-script.
// You’ll wire these to Octokit in the workflow step.

async function resolveByUidViaSearch({ octokit, owner, repo, uid }) {
  // Search by the embedded body marker: <!-- seed-uid:UID -->
  // We scope to repo issues to avoid global search limits.
  const q = `repo:${owner}/${repo} in:body "seed-uid:${uid}"`;
  const res = await octokit.rest.search.issuesAndPullRequests({ q });
  const item = res.data.items.find((i) =>
    i.repository_url.endsWith(`/${owner}/${repo}`)
  );
  if (!item) return null;
  return { issue_number: item.number, issue_node_id: item.node_id };
}

async function resolveProjectItemId({ octokit, projectId, issueNodeId }) {
  // GraphQL: find the project item that references this issue, in projectId
  const query = `
    query($projectId: ID!, $contentId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 50, query: "") {
            nodes {
              id
              content { ... on Issue { id } }
            }
          }
        }
      }
    }`;
  // NOTE: For scale, you’ll want a targeted query (or server-side filter) later.
  const r = await octokit.graphql(query, { projectId, contentId: issueNodeId });
  const items = r?.node?.items?.nodes || [];
  const hit = items.find((n) => n?.content?.id === issueNodeId);
  return hit?.id || null;
}

module.exports = { resolveByUidViaSearch, resolveProjectItemId };
