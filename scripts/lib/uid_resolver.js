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

async function resolveByUidViaSearch({ octokit, owner, repo, uid }) {
  // Search by embedded marker via GraphQL (avoids REST search deprecation)
  const q = `repo:${owner}/${repo} in:body "seed-uid:${uid}" is:issue`;
  const data = await octokit.graphql(
    `query($q:String!){
      search(query:$q, type:ISSUE, first:1){
        nodes { ... on Issue { number id } }
      }
    }`,
    { q }
  );
  const node = data?.search?.nodes?.[0];
  if (!node?.number || !node?.id) return null;
  return { issue_number: node.number, issue_node_id: node.id };
}

module.exports = { resolveByUidViaSearch, resolveProjectItemId };
