import { logger } from "../logger.js";

async function main() {
  const parent_number = process.env.INPUT_PARENT_NUMBER || "";
  const parent_uid = process.env.INPUT_PARENT_UID || "";
  const child_number = process.env.INPUT_CHILD_NUMBER || "";
  const child_uid = process.env.INPUT_CHILD_UID || "";
  const library_path = process.env.INPUT_LIBRARY_PATH || "";

  logger.notice(`gh-link-hierarchy: parent#=${parent_number} parent_uid=${parent_uid} child#=${child_number} child_uid=${child_uid} lib=${library_path}`);
  process.exit(0);
}

main().catch((e) => { logger.error(String(e?.message ?? e)); process.exit(1); });
