import { SeedHeader } from "./types";

/** Resolve final Project URL: explicit header > test/main variable > default repo var */
export function resolveProjectUrl(
  header: SeedHeader,
  env: Record<string,string | undefined>
): { url: string, source: string } {
  if (header.project_url && header.project_url.trim()) {
    return { url: header.project_url.trim(), source: "seed.project_url" };
  }
  if (header.project === "test" && env.PROJECT_URL_TEST) {
    return { url: env.PROJECT_URL_TEST, source: "seed.project=test" };
  }
  if (header.project === "main" && env.PROJECT_URL) {
    return { url: env.PROJECT_URL, source: "seed.project=main" };
  }
  if (env.PROJECT_URL) return { url: env.PROJECT_URL, source: "vars.PROJECT_URL" };
  throw new Error("No Project URL resolved (set PROJECT_URL or use project_url in seed)");
}
