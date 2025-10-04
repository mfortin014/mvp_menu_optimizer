/**
 * Minimal GitHub API helpers using built-in fetch (Node 18+).
 * No external deps. Designed for Actions runners.
 */

export function pickToken(env: Record<string, string | undefined>): string {
  // Prefer PROJECTS_TOKEN for Projects v2 writes (orgs often restrict GITHUB_TOKEN)
  const t = env.PROJECTS_TOKEN || env.GITHUB_TOKEN;
  if (!t) throw new Error("Missing token: set PROJECTS_TOKEN or GITHUB_TOKEN in the environment.");
  return t;
}

export async function ghGraphQL<T = any>(query: string, variables: any, token: string): Promise<T> {
  const res = await fetch("https://api.github.com/graphql", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
      "Accept": "application/json"
    },
    body: JSON.stringify({ query, variables })
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`GraphQL HTTP ${res.status}: ${text}`);
  }
  const json = await res.json();
  if (json.errors?.length) {
    const msg = json.errors.map((e: any) => e.message).join("; ");
    throw new Error(`GraphQL error: ${msg}`);
  }
  return json.data as T;
}

export async function ghREST<T = any>(path: string, token: string, init?: RequestInit): Promise<T> {
  const url = path.startsWith("http") ? path : `https://api.github.com${path}`;
  const res = await fetch(url, {
    method: init?.method ?? "GET",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Accept": "application/vnd.github+json",
      ...(init?.headers || {})
    },
    body: init?.body
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`REST ${res.status} ${path}: ${text}`);
  }
  if (res.status === 204) return {} as T;
  return await res.json() as T;
}

/** Extract owner/repo from GITHUB_REPOSITORY=owner/repo */
export function repoFromEnv(env: Record<string, string | undefined>): { owner: string; repo: string } {
  const rr = env.GITHUB_REPOSITORY;
  if (!rr) throw new Error("GITHUB_REPOSITORY is not set (expected owner/repo).");
  const [owner, repo] = rr.split("/");
  return { owner, repo };
}
