# AGENTS.md - Portainer Docker Compose Repository

## Repository Overview

This repository contains Docker Compose configurations for managing various game servers, network services, and utilities through Portainer. The project focuses on self-hosted infrastructure for gaming communities and home lab environments.

**Repository Type:** Docker Compose Infrastructure  
**Primary Purpose:** Game server hosting and network service management  
**Platform:** Docker/Portainer  
**Deployment:** GitHub repository pulled into Portainer via native Git integration  
**Operating Model:** All functionality must be Docker-native; no ad-hoc scripts or manual operations

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
│   ├── pihole.yml             # Pi-hole DNS/ad blocker (standalone)
│   ├── pihole-vercel.yml      # Pi-hole + Vercel DDNS combined stack
│   ├── satisfactory.yml       # Satisfactory game server
│   ├── valheim.yml            # Valheim game server with Discord webhooks
│   ├── vercel-ddns.yml        # Dynamic DNS service using Vercel (standalone)
│   ├── zomboid.yml            # Project Zomboid game server
│   └── ...
├── env/                       # Environment variable templates (load into Portainer)
│   ├── .env.pihole-vercel.example # Pi-hole + Vercel combined stack
│   ├── .env.vercel-ddns.example   # Vercel DDNS configuration
│   └── .env.zomboid.example   # Project Zomboid server
├── .gitignore                 # Git ignore rules
└── AGENTS.md                  # This file - Complete documentation and agent guidance
```

## Deployment Model

**CRITICAL:** This repository is deployed through Portainer's native Git integration. All operations must be Docker-native.

### Portainer Workflow

1. **Repository Hosting:** GitHub repository (source of truth)
2. **Deployment:** Portainer pulls from GitHub using built-in Git sync
3. **Stack Management:** Stacks are created in Portainer UI from compose files
4. **Environment Variables:** Managed in Portainer's stack environment editor
5. **Updates:** Triggered via Portainer's "Pull and redeploy" feature

### Key Constraints

- **No Ad-Hoc Scripts:** Shell scripts (`.sh` files) in the repository are for reference/documentation only
- **No Manual Operations:** All functionality must work purely through Docker Compose
- **Self-Contained Services:** Services must handle setup, configuration, and maintenance internally
- **Embedded Scripts:** Any scripting must be embedded in compose files via `command:` or `entrypoint:` heredocs

### Portainer Stack Deployment

1. **Create Stack:** Portainer UI → Stacks → Add Stack → Git Repository
2. **Configure:**
   - Repository URL: `https://github.com/your-username/portainer`
   - Compose file path: `compose/service-name.yml`
   - Environment variables: Add via Portainer UI
3. **Deploy:** Click "Deploy the stack"
4. **Monitor:** View logs and status in Portainer UI

### Docker Compose Operations (Reference)

These commands are for reference when working with Docker Compose directly (not in Portainer):

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

### Service Examples in Portainer

**Vercel DDNS:**
- Compose path: `compose/vercel-ddns.yml`
- Required env vars: `VERCEL_TOKEN`, `VERCEL_DOMAIN`

**Pi-hole + Vercel (Combined Stack):**
- Compose path: `compose/pihole-vercel.yml`
- Required env vars: `PIHOLE_PASSWORD`, `VERCEL_TOKEN`, `VERCEL_DOMAIN`

**Valheim Server:**
- Compose path: `compose/valheim.yml`
- Required env vars: `SERVER_PASSWORD`, `DISCORD_WEBHOOK`

**Minecraft Dawncraft:**
- Compose path: `compose/minecraft-dawncraft.yml`
- Required env vars: `CF_API_KEY`, `RCON_PASSWORD`

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

**Nginx Proxy:**
- Uses `nginxproxy/nginx-proxy` image
- Mounts Docker socket for automatic proxy configuration
- Generates reverse proxy configs based on container labels

