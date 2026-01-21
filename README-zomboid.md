# Project Zomboid Dedicated Server (Build 42)

A Docker Compose setup for Project Zomboid dedicated server with Build 42 (unstable branch) support.

## Features

- ✅ Build 42 (unstable branch) support
- ✅ Workshop mod integration
- ✅ RCON remote management
- ✅ Configurable server presets
- ✅ Automatic server updates
- ✅ Health monitoring
- ✅ Resource management (4-6GB RAM)
- ✅ Persistent world and config storage

## Prerequisites

1. **Docker & Docker Compose** installed
2. **Sufficient resources**: Minimum 4GB RAM, recommended 6GB+
3. **Port forwarding** configured on your router (if hosting publicly)

## Quick Setup

### 1. Configure Environment Variables

Copy the example environment file and fill in your details:

```bash
cp .env.zomboid.example .env
```

Edit `.env` with your configuration:

```bash
# Required - Set secure passwords
ZOMBOID_ADMIN_PASSWORD=your_secure_admin_password
ZOMBOID_RCON_PASSWORD=your_secure_rcon_password

# Optional - Server password (leave empty for public)
ZOMBOID_SERVER_PASSWORD=

# Optional - Adjust memory if needed
ZOMBOID_MEMORY=4096m
```

### 2. Create Data Directories

```bash
mkdir -p /data/ZomboidConfig /data/ZomboidDedicatedServer
```

### 3. Start the Server

```bash
# Start the service
docker-compose -f compose/zomboid.yml --env-file .env up -d

# View logs (first startup takes 5-15 minutes)
docker-compose -f compose/zomboid.yml logs -f zomboid-server

# Stop the service
docker-compose -f compose/zomboid.yml down
```

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ZOMBOID_ADMIN_USERNAME` | ❌ | `admin` | Admin username |
| `ZOMBOID_ADMIN_PASSWORD` | ✅ | - | Admin password |
| `ZOMBOID_RCON_PASSWORD` | ✅ | - | RCON password |
| `ZOMBOID_SERVER_PASSWORD` | ❌ | (empty) | Server password (empty = public) |
| `ZOMBOID_SERVER_NAME` | ❌ | `SSF-HordeNight` | Internal server name (no spaces) |
| `ZOMBOID_MEMORY` | ❌ | `4096m` | RAM allocation |
| `TZ` | ❌ | `UTC` | Timezone |

### Server Settings (in compose file)

- **DISPLAYNAME**: "SSF - Horde Night" (public display name)
- **SERVERPRESET**: Apocalypse (difficulty preset)
- **PUBLIC**: true (appears in server browser)
- **STEAMVAC**: true (VAC anti-cheat enabled)
- **STEAMAPPBRANCH**: unstable (Build 42)

### Adding Workshop Mods

Edit `compose/zomboid.yml` and update the `WORKSHOP_IDS` environment variable:

```yaml
# Single mod
- WORKSHOP_IDS=2714850307

# Multiple mods (semicolon-separated)
- WORKSHOP_IDS=2714850307;2160432461;2685168362
```

**For Build 42**, if you need to specify MOD_IDS manually:

```yaml
# MOD_IDS require \\ prefix in Build 42
- MOD_IDS=\\mod1;\\mod2
```

### Port Configuration

| Port | Protocol | Purpose |
|------|----------|---------|
| 16261 | UDP | Game port (main) |
| 16262 | UDP | Game port (secondary) |
| 8766 | UDP | Steam port 1 |
| 8767 | UDP | Steam port 2 |
| 27015 | TCP | RCON (remote console) |

## Monitoring

### View Logs

```bash
docker-compose -f compose/zomboid.yml logs -f zomboid-server
```

### Check Server Status

```bash
docker-compose -f compose/zomboid.yml ps
```

### Health Check

```bash
docker inspect zomboid-server --format='{{.State.Health.Status}}'
```

### Resource Usage

```bash
docker stats zomboid-server
```

## Server Startup Process

1. **First Start**: Downloads server files (5-15 minutes)
2. **Second Start**: Downloads and installs workshop mods
3. **Third Start**: Generates world and maps

**Important**: The server requires multiple restarts to fully initialize all components.

## Connecting to Server

### In-Game Connection

1. Launch Project Zomboid
2. Select "Join" from main menu
3. Choose "Internet" tab
4. Look for "SSF - Horde Night" in server browser
5. Or use "Connect to IP": `your-server-ip:16261`

### RCON Connection

Use an RCON client to connect:
- **Host**: your-server-ip
- **Port**: 27015
- **Password**: Your RCON password from `.env`

## Troubleshooting

### Common Issues

1. **"Server not appearing in browser"**
   - Ensure ports 16261-16262 UDP are forwarded on your router
   - Check firewall settings
   - Verify `PUBLIC=true` is set
   - Wait 5-10 minutes after startup for registration

2. **"Connection timeout" when joining**
   - Verify port forwarding is configured correctly
   - Check that UDP ports 16261, 16262, 8766, 8767 are open
   - Ensure firewall allows connections

3. **"Server crashes on startup"**
   - Check logs: `docker-compose -f compose/zomboid.yml logs zomboid-server`
   - Verify sufficient RAM is allocated (4GB minimum)
   - Ensure data directories exist and are writable
   - Check for conflicting workshop mods

4. **"Admin user not working"**
   - Ensure `ZOMBOID_SERVER_NAME` has no spaces or special characters
   - Use only alphanumeric characters and hyphens
   - Restart server after changing admin credentials

5. **"Slow startup on Windows/WSL2"**
   - First startup can take 15-40 minutes with many mods on WSL2
   - This is a known limitation of the Docker image on Windows
   - Consider running on native Linux for better performance

### Performance Optimization

If experiencing lag or crashes:

```yaml
# Increase memory allocation
- MEMORY=8096m

