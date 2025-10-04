import { ghGraphQL } from "./github_api.js";

/**
 * Write Project fields by **display name** (case-insensitive).
 * - For single-selects: match by option name (case-insensitive).
 * - For text: write literal.
 */
export async function writeFields(
  projectNodeId: string,
  itemNodeId: string,
  writes: { name: string; value: string }[],
  token: string
): Promise<{written: number}> {
  if (!writes.length) return { written: 0 };

  // 1) Read field meta: names, IDs, types, options
  const metaQuery = `
    query($id:ID!){
      node(id:$id){
        ... on ProjectV2 {
          fields(first:100){
            nodes{
              ... on ProjectV2FieldCommon { id name dataType }
              ... on ProjectV2SingleSelectField { id name dataType options { id name } }
            }
          }
        }
      }
    }`;
  const meta = await ghGraphQL<any>(metaQuery, { id: projectNodeId }, token);
  const fields = meta.node?.fields?.nodes ?? [];
  const findField = (n: string) => fields.find((f: any) => (f.name || "").toLowerCase() === n.toLowerCase());

  let wrote = 0;

  for (const w of writes) {
    const f = findField(w.name);
    if (!f) {
      // field missing; skip but not fatal
      continue;
    }
    const fieldId = f.id as string;

    if (f.dataType === "SINGLE_SELECT") {
      const opt = (f.options || []).find((o: any) => (o.name || "").toLowerCase() === w.value.toLowerCase());
      if (!opt) {
        // option not found; skip
        continue;
      }
      const mutation = `
        mutation($projectId:ID!,$itemId:ID!,$fieldId:ID!,$optionId:String!){
          updateProjectV2ItemFieldValue(input:{
            projectId:$projectId,itemId:$itemId,fieldId:$fieldId,
            value:{ singleSelectOptionId:$optionId }
          }){ clientMutationId }
        }`;
      await ghGraphQL(mutation, { projectId: projectNodeId, itemId: itemNodeId, fieldId, optionId: opt.id }, token);
      wrote++;
      continue;
    }

    // TEXT
    const mutation = `
      mutation($projectId:ID!,$itemId:ID!,$fieldId:ID!,$text:String!){
        updateProjectV2ItemFieldValue(input:{
          projectId:$projectId,itemId:$itemId,fieldId:$fieldId,
          value:{ text:$text }
        }){ clientMutationId }
      }`;
    await ghGraphQL(mutation, { projectId: projectNodeId, itemId: itemNodeId, fieldId, text: w.value }, token);
    wrote++;
  }

  return { written: wrote };
}
