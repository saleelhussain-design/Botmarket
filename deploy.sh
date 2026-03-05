#!/bin/bash
#
# botmarket.ae Main Deployment Script
# Usage: ./deploy.sh [environment] [version/commit]
# Example: ./deploy.sh production v1.2.0
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="/var/log/botmarket-deploy-$(date +%Y%m%d-%H%M%S).log"

# Container IDs for each service
declare -A CONTAINERS=(
    ["nginx"]=200
    ["mysql"]=201
    ["ollama"]=202
    ["pm-bot"]=203
    ["uptime-kuma"]=204
    ["bot-factory"]=205
    ["marketplace"]=206
)

# Service deployment order (dependencies first)
DEPLOY_ORDER=("mysql" "nginx" "ollama" "pm-bot" "bot-factory" "marketplace")

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
# Validation
#############################################

validate_environment() {
    local env=$1
    case $env in
        production|staging|development)
            return 0
            ;;
        *)
            error "Invalid environment: $env. Must be: production, staging, or development"
            ;;
    esac
}

validate_version() {
    local version=$1
    
    # Check if version/commit exists
    if ! git rev-parse "$version" >/dev/null 2>&1; then
        error "Version/commit not found: $version"
    fi
    
    log "Validated version: $version ($(git rev-parse --short $version))"
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if running on Proxmox host
    if ! command -v pct &> /dev/null; then
        error "This script must run on Proxmox host (pct command not found)"
    fi
    
    # Check if in git repo
    if [ ! -d "$PROJECT_ROOT/.git" ]; then
        error "Not in a git repository"
    fi
    
    # Check if all containers exist
    for service in "${!CONTAINERS[@]}"; do
        local ct_id=${CONTAINERS[$service]}
        if ! pct status $ct_id &>/dev/null; then
            warning "Container $ct_id ($service) not found or not running"
        fi
    done
    
    success "Prerequisites check passed"
}

#############################################
# Backup Functions
#############################################

create_backups() {
    log "Creating pre-deployment backups..."
    
    local backup_dir="/var/backups/botmarket-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Take Proxmox snapshots for all containers
    for service in "${!CONTAINERS[@]}"; do
        local ct_id=${CONTAINERS[$service]}
        local snapshot_name="pre-deploy-$(date +%Y%m%d-%H%M%S)"
        
        log "Taking snapshot of CT$ct_id ($service): $snapshot_name"
        
        if pct snapshot $ct_id $snapshot_name --description "Pre-deployment backup" 2>&1 | tee -a "$LOG_FILE"; then
            success "Snapshot created for $service"
        else
            warning "Failed to create snapshot for $service"
        fi
    done
    
    # Backup MySQL database
    log "Backing up MySQL database..."
    local mysql_backup="$backup_dir/mysql-backup.sql.gz"
    
    if pct exec 201 -- bash -c "mysqldump -u root --all-databases | gzip" > "$mysql_backup" 2>>"$LOG_FILE"; then
        success "MySQL backup saved: $mysql_backup"
    else
        warning "MySQL backup failed"
    fi
    
    # Backup current version info
    echo "$(git rev-parse HEAD)" > "$backup_dir/previous-version.txt"
    echo "$(cat $PROJECT_ROOT/VERSION 2>/dev/null || echo 'unknown')" >> "$backup_dir/previous-version.txt"
    
    success "All backups created in: $backup_dir"
    echo "$backup_dir" > /tmp/last-backup-dir.txt
}

#############################################
# Deployment Functions
#############################################

checkout_version() {
    local version=$1
    
    log "Checking out version: $version"
    cd "$PROJECT_ROOT"
    
    # Stash any local changes
    git stash save "Auto-stash before deploy $(date)" 2>&1 | tee -a "$LOG_FILE"
    
    # Fetch latest
    git fetch origin 2>&1 | tee -a "$LOG_FILE"
    
    # Checkout version
    if git checkout "$version" 2>&1 | tee -a "$LOG_FILE"; then
        success "Checked out: $version"
    else
        error "Failed to checkout version: $version"
    fi
    
    # Pull if on a branch
    if git symbolic-ref -q HEAD &>/dev/null; then
        git pull origin "$(git branch --show-current)" 2>&1 | tee -a "$LOG_FILE"
    fi
}

deploy_service() {
    local service=$1
    local environment=$2
    local ct_id=${CONTAINERS[$service]}
    
    log "Deploying $service to CT$ct_id ($environment)..."
    
    case $service in
        pm-bot)
            deploy_pm_bot $ct_id $environment
            ;;
        bot-factory)
            deploy_bot_factory $ct_id $environment
            ;;
        marketplace)
            deploy_marketplace $ct_id $environment
            ;;
        nginx)
            deploy_nginx $ct_id $environment
            ;;
        *)
            log "No deployment needed for $service (infrastructure only)"
            ;;
    esac
}

