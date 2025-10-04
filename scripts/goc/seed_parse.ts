import { ParsedSeed, SeedHeader } from "./types";

/**
 * Parse a Markdown seed file's content into {header, body}.
 * Header must be an HTML comment block at the top of the file.
 * Arrays must be valid JSON arrays in the comment.
 */
export function parseSeedMarkdown(content: string, path: string): ParsedSeed {
  const trimmed = content.trimStart();
  const m = trimmed.match(/^<!--([\s\S]*?)-->\s*/);
  if (!m) {
    throw new Error(`Seed missing header comment: ${path}`);
  }
  const headerRaw = m[1];
  const body = trimmed.slice(m[0].length);

  // Parse simple key: value lines; arrays must be JSON
  const header: any = {};
  for (const line of headerRaw.split("\n")) {
    const t = line.trim();
    if (!t || t.startsWith("#")) continue;
    const idx = t.indexOf(":");
    if (idx === -1) continue;
    const key = t.slice(0, idx).trim();
    let value = t.slice(idx + 1).trim();

    // Strip optional surrounding quotes for simple strings
    if (value.startsWith('"') && value.endsWith('"')) value = value.slice(1, -1);
    if (value.startsWith("'") && value.endsWith("'")) value = value.slice(1, -1);

    // Arrays must be JSON arrays (e.g., ["ci","phase:phase-0"])
    if (value.startsWith("[") && value.endsWith("]")) {
      try { header[key] = JSON.parse(value); }
      catch { throw new Error(`Invalid JSON array for key '${key}' in ${path}`); }
      continue;
    }

    header[key] = value;
  }

  // Enforce required keys + array types
  if (!header.title) throw new Error(`Missing 'title' in ${path}`);
  if (!header.uid) throw new Error(`Missing 'uid' in ${path}`);

  const ensureArray = (k: string) => {
    if (header[k] === undefined) return;
    if (!Array.isArray(header[k])) {
      throw new Error(`'${k}' must be a JSON array in ${path}`);
    }
    // Ensure string[]
    header[k] = (header[k] as any[]).map(String);
  };
  ensureArray("labels");
  ensureArray("assignees");
  ensureArray("children_uids");

  // Coerce project to union if present
  if (header.project && header.project !== "test" && header.project !== "main") {
    throw new Error(`'project' must be "test" or "main" in ${path}`);
  }

  return { header: header as SeedHeader, body, path };
}
