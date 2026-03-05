# botmarket.ae Platform Repository

**Complete infrastructure and deployment automation for botmarket.ae**

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](./VERSION)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
[![Deployment](https://img.shields.io/badge/deployment-automated-success.svg)](./scripts/deploy/)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Deployment](#deployment)
- [Rollback](#rollback)
- [Monitoring](#monitoring)
- [Development](#development)
- [Contributing](#contributing)

---

## 🎯 Overview

botmarket.ae is a platform for creating, deploying, and managing automation bots. This repository contains:

- **Infrastructure as Code**: Proxmox LXC container definitions
- **Service Code**: PM Bot, Bot Factory, Marketplace
- **Deployment Automation**: Scripts for zero-downtime deployments
- **Monitoring**: Health checks and uptime monitoring
- **CI/CD**: GitHub Actions workflows

### Key Features

✅ **Automated Deployments** - One command to deploy everything  
✅ **Version Control** - Semantic versioning with git tags  
✅ **Quick Rollbacks** - Rollback to any version in < 5 minutes  
✅ **Health Monitoring** - Automated health checks for all services  
✅ **Backup System** - Automated daily backups with 7-day retention  
✅ **Multi-Environment** - Development, Staging, Production  

---

## 🏗️ Architecture

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Proxmox Host Server                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ CT 200   │  │ CT 201   │  │ CT 202   │  │ CT 203   │   │
│  │ Nginx    │  │ MySQL    │  │ Ollama   │  │ PM Bot   │   │
│  │ Proxy    │  │ Database │  │ AI       │  │ Backend  │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │             │             │             │          │
│  ┌────┴─────┐  ┌────┴─────┐  ┌────┴─────┐                 │
│  │ CT 205   │  │ CT 206   │  │ CT 210+  │                 │
│  │ Bot      │  │ Market   │  │ Bot      │                 │
│  │ Factory  │  │ place    │  │ Instances│                 │
│  └──────────┘  └──────────┘  └──────────┘                 │
└─────────────────────────────────────────────────────────────┘
                          │
                   ┌──────┴───────┐
                   │  Cloudflare  │
                   │  Tunnel      │
                   └──────┬───────┘
                          │
                   ┌──────┴───────┐
                   │   Internet   │
                   └──────────────┘
```

### Service URLs

| Service | Internal URL | Public URL | Container |
|---------|--------------|------------|-----------|
| Nginx Proxy Manager | http://192.168.1.200:81 | - | CT 200 |
| MySQL | 192.168.1.201:3306 | - | CT 201 |
| Ollama AI | http://192.168.1.202:11434 | https://ai.botmarket.ae | CT 202 |
| PM Bot | http://192.168.1.203:5001 | https://pm.botmarket.ae | CT 203 |
| Bot Factory | http://192.168.1.205:5000 | https://api.botmarket.ae | CT 205 |
| Marketplace | http://192.168.1.206:3000 | https://botmarket.ae | CT 206 |

---

## 🚀 Quick Start

### Prerequisites

- Proxmox VE 8.0+ server
- Domain name (botmarket.ae)
- Basic Linux knowledge

### Initial Setup

1. **Clone Repository**
   ```bash
   cd /opt
   git clone https://github.com/yourusername/botmarket-platform.git botmarket
   cd botmarket
   ```

2. **Run Infrastructure Setup**
   ```bash
   chmod +x infrastructure/proxmox/lxc-setup.sh
   bash infrastructure/proxmox/lxc-setup.sh
   ```

3. **Configure Secrets**
   ```bash
   mkdir -p /root/botmarket-secrets
   
   # Copy example files and edit with real values
   cp services/pm-bot/.env.example /root/botmarket-secrets/pm-bot-production.env
   cp services/bot-factory/.env.example /root/botmarket-secrets/bot-factory-production.env
   
   # Edit files
   nano /root/botmarket-secrets/pm-bot-production.env
   nano /root/botmarket-secrets/bot-factory-production.env
   ```

4. **First Deployment**
   ```bash
   ./scripts/deploy/deploy.sh production v1.0.0
   ```

5. **Verify Health**
   ```bash
   ./scripts/deploy/health-check.sh production
   ```

---

## 📦 Deployment

### Deploy to Production

```bash
# Deploy latest version
./scripts/deploy/deploy.sh production v1.2.0

# Deploy specific commit
./scripts/deploy/deploy.sh production abc123f

# Deploy single service
./scripts/deploy/deploy-service.sh pm-bot production v1.2.0
```

### Deploy to Staging

```bash
./scripts/deploy/deploy.sh staging main
```

### Deployment Process

The deployment script automatically:
1. ✅ Validates environment and version
2. ✅ Creates Proxmox snapshots (backups)
3. ✅ Backs up MySQL database
4. ✅ Checks out specified version
5. ✅ Deploys services in dependency order
6. ✅ Runs health checks
7. ✅ Updates VERSION file
8. ✅ Sends notifications (if configured)

---

## 🔄 Rollback

### Quick Rollback

```bash
# Rollback to previous version
./scripts/deploy/rollback.sh production

# Rollback to specific version
./scripts/deploy/rollback.sh production v1.1.5

# Rollback single service
./scripts/deploy/rollback.sh production v1.1.5 pm-bot
```

### Rollback Methods

1. **Git Rollback** (Redeploy from previous version)
   - Slower but ensures code consistency
   - Best for code-related issues

2. **Snapshot Rollback** (Proxmox container restore)
   - Fastest (<2 minutes)
   - Best for configuration or data issues

3. **Combined** (Snapshot + Git)
   - Most thorough
   - Recommended for critical production issues

---

## 📊 Monitoring

### Health Checks

```bash
# Run once
./scripts/deploy/health-check.sh production

# Watch mode (refresh every 30s)
./scripts/deploy/health-check.sh production watch
```

### Service Logs

```bash
# PM Bot logs
pct exec 203 -- journalctl -u pm-bot -f

# Bot Factory logs
pct exec 205 -- journalctl -u bot-factory -f

# Nginx logs
pct exec 200 -- tail -f /var/log/nginx/error.log
```

### Uptime Monitoring

Access Uptime Kuma dashboard:
```
http://192.168.1.204:3001
```

---

## 💻 Development

### Branching Strategy

```
main (production) ← staging ← develop ← feature/new-feature
```

### Creating a New Feature

```bash
# 1. Create feature branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/whatsapp-integration

# 2. Make changes
# ... edit files ...

# 3. Commit with conventional commits
git add .
git commit -m "feat(pm-bot): add WhatsApp notification support"

# 4. Push and create PR
git push origin feature/whatsapp-integration
# Create PR: feature/whatsapp-integration → develop
```

### Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```bash
git commit -m "feat(bot-factory): add custom bot template support"
git commit -m "fix(pm-bot): resolve WhatsApp connection timeout"
git commit -m "docs: update deployment guide"
```

### Testing Locally

```bash
# Run unit tests
pytest services/pm-bot/tests/

# Run integration tests
pytest tests/integration/

# Lint code
pylint services/pm-bot/src/
eslint services/marketplace/src/
```

---

## 🔐 Security

### Secrets Management

**Never commit secrets to git!**

Secrets are stored in `/root/botmarket-secrets/` on Proxmox host:

```
/root/botmarket-secrets/
├── pm-bot-production.env
├── pm-bot-staging.env
├── bot-factory-production.env
└── bot-factory-staging.env
```

### SSH Key Setup

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "botmarket-deploy"

# Add to GitHub deploy keys
cat ~/.ssh/id_ed25519.pub
```

### Firewall Rules

```bash
# Apply firewall rules to all containers
for ct_id in 200 201 202 203 205 206; do
    pct exec $ct_id -- bash -c "
        apt install ufw -y
        ufw default deny incoming
        ufw allow from 192.168.1.0/24
        ufw --force enable
    "
done

# Allow public access only on Nginx (CT 200)
pct exec 200 -- bash -c "
    ufw allow 80/tcp
    ufw allow 443/tcp
"
```

---

## 📁 Repository Structure

```
botmarket-platform/
├── .github/
│   └── workflows/           # GitHub Actions CI/CD
├── infrastructure/
│   ├── proxmox/            # LXC container setup
│   ├── nginx/              # Nginx proxy configs
│   └── cloudflare/         # Cloudflare tunnel configs
├── services/
│   ├── pm-bot/             # PM Bot service
│   ├── bot-factory/        # Bot Factory service
│   ├── marketplace/        # Marketplace frontend
│   └── bots/               # Bot templates
├── scripts/
│   ├── deploy/             # Deployment scripts
│   ├── backup/             # Backup scripts
│   └── maintenance/        # Maintenance scripts
├── docs/                   # Documentation
├── tests/                  # Test suites
├── .gitignore
├── VERSION
└── README.md
```

---

## 🔧 Maintenance

### Daily Backups

Backups run automatically via cron:

```bash
# Add to crontab
0 2 * * * /opt/botmarket/scripts/backup/backup-all.sh daily
```

### Manual Backup

```bash
./scripts/backup/backup-all.sh manual
```

### Update All Services

```bash
./scripts/maintenance/update-all.sh
```

### Restart All Services

```bash
./scripts/maintenance/restart-services.sh
```

---

## 📖 Documentation

- [Deployment Guide](./docs/DEPLOYMENT.md) - Complete deployment instructions
- [Rollback Guide](./docs/ROLLBACK.md) - Emergency rollback procedures
- [Troubleshooting](./docs/TROUBLESHOOTING.md) - Common issues and fixes
- [API Documentation](./docs/API.md) - API endpoints and usage
- [Git Strategy](./GIT_DEPLOYMENT_STRATEGY.md) - Git workflow and versioning

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'feat: add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📝 Changelog

See [CHANGELOG.md](./CHANGELOG.md) for version history.

---

## 📞 Support

- **Documentation**: Check `/docs` directory
- **Issues**: Create GitHub issue
- **Email**: support@botmarket.ae

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](./LICENSE) file.

---

## 🙏 Acknowledgments

- Proxmox VE - Virtualization platform
- Cloudflare - CDN and tunnel services
- Anthropic Claude - AI assistance
- Ollama - Local AI models

---

**Last Updated:** March 2026  
**Current Version:** 1.0.0  
**Status:** Production Ready ✅
