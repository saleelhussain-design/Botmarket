#!/bin/bash
#
# botmarket.ae Backup Script
# Usage: ./backup-all.sh [backup_type]
# Examples:
#   ./backup-all.sh daily
#   ./backup-all.sh manual
#

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
BACKUP_ROOT="/var/backups/botmarket"
BACKUP_TYPE=${1:-manual}
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$BACKUP_TYPE-$TIMESTAMP"

# Retention policy (days)
DAILY_RETENTION=7
WEEKLY_RETENTION=30
MONTHLY_RETENTION=90

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
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
    exit 1
}

#############################################
# Backup Functions
#############################################

create_backup_directory() {
    log "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"/{snapshots,databases,configs,code}
    success "Backup directory created"
}

backup_proxmox_snapshots() {
    log "Creating Proxmox LXC snapshots..."
    
    for service in "${!CONTAINERS[@]}"; do
        local ct_id=${CONTAINERS[$service]}
        local snapshot_name="backup-$BACKUP_TYPE-$(date +%Y%m%d-%H%M%S)"
        
        log "  Snapshotting CT$ct_id ($service)..."
        
        if pct snapshot $ct_id $snapshot_name --description "Automated $BACKUP_TYPE backup" 2>&1 | tee -a "$BACKUP_DIR/snapshot.log"; then
            echo "$service,$ct_id,$snapshot_name" >> "$BACKUP_DIR/snapshots/snapshot-list.txt"
            success "  Snapshot created: $snapshot_name"
        else
            error "  Failed to create snapshot for $service"
        fi
    done
    
    success "All Proxmox snapshots created"
}

backup_mysql_database() {
    log "Backing up MySQL database..."
    
    local mysql_backup="$BACKUP_DIR/databases/mysql-all-databases.sql.gz"
    
    # Full database dump
    if pct exec 201 -- bash -c "mysqldump -u root --all-databases --single-transaction --quick --lock-tables=false | gzip" > "$mysql_backup" 2>>"$BACKUP_DIR/mysql-backup.log"; then
        local size=$(du -h "$mysql_backup" | cut -f1)
        success "MySQL backup saved: $mysql_backup ($size)"
    else
        error "MySQL backup failed"
    fi
    
    # Individual database backups
    log "Backing up individual databases..."
    local databases=$(pct exec 201 -- mysql -u root -e "SHOW DATABASES" | grep -Ev "^(Database|information_schema|performance_schema|mysql|sys)$")
    
    for db in $databases; do
        log "  Backing up database: $db"
        pct exec 201 -- mysqldump -u root "$db" | gzip > "$BACKUP_DIR/databases/${db}.sql.gz"
    done
    
    success "MySQL database backups complete"
}