**Pi-hole (Standalone):**
- Ad-blocking DNS server with web interface
- Requires `NET_ADMIN` capability for DNS operations
- Supports HTTPS via self-signed certificates (generated in-container)
- Security: Rate limiting, privacy controls, resource constraints
- Ports: 53 (DNS), 8053 (HTTP), 8443 (HTTPS)

**Pi-hole + Vercel (Combined Stack):**
- Combines Pi-hole DNS filtering with Vercel public DNS hosting
- DDNS service automatically updates Vercel DNS when public IP changes
- Creates both primary domain and Pi-hole subdomain records
- All configuration embedded in `compose/pihole-vercel.yml`
- Uses shared Docker network for service coordination

**Vercel DDNS (Standalone):**
- Dynamic DNS using Vercel's DNS infrastructure
- Embeds shell script directly in compose file via heredoc
- Detects public IP changes and updates Vercel DNS records
- No external dependencies - fully self-contained in compose file

## Environment Configuration

### Portainer Environment Management

**IMPORTANT:** Environment variables are managed in Portainer's stack editor, not via `.env` files.

**Workflow:**
1. Create stack in Portainer from Git repository
2. Load environment template from `env/` folder or add variables manually
3. Portainer can load `.env.*.example` files directly from the repository
4. Edit variables in Portainer's "Environment variables" section
5. Portainer injects variables into containers at runtime

### Environment Variable Templates

The repository includes environment templates in the `env/` folder:
- `env/.env.vercel-ddns.example` - Vercel DDNS service
- `env/.env.pihole-vercel.example` - Pi-hole + Vercel combined stack
- `env/.env.zomboid.example` - Project Zomboid server

**Loading in Portainer:**
1. When creating/editing a stack, click "Load variables from .env file"
2. Portainer can read files directly from the Git repository
3. Select the appropriate template from `env/` folder
4. Edit values as needed in the UI

### Common Environment Variables

**Game Servers:**
- `SERVER_PASSWORD`: Server password
- `RCON_PASSWORD`: Remote console password
- `CF_API_KEY`: CurseForge API key (for Minecraft modpacks)
- `DISCORD_WEBHOOK`: Discord webhook URL (for notifications)
- `SERVER_IP`: Public IP address for connection info
- `DNS_HOSTNAME`: Local DNS name (e.g., `valheim.italicninja.com`)

