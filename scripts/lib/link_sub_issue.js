// scripts/link_sub_issue.js
// Step 4: Link native parent/child relationships by reading library.json only.
// Uses: scripts/lib/sub_issues.js (addSubIssueIfMissing)

"use strict";

const fs = require("fs");
const path = require("path");
const { addSubIssueIfMissing } = require("./lib/sub_issues.js");

function readLibrary(libraryPath = ".github/project-seeds/library.json") {
  try {
    const p = path.resolve(process.cwd(), libraryPath);
    const raw = fs.readFileSync(p, "utf8");
    const data = JSON.parse(raw);
    if (Array.isArray(data)) return data;
    if (data && Array.isArray(data.records)) return data.records;
    return [];
  } catch (_) {
    return [];
  }
}

/**
 * Link all parent/child pairs found in library.json.
 * A record links if:
 *  - record.parent_uid is present
 *  - both child.issue_number and parent.issue_number can be resolved from the library
 */
async function linkFromLibrary({
  octokit,
  core,
  owner,
  repo,
  dryRun = false,
  libraryPath,
}) {
  const records = readLibrary(libraryPath);
  core.notice(`[link-lib] loaded ${records.length} records from library`);

  // Build index by uid for quick parent lookups
  const byUid = new Map();
  for (const r of records) {
    if (!r || !r.uid) continue;
    byUid.set(String(r.uid), r);
  }

  let attempts = 0,
    linked = 0,
    skipped = 0,
    warnings = 0;

  for (const child of records) {
    const uid = child?.uid;
    const parentUid = child?.parent_uid;
    if (!uid || !parentUid) continue; // only children with a parent

    const childNum = Number(child.issue_number);
    const parent = byUid.get(String(parentUid));
    const parentNum = Number(parent?.issue_number);

    if (!childNum || !parentNum) {
      core.warning(
        `[link-lib] missing issue_number(s) for uid=${uid} (parent_uid=${parentUid}) — child=${
          childNum || "n/a"
        } parent=${parentNum || "n/a"}`
      );
      warnings++;
      continue;
    }

    attempts++;
    if (dryRun) {
      core.notice(
        `[dry-run] would link: Parent #${parentNum} ← Child #${childNum} (uids: ${parentUid}/${uid})`
      );
      continue;
    }

    const res = await addSubIssueIfMissing({
      octokit,
      owner,
      repo,
      parentIssueNumber: parentNum,
      childIssueNumber: childNum,
      core,
    });

    if (res.ok && res.skipped) skipped++;
    else if (res.ok) linked++;
  }

  core.notice(
    `[link-lib] done: attempts=${attempts} linked=${linked} skipped=${skipped} warnings=${warnings} dry_run=${dryRun}`
  );
}

module.exports = { linkFromLibrary };
