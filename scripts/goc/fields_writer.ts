import { FieldWrite } from "./types";

/**
 * Placeholder: write Project fields for a given item node ID.
 * Implement in E2.2 using GraphQL `updateProjectV2ItemFieldValue`.
 */
export async function writeFields(
  projectNodeId: string,
  itemNodeId: string,
  writes: FieldWrite[],
  token: string
): Promise<{written: number}> {
  // TODO: implement GraphQL updates; for now, pretend success.
  return { written: writes.length };
}
