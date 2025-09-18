# Vercel Dynamic DNS Service

A Docker Compose service that automatically updates Vercel DNS records when your public IP address changes. Perfect for home servers or dynamic IP environments.

## Features

- ✅ Checks public IP every 5 minutes (configurable)
- ✅ Updates Vercel DNS records only when IP changes
- ✅ Supports multiple IP detection services for reliability
- ✅ Comprehensive logging with timestamps
- ✅ Health checks and automatic restart
- ✅ Minimal resource usage (64MB RAM limit)
- ✅ Graceful shutdown handling

## Prerequisites

1. **Vercel Account**: You need a Vercel account with a domain configured
2. **Vercel API Token**: Generate an API token from [Vercel Account Settings](https://vercel.com/account/tokens)
3. **Docker & Docker Compose**: Installed on your system

## Quick Setup

### 1. Configure Environment Variables

Copy the example environment file and fill in your details:

```bash
cp .env.vercel-ddns.example .env
```

Edit `.env` with your configuration:

```bash
# Required
VERCEL_TOKEN=your_vercel_api_token_here
VERCEL_DOMAIN=yourdomain.com

# Optional (with defaults)
VERCEL_RECORD_NAME=@              # @ for root domain, or subdomain like 'home'
VERCEL_RECORD_TYPE=A              # A record for IPv4
CHECK_INTERVAL=300                # 5 minutes in seconds
TZ=UTC                           # Your timezone
```

### 2. Start the Service

```bash
# Start the service
docker-compose -f compose/vercel-ddns.yml --env-file .env up -d

# View logs
docker-compose -f compose/vercel-ddns.yml logs -f vercel-ddns

# Stop the service
docker-compose -f compose/vercel-ddns.yml down
```

## Configuration Options

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `VERCEL_TOKEN` | ✅ | - | Your Vercel API token |
| `VERCEL_DOMAIN` | ✅ | - | Domain to update (e.g., `example.com`) |
| `VERCEL_RECORD_NAME` | ❌ | `@` | Record name (`@` for root, `www`, `api`, etc.) |
| `VERCEL_RECORD_TYPE` | ❌ | `A` | DNS record type (usually `A` for IPv4) |
| `CHECK_INTERVAL` | ❌ | `300` | Check interval in seconds (min: 60) |
| `TZ` | ❌ | `UTC` | Timezone for logs |

## Getting Your Vercel API Token

1. Go to [Vercel Account Settings](https://vercel.com/account/tokens)
2. Click "Create Token"
3. Give it a name (e.g., "DDNS Service")
4. Select appropriate scope (usually "Full Account")
5. Copy the generated token

## Monitoring

### View Logs
```bash
docker-compose -f compose/vercel-ddns.yml logs -f vercel-ddns
```

### Check Service Status
```bash
docker-compose -f compose/vercel-ddns.yml ps
```

### Health Check
The service includes a health check that monitors the script process. You can check it with:
```bash
docker inspect vercel-ddns --format='{{.State.Health.Status}}'
```

## Example Log Output

```
[2024-01-15 10:30:00] VERCEL-DDNS: Starting Vercel Dynamic DNS service
[2024-01-15 10:30:00] VERCEL-DDNS: Configuration validated successfully
[2024-01-15 10:30:00] VERCEL-DDNS: Domain: example.com
[2024-01-15 10:30:00] VERCEL-DDNS: Record: @.example.com (A)
[2024-01-15 10:30:00] VERCEL-DDNS: Check interval: 300 seconds
[2024-01-15 10:30:01] VERCEL-DDNS: Checking current public IP...
[2024-01-15 10:30:02] VERCEL-DDNS: Current public IP: 203.0.113.42
[2024-01-15 10:30:02] VERCEL-DDNS: IP address changed from '203.0.113.41' to '203.0.113.42'
[2024-01-15 10:30:03] VERCEL-DDNS: Successfully updated DNS record: @.example.com -> 203.0.113.42
[2024-01-15 10:30:03] VERCEL-DDNS: DNS update completed successfully
[2024-01-15 10:30:03] VERCEL-DDNS: Sleeping for 300 seconds...
```

## Troubleshooting

### Common Issues

1. **"VERCEL_TOKEN environment variable is required"**
   - Make sure your `.env` file is properly configured
   - Verify the token is valid and not expired

2. **"Failed to get public IP address"**
   - Check your internet connection
   - Verify the container can reach external services

3. **"Failed to update DNS record"**
   - Verify your Vercel token has the correct permissions
   - Check that the domain exists in your Vercel account
   - Ensure the domain is properly configured in Vercel

### Debug Mode

To see more detailed output, you can run the container interactively:

```bash
docker run --rm -it \
  --env-file .env \
  -v "$(pwd)/scripts/vercel-ddns.sh:/app/vercel-ddns.sh:ro" \
  alpine:3.18 \
  sh -c "apk add --no-cache curl jq && chmod +x /app/vercel-ddns.sh && /app/vercel-ddns.sh"
```

## Security Notes

- Store your Vercel API token securely
- Consider using Docker secrets for production deployments
- The service only needs network access to check IP and update DNS
- Logs are rotated automatically (10MB max, 3 files)

## File Structure

```
├── compose/
│   └── vercel-ddns.yml          # Docker Compose configuration with embedded script
├── .env.vercel-ddns.example     # Environment template
└── README-vercel-ddns.md        # This file
```

Note: The DDNS script is embedded directly in the Docker Compose file for easier deployment and to avoid file mounting issues.

## License

This project is provided as-is for educational and personal use.