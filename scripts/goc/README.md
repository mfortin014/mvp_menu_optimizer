# scripts/goc — Domain Logic

This folder houses reusable, testable modules for **GitHub Objects Creation (GOC)**.
E2 introduces pure module contracts; E2.2 plugs in real GitHub API calls and wires actions.

## Modules
- `types.ts` — shared types/contracts
- `seed_parse.ts` — parse HTML comment header; enforce JSON arrays; return {header, body}
- `seed_library.ts` — local UID↔Issue map (`.github/project-seeds/library.json`)
- `routing.ts` — resolve Project URL from seed + env (project_url > project hint > default)
- `project_resolver.ts` — URL → Project node ID (GraphQL) **[stub: E2.2]**
- `fields_writer.ts` — write Project fields **[stub: E2.2]**
- `issue_creator.ts` — find/create issue **[stub: E2.2]**
- `hierarchy_linker.ts` — native Sub-issues link **[stub: E2.2]**
- `logger.ts` — standard notices/warnings

> E2.1 adds contracts and pure parts; **E2.2** implements GitHub calls and the actions will call these modules.