deploy_pm_bot() {
    local ct_id=$1
    local environment=$2
    
    log "Deploying PM Bot to CT$ct_id..."
    
    # Create directory
    pct exec $ct_id -- mkdir -p /opt/pm-bot
    
    # Copy source files
    pct push $ct_id "$PROJECT_ROOT/services/pm-bot/src/pm_server.py" /opt/pm-bot/pm_server.py
    pct push $ct_id "$PROJECT_ROOT/services/pm-bot/src/dashboard.html" /opt/pm-bot/dashboard.html
    
    # Copy environment file
    if [ -f "/root/botmarket-secrets/pm-bot-$environment.env" ]; then
        pct push $ct_id "/root/botmarket-secrets/pm-bot-$environment.env" /opt/pm-bot/.env
    else
        warning "Environment file not found: /root/botmarket-secrets/pm-bot-$environment.env"
    fi
    
    # Copy requirements
    pct push $ct_id "$PROJECT_ROOT/services/pm-bot/requirements.txt" /opt/pm-bot/requirements.txt
    
    # Install dependencies
    log "Installing PM Bot dependencies..."
    pct exec $ct_id -- bash -c "pip3 install -r /opt/pm-bot/requirements.txt --break-system-packages" 2>&1 | tee -a "$LOG_FILE"
    
    # Copy systemd service
    pct push $ct_id "$PROJECT_ROOT/services/pm-bot/systemd/pm-bot.service" /etc/systemd/system/pm-bot.service
    
    # Reload systemd and restart service
    log "Restarting PM Bot service..."
    pct exec $ct_id -- systemctl daemon-reload
    pct exec $ct_id -- systemctl enable pm-bot
    pct exec $ct_id -- systemctl restart pm-bot
    
    # Wait for service to start
    sleep 5
    
    # Check service status
    if pct exec $ct_id -- systemctl is-active pm-bot &>/dev/null; then
        success "PM Bot deployed and running"
    else
        error "PM Bot failed to start. Check logs: pct exec $ct_id -- journalctl -u pm-bot -n 50"
    fi
}

deploy_bot_factory() {
    local ct_id=$1
    local environment=$2
    
    log "Deploying Bot Factory to CT$ct_id..."
    
    # Create directory
    pct exec $ct_id -- mkdir -p /opt/bot-factory
    
    # Copy source files
    pct push $ct_id "$PROJECT_ROOT/services/bot-factory/src/server.py" /opt/bot-factory/server.py
    
    # Copy UI files if they exist
    if [ -d "$PROJECT_ROOT/services/bot-factory/src/ui" ]; then
        pct exec $ct_id -- mkdir -p /opt/bot-factory/ui
        # Copy UI files (adjust as needed)
    fi
    
    # Copy environment file
    if [ -f "/root/botmarket-secrets/bot-factory-$environment.env" ]; then
        pct push $ct_id "/root/botmarket-secrets/bot-factory-$environment.env" /opt/bot-factory/.env
    fi
    
    # Copy requirements
    pct push $ct_id "$PROJECT_ROOT/services/bot-factory/requirements.txt" /opt/bot-factory/requirements.txt
    
    # Install dependencies
    log "Installing Bot Factory dependencies..."
    pct exec $ct_id -- bash -c "pip3 install -r /opt/bot-factory/requirements.txt --break-system-packages" 2>&1 | tee -a "$LOG_FILE"
    
    # Copy and enable systemd service
    pct push $ct_id "$PROJECT_ROOT/services/bot-factory/systemd/bot-factory.service" /etc/systemd/system/bot-factory.service
    
    log "Restarting Bot Factory service..."
    pct exec $ct_id -- systemctl daemon-reload
    pct exec $ct_id -- systemctl enable bot-factory
    pct exec $ct_id -- systemctl restart bot-factory
    
    sleep 5
    
    if pct exec $ct_id -- systemctl is-active bot-factory &>/dev/null; then
        success "Bot Factory deployed and running"
    else
        error "Bot Factory failed to start"
    fi
}

