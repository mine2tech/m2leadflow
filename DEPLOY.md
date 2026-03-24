# Deployment Guide

## Server Details

- **Host**: `root@144.24.119.241`
- **SSH**: `ssh -i ~/keys/m2/m2portal.pem root@144.24.119.241`
- **App path**: `/opt/m2leadflow`
- **App URL**: `http://144.24.119.241:3000`
- **Architecture**: ARM64 (Oracle Cloud), Ubuntu 22.04, Docker

## Quick Deploy (code update)

Run from local machine:

```bash
# 1. Create tarball (excludes secrets, git, tmp)
cd ~/projects/mine2
tar czf /tmp/m2leadflow.tar.gz \
  --exclude='.git' --exclude='node_modules' --exclude='log/*' \
  --exclude='tmp/*' --exclude='storage/*' --exclude='.bundle' \
  --exclude='.env' --exclude='.env.production' --exclude='config/master.key' \
  --exclude='.claude/skills/cowork_config.json' --exclude='*.png' \
  m2leadflow/

# 2. SCP to server
scp -i ~/keys/m2/m2portal.pem /tmp/m2leadflow.tar.gz root@144.24.119.241:/tmp/

# 3. SSH in, extract (preserving .env.production), rebuild, restart
ssh -i ~/keys/m2/m2portal.pem root@144.24.119.241
cd /opt/m2leadflow
cp .env.production /tmp/.env.production.bak
tar xzf /tmp/m2leadflow.tar.gz --strip-components=1 --overwrite
cp /tmp/.env.production.bak .env.production
docker compose build --no-cache
docker compose down && docker compose up -d
```

## First-time Setup

### 1. Create local DB dump

```bash
PGPASSWORD=<your-db-password> pg_dump -U postgres -h localhost -Fc m2leadflow_development > /tmp/m2leadflow.dump
```

### 2. Transfer app + dump to server

```bash
scp -i ~/keys/m2/m2portal.pem /tmp/m2leadflow.tar.gz /tmp/m2leadflow.dump root@144.24.119.241:/tmp/
```

### 3. Extract and set up on server

```bash
ssh -i ~/keys/m2/m2portal.pem root@144.24.119.241

mkdir -p /opt/m2leadflow
cd /opt/m2leadflow
tar xzf /tmp/m2leadflow.tar.gz --strip-components=1
```

### 4. Create .env.production

Copy from `.env.production.example` or create manually. Required vars:

```
RAILS_ENV=development
SECRET_KEY_BASE=<generate with: openssl rand -hex 64>
DATABASE_HOST=db
DATABASE_PORT=5432
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=<your-db-password>
BASIC_AUTH_USERNAME=<username>
BASIC_AUTH_PASSWORD=<generate with: openssl rand -hex 16>
API_KEY=<generate with: openssl rand -hex 32>
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=mine2.io
SMTP_USERNAME=<your-email>
SMTP_PASSWORD=<google app password>
GMAIL_CLIENT_ID=<from Google Cloud Console>
GMAIL_CLIENT_SECRET=<from Google Cloud Console>
GMAIL_REDIRECT_URI=http://144.24.119.241:3000/auth/gmail/callback
DEFAULT_FOLLOWUP_DELAY_DAYS=3
DEFAULT_MAX_FOLLOWUPS=3
```

### 5. Build and start

```bash
docker compose build --no-cache
docker compose up -d
```

### 6. Restore database dump

```bash
mkdir -p tmp/dump
cp /tmp/m2leadflow.dump tmp/dump/
docker exec m2leadflow-db-1 pg_restore -U postgres -d m2leadflow_development --clean --if-exists --no-owner /dump/m2leadflow.dump
```

### 7. Run migrations and seed

```bash
docker exec m2leadflow-web-1 bundle exec rails db:migrate
docker exec m2leadflow-web-1 bundle exec rails db:seed
```

## Docker Services

| Service | Purpose | Port |
|---------|---------|------|
| **db** | PostgreSQL 16 | 5433 (host) → 5432 (container) |
| **web** | Puma (Rails app) | 3000 |
| **jobs** | Solid Queue worker (Gmail polling, followup checks) | — |

## Common Operations

```bash
# SSH into server
ssh -i ~/keys/m2/m2portal.pem root@144.24.119.241
cd /opt/m2leadflow

# View logs
docker compose logs -f              # all services
docker compose logs -f web          # just web
docker compose logs -f jobs         # just worker

# Restart services
docker compose restart web jobs     # NOTE: doesn't reload .env.production
docker compose down && docker compose up -d   # full restart, reloads env

# Run Rails console
docker exec -it m2leadflow-web-1 bundle exec rails console

# Run migrations
docker exec m2leadflow-web-1 bundle exec rails db:migrate

# Run a one-off command
docker exec m2leadflow-web-1 bundle exec rails runner "puts User.count"

# Check container status
docker compose ps

# Database backup from server
docker exec m2leadflow-db-1 pg_dump -U postgres -Fc m2leadflow_development > /tmp/backup.dump

# Database restore on server
docker exec m2leadflow-db-1 pg_restore -U postgres -d m2leadflow_development --clean --if-exists --no-owner /dump/m2leadflow.dump
```

## Gotchas

- **`docker compose restart` does NOT reload `.env.production`** — use `docker compose down && docker compose up -d` instead
- **Jobs container may fail on first boot** if web hasn't created the DB yet — it depends on web via `service_started` and has a 10s sleep, but if that's not enough, just `docker compose restart jobs`
- **Port 80/443 are taken** by an existing nginx Docker container — app runs on 3000
- **DB volume persists** across `docker compose down` — data is safe unless you explicitly `docker compose down -v`
- **Tailwind CSS is built at Docker build time** — if styles look wrong, rebuild: `docker compose build --no-cache`
