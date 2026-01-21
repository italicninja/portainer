# AGENTS.md - Portainer Docker Compose Repository

## Repository Overview

This repository contains Docker Compose configurations for managing various game servers, network services, and utilities through Portainer. The project focuses on self-hosted infrastructure for gaming communities and home lab environments.

**Repository Type:** Docker Compose Infrastructure  
**Primary Purpose:** Game server hosting and network service management  
**Platform:** Docker/Portainer on Windows (Git Bash environment)

## Project Structure

```
portainer/
├── compose/                    # Docker Compose service definitions
│   ├── 7dtd.yml               # 7 Days to Die game server
│   ├── enshrouded.yml         # Enshrouded game server
│   ├── icarus.yml             # Icarus game server
│   ├── minecraft-dawncraft.yml    # Minecraft Dawncraft modpack
│   ├── minecraft-prominence2.yml  # Minecraft Prominence II modpack
│   ├── minecraft-steampunk.yml    # Minecraft Steampunk modpack
│   ├── nginx.yml              # Nginx reverse proxy
│   ├── pihole.yml             # Pi-hole DNS/ad blocker
│   ├── satisfactory.yml       # Satisfactory game server
│   ├── valheim.yml            # Valheim game server with Discord webhooks
│   ├── vercel-ddns.yml        # Dynamic DNS service using Vercel
│   ├── zomboid.yml            # Project Zomboid game server
│   └── ...
├── .env                       # Environment variables (gitignored)
├── .env.vercel-ddns.example   # Template for Vercel DDNS configuration
├── .gitignore                 # Git ignore rules
├── README-vercel-ddns.md      # Documentation for Vercel DDNS service
├── valheim-discord-embed-design.md  # Discord webhook design spec
├── final-validation.sh        # Discord webhook JSON validation script
├── test-discord-webhook.sh    # Discord webhook testing script
├── test-corrected-implementation.sh  # Implementation testing
└── validate-json-structure.sh # JSON structure validation
```

## Essential Commands

### Docker Compose Operations

All services are managed via individual compose files in the `compose/` directory:

```bash
# Start a service with environment variables
docker-compose -f compose/service-name.yml --env-file .env up -d

# View logs for a service
docker-compose -f compose/service-name.yml logs -f [service-name]

# Stop a service
docker-compose -f compose/service-name.yml down

# Restart a service
docker-compose -f compose/service-name.yml restart

# Check service status
docker-compose -f compose/service-name.yml ps

# View container stats
docker stats [container-name]

# Inspect container health
docker inspect [container-name] --format='{{.State.Health.Status}}'
```

### Specific Service Examples

```bash
# Vercel DDNS service
docker-compose -f compose/vercel-ddns.yml --env-file .env up -d
docker-compose -f compose/vercel-ddns.yml logs -f vercel-ddns

# Valheim server
docker-compose -f compose/valheim.yml up -d
docker-compose -f compose/valheim.yml logs -f valheim-server

# Minecraft Dawncraft
docker-compose -f compose/minecraft-dawncraft.yml up -d
docker-compose -f compose/minecraft-dawncraft.yml logs -f mc

# Pi-hole
docker-compose -f compose/pihole.yml up -d
docker-compose -f compose/pihole.yml logs -f pihole
```

### Git Operations

```bash
# View recent commits
git log --oneline -10

# Check current status
git status

# View changes
git diff

# View specific file history
git log --oneline -- compose/service-name.yml
git blame compose/service-name.yml
```

## Code Organization and Patterns

### Docker Compose File Structure

All compose files follow a consistent structure:

1. **Version Declaration:** `version: '3.8'` (or `version: '3'` for older files)
2. **Services Definition:** Each compose file defines 1-2 related services
3. **Resource Management:** Deploy limits and reservations are specified
4. **Health Checks:** Most services include health check configurations
5. **Logging:** JSON file logging with rotation (typically 10m max-size, 3 files)
6. **Labels:** Services are labeled with project and service metadata
7. **Networks:** Custom bridge networks for service isolation
8. **Volumes:** Persistent storage with local drivers, often using bind mounts

### Common Patterns

#### Environment Variables

Services use environment variables extensively:
- Secrets (passwords, tokens) are referenced from `.env` files
- Default values are provided using `${VAR:-default}` syntax
- Service-specific configuration uses uppercase naming

#### Volume Mounting Strategy

Two primary patterns:
1. **Named volumes** for simple persistent storage
2. **Bind mounts** via local driver with `type: none` and `device:` pointing to absolute paths

```yaml
volumes:
  named_volume:
    driver: local
  
  bind_mount_volume:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /data/service-name
```

