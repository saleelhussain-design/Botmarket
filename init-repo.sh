#!/bin/bash
#
# botmarket.ae Repository Initialization Script
# This script creates the complete repository structure
# Usage: ./init-repo.sh
#

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo ""
echo "=========================================="
echo "  botmarket.ae Repository Initialization"
echo "=========================================="
echo ""

# Get repository root
REPO_ROOT="/opt/botmarket"
log "Repository will be created at: $REPO_ROOT"

# Create main directory structure
log "Creating directory structure..."

mkdir -p "$REPO_ROOT"/{.github/workflows,infrastructure/{proxmox,nginx,cloudflare},services/{pm-bot/{src,systemd,tests},bot-factory/{src,systemd,tests},marketplace/{src,public,nginx},bots/{templates,deployed}},scripts/{deploy,backup,maintenance},docs,tests/{unit,integration,e2e}}

success "Directory structure created"

# Copy deployment scripts
log "Installing deployment scripts..."

# Main scripts directory
SCRIPTS_DIR="$REPO_ROOT/scripts"

# Copy deploy scripts
cp /home/claude/deploy.sh "$SCRIPTS_DIR/deploy/deploy.sh"
cp /home/claude/rollback.sh "$SCRIPTS_DIR/deploy/rollback.sh"
cp /home/claude/health-check.sh "$SCRIPTS_DIR/deploy/health-check.sh"

# Copy backup scripts
cp /home/claude/backup-all.sh "$SCRIPTS_DIR/backup/backup-all.sh"

# Make scripts executable
chmod +x "$SCRIPTS_DIR/deploy/"*.sh
chmod +x "$SCRIPTS_DIR/backup/"*.sh

success "Deployment scripts installed"

# Copy documentation
log "Installing documentation..."

cp /home/claude/GIT_DEPLOYMENT_STRATEGY.md "$REPO_ROOT/docs/GIT_DEPLOYMENT_STRATEGY.md"
cp /home/claude/README.md "$REPO_ROOT/README.md"

success "Documentation installed"

# Copy configuration files
log "Installing configuration files..."

cp /home/claude/.gitignore "$REPO_ROOT/.gitignore"
cp /home/claude/VERSION "$REPO_ROOT/VERSION"

# Copy .env examples
cp /home/claude/pm-bot.env.example "$REPO_ROOT/services/pm-bot/.env.example"
cp /home/claude/bot-factory.env.example "$REPO_ROOT/services/bot-factory/.env.example"

success "Configuration files installed"

# Create placeholder files
log "Creating placeholder files..."

# requirements.txt for PM Bot
cat > "$REPO_ROOT/services/pm-bot/requirements.txt" << 'EOF'
flask==3.0.0
flask-cors==4.0.0
apscheduler==3.10.4
twilio==8.10.0
python-dotenv==1.0.0
requests==2.31.0
pymysql==1.1.0
cryptography==41.0.7
EOF

# requirements.txt for Bot Factory
cat > "$REPO_ROOT/services/bot-factory/requirements.txt" << 'EOF'
flask==3.0.0
flask-cors==4.0.0
paramiko==3.4.0
anthropic==0.8.0
python-dotenv==1.0.0
requests==2.31.0
pymysql==1.1.0
jinja2==3.1.2
EOF

# Create systemd service file for PM Bot
cat > "$REPO_ROOT/services/pm-bot/systemd/pm-bot.service" << 'EOF'
[Unit]
Description=botmarket.ae PM Bot
After=network.target mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/pm-bot
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/bin/python3 /opt/pm-bot/pm_server.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service file for Bot Factory
cat > "$REPO_ROOT/services/bot-factory/systemd/bot-factory.service" << 'EOF'
[Unit]
Description=botmarket.ae Bot Factory
After=network.target mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/bot-factory
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/bin/python3 /opt/bot-factory/server.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create CHANGELOG.md
cat > "$REPO_ROOT/CHANGELOG.md" << 'EOF'
# Changelog

All notable changes to botmarket.ae will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-05

### Added
- Initial release
- PM Bot with WhatsApp and email notifications
- Bot Factory with AI-powered bot generation
- Marketplace frontend
- Automated deployment scripts
- Rollback system
- Health monitoring
- Backup automation

### Infrastructure
- Proxmox LXC container setup
- Nginx reverse proxy
- MySQL database
- Ollama AI integration
- Cloudflare Tunnel support

## [Unreleased]

### Planned Features
- Bot marketplace with payment integration
- Advanced bot templates
- Multi-user support
- API documentation portal
- Enhanced monitoring dashboard
EOF