backup_configurations() {
    log "Backing up configuration files..."
    
    # PM Bot configs
    pct exec 203 -- tar czf - /opt/pm-bot/.env /opt/pm-bot/*.py 2>/dev/null > "$BACKUP_DIR/configs/pm-bot-config.tar.gz" || true
    
    # Bot Factory configs
    pct exec 205 -- tar czf - /opt/bot-factory/.env /opt/bot-factory/*.py 2>/dev/null > "$BACKUP_DIR/configs/bot-factory-config.tar.gz" || true
    
    # Nginx configs
    pct exec 200 -- tar czf - /etc/nginx 2>/dev/null > "$BACKUP_DIR/configs/nginx-config.tar.gz" || true
    pct exec 206 -- tar czf - /etc/nginx 2>/dev/null > "$BACKUP_DIR/configs/nginx-marketplace-config.tar.gz" || true
    
    # Systemd service files
    for service in pm-bot bot-factory; do
        local ct_id=${CONTAINERS[$service]}
        pct exec $ct_id -- cat /etc/systemd/system/${service}.service > "$BACKUP_DIR/configs/${service}.service" 2>/dev/null || true
    done
    
    success "Configuration files backed up"
}

backup_code_repository() {
    log "Backing up code repository..."
    
    cd /opt/botmarket
    
    # Create git bundle (complete repo backup)
    git bundle create "$BACKUP_DIR/code/botmarket-repo.bundle" --all 2>&1 | tee -a "$BACKUP_DIR/git-backup.log"
    
    # Save current commit info
    cat > "$BACKUP_DIR/code/git-info.txt" << EOF
Current Branch: $(git branch --show-current)
Current Commit: $(git rev-parse HEAD)
Commit Message: $(git log -1 --pretty=%B)
Commit Date: $(git log -1 --pretty=%cd)
Commit Author: $(git log -1 --pretty=%an)

Tags:
$(git tag -l)

Recent History:
$(git log --oneline -10)
EOF
    
    # Backup VERSION file
    cp VERSION "$BACKUP_DIR/code/VERSION" 2>/dev/null || true
    
    success "Code repository backed up"
}

backup_deployed_bots() {
    log "Backing up deployed bots..."
    
    # Backup bot definitions
    if [ -d "/opt/botmarket/services/bots/deployed" ]; then
        tar czf "$BACKUP_DIR/code/deployed-bots.tar.gz" /opt/botmarket/services/bots/deployed 2>/dev/null || true
        success "Deployed bots backed up"
    else
        log "No deployed bots directory found"
    fi
}

backup_secrets() {
    log "Backing up secrets (encrypted)..."
    
    if [ -d "/root/botmarket-secrets" ]; then
        # Encrypt secrets before backing up
        tar czf - /root/botmarket-secrets | gpg --symmetric --cipher-algo AES256 --output "$BACKUP_DIR/configs/secrets-encrypted.tar.gz.gpg" 2>>"$BACKUP_DIR/secrets-backup.log" || true
        success "Secrets backed up (encrypted)"
    else
        log "No secrets directory found"
    fi
}

create_backup_manifest() {
    log "Creating backup manifest..."
    
    cat > "$BACKUP_DIR/MANIFEST.txt" << EOF
================================================
botmarket.ae Backup Manifest
================================================
Backup Type: $BACKUP_TYPE
Backup Date: $(date)
Backup Location: $BACKUP_DIR

━━━ System Information ━━━
Hostname: $(hostname)
Proxmox Version: $(pveversion)
Kernel: $(uname -r)

━━━ Backup Contents ━━━
Snapshots: $(ls -1 "$BACKUP_DIR/snapshots/"*.txt 2>/dev/null | wc -l) container snapshots
Databases: $(ls -1 "$BACKUP_DIR/databases/"*.gz 2>/dev/null | wc -l) database backups
Configs: $(ls -1 "$BACKUP_DIR/configs/" 2>/dev/null | wc -l) configuration archives
Code: Git bundle + deployed bots

━━━ Container Versions ━━━
EOF
    
    # Add version info from each container
    for service in pm-bot bot-factory marketplace; do
        local ct_id=${CONTAINERS[$service]}
        echo "$service (CT$ct_id):" >> "$BACKUP_DIR/MANIFEST.txt"
        pct exec $ct_id -- cat /opt/VERSION 2>/dev/null | sed 's/^/  /' >> "$BACKUP_DIR/MANIFEST.txt" || echo "  No version file" >> "$BACKUP_DIR/MANIFEST.txt"
    done
    
    cat >> "$BACKUP_DIR/MANIFEST.txt" << EOF

━━━ Backup Size ━━━
$(du -sh "$BACKUP_DIR" | cut -f1) total

━━━ File Checksums ━━━
EOF
    
    # Generate checksums for all backup files
    find "$BACKUP_DIR" -type f -not -name "MANIFEST.txt" -exec sha256sum {} \; >> "$BACKUP_DIR/MANIFEST.txt"
    
    success "Backup manifest created"
}

#############################################
# Cleanup Old Backups
#############################################

cleanup_old_backups() {
    log "Cleaning up old backups based on retention policy..."
    
    # Clean daily backups older than retention period
    find "$BACKUP_ROOT" -maxdepth 1 -type d -name "daily-*" -mtime +$DAILY_RETENTION -exec rm -rf {} \; 2>/dev/null
    
    # Clean weekly backups
    find "$BACKUP_ROOT" -maxdepth 1 -type d -name "weekly-*" -mtime +$WEEKLY_RETENTION -exec rm -rf {} \; 2>/dev/null
    
    # Clean monthly backups
    find "$BACKUP_ROOT" -maxdepth 1 -type d -name "monthly-*" -mtime +$MONTHLY_RETENTION -exec rm -rf {} \; 2>/dev/null
    
    # Clean Proxmox snapshots older than 7 days (keep only recent)
    for service in "${!CONTAINERS[@]}"; do
        local ct_id=${CONTAINERS[$service]}
        
        # List snapshots older than 7 days and delete
        pct listsnapshot $ct_id 2>/dev/null | tail -n +2 | while read snap_name snap_time _; do
            # Convert snapshot time to epoch
            snap_epoch=$(date -d "$snap_time" +%s 2>/dev/null || echo 0)
            now_epoch=$(date +%s)
            age_days=$(( (now_epoch - snap_epoch) / 86400 ))
            
            if [ $age_days -gt 7 ]; then
                log "  Deleting old snapshot: $snap_name from CT$ct_id (${age_days} days old)"
                pct delsnapshot $ct_id $snap_name 2>/dev/null || true
            fi
        done
    done
    
    success "Old backups cleaned up"
}

#############################################
# Main Backup Flow
#############################################

main() {
    echo ""
    echo "=========================================="
    echo "  botmarket.ae Backup Script"
    echo "  Type: $BACKUP_TYPE"
    echo "=========================================="
    echo ""
    
    # Create backup directory
    create_backup_directory
    
    # Run all backup tasks
    backup_proxmox_snapshots
    backup_mysql_database
    backup_configurations
    backup_code_repository
    backup_deployed_bots
    backup_secrets
    
    # Create manifest
    create_backup_manifest
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Summary
    local backup_size=$(du -sh "$BACKUP_DIR" | cut -f1)
    
    echo ""
    echo "=========================================="
    echo "  Backup Complete"
    echo "=========================================="
    echo "Location: $BACKUP_DIR"
    echo "Size: $backup_size"
    echo "Type: $BACKUP_TYPE"
    echo "Time: $(date)"
    echo ""
    echo "Manifest: $BACKUP_DIR/MANIFEST.txt"
    echo "=========================================="
    echo ""
    
    success "Backup completed successfully!"
    
    # Save backup path for rollback script
    echo "$BACKUP_DIR" > /tmp/last-backup-dir.txt
}

# Run main
main
