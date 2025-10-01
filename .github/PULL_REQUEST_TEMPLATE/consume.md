# chore(automation): consume seeds → applied/

This PR was created by the seeder. It moves processed seeds and updates the library index.

## What’s in here

- Move: `.github/project-seeds/pending/**` → `applied/`
- Update: `.github/project-seeds/library.json`

## Safety

- No code changes outside `.github/project-seeds/**`
- Re-run safe; idempotent moves/updates

<!-- Keep this short; reviewers just sanity-check file moves & library diff. -->