# Create LICENSE
cat > "$REPO_ROOT/LICENSE" << 'EOF'
MIT License

Copyright (c) 2026 botmarket.ae

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# Create CONTRIBUTING.md
cat > "$REPO_ROOT/CONTRIBUTING.md" << 'EOF'
# Contributing to botmarket.ae

Thank you for considering contributing to botmarket.ae!

## Development Workflow

1. Fork the repository
2. Create a feature branch from `develop`
3. Make your changes
4. Write/update tests
5. Ensure all tests pass
6. Submit a pull request

## Commit Message Guidelines

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

## Code Style

- Python: Follow PEP 8
- JavaScript: Use ESLint with Airbnb config
- Always include docstrings

## Testing

```bash
# Run all tests
pytest

# Run specific test file
pytest tests/test_pm_bot.py

# Run with coverage
pytest --cov
```

## Questions?

Create an issue or contact support@botmarket.ae
EOF

# Create GitHub Actions workflow
mkdir -p "$REPO_ROOT/.github/workflows"

cat > "$REPO_ROOT/.github/workflows/deploy-production.yml" << 'EOF'
name: Deploy to Production

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup SSH
        env:
          SSH_PRIVATE_KEY: ${{ secrets.PROXMOX_SSH_KEY }}
          PROXMOX_HOST: ${{ secrets.PROXMOX_HOST }}
        run: |
          mkdir -p ~/.ssh
          echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          ssh-keyscan -H $PROXMOX_HOST >> ~/.ssh/known_hosts
      
      - name: Deploy to Production
        env:
          PROXMOX_HOST: ${{ secrets.PROXMOX_HOST }}
        run: |
          ssh root@$PROXMOX_HOST \
            "cd /opt/botmarket && git pull && \
             ./scripts/deploy/deploy.sh production ${GITHUB_REF#refs/tags/}"
      
      - name: Health Check
        run: |
          sleep 30
          curl -f https://botmarket.ae/api/health || exit 1
      
      - name: Notify Success
        if: success()
        run: echo "Deployment successful!"
      
      - name: Rollback on Failure
        if: failure()
        env:
          PROXMOX_HOST: ${{ secrets.PROXMOX_HOST }}
        run: |
          ssh root@$PROXMOX_HOST \
            "/opt/botmarket/scripts/deploy/rollback.sh production"
EOF

success "Placeholder files created"

# Initialize git repository
log "Initializing git repository..."

cd "$REPO_ROOT"

if [ ! -d ".git" ]; then
    git init
    git config user.email "deploy@botmarket.ae"
    git config user.name "botmarket deployment"
    
    # Initial commit
    git add .
    git commit -m "chore: initial repository setup

- Complete directory structure
- Deployment automation scripts
- Rollback and health check systems
- Documentation and examples
- CI/CD workflows"
    
    success "Git repository initialized"
else
    warning "Git repository already exists"
fi

# Create summary report
echo ""
echo "=========================================="
echo "  Repository Initialization Complete!"
echo "=========================================="
echo ""
echo "Repository location: $REPO_ROOT"
echo ""
echo "📁 Directory Structure:"
echo "  ├── services/          # All service code"
echo "  ├── scripts/           # Deployment automation"
echo "  ├── infrastructure/    # Infrastructure as code"
echo "  ├── docs/              # Documentation"
echo "  └── tests/             # Test suites"
echo ""
echo "🚀 Next Steps:"
echo ""
echo "  1. Configure secrets:"
echo "     mkdir -p /root/botmarket-secrets"
echo "     cp $REPO_ROOT/services/pm-bot/.env.example /root/botmarket-secrets/pm-bot-production.env"
echo "     cp $REPO_ROOT/services/bot-factory/.env.example /root/botmarket-secrets/bot-factory-production.env"
echo "     nano /root/botmarket-secrets/pm-bot-production.env"
echo ""
echo "  2. Set up GitHub remote:"
echo "     cd $REPO_ROOT"
echo "     git remote add origin git@github.com:yourusername/botmarket-platform.git"
echo "     git push -u origin main"
echo ""
echo "  3. Run infrastructure setup:"
echo "     bash $REPO_ROOT/infrastructure/proxmox/lxc-setup.sh"
echo ""
echo "  4. Deploy to production:"
echo "     $REPO_ROOT/scripts/deploy/deploy.sh production v1.0.0"
echo ""
echo "  5. Verify deployment:"
echo "     $REPO_ROOT/scripts/deploy/health-check.sh production"
echo ""
echo "=========================================="
echo ""

success "Repository ready for use!"
