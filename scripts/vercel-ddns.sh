#!/bin/sh

# Vercel Dynamic DNS Script
# Updates Vercel DNS records when public IP changes

set -e

# Configuration
VERCEL_TOKEN="${VERCEL_TOKEN}"
VERCEL_DOMAIN="${VERCEL_DOMAIN}"
VERCEL_RECORD_NAME="${VERCEL_RECORD_NAME:-@}"
VERCEL_RECORD_TYPE="${VERCEL_RECORD_TYPE:-A}"
CHECK_INTERVAL="${CHECK_INTERVAL:-300}"

# Data directory for storing last known IP
DATA_DIR="/app/data"
IP_FILE="${DATA_DIR}/last_ip.txt"
LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')] VERCEL-DDNS:"

# Ensure data directory exists
mkdir -p "${DATA_DIR}"

# Logging function
log() {
    echo "${LOG_PREFIX} $1"
}

# Function to get current public IP
get_public_ip() {
    # Try multiple services for reliability
    for service in "https://ipv4.icanhazip.com" "https://api.ipify.org" "https://checkip.amazonaws.com"; do
        if ip=$(curl -s --max-time 10 "${service}" | tr -d '\n\r'); then
            # Validate IP format
            if echo "${ip}" | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' > /dev/null; then
                echo "${ip}"
                return 0
            fi
        fi
    done
    return 1
}

# Function to get current DNS record from Vercel
get_vercel_record() {
    local domain="$1"
    local record_name="$2"
    local record_type="$3"
    
    response=$(curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
        "https://api.vercel.com/v2/domains/${domain}/records")
    
    if [ $? -ne 0 ]; then
        log "ERROR: Failed to fetch DNS records from Vercel"
        return 1
    fi
    
    # Parse JSON to find the record
    echo "${response}" | jq -r ".records[] | select(.name == \"${record_name}\" and .type == \"${record_type}\") | .value" 2>/dev/null || echo ""
}

# Function to update Vercel DNS record
update_vercel_record() {
    local domain="$1"
    local record_name="$2"
    local record_type="$3"
    local new_ip="$4"
    
    # First, try to find existing record ID
    response=$(curl -s -H "Authorization: Bearer ${VERCEL_TOKEN}" \
        "https://api.vercel.com/v2/domains/${domain}/records")
    
    record_id=$(echo "${response}" | jq -r ".records[] | select(.name == \"${record_name}\" and .type == \"${record_type}\") | .id" 2>/dev/null)
    
    if [ -n "${record_id}" ] && [ "${record_id}" != "null" ]; then
        # Update existing record
        log "Updating existing DNS record (ID: ${record_id})"
        update_response=$(curl -s -X PATCH \
            -H "Authorization: Bearer ${VERCEL_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "{\"value\": \"${new_ip}\"}" \
            "https://api.vercel.com/v2/domains/${domain}/records/${record_id}")
    else
        # Create new record
        log "Creating new DNS record"
        update_response=$(curl -s -X POST \
            -H "Authorization: Bearer ${VERCEL_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "{\"name\": \"${record_name}\", \"type\": \"${record_type}\", \"value\": \"${new_ip}\"}" \
            "https://api.vercel.com/v2/domains/${domain}/records")
    fi
    
    # Check if update was successful
    if echo "${update_response}" | jq -e '.error' > /dev/null 2>&1; then
        error_message=$(echo "${update_response}" | jq -r '.error.message')
        log "ERROR: Failed to update DNS record: ${error_message}"
        return 1
    else
        log "Successfully updated DNS record: ${record_name}.${domain} -> ${new_ip}"
        return 0
    fi
}

# Function to validate required environment variables
validate_config() {
    if [ -z "${VERCEL_TOKEN}" ]; then
        log "ERROR: VERCEL_TOKEN environment variable is required"
        exit 1
    fi
    
    if [ -z "${VERCEL_DOMAIN}" ]; then
        log "ERROR: VERCEL_DOMAIN environment variable is required"
        exit 1
    fi
    
    log "Configuration validated successfully"
    log "Domain: ${VERCEL_DOMAIN}"
    log "Record: ${VERCEL_RECORD_NAME}.${VERCEL_DOMAIN} (${VERCEL_RECORD_TYPE})"
    log "Check interval: ${CHECK_INTERVAL} seconds"
}

# Main loop
main() {
    log "Starting Vercel Dynamic DNS service"
    
    # Validate configuration
    validate_config
    
    while true; do
        log "Checking current public IP..."
        
        # Get current public IP
        if ! current_ip=$(get_public_ip); then
            log "ERROR: Failed to get public IP address"
            sleep "${CHECK_INTERVAL}"
            continue
        fi
        
        log "Current public IP: ${current_ip}"
        
        # Read last known IP
        last_ip=""
        if [ -f "${IP_FILE}" ]; then
            last_ip=$(cat "${IP_FILE}" 2>/dev/null || echo "")
        fi
        
        # Check if IP has changed
        if [ "${current_ip}" != "${last_ip}" ]; then
            log "IP address changed from '${last_ip}' to '${current_ip}'"
            
            # Update Vercel DNS record
            if update_vercel_record "${VERCEL_DOMAIN}" "${VERCEL_RECORD_NAME}" "${VERCEL_RECORD_TYPE}" "${current_ip}"; then
                # Save new IP to file
                echo "${current_ip}" > "${IP_FILE}"
                log "DNS update completed successfully"
            else
                log "ERROR: Failed to update DNS record"
            fi
        else
            log "IP address unchanged (${current_ip})"
        fi
        
        log "Sleeping for ${CHECK_INTERVAL} seconds..."
        sleep "${CHECK_INTERVAL}"
    done
}

# Handle signals for graceful shutdown
trap 'log "Received shutdown signal, exiting..."; exit 0' TERM INT

# Start the main loop
main