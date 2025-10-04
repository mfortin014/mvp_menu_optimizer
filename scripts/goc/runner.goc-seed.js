/* Minimal parse+route runner (no deps, no API calls) */
import fs from 'node:fs';
import path from 'node:path';

function parseHeader(md, file) {
  const m = md.trimStart().match(/^<!--([\s\S]*?)-->\s*/);
  if (!m) throw new Error(`Seed missing header comment: ${file}`);
  const headerRaw = m[1];
  const header = {};
  for (const line of headerRaw.split('\n')) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const idx = t.indexOf(':');
    if (idx === -1) continue;
    const key = t.slice(0, idx).trim();
    let value = t.slice(idx + 1).trim();
    // strip surrounding quotes for simple scalars
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    if (value.startsWith('[') && value.endsWith(']')) {
      try { header[key] = JSON.parse(value); }
      catch { throw new Error(`Invalid JSON array for key '${key}' in ${file}`); }
      continue;
    }
    header[key] = value;
  }
  if (!header.title) throw new Error(`Missing 'title' in ${file}`);
  if (!header.uid) throw new Error(`Missing 'uid' in ${file}`);
  for (const k of ['labels','assignees','children_uids']) {
    if (header[k] !== undefined && !Array.isArray(header[k])) {
      throw new Error(`'${k}' must be a JSON array in ${file}`);
    }
  }
  if (header.project && !['test','main'].includes(header.project)) {
    throw new Error(`'project' must be "test" or "main" in ${file}`);
  }
  return header;
}

function resolveProjectUrl(header, env) {
  if (header.project_url && header.project_url.trim()) {
    return { url: header.project_url.trim(), source: 'seed.project_url' };
  }
  if (header.project === 'test' && env.PROJECT_URL_TEST) {
    return { url: env.PROJECT_URL_TEST, source: 'seed.project=test' };
  }
  if (header.project === 'main' && env.PROJECT_URL) {
    return { url: env.PROJECT_URL, source: 'seed.project=main' };
  }
  if (env.PROJECT_URL) return { url: env.PROJECT_URL, source: 'env.PROJECT_URL' };
  throw new Error('No Project URL resolved (set PROJECT_URL or use project_url in seed)');
}

function listSeeds(glob) {
  if (!glob) return [];
  // Expect pattern like "dir/*.md". If a file path is given, just use it.
  if (!glob.includes('*')) return fs.existsSync(glob) ? [glob] : [];
  const dir = path.dirname(glob);
  const ext = path.extname(glob) || '.md';
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir)
    .filter(f => f.toLowerCase().endsWith(ext.toLowerCase()))
    .map(f => path.join(dir, f));
}

async function main() {
  const seedsGlob = process.env.INPUT_SEEDS_GLOB || '';
  const override = process.env.INPUT_PROJECT_URL_OVERRIDE || '';
  const files = listSeeds(seedsGlob);
  console.log(`::notice::parse-run files=${files.length} pattern="${seedsGlob}"`);

  for (const file of files) {
    const md = fs.readFileSync(file, 'utf8');
    const header = parseHeader(md, file);
    const route = override
      ? { url: override, source: 'override' }
      : resolveProjectUrl(header, process.env);

    console.log(`::notice title=seed::uid=${header.uid} title="${header.title}" route="${route.url}" source=${route.source}`);
  }
}

main().catch(e => { console.log(`::error::${e.message || e}`); process.exit(1); });