deploy_marketplace() {
    local ct_id=$1
    local environment=$2
    
    log "Deploying Marketplace to CT$ct_id..."
    
    # Create web root
    pct exec $ct_id -- mkdir -p /var/www/botmarket
    
    # Copy static files
    if [ -d "$PROJECT_ROOT/services/marketplace/public" ]; then
        pct exec $ct_id -- rm -rf /var/www/botmarket/*
        # Copy all files from public directory
        find "$PROJECT_ROOT/services/marketplace/public" -type f | while read file; do
            relative_path="${file#$PROJECT_ROOT/services/marketplace/public/}"
            target_dir="/var/www/botmarket/$(dirname $relative_path)"
            pct exec $ct_id -- mkdir -p "$target_dir"
            pct push $ct_id "$file" "/var/www/botmarket/$relative_path"
        done
    fi
    
    # Copy nginx config
    if [ -f "$PROJECT_ROOT/services/marketplace/nginx/site.conf" ]; then
        pct push $ct_id "$PROJECT_ROOT/services/marketplace/nginx/site.conf" /etc/nginx/sites-available/botmarket
        pct exec $ct_id -- ln -sf /etc/nginx/sites-available/botmarket /etc/nginx/sites-enabled/
    fi
    
    # Test nginx config
    log "Testing nginx configuration..."
    if pct exec $ct_id -- nginx -t 2>&1 | tee -a "$LOG_FILE"; then
        pct exec $ct_id -- systemctl reload nginx
        success "Marketplace deployed"
    else
        error "Nginx configuration test failed"
    fi
}

deploy_nginx() {
    local ct_id=$1
    local environment=$2
    
    log "Updating Nginx Proxy Manager configuration..."
    
    # Copy proxy configs if they exist
    if [ -d "$PROJECT_ROOT/infrastructure/nginx/proxy-configs" ]; then
        log "Nginx Proxy Manager configs are managed via web UI"
        warning "Manual configuration may be needed in Nginx Proxy Manager"
    fi
}

#############################################
# Health Check Functions
#############################################

run_health_checks() {
    local environment=$1
    
    log "Running health checks..."
    
    local all_healthy=true
    
    # Check PM Bot
    if ! curl -sf http://192.168.1.203:5001/api/health &>/dev/null; then
        warning "PM Bot health check failed"
        all_healthy=false
    else
        success "PM Bot is healthy"
    fi
    
    # Check Bot Factory
    if ! curl -sf http://192.168.1.205:5000/api/health &>/dev/null; then
        warning "Bot Factory health check failed"
        all_healthy=false
    else
        success "Bot Factory is healthy"
    fi
    
    # Check Marketplace (production only)
    if [ "$environment" == "production" ]; then
        if ! curl -sf https://botmarket.ae &>/dev/null; then
            warning "Marketplace health check failed"
            all_healthy=false
        else
            success "Marketplace is healthy"
        fi
    fi
    
    # Check MySQL
    if ! pct exec 201 -- mysql -u root -e "SELECT 1" &>/dev/null; then
        warning "MySQL health check failed"
        all_healthy=false
    else
        success "MySQL is healthy"
    fi
    
    if $all_healthy; then
        success "All health checks passed"
        return 0
    else
        warning "Some health checks failed"
        return 1
    fi
}

#############################################
# Version Management
#############################################

update_version_file() {
    local version=$1
    local commit_hash=$(git rev-parse --short HEAD)
    local deploy_time=$(date '+%Y-%m-%d %H:%M:%S %Z')
    
    log "Updating VERSION file..."
    
    cat > "$PROJECT_ROOT/VERSION" << EOF
VERSION=$version
COMMIT=$commit_hash
DEPLOYED=$deploy_time
DEPLOYED_BY=$(whoami)
EOF
    
    # Copy to each service container
    for service in "${DEPLOY_ORDER[@]}"; do
        local ct_id=${CONTAINERS[$service]}
        if pct status $ct_id &>/dev/null; then
            pct push $ct_id "$PROJECT_ROOT/VERSION" /opt/VERSION
        fi
    done
    
    success "VERSION file updated"
}

#############################################
# Main Deployment Flow
#############################################

main() {
    local environment=$1
    local version=$2
    
    # Header
    echo ""
    echo "=========================================="
    echo "  botmarket.ae Deployment Script"
    echo "=========================================="
    echo ""
    
    # Validate inputs
    if [ -z "$environment" ] || [ -z "$version" ]; then
        error "Usage: $0 [environment] [version/commit]\nExample: $0 production v1.2.0"
    fi
    
    validate_environment "$environment"
    check_prerequisites
    validate_version "$version"
    
    # Show deployment info
    log "Environment: $environment"
    log "Version: $version"
    log "Current version: $(cat $PROJECT_ROOT/VERSION 2>/dev/null | grep VERSION | cut -d'=' -f2 || echo 'unknown')"
    echo ""
    
    # Confirmation for production
    if [ "$environment" == "production" ]; then
        echo ""
        if ! confirm "Deploy to PRODUCTION environment?"; then
            error "Deployment cancelled by user"
        fi
        echo ""
    fi
    
    # Start deployment
    log "Starting deployment..."
    
    # Step 1: Create backups
    create_backups
    
    # Step 2: Checkout version
    checkout_version "$version"
    
    # Step 3: Deploy services in order
    for service in "${DEPLOY_ORDER[@]}"; do
        deploy_service "$service" "$environment"
    done
    
    # Step 4: Update version file
    update_version_file "$version"
    
    # Step 5: Run health checks
    if run_health_checks "$environment"; then
        success "Deployment completed successfully!"
    else
        warning "Deployment completed with warnings. Check health status above."
        
        if [ "$environment" == "production" ]; then
            echo ""
            if confirm "Health checks failed. Rollback?"; then
                log "Initiating rollback..."
                "$SCRIPT_DIR/rollback.sh" "$environment"
            fi
        fi
    fi
    
    # Summary
    echo ""
    echo "=========================================="
    echo "  Deployment Summary"
    echo "=========================================="
    echo "Environment: $environment"
    echo "Version: $version"
    echo "Deployed: $(date)"
    echo "Log file: $LOG_FILE"
    echo "Backup dir: $(cat /tmp/last-backup-dir.txt 2>/dev/null || echo 'unknown')"
    echo "=========================================="
    echo ""
    
    success "Deployment complete!"
}

# Run main function
main "$@"
