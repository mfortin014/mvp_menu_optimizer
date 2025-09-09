# Upgrade: Single-DB Multi-Tenant + Soft Delete (MVP)

## Prereqs
- `psql` and `pg_dump` installed.
- `.env` at repo root:
```
DATABASE_URL=postgresql://user:pass@host:port/dbname?sslmode=require
SUPABASE_URL=
SUPABASE_KEY=
CHEF_EMAIL=davidnoireaut@surlefeu.com
```

## First time only
```bash
chmod +x scripts/*.sh
```

## Run
```bash
./scripts/backup_db.sh
./scripts/upgrade.sh
./scripts/verify.sh
```
