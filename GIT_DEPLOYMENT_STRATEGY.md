# botmarket.ae Git Deployment Strategy
**Complete Version Control & Deployment Workflow**

Version: 1.0.0 | Last Updated: March 2026

---

## Table of Contents
1. [Overview](#overview)
2. [Repository Structure](#repository-structure)
3. [Branching Strategy](#branching-strategy)
4. [Versioning System](#versioning-system)
5. [Deployment Workflow](#deployment-workflow)
6. [Rollback Procedures](#rollback-procedures)
7. [Environment Management](#environment-management)
8. [CI/CD Pipeline](#cicd-pipeline)

---

## Overview

This strategy ensures:
- ✅ **Version Control**: Every change is tracked with semantic versioning
- ✅ **Safe Deployments**: Test → Staging → Production pipeline
- ✅ **Quick Rollbacks**: Instant rollback to any previous version
- ✅ **Multi-Container Sync**: Deploy to multiple LXC containers consistently
- ✅ **Zero Downtime**: Blue-green deployments for critical services
- ✅ **Audit Trail**: Complete history of who deployed what and when

---

## Repository Structure

```
botmarket-platform/
├── .github/
│   └── workflows/
│       ├── deploy-production.yml
│       ├── deploy-staging.yml
│       └── run-tests.yml
├── infrastructure/
│   ├── proxmox/
│   │   ├── lxc-setup.sh
│   │   └── container-configs/
│   ├── nginx/
│   │   └── proxy-configs/
│   └── cloudflare/
│       └── tunnel-config.yml
├── services/
│   ├── pm-bot/
│   │   ├── src/
│   │   │   ├── pm_server.py
│   │   │   └── dashboard.html
│   │   ├── .env.example
│   │   ├── requirements.txt
│   │   ├── Dockerfile
│   │   └── systemd/
│   │       └── pm-bot.service
│   ├── bot-factory/
│   │   ├── src/
│   │   │   ├── server.py
│   │   │   └── ui/
│   │   ├── .env.example
│   │   ├── requirements.txt
│   │   └── systemd/
│   │       └── bot-factory.service
│   ├── marketplace/
│   │   ├── src/
│   │   ├── public/
│   │   ├── package.json
│   │   └── nginx/
│   │       └── site.conf
│   └── bots/
│       └── templates/
├── scripts/
│   ├── deploy/
│   │   ├── deploy.sh
│   │   ├── deploy-service.sh
│   │   ├── rollback.sh
│   │   └── health-check.sh
│   ├── backup/
│   │   ├── backup-all.sh
│   │   └── restore.sh
│   └── maintenance/
│       ├── update-all.sh
│       └── restart-services.sh
├── docs/
│   ├── DEPLOYMENT.md
│   ├── ROLLBACK.md
│   ├── TROUBLESHOOTING.md
│   └── API.md
├── tests/
│   ├── integration/
│   ├── unit/
│   └── e2e/
├── .gitignore
├── .env.example
├── VERSION
└── README.md
```

---

## Branching Strategy

### Branch Types

```
main (production)
  ↑
  staging
    ↑
    develop
      ↑
      feature/bot-factory-ui
      feature/pm-bot-whatsapp
      fix/nginx-ssl-issue
      hotfix/critical-security-patch
```

### Branch Rules

| Branch | Purpose | Deploy To | Protected |
|--------|---------|-----------|-----------|
| `main` | Production code | Production LXC containers | ✅ Yes |
| `staging` | Pre-production testing | Staging LXC containers | ✅ Yes |
| `develop` | Integration branch | Development environment | ⚠️ Semi |
| `feature/*` | New features | Local only | ❌ No |
| `fix/*` | Bug fixes | Local only | ❌ No |
| `hotfix/*` | Critical production fixes | Direct to main after review | ✅ Yes |

### Workflow

```bash
# 1. Create feature branch
git checkout develop
git pull origin develop
git checkout -b feature/new-bot-template

# 2. Make changes and commit
git add .
git commit -m "feat(bot-factory): add custom bot template support"

# 3. Push and create PR
git push origin feature/new-bot-template
# Create PR: feature/new-bot-template → develop

# 4. After PR approval, merge to develop
git checkout develop
git merge feature/new-bot-template
git push origin develop

# 5. When ready for staging
git checkout staging
git merge develop
git push origin staging
# Auto-deploys to staging environment

# 6. After staging tests pass
git checkout main
git merge staging
git tag -a v1.2.0 -m "Release v1.2.0: New bot templates"
git push origin main --tags
# Auto-deploys to production
```

---

## Versioning System

### Semantic Versioning (MAJOR.MINOR.PATCH)

```
v1.2.3
│ │ │
│ │ └─ PATCH: Bug fixes, security patches (backwards compatible)
│ └─── MINOR: New features (backwards compatible)
└───── MAJOR: Breaking changes (not backwards compatible)
```

### Examples

- `v1.0.0` → Initial production release
- `v1.1.0` → Added WhatsApp integration to PM Bot
- `v1.1.1` → Fixed SSL certificate renewal bug
- `v2.0.0` → Redesigned Bot Factory API (breaking changes)

### Tagging Releases

```bash
# Create annotated tag
git tag -a v1.2.0 -m "Release v1.2.0

New Features:
- Bot Factory: Custom template support
- PM Bot: WhatsApp notifications
- Marketplace: Stripe payment integration

Bug Fixes:
- Fixed Nginx proxy timeout issue
- Resolved MySQL connection pool leak

Breaking Changes:
- None
"

# Push tag
git push origin v1.2.0

# List all tags
git tag -l

# Show tag details
git show v1.2.0
```

---

## Deployment Workflow

### Automated Deployment Pipeline

```
Developer Push
    ↓
GitHub Actions Triggered
    ↓
Run Tests (pytest, eslint)
    ↓
Tests Pass? ──No──→ Send Alert ──→ Stop
    ↓ Yes
Build Artifacts
    ↓
Deploy to Target Environment
    ↓
Run Health Checks
    ↓
Health OK? ──No──→ Auto-Rollback ──→ Send Alert
    ↓ Yes
Update VERSION file
    ↓
Send Success Notification
    ↓
Complete ✅
```

### Manual Deployment

```bash
# Deploy specific service to production
./scripts/deploy/deploy-service.sh pm-bot production v1.2.0

# Deploy all services
./scripts/deploy/deploy.sh production v1.2.0

# Deploy with specific commit
./scripts/deploy/deploy.sh staging abc123f
```

### Deployment Checklist

Before every production deployment:

- [ ] All tests pass in staging
- [ ] Database migrations tested
- [ ] Backup taken (automated by script)
- [ ] Proxmox snapshots created
- [ ] Health checks configured
- [ ] Rollback plan confirmed
- [ ] Stakeholders notified
- [ ] Maintenance window scheduled (if needed)

---

## Rollback Procedures

### Quick Rollback (< 5 minutes)

```bash
# Rollback to previous version
./scripts/deploy/rollback.sh production

# Rollback to specific version
./scripts/deploy/rollback.sh production v1.1.5

# Rollback specific service only
./scripts/deploy/rollback.sh production v1.1.5 pm-bot
```

### Emergency Rollback

```bash
# Immediate rollback via Proxmox snapshot
pct rollback 203 pre-deploy-20260305

# Restart service
pct exec 203 -- systemctl restart pm-bot

# Verify health
curl -f http://192.168.1.203:5001/api/health || echo "FAILED"
```

### Rollback Decision Tree

```
Service Failing?
    ↓ Yes
Quick Rollback (<5 min)?
    ↓ Yes
Use automated rollback script
    ↓
Verify health checks
    ↓
Document incident
    ↓
Post-mortem analysis
```

---

## Environment Management

### Environment Files

Each environment has its own configuration:

```bash
# Production
services/pm-bot/.env.production

# Staging
services/pm-bot/.env.staging

# Development
services/pm-bot/.env.development
```

### .env.example Template

```bash
# services/pm-bot/.env.example
# Copy this to .env and fill in your values

# Environment
ENVIRONMENT=production  # production, staging, development

# Database
DB_HOST=192.168.1.201
DB_PORT=3306
DB_NAME=botmarket
DB_USER=botmarket_user
DB_PASSWORD=CHANGE_ME_STRONG_PASSWORD

# Twilio (WhatsApp)
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
WHATSAPP_FROM=whatsapp:+14155238886
WHATSAPP_TO=whatsapp:+971501234567

# Email (Gmail)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=notifications@botmarket.ae
SMTP_PASSWORD=your_app_password_here

# API Keys
ANTHROPIC_API_KEY=sk-ant-xxxxx
OPENAI_API_KEY=sk-xxxxx

# Security
JWT_SECRET=CHANGE_ME_RANDOM_64_CHAR_STRING
API_KEY=CHANGE_ME_RANDOM_32_CHAR_STRING

# Monitoring
SENTRY_DSN=https://xxx@sentry.io/xxx
UPTIME_KUMA_URL=http://192.168.1.204:3001
```

### Secrets Management

**Never commit real .env files to git!**

```bash
# .gitignore
.env
.env.local
.env.production
.env.staging
*.key
*.pem
secrets/
```

**For deployment:**

```bash
# Store secrets in Proxmox host
mkdir -p /root/botmarket-secrets/
chmod 700 /root/botmarket-secrets/

# Create production secrets
cat > /root/botmarket-secrets/pm-bot.env << 'EOF'
TWILIO_AUTH_TOKEN=actual_secret_token_here
DB_PASSWORD=actual_db_password_here
EOF

chmod 600 /root/botmarket-secrets/*.env

# Deploy script copies these to containers securely
```

---

## CI/CD Pipeline

### GitHub Actions Workflows

#### 1. Run Tests (on every push)

```yaml
# .github/workflows/run-tests.yml
name: Run Tests

on:
  push:
    branches: [ develop, staging, main ]
  pull_request:
    branches: [ develop, staging, main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          pip install -r services/pm-bot/requirements.txt
          pip install pytest pytest-cov
      
      - name: Run tests
        run: |
          pytest tests/ --cov --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

#### 2. Deploy to Staging (on push to staging)

```yaml
# .github/workflows/deploy-staging.yml
name: Deploy to Staging

on:
  push:
    branches: [ staging ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Staging
        env:
          SSH_PRIVATE_KEY: ${{ secrets.PROXMOX_SSH_KEY }}
          PROXMOX_HOST: ${{ secrets.PROXMOX_HOST }}
        run: |
          # Setup SSH
          mkdir -p ~/.ssh
          echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          
          # Deploy
          ssh -o StrictHostKeyChecking=no root@$PROXMOX_HOST \
            'bash -s' < scripts/deploy/deploy.sh staging
      
      - name: Run Health Checks
        run: |
          sleep 30
          curl -f https://staging.botmarket.ae/api/health || exit 1
      
      - name: Notify Slack
        if: always()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Staging deployment: ${{ job.status }}"
            }
```

#### 3. Deploy to Production (on tag push)

```yaml
# .github/workflows/deploy-production.yml
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
      
      - name: Take Backups
        env:
          SSH_PRIVATE_KEY: ${{ secrets.PROXMOX_SSH_KEY }}
          PROXMOX_HOST: ${{ secrets.PROXMOX_HOST }}
        run: |
          ssh root@$PROXMOX_HOST 'bash /opt/botmarket/scripts/backup/backup-all.sh'
      
      - name: Deploy to Production
        run: |
          ssh root@$PROXMOX_HOST \
            "bash /opt/botmarket/scripts/deploy/deploy.sh production ${GITHUB_REF#refs/tags/}"
      
      - name: Run Health Checks
        run: |
          sleep 60
          curl -f https://botmarket.ae/api/health || exit 1
          curl -f https://pm.botmarket.ae/api/health || exit 1
          curl -f https://api.botmarket.ae/api/health || exit 1
      
      - name: Create GitHub Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          draft: false
          prerelease: false
```

---

## Quick Reference Commands

### Daily Operations

```bash
# Check current version in production
cat /opt/botmarket/VERSION

# Pull latest changes
cd /opt/botmarket
git fetch origin
git checkout main
git pull origin main

# Deploy latest to production
./scripts/deploy/deploy.sh production

# Check service status
./scripts/maintenance/check-status.sh

# View logs
pct exec 203 -- journalctl -u pm-bot -f
```

### Emergency Commands

```bash
# Emergency rollback
./scripts/deploy/rollback.sh production

# Restart all services
./scripts/maintenance/restart-services.sh

# Check health of all services
./scripts/deploy/health-check.sh

# View recent deployments
git log --oneline --graph --decorate
```

---

## Success Metrics

Track these metrics to measure deployment success:

| Metric | Target | Current |
|--------|--------|---------|
| Deployment frequency | 2-3 per week | - |
| Deployment success rate | > 95% | - |
| Mean time to recovery (MTTR) | < 15 min | - |
| Rollback rate | < 10% | - |
| Test coverage | > 80% | - |
| Failed deployment rate | < 5% | - |

---

## Next Steps

1. ✅ Initialize git repo with this structure
2. ✅ Create deployment scripts
3. ✅ Set up GitHub Actions
4. ✅ Configure secrets management
5. ✅ Test deployment to staging
6. ✅ Document rollback procedures
7. ✅ Train team on workflow
8. ✅ First production deployment

---

**Last Updated:** March 2026  
**Maintained By:** botmarket.ae DevOps Team  
**Questions?** Check `/docs/TROUBLESHOOTING.md` or create an issue
