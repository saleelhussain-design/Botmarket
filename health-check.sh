#!/bin/bash
#
# botmarket.ae Health Check Script
# Usage: ./health-check.sh [environment]
# Example: ./health-check.sh production
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
declare -A CONTAINERS=(
    ["nginx"]=200
    ["mysql"]=201
    ["ollama"]=202
    ["pm-bot"]=203
    ["uptime-kuma"]=204
    ["bot-factory"]=205
    ["marketplace"]=206
)

declare -A SERVICE_URLS=(
    ["pm-bot"]="http://192.168.1.203:5001/api/health"
    ["bot-factory"]="http://192.168.1.205:5000/api/health"
    ["marketplace"]="http://192.168.1.206:3000"
    ["ollama"]="http://192.168.1.202:11434/api/tags"
)

#############################################
# Helper Functions
#############################################

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

#############################################
# Health Check Functions
#############################################

check_container_status() {
    local service=$1
    local ct_id=${CONTAINERS[$service]}
    
    if pct status $ct_id 2>/dev/null | grep -q "running"; then
        success "$service (CT$ct_id): Container Running"
        return 0
    else
        error "$service (CT$ct_id): Container NOT Running"
        return 1
    fi
}

check_systemd_service() {
    local service=$1
    local ct_id=${CONTAINERS[$service]}
    
    if pct exec $ct_id -- systemctl is-active $service &>/dev/null; then
        success "$service: Service Active"
        return 0
    else
        error "$service: Service NOT Active"
        # Show recent logs
        echo "  Recent logs:"
        pct exec $ct_id -- journalctl -u $service -n 5 --no-pager | sed 's/^/    /'
        return 1
    fi
}

check_http_endpoint() {
    local service=$1
    local url=${SERVICE_URLS[$service]}
    
    if [ -z "$url" ]; then
        return 0  # No URL to check
    fi
    
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 400 ]; then
        success "$service: HTTP Endpoint Healthy (${http_code})"
        return 0
    else
        error "$service: HTTP Endpoint Failed (${http_code})"
        return 1
    fi
}

check_mysql() {
    local ct_id=${CONTAINERS[mysql]}
    
    if pct exec $ct_id -- mysql -u root -e "SELECT 1" &>/dev/null; then
        success "MySQL: Database Responding"
        
        # Check connections
        local connections=$(pct exec $ct_id -- mysql -u root -e "SHOW STATUS LIKE 'Threads_connected'" 2>/dev/null | tail -1 | awk '{print $2}')
        log "  Active connections: $connections"
        
        return 0
    else
        error "MySQL: Database NOT Responding"
        return 1
    fi
}

check_ollama() {
    local ct_id=${CONTAINERS[ollama]}
    
    if pct exec $ct_id -- ollama list &>/dev/null; then
        success "Ollama: AI Service Running"
        
        # List models
        log "  Available models:"
        pct exec $ct_id -- ollama list | tail -n +2 | sed 's/^/    /'
        
        return 0
    else
        error "Ollama: AI Service NOT Running"
        return 1
    fi
}

check_disk_space() {
    local service=$1
    local ct_id=${CONTAINERS[$service]}
    
    local disk_usage=$(pct exec $ct_id -- df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -lt 80 ]; then
        success "$service: Disk Space OK (${disk_usage}% used)"
        return 0
    elif [ "$disk_usage" -lt 90 ]; then
        warning "$service: Disk Space Warning (${disk_usage}% used)"
        return 1
    else
        error "$service: Disk Space Critical (${disk_usage}% used)"
        return 1
    fi
}