#### Resource Constraints

Services define CPU and memory limits:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 16G
    reservations:
      memory: 8G
```

#### Health Checks

Most services include health checks with consistent parameters:

```yaml
healthcheck:
  test: ["CMD", "command", "args"]
  interval: 60s
  timeout: 10s
  retries: 3
  start_period: 120s
```

#### Logging Configuration

Standard logging across services:

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### Service-Specific Patterns

#### Game Servers

- Use dedicated game server images (e.g., `itzg/minecraft-server`, `lloesche/valheim-server`)
- Expose game ports (UDP for most games)
- Include RCON ports for administration
- Use `/data/` prefix for persistent storage paths
- Include backup configurations

#### Minecraft Servers

Minecraft servers use the `itzg/minecraft-server` image with:
- **Modpack Management:** CurseForge integration via `CF_API_KEY` and `CF_SLUG`
- **RCON Commands:** Startup, first connect, last disconnect hooks
- **Memory Tuning:** Aikar flags for JVM optimization
- **Mod Exclusions:** `CF_EXCLUDE_MODS` to skip incompatible mods
- **Force Sync:** `CF_FORCE_SYNCHRONIZE: true` to update mods

Example CurseForge configuration:
```yaml
MOD_PLATFORM: AUTO_CURSEFORGE
CF_API_KEY: ${CF_API_KEY}
CF_SLUG: dawn-craft
CF_EXCLUDE_MODS: 368398
CURSEFORGE_FILES: ftb-backups-2,polylib,iceberg,nether-skeletons:4409036
CF_FORCE_SYNCHRONIZE: true
```

#### Valheim Server

Special features:
- **BepInEx Mod Support:** Enabled via `BEPINEX=true`
- **Post-BepInEx Hook:** Downloads and installs mods from Thunderstore
- **Discord Webhooks:** Rich embeds for server events
- **Backup System:** Automated with `BACKUPS_CRON`, external copy via `POST_BACKUP_HOOK`

#### Network Services

- **Nginx Proxy:** Uses `nginxproxy/nginx-proxy` with docker socket mounting
- **Pi-hole:** Requires `NET_ADMIN` capability for DNS operations
- **Vercel DDNS:** Embeds shell script directly in compose file via heredoc

## Environment Configuration

### Required Environment Files

Create `.env` files based on examples:

```bash
# Copy Vercel DDNS example
cp .env.vercel-ddns.example .env
```

### Common Environment Variables

Game servers typically need:
- `SERVER_PASSWORD`: Server password
- `RCON_PASSWORD`: Remote console password
- `CF_API_KEY`: CurseForge API key (for Minecraft modpacks)
- `DISCORD_WEBHOOK`: Discord webhook URL (for notifications)
- `SERVER_IP`: Public IP address for connection info

Network services:
- `VERCEL_TOKEN`: Vercel API token
- `VERCEL_DOMAIN`: Domain to update
- `PIHOLE_PASSWORD`: Pi-hole admin password

### Sensitive Data Handling

- All `.env` files are gitignored
- Secrets are never committed to the repository
- API tokens and passwords are always referenced from environment variables

## Important Patterns and Conventions

### Naming Conventions

- **Container Names:** Lowercase with hyphens (e.g., `valheim-server`, `minecraft-dawncraft`)
- **Volume Names:** Service name prefix with underscore suffix (e.g., `valheim_data`, `minecraft_dawncraft_data`)
- **Network Names:** Purpose-based with `_network` suffix (e.g., `game_network`, `dns_network`)
- **Labels:** Use `com.docker.compose.project` and `com.docker.compose.service`

### Port Mapping

- Game servers use their default ports when possible
- Some services expose alternative ports to avoid conflicts (e.g., Pi-hole on `8053:80`)
- Most game traffic uses UDP
- RCON and web interfaces use TCP

### Storage Paths

Persistent data is stored under `/data/` on the host:
- `/data/minecraft-dawncraft/`
- `/data/valheim-server/config`
- `/data/valheim-server/data`
- `/data/enshrouded-persistent-data/`
- `/backup/valheim/` for external backups

### Restart Policy

All production services use `restart: unless-stopped`

## Discord Webhook Integration

### Valheim Server Discord Embeds

The Valheim server includes sophisticated Discord webhook integration with rich embeds:

- **Startup Notifications:** Sent via `PRE_BOOTSTRAP_HOOK` with server details
- **Embed Structure:** JSON embeds with fields for server info, mods, backups
- **Variable Substitution:** Uses `sed` with pipe delimiter for URL handling
- **Design Spec:** See `valheim-discord-embed-design.md` for complete embed designs

#### Critical Webhook Implementation Notes

1. **URL Escaping:** Use pipe delimiter in `sed` (not forward slash) to handle URLs:
   ```bash
   sed "s|$$PLACEHOLDER|$VALUE|g"
   ```

2. **Variable Syntax:** Double dollar signs (`$$`) in compose files for shell variable escaping

3. **JSON Structure:** Embeds are defined in environment variables, then substituted

4. **Testing Scripts:**
   - `test-discord-webhook.sh`: Validates JSON structure and webhook syntax
   - `final-validation.sh`: Tests corrected substitution with proper escaping
   - `validate-json-structure.sh`: JSON parsing validation

### Discord Embed Color Codes

Valheim branding colors (decimal values):
- **Blue (Starting):** `1973162` (#1e3a8a)
- **Green (Success):** `1096065` (#10b981)
- **Orange (Warning):** `16098827` (#f59e0b)
- **Red (Error):** `15680324` (#ef4444)

## Vercel DDNS Service

### Special Implementation

The Vercel DDNS service embeds its entire shell script directly in the compose file using a heredoc:

```yaml
command:
  - -c
  - |
    cat > /app/ddns.sh << 'SCRIPT_END'
    #!/bin/sh
    # Script content here
    SCRIPT_END
