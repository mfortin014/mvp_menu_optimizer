/**
 * Placeholder: create a native Sub-issues link (parent <- child).
 * Implement in E2.2 using REST Sub-issues endpoints.
 */
export async function ensureSubIssueLink(
  parentIssueNumber: number,
  childIssueNumber: number,
  token: string
): Promise<{linked: boolean, reason?: string}> {
  // TODO: implement REST call; treat existing as success.
  return { linked: false, reason: "stub" };
}
