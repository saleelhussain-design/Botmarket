#!/bin/bash
#
# botmarket.ae Rollback Script
# Usage: ./rollback.sh [environment] [version] [service]
# Examples:
#   ./rollback.sh production              # Rollback to previous version (all services)
#   ./rollback.sh production v1.1.5       # Rollback to specific version
#   ./rollback.sh production v1.1.5 pm-bot   # Rollback specific service only
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="/var/log/botmarket-rollback-$(date +%Y%m%d-%H%M%S).log"

# Container IDs
declare -A CONTAINERS=(
    ["nginx"]=200
    ["mysql"]=201
    ["ollama"]=202
    ["pm-bot"]=203
    ["uptime-kuma"]=204
    ["bot-factory"]=205
    ["marketplace"]=206
)

#############################################
# Helper Functions
#############################################

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}❌ ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

confirm() {
    read -p "$(echo -e ${YELLOW}"⚠️  $1 (yes/no): "${NC})" response
    case "$response" in
        yes|YES|y|Y) return 0 ;;
        *) return 1 ;;
    esac
}

#############################################
# Rollback Methods
#############################################

get_previous_version() {
    local backup_dir=$(cat /tmp/last-backup-dir.txt 2>/dev/null)
    
    if [ -z "$backup_dir" ] || [ ! -f "$backup_dir/previous-version.txt" ]; then
        # Try to get from git
        local current_commit=$(git rev-parse HEAD)
        local previous_commit=$(git rev-parse HEAD~1)
        echo "$previous_commit"
    else
        cat "$backup_dir/previous-version.txt" | head -n 1
    fi
}

list_available_snapshots() {
    local ct_id=$1
    local service=$2
    
    log "Available snapshots for $service (CT$ct_id):"
    pct listsnapshot $ct_id 2>/dev/null | tail -n +2 || echo "No snapshots found"
}

rollback_via_snapshot() {
    local service=$1
    local snapshot_name=$2
    local ct_id=${CONTAINERS[$service]}
    
    log "Rolling back $service via snapshot..."
    
    # List snapshots if no specific one provided
    if [ -z "$snapshot_name" ]; then
        log "Finding latest pre-deployment snapshot..."
        snapshot_name=$(pct listsnapshot $ct_id 2>/dev/null | grep "pre-deploy" | tail -n 1 | awk '{print $1}')
        
        if [ -z "$snapshot_name" ]; then
            warning "No pre-deployment snapshot found for $service"
            return 1
        fi
        
        log "Using snapshot: $snapshot_name"
    fi
    
    # Stop container
    log "Stopping CT$ct_id..."
    pct stop $ct_id 2>&1 | tee -a "$LOG_FILE"
    
    # Rollback
    log "Rolling back to snapshot: $snapshot_name"
    if pct rollback $ct_id $snapshot_name 2>&1 | tee -a "$LOG_FILE"; then
        success "Snapshot rollback successful"
    else
        error "Snapshot rollback failed"
    fi
    
    # Start container
    log "Starting CT$ct_id..."
    pct start $ct_id 2>&1 | tee -a "$LOG_FILE"
    
    # Wait for container to start
    sleep 10
    
    success "$service rolled back via snapshot"
}

rollback_via_git() {
    local version=$1
    local service=$2
    
    log "Rolling back via git to version: $version"
    
    cd "$PROJECT_ROOT"
    
    # Checkout previous version
    if ! git checkout "$version" 2>&1 | tee -a "$LOG_FILE"; then
        error "Failed to checkout version: $version"
    fi
    
    # If specific service, deploy only that service
    if [ -n "$service" ]; then
        log "Deploying only $service..."
        "$SCRIPT_DIR/deploy-service.sh" "$service" "$environment" "$version"
    else
        log "Deploying all services..."
        "$SCRIPT_DIR/deploy.sh" "$environment" "$version"
    fi
}

restore_mysql_backup() {
    local backup_dir=$(cat /tmp/last-backup-dir.txt 2>/dev/null)
    
    if [ -z "$backup_dir" ]; then
        warning "No backup directory found in /tmp/last-backup-dir.txt"
        return 1
    fi
    
    local mysql_backup="$backup_dir/mysql-backup.sql.gz"
    
    if [ ! -f "$mysql_backup" ]; then
        warning "MySQL backup not found: $mysql_backup"
        return 1
    fi
    
    log "Restoring MySQL database from backup..."
    
    if confirm "This will restore MySQL to previous state. Continue?"; then
        gunzip -c "$mysql_backup" | pct exec 201 -- mysql -u root 2>&1 | tee -a "$LOG_FILE"
        success "MySQL database restored"
    else
        log "MySQL restore skipped"
    fi
}

#############################################
# Health Checks After Rollback
#############################################

