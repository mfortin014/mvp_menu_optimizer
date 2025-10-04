import { ghREST, repoFromEnv } from "./github_api.js";
import { ParsedSeed, IssueRef } from "./types";

/** Embed a hidden marker for idempotency */
function seedMarker(uid: string): string {
  return `<!-- seed-uid:${uid} -->`;
}

/** Search for an existing issue by seed marker (best-effort) */
async function findIssueBySeedUid(uid: string, token: string, env: Record<string,string|undefined>): Promise<IssueRef | null> {
  const { owner, repo } = repoFromEnv(env);
  // Use search issues (requires `repo` scope)
  const q = encodeURIComponent(`repo:${owner}/${repo} "${seedMarker(uid)}" in:body is:issue`);
  const res = await ghREST<any>(`/search/issues?q=${q}&per_page=1`, token);
  const item = res.items?.[0];
  if (!item) return null;
  return { number: item.number, nodeId: item.node_id };
}

export async function findOrCreateIssue(seed: ParsedSeed, token: string, env: Record<string,string|undefined> = process.env): Promise<IssueRef & { created: boolean }> {
  // 1) search by marker
  const existing = await findIssueBySeedUid(seed.header.uid, token, env);
  if (existing) return { ...existing, created: false };

  // 2) create new
  const { owner, repo } = repoFromEnv(env);
  const body = `${seedMarker(seed.header.uid)}\n\n${seed.body || `# ${seed.header.title}`}`;
  const payload = {
    title: seed.header.title,
    body,
    labels: seed.header.labels || [],
    assignees: seed.header.assignees || []
  };
  const created = await ghREST<any>(`/repos/${owner}/${repo}/issues`, token, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });
  return { number: created.number, nodeId: created.node_id, created: true };
}
