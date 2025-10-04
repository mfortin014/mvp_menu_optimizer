import { ParsedSeed, IssueRef } from "./types";

/**
 * Placeholder: find-or-create an issue based on embedded seed-uid marker.
 * Implement in E2.2 using REST (search + create).
 */
export async function findOrCreateIssue(seed: ParsedSeed, token: string): Promise<IssueRef & { created: boolean }> {
  // TODO: implement via REST. For now, pretend there's an existing issue #0.
  return { number: 0, nodeId: "I_FAKE_NODE", created: false };
}
