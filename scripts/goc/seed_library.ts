import * as fs from 'node:fs';
import * as p from 'node:path';
import { LibraryEntry } from "./types";

const DEFAULT_PATH = ".github/project-seeds/library.json";

export function readLibrary(filePath: string = DEFAULT_PATH): LibraryEntry[] {
  if (!fs.existsSync(filePath)) return [];
  const raw = fs.readFileSync(filePath, "utf8").trim();
  if (!raw) return [];
  try { return JSON.parse(raw) as LibraryEntry[]; }
  catch (e: any) { throw new Error(`Invalid library JSON at ${filePath}: ${e.message}`); }
}

export function upsertLibraryEntry(entry: LibraryEntry, filePath: string = DEFAULT_PATH): void {
  const lib = readLibrary(filePath);
  const i = lib.findIndex(x => x.uid === entry.uid);
  if (i >= 0) lib[i] = entry; else lib.push(entry);
  fs.mkdirSync(p.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, JSON.stringify(lib, null, 2) + "\n", "utf8");
}

export function findByUid(uid: string, filePath: string = DEFAULT_PATH): LibraryEntry | undefined {
  return readLibrary(filePath).find(x => x.uid === uid);
}