**Network Services:**
- `VERCEL_TOKEN`: Vercel API token (from https://vercel.com/account/tokens)
- `VERCEL_DOMAIN`: Domain to manage (e.g., `example.com`)
- `PIHOLE_PASSWORD`: Pi-hole admin password
- `PIHOLE_SUBDOMAIN`: Subdomain for Pi-hole access (e.g., `pihole`)
- `LOCAL_IPV4`: Pi-hole server local IP (e.g., `192.168.1.10`)
- `DNS_HOSTNAME`: Local DNS name (e.g., `pihole.italicninja.com`)

### Sensitive Data Handling

- **Portainer Secrets:** Store sensitive data in Portainer's environment variable editor
- **Never Commit Secrets:** `.env` files are gitignored; never commit passwords or tokens
- **Variable References:** Compose files use `${VAR}` syntax to reference environment variables
- **Default Values:** Use `${VAR:-default}` for optional configuration with fallbacks

## Important Patterns and Conventions

### Naming Conventions

- **Container Names:** Lowercase with hyphens (e.g., `valheim-server`, `minecraft-dawncraft`)
- **Volume Names:** Service name prefix with underscore suffix (e.g., `valheim_data`, `minecraft_dawncraft_data`)
- **Network Names:** Purpose-based with `_network` suffix (e.g., `game_network`, `dns_network`)
- **Labels:** Use `com.docker.compose.project` and `com.docker.compose.service`
- **DNS Hostnames:** Service name in dot notation (e.g., `valheim.italicninja.com`, `minecraft-dawncraft.italicninja.com`)

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

### DNS Management with Pi-hole

**CRITICAL:** All Docker services must have corresponding DNS entries in Pi-hole for local network discovery.

**Pi-hole Local DNS Configuration:**
- Access Pi-hole: `https://pihole.italicninja.com:8443/admin`
- Navigate to: **Local DNS** → **DNS Records**
- Add A record for each service

**DNS Naming Convention:**
- Format: `service-name.italicninja.com` → `192.168.1.X`
- Use lowercase with hyphens for service names
- Match container name for consistency
- Use `.italicninja.com` domain for all local services

**Standard DNS Entries:**

| Service | DNS Hostname | IP Address | Notes |
|---------|-------------|------------|-------|
| Pi-hole | `pihole.italicninja.com` | `192.168.1.10` | DNS/Ad-blocking server |
| Valheim | `valheim.italicninja.com` | `192.168.1.10` | Game server |
| Minecraft Dawncraft | `minecraft-dawncraft.italicninja.com` | `192.168.1.10` | Modded Minecraft |
| Zomboid | `zomboid.italicninja.com` | `192.168.1.10` | Project Zomboid server |
| Nginx | `nginx.italicninja.com` | `192.168.1.10` | Reverse proxy |

**When Adding a New Service:**
1. Deploy service via Portainer
2. Immediately add DNS entry to Pi-hole
3. Test DNS resolution: `nslookup service-name.italicninja.com 192.168.1.10`
4. Document DNS entry in service's environment template
5. Update this table in AGENTS.md

**DNS Entry Methods:**

**Via Pi-hole Web Interface (Recommended):**
1. Login to Pi-hole admin panel
2. Go to **Local DNS** → **DNS Records**
3. Add Domain: `service-name.italicninja.com`
4. Add IP Address: `192.168.1.X` (typically `192.168.1.10` for same-host services)
5. Click **Add**

**Via Docker Exec (Alternative):**
```bash
# Add DNS entry directly to Pi-hole
docker exec pihole sh -c "echo '192.168.1.10 service-name.italicninja.com' >> /etc/pihole/custom.list"
docker exec pihole pihole restartdns
```

**Via Compose File (For multi-service stacks):**
```yaml
extra_hosts:
  - 'service-name service-name.italicninja.com:192.168.1.10'
```

**DNS Resolution Benefits:**
- Service discovery without hardcoded IPs
- Easy to remember service URLs
- Consistent naming across infrastructure
- Simplified nginx proxy configuration
- Better certificate management (can use Let's Encrypt with DNS)

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

4. **Embedded Testing:** All logic embedded in compose file, no external scripts required

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

## Pi-hole with Vercel DNS Integration

### Overview

The `compose/pihole-vercel.yml` stack combines Pi-hole DNS ad-blocking with Vercel DNS hosting:

**Architecture:**
1. **Pi-hole Container:** Local DNS filtering and ad-blocking
2. **Vercel DDNS Container:** Automatically updates Vercel DNS when public IP changes
3. **Shared Network:** Both services on `dns_network` for coordination

**Use Case:**
- Run Pi-hole for local network DNS filtering
- Use Vercel to host public DNS records for your domain
- Automatically update DNS when your public IP changes
- Access Pi-hole remotely via public domain (e.g., `pihole.yourdomain.com`)

### Features

**Pi-hole:**
- Ad blocking and DNS filtering
- HTTPS web interface (port 8443)
- Security hardening (rate limiting, privacy controls)
- Cloudflare upstream DNS (1.1.1.1) by default

**Vercel DDNS:**
- Updates primary domain record (e.g., `yourdomain.com`)
- Creates Pi-hole subdomain (e.g., `pihole.yourdomain.com`)
- Checks for IP changes every 5 minutes (configurable)
- Uses Vercel's enterprise DNS infrastructure

**Security:**
- Rate limiting: 1000 queries/60 seconds
- Resource constraints: 1 CPU, 1GB RAM for Pi-hole
- HTTPS support with self-signed certificates (generated in-container)
- Privacy controls: Blocks iCloud Private Relay, enables Mozilla canary

### Required Environment Variables

**Pi-hole Configuration:**
- `PIHOLE_PASSWORD`: Web interface password (required)
- `LOCAL_IPV4`: Pi-hole server local IP (default: `192.168.1.10`)
- `PIHOLE_DOMAIN`: Local or public domain (default: `pihole.local`)
- `SERVER_PUBLIC_IP`: Your public IP (optional, for initial setup)

**Vercel Configuration:**
- `VERCEL_TOKEN`: API token from https://vercel.com/account/tokens (required)
- `VERCEL_DOMAIN`: Domain to manage (e.g., `example.com`) (required)
- `VERCEL_RECORD_NAME`: Primary record name (default: `@` for root)
- `PIHOLE_SUBDOMAIN`: Subdomain for Pi-hole (default: `pihole`)
- `CHECK_INTERVAL`: DDNS check interval in seconds (default: `300`)

**General:**
- `TZ`: Timezone (default: `America/Vancouver`)
- `IMAGE_TAG`: Pi-hole image tag (default: `latest`)

### Deployment in Portainer

1. **Create Stack:**
   - Name: `pihole-vercel`
   - Repository: Your GitHub repo URL
   - Compose path: `compose/pihole-vercel.yml`

2. **Add Environment Variables:**
   - Use `.env.pihole-vercel.example` as reference
   - Enter all required variables in Portainer UI

3. **Deploy Stack:**
   - Click "Deploy the stack"
   - Wait for DDNS service to detect IP and update Vercel

4. **Access Pi-hole:**
   - Local: `https://192.168.1.10:8443/admin`
   - Remote: `https://pihole.yourdomain.com:8443/admin` (after port forwarding)

### HTTPS Certificate Generation

Certificates are generated **automatically inside the Pi-hole container** on first startup:

```yaml
# Embedded in compose file - no manual steps required
command:
  - sh
  - -c
  - |
    # Generate self-signed certificate
    mkdir -p /etc/lighttpd/certs
    openssl req -new -x509 -days 3650 ...
    # Configure lighttpd for HTTPS
    # Start Pi-hole
```

**Note:** For production, replace with Let's Encrypt certificate (requires domain and port 80 access).

### DNS Resolution Flow

1. **Local clients** → Point DNS to Pi-hole IP (192.168.1.10)
2. **Pi-hole** → Filters/blocks ads, forwards to Cloudflare (1.1.1.1)
3. **Public DNS** → Vercel manages `yourdomain.com` records
4. **DDNS** → Updates Vercel when public IP changes

### Port Forwarding (Optional Remote Access)

To access Pi-hole remotely:

| Service | External Port | Internal IP | Internal Port | Protocol |
|---------|---------------|-------------|---------------|----------|
| Pi-hole HTTPS | 8443 | 192.168.1.10 | 8443 | TCP |

**Security Warning:** Only forward port 8443 if needed. Never expose port 53 publicly.

### Monitoring

**Service Health (in Portainer):**
- View stack status in Portainer UI
- Check container logs for Pi-hole and Vercel DDNS

**DDNS Status:**
```bash
# Check last detected IP
docker exec vercel-ddns cat /app/data/last_ip.txt

# Verify Vercel DNS records
docker exec vercel-ddns vercel dns ls yourdomain.com --token "$VERCEL_TOKEN"
```

**Pi-hole Statistics:**
- Access web interface: `https://pihole.yourdomain.com:8443/admin`
- View queries blocked, top domains, client activity

### Additional Notes

- All documentation consolidated in AGENTS.md
- Certificate generation is automatic - no manual intervention required
- For Let's Encrypt certificates, see HTTPS Certificate Generation section above

## Testing and Validation

### Service Health Monitoring

All monitoring done through Portainer UI or Docker commands:

```bash
# Check container health status
docker inspect [container-name] --format='{{.State.Health.Status}}'

# View health check logs
docker inspect [container-name] --format='{{range .State.Health.Log}}{{.Output}}{{end}}'

# Monitor container stats
docker stats [container-name]
```

### Compose File Validation

**Before committing changes:**
```bash
# Validate compose file syntax
docker-compose -f compose/service-name.yml config

# Check for syntax errors
docker-compose -f compose/service-name.yml config --quiet
```

### Embedded Script Testing

Services with embedded scripts (Vercel DDNS, Valheim webhooks) include self-validation:
- Scripts validate configuration on startup
- Errors logged to container output
- Health checks monitor script execution
- All testing automatic - no external scripts needed

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

### Critical Principle: Docker-Native Only

**ALL functionality must work purely through Docker Compose.** No manual setup, no external scripts.

### Adding a New Service

1. **Create Compose File:** `compose/service-name.yml`
2. **Follow Standard Structure:**
   - Version declaration: `version: '3.8'`
   - Service definition with official image
   - Port mappings (check for conflicts)
   - Named volumes or bind mounts under `/data/`
   - Resource limits (CPU, memory)
   - Health check with appropriate test command
   - Logging: JSON driver, 10m max-size, 3 files
   - Labels: `com.docker.compose.project` and `com.docker.compose.service`
   - Restart policy: `unless-stopped`
   - Custom bridge network

3. **Embed All Setup Logic:**
   - Use `command:` or `entrypoint:` with heredoc for setup scripts
   - Generate certificates in-container (e.g., Pi-hole HTTPS)
   - Download/install dependencies in container startup
   - No external files or manual steps

4. **Add DNS Entry to Pi-hole:** (REQUIRED)
   - Add local DNS entry in Pi-hole for service discovery
   - Naming convention: `service-name.italicninja.com` → `192.168.1.X`
   - Access Pi-hole web interface: `https://pihole.italicninja.com:8443/admin`
   - Navigate to: **Local DNS** → **DNS Records**
   - Add A record mapping service hostname to container/host IP
   - Examples:
     - `valheim.italicninja.com` → `192.168.1.10`
     - `minecraft-dawncraft.italicninja.com` → `192.168.1.10`
     - `zomboid.italicninja.com` → `192.168.1.10`
   - Use local IP (192.168.1.X) for services on same host
   - Document DNS entry in service environment template

5. **Create Environment Template:**
   - Add `env/.env.service-name.example` with all required variables
   - Document each variable with comments
   - Include DNS hostname in template
   - Include usage examples and deployment instructions
   - Format for easy loading in Portainer

6. **Document:**
   - Update AGENTS.md with service-specific patterns
   - Include DNS hostname in service documentation
   - Include Portainer deployment instructions
   - Note Pi-hole DNS entry requirement

7. **Test:**
   - Validate compose syntax: `docker-compose config`
   - Deploy in Portainer and verify startup
   - Check logs for errors
   - Verify health checks pass
   - Test DNS resolution: `nslookup service-name.italicninja.com 192.168.1.10`

### Updating Discord Webhooks

When modifying Discord webhook integrations:
1. Update JSON embed structure in environment variable
2. Use proper escaping (double `$$` for shell variables in compose)
3. Use pipe delimiter in `sed` commands for URL substitution: `sed "s|$$VAR|value|g"`
4. Test by deploying in Portainer and checking webhook delivery
5. All webhook logic must be embedded in compose file

### Modifying Embedded Scripts

For services like Vercel DDNS with embedded scripts:

1. **Edit Heredoc:** Modify script content in compose file's `command:` section
2. **Shell Variable Escaping:** Use `$$VAR` for shell variables, `${VAR}` for Docker env vars
3. **Testing:**
   ```yaml
   # Scripts self-validate on startup
   command:
     - sh
     - -c
     - |
       # Validation logic here
       if [ -z "$${REQUIRED_VAR}" ]; then
         echo "ERROR: Missing variable"
         exit 1
       fi
       # Main script logic
   ```
4. **Avoid External Files:** Never reference external `.sh` files - embed everything
5. **Heredoc Syntax:** Use `'SCRIPT_END'` (single quotes) to prevent Docker variable interpolation:
   ```yaml
   cat > /app/script.sh << 'SCRIPT_END'
   #!/bin/sh
   echo "$$SHELL_VAR"  # Shell variable
   echo "${DOCKER_VAR}" # Replaced by Docker before container starts
   SCRIPT_END
   ```

### Self-Contained Service Checklist

- [ ] All setup logic embedded in compose file
- [ ] No external scripts required
- [ ] Certificates/keys generated in-container if needed
- [ ] Dependencies installed during container startup
- [ ] Configuration created from environment variables
- [ ] Health check validates service is operational
- [ ] Works purely through Portainer deployment
- [ ] **DNS entry added to Pi-hole** (`service-name.italicninja.com`)
- [ ] Environment template created in `env/` folder
- [ ] DNS hostname documented in environment template
- [ ] AGENTS.md updated with service patterns and DNS entry

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
   - Pi-hole DNS (standalone)
   - Pi-hole + Vercel DDNS (combined stack)
   - Vercel DDNS (standalone)

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

**Portainer UI:**
- View stack status and container health
- Access logs for each container
- Monitor resource usage (CPU, memory, network)
- Restart/stop containers as needed

**Health Checks:**
- All services include health check configurations
- Portainer displays health status in UI
- Unhealthy containers automatically logged

**Custom Monitoring:**
- Discord webhooks for server events (Valheim example)
- Embedded monitoring logic in compose files
- No external monitoring tools required

## Recent Changes

Based on git history:

- **Pi-hole + Vercel Integration:** Added combined stack for DNS filtering with public DNS hosting
- **HTTPS Support:** Pi-hole now includes self-signed certificate generation in-container
- **Security Hardening:** Pi-hole rate limiting, privacy controls, resource constraints
- **CurseForge Slug Updates:** Modpack slugs change periodically (verify on CurseForge)
- **Vercel CLI Migration:** DDNS service switched to Vercel CLI for better reliability
- **BepInEx Fixes:** Valheim mod hook improvements for Thunderstore integration

## Future Agent Guidance

### Critical Operating Principles

1. **Portainer-Native Deployment:**
   - All services deployed via Portainer's Git integration
   - No ad-hoc scripts or manual operations
   - Everything must work through Docker Compose alone

2. **Self-Contained Services:**
   - Embed all setup logic in compose files
   - Generate certificates/configs in-container
   - No external dependencies or manual steps

3. **Environment Variables:**
   - Review compose file for required variables
   - Check `.env.*.example` files for reference
   - Document all variables in Portainer UI

4. **Testing and Validation:**
   - Validate compose syntax: `docker-compose config`
   - Deploy in Portainer and verify logs
   - Check health status in Portainer UI
   - No external test scripts - services self-validate

5. **Documentation:**
   - Update AGENTS.md for new services
   - Create README-*.md for complex services
   - Include Portainer deployment instructions
   - Document all environment variables

6. **DNS Management:**
   - Add Pi-hole DNS entry for every new service
   - Use naming convention: `service-name.italicninja.com`
   - Document DNS hostname in environment template
   - Test DNS resolution after adding entry
   - Update DNS table in AGENTS.md

7. **Common Checks:**
   - CurseForge slugs may change (verify on CurseForge)
   - Game servers need significant resources (8-16GB RAM)
   - Check port conflicts before deploying
   - Review container logs after changes
   - Verify DNS entry exists in Pi-hole

8. **Consistency:**
   - Follow established naming conventions
   - Use standard health check patterns
   - Apply consistent resource limits
   - Maintain logging configuration (10m, 3 files)
   - Maintain DNS naming convention

9. **Embedded Scripts:**
   - Use heredoc syntax for inline scripts
   - Escape shell variables: `$$VAR`
   - Docker env vars: `${VAR}`
   - Validate on startup, log errors

### Repository Structure Philosophy

**What belongs in the repo:**
- Docker Compose files (`compose/*.yml`)
- Environment templates (`env/.env.*.example`)
- Documentation (AGENTS.md)
- Utility compose files (e.g., clear-zomboid-workshop.yml)

**What does NOT belong:**
- Actual `.env` files (use Portainer UI)
- Setup scripts (`.sh` files are reference only)
- Manual configuration steps
- External dependencies

### When Adding New Services

**Ask yourself:**
1. Can this run purely through Docker Compose? (Must be YES)
2. Does it require manual setup steps? (Must be NO)
3. Are all scripts embedded in compose file? (Must be YES)
4. Will it work in Portainer without intervention? (Must be YES)
5. Has a DNS entry been added to Pi-hole? (Must be YES)
6. Is the DNS hostname documented? (Must be YES)

**If any answer is wrong, redesign the service to be self-contained or add the missing DNS entry.**

## Additional Resources

### External Resources

- **Portainer:** [portainer.io](https://www.portainer.io/) - Web UI for Docker management
- **Vercel DNS:** [vercel.com/docs/projects/domains](https://vercel.com/docs/projects/domains)
- **CurseForge API:** [docs.curseforge.com](https://docs.curseforge.com/) - Required for Minecraft modpacks
- **Pi-hole:** [pi-hole.net](https://pi-hole.net/) - Network-wide ad blocking

## Quick Reference

### Portainer Deployment

1. **Add Stack:**
   - Stacks → Add Stack → Git Repository
   - Repository URL: Your GitHub repo
   - Compose path: `compose/SERVICE.yml`

2. **Environment Variables:**
   - Load from `env/.env.SERVICE.example` file, OR
   - Add manually in Portainer UI (Stack editor)

3. **Deploy:**
   - Click "Deploy the stack"
   - Monitor logs in Portainer UI

### Docker Compose Commands (Reference)

These commands are for local testing, not Portainer deployment:

```bash
# Validate compose file
docker-compose -f compose/SERVICE.yml config

# Start service (local testing)
docker-compose -f compose/SERVICE.yml up -d

# View logs
docker-compose -f compose/SERVICE.yml logs -f

# Stop service
docker-compose -f compose/SERVICE.yml down

# Check health
docker inspect CONTAINER --format='{{.State.Health.Status}}'
```

### Service Compose File Locations

| Service | Compose File | Environment Template |
|---------|-------------|---------------------|
| Pi-hole (standalone) | `compose/pihole.yml` | N/A |
| Pi-hole + Vercel | `compose/pihole-vercel.yml` | `env/.env.pihole-vercel.example` |
| Vercel DDNS | `compose/vercel-ddns.yml` | `env/.env.vercel-ddns.example` |
| Zomboid | `compose/zomboid.yml` | `env/.env.zomboid.example` |
| Valheim | `compose/valheim.yml` | N/A |
| Minecraft Dawncraft | `compose/minecraft-dawncraft.yml` | N/A |
| Nginx Proxy | `compose/nginx.yml` | N/A |

### Common Ports

| Service | Ports | Protocol | Purpose |
|---------|-------|----------|----------|
| Pi-hole | 53 | TCP/UDP | DNS queries |
| Pi-hole | 8053 | TCP | HTTP web interface |
| Pi-hole | 8443 | TCP | HTTPS web interface |
| Valheim | 2456-2458 | UDP | Game traffic |
| Minecraft | 25565 | TCP | Game connections |
| Minecraft | 25575 | TCP | RCON administration |
| Zomboid | 16261, 16262 | UDP | Game traffic |
| Zomboid | 27015 | TCP | RCON administration |
| Nginx | 80, 443 | TCP | HTTP/HTTPS proxy |

### Data Storage Locations

- **Service Data:** `/data/SERVICE-NAME/`
- **Backups:** `/backup/SERVICE-NAME/`
- **Pi-hole Config:** `pihole_etc` volume (Docker managed)
- **Vercel DDNS Data:** `ddns_data` volume (Docker managed)
- **Zomboid Data:** `/data/ZomboidConfig/`, `/data/ZomboidDedicatedServer/`

## Service-Specific Details

### Project Zomboid Server

**Build 42 Support (Unstable Branch)**

The Zomboid server is configured for Build 42 using the unstable branch with workshop mod support.

**Key Features:**
- Build 42 (unstable branch) compatibility
- Workshop mod integration via Steam Workshop IDs
- RCON remote management
- Configurable server presets (Apocalypse, Survivor, Builder, etc.)
- Automatic server updates
- 4-6GB RAM allocation

**Required Environment Variables:**
- `ZOMBOID_ADMIN_PASSWORD`: Server admin password (required)
- `ZOMBOID_RCON_PASSWORD`: RCON password for remote management (required)
- `ZOMBOID_SERVER_PASSWORD`: Server password (optional, leave empty for public)
- `ZOMBOID_MEMORY`: Memory allocation (default: `4096m`)

**Workshop Mods:**
Configure in compose file via `WORKSHOP_IDS` environment variable:
```yaml
WORKSHOP_IDS: "2169435993;2366717227;2703664356"
```

**Server Configuration:**
- Preset: `Apocalypse` (adjustable via `SERVER_PRESET`)
- Max Players: 32
- Public Server: Yes (configurable)
- PvP: Disabled by default
- Server Name: Configurable via `SERVER_NAME`

**Resource Requirements:**
- Minimum: 4GB RAM
- Recommended: 6GB+ RAM for modded servers
- CPU: 2+ cores recommended

**Ports:**
- 16261/UDP: Game traffic
- 16262/UDP: Game traffic
- 27015/TCP: RCON administration

**Storage:**
- `/data/ZomboidConfig/`: Server configuration
- `/data/ZomboidDedicatedServer/`: World data and saves

### Valheim Discord Webhook Integration

The Valheim server includes sophisticated Discord webhook notifications with rich embeds.

**Embed Color Codes (Decimal):**
- **Blue (Starting):** `1973162` (#1e3a8a)
- **Green (Success):** `1096065` (#10b981)
- **Orange (Warning):** `16098827` (#f59e0b)
- **Red (Error):** `15680324` (#ef4444)

**Notification Types:**

1. **Server Startup** - Sent via `PRE_BOOTSTRAP_HOOK`
   - Server name and world
   - Connection details
   - Mod information
   - Backup schedule

2. **Backup Completion** - Sent via `POST_BACKUP_HOOK`
   - Backup filename and size
   - Backup statistics
   - Next backup time

**Environment Variables for Discord:**
- `DISCORD_WEBHOOK`: Discord webhook URL (required)
- `SERVER_NAME`: Server display name
- `WORLD_NAME`: World name
- `SERVER_IP`: Public IP for connection info
- `SERVER_PORT`: Server port (default: 2456)

**Embed Template Structure:**
```json
{
  "username": "Valheim Server",
  "embeds": [{
    "title": "🚀 Server Starting",
    "description": "Server details here",
    "color": 1973162,
    "fields": [
      {"name": "🌍 World", "value": "WorldName", "inline": true},
      {"name": "🌐 Connect", "value": "IP:Port", "inline": true}
    ],
    "timestamp": "ISO8601 timestamp"
  }]
}
```

**Implementation Notes:**
- All webhook logic embedded in compose file
- Uses `sed` with pipe delimiter for URL substitution: `sed "s|$$VAR|value|g"`
- Shell variables escaped with `$$` in Docker Compose
- JSON embeds defined as environment variables

**Hook Integration Points:**
- `PRE_BOOTSTRAP_HOOK`: Startup notification
- `POST_BACKUP_HOOK`: Backup completion + external backup copy
- `POST_BEPINEX_HOOK`: Mod installation from Thunderstore

---

**Last Updated:** 2025-01-31  
**Repository:** Portainer Docker Compose configurations for game servers and network services  
**Deployment:** GitHub → Portainer Git Integration → Docker Stacks  
**All Documentation:** Consolidated in this file (AGENTS.md)
