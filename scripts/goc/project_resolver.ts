/**
 * Placeholder: resolve a Project v2 URL to its node ID (GraphQL).
 * Implement in E2.2 by calling the GitHub API using a provided token.
 */
export async function resolveProjectNodeId(projectUrl: string, token: string): Promise<string> {
  // TODO: implement GraphQL call (projectsV2 id resolve)
  // Return a stable fake to keep callers from exploding during dry usage.
  return `PVT_FAKE_${Buffer.from(projectUrl).toString("base64").slice(0,8)}`;
}