```

### Key Features

- **IP Detection:** Tries multiple services (icanhazip, ipify, AWS)
- **DNS Record Management:** Uses Vercel CLI (`vercel dns` commands)
- **Change Detection:** Only updates when IP actually changes
- **Validation:** Tests Vercel authentication on startup
- **Logging:** Timestamped log messages with prefix

### Configuration

See `.env.vercel-ddns.example` for required variables:
- `VERCEL_TOKEN`: API token from Vercel account
- `VERCEL_DOMAIN`: Domain to manage (without subdomain)
- `VERCEL_RECORD_NAME`: Record name (default: `@` for root)
- `VERCEL_RECORD_TYPE`: Record type (default: `A`)
- `CHECK_INTERVAL`: Update check interval in seconds (default: 300)

## Testing and Validation

### Shell Script Testing

The repository includes validation scripts for Discord webhook integration:

```bash
# Test Discord webhook JSON structure
./test-discord-webhook.sh

# Validate corrected implementation with proper escaping
./final-validation.sh

# Validate JSON structure
./validate-json-structure.sh
```

These scripts:
- Test variable substitution
- Validate JSON syntax
- Check payload size
- Test curl command structure

### Service Health Monitoring

```bash
# Check container health status
docker inspect [container-name] --format='{{.State.Health.Status}}'

# View health check logs
docker inspect [container-name] --format='{{range .State.Health.Log}}{{.Output}}{{end}}'

