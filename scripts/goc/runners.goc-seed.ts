import { logger } from "../logger.js";
import { parseSeedMarkdown } from "../seed_parse.js";
import { resolveProjectUrl } from "../routing.js";
import * as fs from "node:fs";

async function main() {
  const seedsGlob = process.env.INPUT_SEEDS_GLOB || "";
  const projectOverride = process.env.INPUT_PROJECT_URL_OVERRIDE || "";
  const linkAfterSeed = (process.env.INPUT_LINK_AFTER_SEED || "").toLowerCase() === "true";

  logger.notice(`goc-seed: seeds_glob="${seedsGlob}" project_url_override="${projectOverride}" link_after_seed=${linkAfterSeed}`);

  // This runner is intentionally minimal for E2.2; we just prove wiring.
  // Real issue creation / field writes are implemented when we toggle workflows to use this.
  // Demonstrate parsing on a single file if a direct path is provided:
  if (seedsGlob && fs.existsSync(seedsGlob)) {
    const content = fs.readFileSync(seedsGlob, "utf8");
    const parsed = parseSeedMarkdown(content, seedsGlob);
    const route = resolveProjectUrl(parsed.header, {
      PROJECT_URL: process.env.PROJECT_URL,
      PROJECT_URL_TEST: process.env.PROJECT_URL_TEST
    });
    logger.notice(`seed uid=${parsed.header.uid} -> route=${route.url} (source=${route.source})`);
  }

  // Exit success
  process.exit(0);
}

main().catch((e) => { logger.error(String(e?.message ?? e)); process.exit(1); });
