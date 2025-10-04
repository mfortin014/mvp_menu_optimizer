export type Json = string | number | boolean | null | Json[] | { [key: string]: Json };

export interface SeedHeader {
  title: string;
  labels?: string[];
  assignees?: string[];
  uid: string;
  parent_uid?: string;
  children_uids?: string[];
  type?: string;
  status?: string;
  priority?: string;
  target?: string;
  area?: string;
  doc?: string;
  pr?: string;
  project?: "test" | "main";
  project_url?: string;
}

export interface ParsedSeed {
  header: SeedHeader;
  body: string;
  path: string;
}

export interface IssueRef {
  number: number;
  nodeId: string;
}

export interface ProjectContext {
  url: string;
  nodeId: string;
}

export interface FieldWrite {
  name: "Type"|"Status"|"Priority"|"Target Release"|"Area"|"Doc Link"|"PR Link";
  value: string;
}

export interface LibraryEntry {
  uid: string;
  issue_number: number;
  issue_node_id: string;
  project_item_id?: string;
  parent_uid?: string;
  created_at: string;
}

export interface Logger {
  notice(msg: string): void;
  warn(msg: string): void;
  error(msg: string): void;
}
