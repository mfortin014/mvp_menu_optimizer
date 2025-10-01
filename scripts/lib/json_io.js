// scripts/lib/json_io.js
// Tiny JSON helpers: atomic write, stable sort, dedupe, validate.

const fs = require("fs");
const path = require("path");

function readJsonFile(p) {
  try {
    const s = fs.readFileSync(p, "utf8");
    return JSON.parse(s);
  } catch (e) {
    return {}; // missing or malformed → treat as empty
  }
}

function writeJsonAtomic(p, dataObj) {
  const dir = path.dirname(p);
  const tmp = path.join(dir, `.tmp_${path.basename(p)}_${Date.now()}`);
  const s = JSON.stringify(dataObj, null, 2) + "\n";
  fs.writeFileSync(tmp, s, "utf8");
  fs.renameSync(tmp, p); // atomic on same device
}

function stableSortRecords(records) {
  return [...records].sort((a, b) => {
    const ua = (a.uid || "").toString();
    const ub = (b.uid || "").toString();
    return ua.localeCompare(ub);
  });
}

function dedupeByUid(records) {
  const seen = new Map();
  for (const r of records) {
    const uid = r && r.uid ? String(r.uid) : "";
    if (!uid) continue;
    if (!seen.has(uid)) {
      seen.set(uid, r);
    } else {
      // Keep earliest created_at if both exist
      const cur = seen.get(uid);
      const a = Date.parse(cur.created_at || "") || Infinity;
      const b = Date.parse(r.created_at || "") || Infinity;
      if (b < a) seen.set(uid, r);
    }
  }
  return Array.from(seen.values());
}

function validateRecord(r) {
  if (!r || typeof r !== "object") return false;
  const must = ["uid", "owner", "repo", "issue_number", "issue_node_id"];
  for (const k of must) {
    if (!(k in r)) return false;
  }
  if (typeof r.uid !== "string") return false;
  if (typeof r.owner !== "string") return false;
  if (typeof r.repo !== "string") return false;
  if (typeof r.issue_number !== "number") return false;
  if (typeof r.issue_node_id !== "string") return false;
  // Optional: parent_uid (string|null), project_item_id (string|null), created_at (ISO string)
  return true;
}

module.exports = {
  readJsonFile,
  writeJsonAtomic,
  stableSortRecords,
  dedupeByUid,
  validateRecord,
};
