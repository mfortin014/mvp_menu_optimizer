<!--
title: chore,scripts: Make `dump_sample_data.sh` Bitwarden-run aware
labels: ["ci","db"]
uid: scripts-dump-sample-data-bws2
parent_uid: epic-bws-script-hardening
type: Chore
status: Todo
priority: P2
area: ci
-->

# chore,scripts: Make `dump_sample_data.sh` Bitwarden-run aware

## Intent

Run sample-data exports through `bws run --project-id=…` and synthesize the connection URL so the script stays environment agnostic.

## Scope

- Replace ambient `DATABASE_URL` usage with `python -m utils.db`, honoring a driver override flag.
- Remove `.env` sourcing and update help text to show the Bitwarden invocation pattern.
- Ensure schema selection still works with the synthesized URL.

## Acceptance

- `bws run --project-id="$TEST" -- ./dump_sample_data.sh` succeeds without sourcing `.env`.
- The script fails fast with a clear error if required secrets are missing.
- No references remain to prod/staging env vars.

<!-- seed-uid:cripts-dump-sample-data-bws2 -->
