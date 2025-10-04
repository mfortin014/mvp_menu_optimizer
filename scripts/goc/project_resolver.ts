import { ghGraphQL } from "./github_api.js";

/**
 * Resolve a Projects v2 URL (user or org project) to its node ID.
 * Supports:
 *  - https://github.com/users/<login>/projects/<number>
 *  - https://github.com/orgs/<org>/projects/<number>
 */
export async function resolveProjectNodeId(projectUrl: string, token: string): Promise<string> {
  const mUser = projectUrl.match(/^https:\/\/github\.com\/users\/([^/]+)\/projects\/(\d+)/i);
  const mOrg  = projectUrl.match(/^https:\/\/github\.com\/orgs\/([^/]+)\/projects\/(\d+)/i);
  if (!mUser && !mOrg) {
    throw new Error(`Unsupported Project URL format: ${projectUrl}`);
  }
  const loginOrOrg = (mUser?.[1] ?? mOrg?.[1])!;
  const number = parseInt((mUser?.[2] ?? mOrg?.[2])!, 10);

  const query = `
    query($login:String,$org:String,$number:Int!){
      user(login:$login){ projectV2(number:$number){ id } }
      organization(login:$org){ projectV2(number:$number){ id } }
    }`;
  const data = await ghGraphQL<any>(query, { login: mUser ? loginOrOrg : null, org: mOrg ? loginOrOrg : null, number }, token);
  const id = data.user?.projectV2?.id ?? data.organization?.projectV2?.id;
  if (!id) throw new Error(`Project not found for ${projectUrl}`);
  return id as string;
}
