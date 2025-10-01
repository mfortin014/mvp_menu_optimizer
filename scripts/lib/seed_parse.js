// scripts/lib/seed_parse.js
// Parse the top HTML comment header into a normalized object.
// Enforces JSON arrays for `labels`, `assignees`, `children_uids`.

function extractHeader(markdown) {
  const m = markdown.match(/^<!--([\s\S]*?)-->/);
  return m ? m[1] : "";
}

function parseLinesToObject(block) {
  const obj = {};
  const lines = block.split(/\r?\n/);
  for (let raw of lines) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) continue;
    const idx = line.indexOf(":");
    if (idx === -1) continue;
    const key = line.slice(0, idx).trim().toLowerCase();
    let val = line.slice(idx + 1).trim();
    // Strip surrounding quotes for plain scalars
    if (/^".*"$/.test(val) || /^'.*'$/.test(val)) {
      val = val.slice(1, -1);
    }
    obj[key] = val;
  }
  return obj;
}

function normalizeArrays(obj) {
  const arrayKeys = ["labels", "assignees", "children_uids"];
  for (const k of arrayKeys) {
    if (!(k in obj)) continue;
    const raw = obj[k];
    // Expect JSON array
    try {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.every((s) => typeof s === "string")) {
        obj[k] = parsed;
      } else {
        console.warn(
          `seed_parse: "${k}" not an array of strings; coercing to []`
        );
        obj[k] = [];
      }
    } catch {
      console.warn(`seed_parse: "${k}" not valid JSON; coercing to []`);
      obj[k] = [];
    }
  }
  return obj;
}

function parseSeedHeader(markdown) {
  const hdr = extractHeader(markdown);
  if (!hdr) return {};
  const obj = parseLinesToObject(hdr);
  normalizeArrays(obj);
  return obj;
}

module.exports = { parseSeedHeader };