verify_rollback() {
    local environment=$1
    
    log "Verifying rollback..."
    
    sleep 15  # Give services time to fully start
    
    local all_healthy=true
    
    # Check PM Bot
    if curl -sf http://192.168.1.203:5001/api/health &>/dev/null; then
        success "PM Bot is responding"
    else
        warning "PM Bot is not responding"
        all_healthy=false
    fi
    
    # Check Bot Factory
    if curl -sf http://192.168.1.205:5000/api/health &>/dev/null; then
        success "Bot Factory is responding"
    else
        warning "Bot Factory is not responding"
        all_healthy=false
    fi
    
    # Check MySQL
    if pct exec 201 -- mysql -u root -e "SELECT 1" &>/dev/null; then
        success "MySQL is responding"
    else
        warning "MySQL is not responding"
        all_healthy=false
    fi
    
    if $all_healthy; then
        success "All services verified healthy after rollback"
        return 0
    else
        warning "Some services still unhealthy after rollback"
        return 1
    fi
}

#############################################
# Main Rollback Flow
#############################################

main() {
    local environment=$1
    local version=$2
    local service=$3
    
    echo ""
    echo "=========================================="
    echo "  botmarket.ae Rollback Script"
    echo "=========================================="
    echo ""
    
    if [ -z "$environment" ]; then
        error "Usage: $0 [environment] [version] [service]\nExample: $0 production v1.1.5 pm-bot"
    fi
    
    # Get current version
    local current_version=$(cat $PROJECT_ROOT/VERSION 2>/dev/null | grep VERSION | cut -d'=' -f2 || echo 'unknown')
    log "Current version: $current_version"
    
    # Determine rollback version
    if [ -z "$version" ]; then
        log "No version specified, finding previous version..."
        version=$(get_previous_version)
        log "Previous version: $version"
    fi
    
    # Show rollback plan
    echo ""
    log "Rollback Plan:"
    log "  Environment: $environment"
    log "  From version: $current_version"
    log "  To version: $version"
    if [ -n "$service" ]; then
        log "  Service: $service (specific service rollback)"
    else
        log "  Service: ALL SERVICES"
    fi
    echo ""
    
    # Confirmation
    if ! confirm "Proceed with rollback?"; then
        error "Rollback cancelled by user"
    fi
    
    echo ""
    log "Starting rollback..."
    
    # Choose rollback method
    log "Rollback method selection:"
    echo "  1) Git rollback (redeploy from previous version)"
    echo "  2) Proxmox snapshot rollback (faster, container-level)"
    echo "  3) Both (snapshot first, then git to ensure consistency)"
    echo ""
    read -p "Select method (1-3): " method
    
    case $method in
        1)
            log "Using git rollback method..."
            rollback_via_git "$version" "$service"
            ;;
        2)
            log "Using snapshot rollback method..."
            if [ -n "$service" ]; then
                rollback_via_snapshot "$service"
            else
                # Rollback all services
                for svc in pm-bot bot-factory marketplace; do
                    if [[ -n "${CONTAINERS[$svc]}" ]]; then
                        rollback_via_snapshot "$svc"
                    fi
                done
            fi
            ;;
        3)
            log "Using combined rollback method..."
            # First snapshot rollback
            if [ -n "$service" ]; then
                rollback_via_snapshot "$service"
            else
                for svc in pm-bot bot-factory marketplace; do
                    if [[ -n "${CONTAINERS[$svc]}" ]]; then
                        rollback_via_snapshot "$svc"
                    fi
                done
            fi
            # Then git rollback to ensure code consistency
            rollback_via_git "$version" "$service"
            ;;
        *)
            error "Invalid selection"
            ;;
    esac
    
    # Offer MySQL restore
    echo ""
    if confirm "Restore MySQL database to previous backup?"; then
        restore_mysql_backup
    fi
    
    # Verify rollback
    echo ""
    verify_rollback "$environment"
    
    # Update VERSION file
    log "Updating VERSION file..."
    cat > "$PROJECT_ROOT/VERSION" << EOF
VERSION=$version
COMMIT=$(git rev-parse --short HEAD)
DEPLOYED=$(date '+%Y-%m-%d %H:%M:%S %Z')
DEPLOYED_BY=$(whoami)
ROLLBACK=true
ROLLBACK_FROM=$current_version
EOF
    
    # Summary
    echo ""
    echo "=========================================="
    echo "  Rollback Summary"
    echo "=========================================="
    echo "Environment: $environment"
    echo "Rolled back from: $current_version"
    echo "Rolled back to: $version"
    echo "Time: $(date)"
    echo "Log file: $LOG_FILE"
    echo "=========================================="
    echo ""
    
    success "Rollback complete!"
    
    # Post-rollback recommendations
    echo ""
    log "Post-rollback recommendations:"
    echo "  1. Monitor services: watch -n 5 'pct exec 203 -- systemctl status pm-bot'"
    echo "  2. Check logs: pct exec 203 -- journalctl -u pm-bot -f"
    echo "  3. Verify in browser: https://botmarket.ae"
    echo "  4. Document incident and root cause"
    echo "  5. Plan fix for next deployment"
    echo ""
}

# Run main
main "$@"
