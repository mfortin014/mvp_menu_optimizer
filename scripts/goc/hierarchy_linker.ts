import { ghREST, repoFromEnv } from "./github_api.js";

/**
 * Create a native Sub-issues link (parent <- child).
 * Treat existing link as success.
 */
export async function ensureSubIssueLink(
  parentIssueNumber: number,
  childIssueNumber: number,
  token: string,
  env: Record<string,string|undefined> = process.env
): Promise<{linked: boolean, reason?: string}> {
  const { owner, repo } = repoFromEnv(env);

  // Pre-check: list child’s tracked_by relationships (best-effort)
  try {
    const rels = await ghREST<any>(`/repos/${owner}/${repo}/issues/${childIssueNumber}/timeline?per_page=100`, token, {
      headers: { "Accept": "application/vnd.github+json" }
    });
    if (Array.isArray(rels)) {
      const has = rels.some((e: any) =>
        e.event === "connected" &&
        e.subject?.type === "issue" &&
        e.subject?.number === childIssueNumber &&
        e.source?.type === "issue" &&
        e.source?.number === parentIssueNumber
      );
      if (has) return { linked: false, reason: "exists" };
    }
  } catch {
    // timeline may require extra preview headers; ignore failures here
  }

  // Create link: child is "tracked by" parent (Sub-issues)
  // API: POST /repos/{owner}/{repo}/issues/{issue_number}/sub-issues with { "parent_issue_number": N }
  const res = await ghREST<any>(`/repos/${owner}/${repo}/issues/${childIssueNumber}/sub-issues`, token, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ parent_issue_number: parentIssueNumber })
  });

  // If API returns success, we're linked.
  return { linked: true };
}