check_memory_usage() {
    local service=$1
    local ct_id=${CONTAINERS[$service]}
    
    local mem_usage=$(pct exec $ct_id -- free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    
    if [ "$mem_usage" -lt 80 ]; then
        success "$service: Memory OK (${mem_usage}% used)"
        return 0
    elif [ "$mem_usage" -lt 90 ]; then
        warning "$service: Memory Warning (${mem_usage}% used)"
        return 1
    else
        error "$service: Memory Critical (${mem_usage}% used)"
        return 1
    fi
}

check_external_urls() {
    local environment=$1
    
    if [ "$environment" != "production" ]; then
        return 0  # Skip for non-production
    fi
    
    log "Checking public URLs..."
    
    # Check main site
    if curl -sf -o /dev/null "https://botmarket.ae" --max-time 10; then
        success "Public: https://botmarket.ae - Reachable"
    else
        error "Public: https://botmarket.ae - NOT Reachable"
    fi
    
    # Check PM Bot
    if curl -sf -o /dev/null "https://pm.botmarket.ae" --max-time 10; then
        success "Public: https://pm.botmarket.ae - Reachable"
    else
        error "Public: https://pm.botmarket.ae - NOT Reachable"
    fi
    
    # Check API
    if curl -sf -o /dev/null "https://api.botmarket.ae/api/health" --max-time 10; then
        success "Public: https://api.botmarket.ae - Reachable"
    else
        error "Public: https://api.botmarket.ae - NOT Reachable"
    fi
}

#############################################
# Comprehensive Health Report
#############################################

generate_health_report() {
    local environment=$1
    local all_healthy=true
    
    echo ""
    echo "=========================================="
    echo "  botmarket.ae Health Check Report"
    echo "  Environment: ${environment:-production}"
    echo "  Time: $(date)"
    echo "=========================================="
    echo ""
    
    # Container Status
    echo "━━━ Container Status ━━━"
    for service in "${!CONTAINERS[@]}"; do
        check_container_status "$service" || all_healthy=false
    done
    echo ""
    
    # Systemd Services
    echo "━━━ Systemd Services ━━━"
    for service in pm-bot bot-factory; do
        check_systemd_service "$service" || all_healthy=false
    done
    echo ""
    
    # HTTP Endpoints
    echo "━━━ HTTP Endpoints ━━━"
    for service in "${!SERVICE_URLS[@]}"; do
        check_http_endpoint "$service" || all_healthy=false
    done
    echo ""
    
    # Database & AI
    echo "━━━ Core Services ━━━"
    check_mysql || all_healthy=false
    check_ollama || all_healthy=false
    echo ""
    
    # Resource Usage
    echo "━━━ Resource Usage ━━━"
    for service in pm-bot bot-factory marketplace mysql; do
        check_disk_space "$service" || true
        check_memory_usage "$service" || true
    done
    echo ""
    
    # External URLs (production only)
    if [ "$environment" == "production" ]; then
        echo "━━━ Public URLs ━━━"
        check_external_urls "$environment" || all_healthy=false
        echo ""
    fi
    
    # Version Info
    echo "━━━ Version Information ━━━"
    if [ -f "/opt/botmarket/VERSION" ]; then
        cat /opt/botmarket/VERSION | sed 's/^/  /'
    else
        warning "VERSION file not found"
    fi
    echo ""
    
    # Summary
    echo "=========================================="
    if $all_healthy; then
        success "Overall Status: ALL HEALTHY ✅"
    else
        error "Overall Status: ISSUES DETECTED ⚠️"
    fi
    echo "=========================================="
    echo ""
    
    return $([ "$all_healthy" = true ] && echo 0 || echo 1)
}

#############################################
# Monitoring Mode
#############################################

watch_mode() {
    local environment=$1
    
    while true; do
        clear
        generate_health_report "$environment"
        echo "Refreshing in 30 seconds... (Ctrl+C to stop)"
        sleep 30
    done
}

#############################################
# Main
#############################################

main() {
    local environment=${1:-production}
    local watch=${2:-false}
    
    if [ "$watch" == "watch" ] || [ "$watch" == "-w" ]; then
        watch_mode "$environment"
    else
        generate_health_report "$environment"
    fi
}

# Run
main "$@"