# Monitor container stats
docker stats [container-name]
```

## Common Gotchas and Issues

### 1. Shell Escaping in Docker Compose

When embedding shell scripts in compose files:
- Use `$$` to escape dollar signs for shell variables
- Use single quotes in heredoc (`'SCRIPT_END'`) to prevent interpolation
- Use pipe delimiter (`|`) in `sed` commands when working with URLs

### 2. Path Conventions

- The repository is on Windows, but uses Unix-style paths in compose files
- Absolute paths in volumes use forward slashes: `/data/service-name`
- Git Bash environment provides Unix-like command interface

### 3. CurseForge Slug Changes

Recent commit history shows "Curseforge updated slug name" - modpack slugs can change:
- Always verify `CF_SLUG` value matches current CurseForge project
- Check CurseForge project pages for updated slugs

### 4. Environment Variable Requirements

Different services require different `.env` files:
- Not all services use the same environment file
- Check compose file for required variables before starting
- Missing environment variables will cause service startup failures

### 5. Volume Permissions

When using bind mounts:
- Ensure host directories exist before starting services
- Check directory permissions for Docker user access
- Some services specify `PUID` and `PGID` for permission mapping

### 6. Resource Limits

Game servers specify significant resource requirements:
- Minecraft servers: 8-16GB RAM, 4 CPUs
- Valheim: Lower requirements but needs `SYS_NICE` capability
- Ensure host has sufficient resources before deploying

### 7. Network Conflicts

Multiple services may compete for ports:
- Check for port conflicts before starting new services
- Pi-hole uses port 53 (may conflict with system DNS)
- Nginx proxy uses ports 80/443 (standard web traffic)

## Modification Guidelines

### Adding a New Game Server

1. Create new compose file in `compose/` directory
2. Follow existing naming conventions
3. Include these standard sections:
   - Version declaration
   - Service with appropriate image
   - Port mappings (check for conflicts)
   - Volume mounts under `/data/`
   - Resource limits
   - Health check
   - Logging configuration
   - Labels (project: games, service: name)
   - Restart policy
   - Network definition
   - Volume definition

4. Add required environment variables to `.env`
5. Test startup and verify logs
6. Document any special configuration

### Updating Discord Webhooks

When modifying Discord webhook integrations:
1. Update JSON embed structure in environment variable
2. Use proper escaping (double `$$` for shell variables)
3. Test JSON validity with validation scripts
4. Use pipe delimiter in `sed` commands for URL substitution
5. Verify webhook delivery with test scripts

### Modifying Embedded Scripts

For services like Vercel DDNS with embedded scripts:
1. Edit the heredoc content in the compose file
2. Maintain shell variable escaping (`$$VAR`)
3. Test script syntax before deploying
4. Consider extracting to separate file if script grows complex

## Architecture Notes

### Service Categories

Services are organized by purpose:

1. **Game Servers** (project: games)
   - Minecraft variants (Dawncraft, Prominence II, Steampunk)
   - Valheim
   - Enshrouded
   - Satisfactory
   - 7 Days to Die
   - Project Zomboid
   - Icarus

2. **Network Services** (project: networking)
   - Nginx reverse proxy
   - Pi-hole DNS
   - Vercel DDNS

### Network Isolation

Each service or service group has its own bridge network:
- `game_network`: Game servers
- `dns_network`: Pi-hole
- `web_network`: Nginx proxy
- `ddns_network`: Vercel DDNS
- `minecraft_network`: Minecraft servers

This isolation improves security and prevents service conflicts.

### Backup Strategy

Game servers implement backups differently:
- **Valheim:** Built-in backup system with cron schedule, external copy via post-hook
- **Minecraft:** Uses FTB Backups mod (included in modpack)
- **Others:** Rely on volume snapshots or external backup solutions

### Monitoring and Observability

Services include health checks but no centralized monitoring. Consider:
- Docker health check status
- Container logs via `docker-compose logs`
- Resource usage via `docker stats`
- Custom monitoring via Discord webhooks (Valheim example)

## Recent Changes

Based on git history:

- **a9e6166:** CurseForge updated slug name (modpack name changes)
- **665ef56:** Generic message commit
- **35138ca:** Fix mod hook (BepInEx/Thunderstore integration)
- **dacec1c:** Pi-hole use latest by default
- **0af5306:** Container fixes
- **1aa2f83:** Logging configuration updates
- **290d018:** Switch to Vercel CLI for DDNS

## Future Agent Guidance

When working in this repository:

1. **Always check environment variables:** Review compose file for required vars before starting services
2. **Test Discord webhooks:** Use provided validation scripts before deploying webhook changes
3. **Verify CurseForge slugs:** Modpack slugs change - always verify current project name
4. **Check resource availability:** Game servers require significant RAM/CPU
5. **Review logs after changes:** Always check container logs after modifications
6. **Maintain consistency:** Follow established patterns for naming, structure, and configuration
7. **Document new services:** Add service-specific notes to this file when adding new compose files
8. **Test before committing:** Validate compose files with `docker-compose config` before committing

## Additional Resources

- **Vercel DDNS Documentation:** See `README-vercel-ddns.md`
- **Discord Embed Design:** See `valheim-discord-embed-design.md`
- **CurseForge API:** Required for Minecraft modpack servers
- **Portainer:** Web UI for managing these Docker Compose stacks

## Quick Reference

### Most Common Tasks

```bash
# Start a service
docker-compose -f compose/SERVICE.yml up -d

# View logs
docker-compose -f compose/SERVICE.yml logs -f

# Restart a service
docker-compose -f compose/SERVICE.yml restart

# Stop a service
docker-compose -f compose/SERVICE.yml down

# Update a service (pull new image)
docker-compose -f compose/SERVICE.yml pull
docker-compose -f compose/SERVICE.yml up -d

# Check service status
docker-compose -f compose/SERVICE.yml ps
docker inspect CONTAINER --format='{{.State.Health.Status}}'
```

### File Locations to Know

- **Compose definitions:** `compose/*.yml`
- **Environment config:** `.env` (create from `.env.*.example`)
- **Service data:** `/data/SERVICE-NAME/`
- **Backups:** `/backup/SERVICE-NAME/`
- **Validation scripts:** `*.sh` in root directory

---

**Last Updated:** 2025-01-20  
**Repository:** Portainer Docker Compose configurations for game servers and network services
