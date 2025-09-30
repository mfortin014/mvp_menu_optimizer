/**
 * scripts/lib/uid_resolver.js
 * Resolve issues by seed UID and (optionally) find the ProjectV2 item id.
 */

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

async function resolveProjectItemId({ octokit, projectId, issueNodeId }) {
  // Page through project items and find the one whose content is our Issue id
  const q = `
    query($projectId:ID!, $after:String) {
      node(id:$projectId) {
        ... on ProjectV2 {
          items(first: 100, after: $after) {
            nodes {
              id
              content { __typename ... on Issue { id } }
            }
            pageInfo { hasNextPage endCursor }
          }
        }
      }
    }`;
  let after = null;
  // eslint-disable-next-line no-constant-condition
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