# Adjust resource limits in deploy section
limits:
  cpus: '6'
  memory: 10G
reservations:
  memory: 8G
```

## Backup Strategy

Server data is stored in:
- `/data/ZomboidConfig` - Server configuration and player data
- `/data/ZomboidDedicatedServer` - World saves and game files

**Recommended backup schedule**:
```bash
# Create backup script
#!/bin/bash
timestamp=$(date +%Y%m%d_%H%M%S)
tar -czf /backup/zomboid_config_$timestamp.tar.gz /data/ZomboidConfig
tar -czf /backup/zomboid_server_$timestamp.tar.gz /data/ZomboidDedicatedServer

# Keep only last 7 days
find /backup -name "zomboid_*.tar.gz" -mtime +7 -delete
```

## Updating the Server

### Update Game Version

```bash
# Pull latest image
docker-compose -f compose/zomboid.yml pull

# Recreate container
docker-compose -f compose/zomboid.yml up -d
```

### Force Server Update

Set `FORCEUPDATE=true` in compose file, restart, then set back to `false`.

### Switch Between Build 41 and Build 42

Edit `compose/zomboid.yml`:

```yaml
# Build 42 (unstable)
- STEAMAPPBRANCH=unstable

# Build 41 (stable)
- STEAMAPPBRANCH=public
```

**Warning**: Switching branches may require world reset due to incompatibility.

## Advanced Configuration

### Server Presets

Change difficulty preset:

```yaml
- SERVERPRESET=Apocalypse    # Default
- SERVERPRESET=Survival      # Easier
- SERVERPRESET=Builder       # Creative mode
- SERVERPRESET=Beginner      # Very easy
```

### Custom Server Settings

For advanced configuration, edit files in `/data/ZomboidConfig` after first startup:
- `Server/servertest.ini` - Main server configuration
- `Server/servertest_SandboxVars.lua` - Sandbox settings

## Migration from Old Setup

If migrating from renegademaster image:

1. **Stop old server**: `docker-compose -f compose/zomboid.yml down`
2. **Backup data**: Copy `/data/ZomboidConfig` and `/data/ZomboidDedicatedServer`
3. **Update compose file**: Replace with new Danixu-based configuration
4. **Create .env file**: Using `.env.zomboid.example` template
5. **Start new server**: `docker-compose -f compose/zomboid.yml --env-file .env up -d`
6. **Verify compatibility**: Check logs for any mod or configuration issues

## Security Notes

- Never commit `.env` files with passwords to git
- Use strong, unique passwords for admin and RCON access
- Consider using Docker secrets for production deployments
- Regularly update the server image for security patches
- Review workshop mods for potential security issues

## Resources

- **Docker Image**: [danixu86/project-zomboid-dedicated-server](https://hub.docker.com/r/danixu86/project-zomboid-dedicated-server)
- **GitHub Repository**: [Danixu/project-zomboid-server-docker](https://github.com/Danixu/project-zomboid-server-docker)
- **Project Zomboid Wiki**: [pzwiki.net](https://pzwiki.net/)
- **Workshop Mods**: [Steam Workshop](https://steamcommunity.com/app/108600/workshop/)

## License

This Docker Compose configuration is part of a personal infrastructure setup. The Docker image is maintained by Danixu and uses the official Project Zomboid dedicated server.
