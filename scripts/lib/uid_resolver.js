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
  const q = `
    query($projectId:ID!, $after:String) {
      node(id:$projectId) {
        ... on ProjectV2 {
          items(first:100, after:$after) {
            nodes { id content { __typename ... on Issue { id } } }
            pageInfo { hasNextPage endCursor }
          }
        }
      }
    }`;
  let after = null;
  while (true) {
    const r = await octokit.graphql(q, { projectId, after });
    const items = r?.node?.items?.nodes || [];
    const hit = items.find(
      (n) => n?.content?.__typename === "Issue" && n.content.id === issueNodeId
    );
    if (hit) return hit.id;
    const pi = r?.node?.items?.pageInfo;
    if (!pi?.hasNextPage) break;
    after = pi.endCursor;
  }
  return null;
}

module.exports = { resolveByUidViaSearch, resolveProjectItemId };
