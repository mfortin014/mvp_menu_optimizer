import { LibraryEntry } from "./types";
import * as fs from "fs";

const DEFAULT_PATH = ".github/project-seeds/library.json";

export function readLibrary(path: string = DEFAULT_PATH): LibraryEntry[] {
  if (!fs.existsSync(path)) return [];
  const raw = fs.readFileSync(path, "utf8").trim();
  if (!raw) return [];
  try { return JSON.parse(raw) as LibraryEntry[]; }
  catch (e:any) { throw new Error(`Invalid library JSON at ${path}: ${e.message}`); }
}

export function upsertLibraryEntry(entry: LibraryEntry, path: string = DEFAULT_PATH): void {
  const lib = readLibrary(path);
  const i = lib.findIndex(x => x.uid === entry.uid);
  if (i >= 0) lib[i] = entry; else lib.push(entry);
  fs.mkdirSync(require("path").dirname(path), { recursive: true });
  fs.writeFileSync(path, JSON.stringify(lib, null, 2) + "\n", "utf8");
}

export function findByUid(uid: string, path: string = DEFAULT_PATH): LibraryEntry | undefined {
  return readLibrary(path).find(x => x.uid === uid);
}
