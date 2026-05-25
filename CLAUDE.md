# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal Docker Compose multi-service PHP development environment running on macOS via Orbstack. 15 services on a custom bridge network `maxhuang_network` for container-to-container DNS resolution.

## Common Commands

```bash
# Start all services
docker-compose up -d

# Start specific services
docker-compose up -d frankenphp mysql redis

# Stop all services
docker-compose down

# View status
docker-compose ps

# View logs
docker-compose logs -f [service_name]

# Exec into a container
docker-compose exec frankenphp bash
docker-compose exec mysql mysql -u root -p
docker-compose exec postgresql psql -U default -d default

# Restart a specific service
docker-compose restart frankenphp

# Add a new site to FrankenPHP (creates dir + updates Caddyfile + restarts)
./caddy.sh <site-name> [php-container]   # default php container is php83

# Backup databases
docker-compose exec mysql mysqldump -u root -p123456 --all-databases > backup.sql
docker-compose exec postgresql pg_dumpall -U default > backup.sql
```

## Architecture

### Multi-PHP Version Routing

FrankenPHP (Caddy) serves as the main web server on ports 80/443. PHP-FPM containers (php74, php80, php81, php82, php83) handle PHP execution. Each site directory under `frankenphp/wwwroot/` can contain a `.php-version` file (e.g., `php81`) — the Caddyfile reads this to route FastCGI requests to the matching container. Falls back to php83 if unspecified.

### Service Credentials

All services use `123456` as the password. Default database and user are both `default`. RabbitMQ uses `guest/guest`. These are hardcoded in `docker-compose.yml` — there is no `.env` file.

### Host Connectivity

FrankenPHP connects to the Orbstack host machine's MySQL/Redis via `host.docker.internal` (set in environment variables: `DB_HOST`, `REDIS_HOST`). This is separate from the Docker-hosted MySQL/Redis services.

### Custom Dockerfiles

- `frankenphp/custom.Dockerfile` — the compose file builds from this (not the fuller `Dockerfile`). Based on `dunglas/frankenphp`, only adds `pdo_mysql`.
- `webman/Dockerfile` — PHP 8.3.22 CLI Alpine with Supervisor managing `php /app/start.php start` on port 8787. Installs 60+ extensions via `webman/extension/install.sh`.
- `rabbitmq/Dockerfile` — adds `rabbitmq_delayed_message_exchange` plugin to `rabbitmq:3.13-management`.

### Restart Policy Convention

`restart: "no"` on frankenphp, rabbitmq, and elasticsearch means they do NOT auto-start with Docker — must be started manually. `restart: always` on mysql, postgresql, mongodb, redis, dpanel, wbo. `restart: unless-stopped` on php-fpm containers.

### Data Persistence

Runtime data (databases, logs, caches) is stored in service-named directories under the project root. These are gitignored except for `.gitkeep` placeholder files that preserve the directory structure.
