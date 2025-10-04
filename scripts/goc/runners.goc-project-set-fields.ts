import { logger } from "../logger.js";

async function main() {
  const projectUrl = process.env.INPUT_PROJECT_URL || "";
  const issueNodeId = process.env.INPUT_ISSUE_NODE_ID || "";
  const fields = {
    type: process.env.INPUT_TYPE || "",
    status: process.env.INPUT_STATUS || "",
    priority: process.env.INPUT_PRIORITY || "",
    target: process.env.INPUT_TARGET || "",
    area: process.env.INPUT_AREA || "",
    doc: process.env.INPUT_DOC || "",
    pr: process.env.INPUT_PR || ""
  };

  logger.notice(`goc-project-set-fields: issue=${issueNodeId} project=${projectUrl} fields=${JSON.stringify(fields)}`);
  process.exit(0);
}

main().catch((e) => { logger.error(String(e?.message ?? e)); process.exit(1); });
