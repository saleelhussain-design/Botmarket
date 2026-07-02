# 🏗️ BotMarket.me: Modern Monorepo Architecture

This document defines the current, active technical architecture for BotMarket.me. All legacy "Fragmented CT" plans are deprecated.

## 🌐 System Overview
The platform is built as a high-performance monorepo to ensure rapid development and seamless deployment.

### 1. Frontend (The Showroom)
*   **Host:** Dedicated Proxmox LXC/VM.
*   **Tech Stack:** Static HTML/JS (Current) $\rightarrow$ Next.js (Planned).
*   **Role:** Handles User Experience, The Onboarding Wizard, and the Interactive Demo.
*   **Connection:** Communicates via REST API to the Backend.

### 2. Backend (The Engine)
*   **Host:** Dedicated Proxmox LXC (Ubuntu 24.04, Node.js v20+).
*   **Tech Stack:** Express.js, TypeScript, Sequelize.
*   **Database:** SQLite (Multi-tenant isolation via `tenant_id`).
*   **Role:** 
    *   **Orchestration:** Manages Personas, Knowledge bases, and Integrations.
    *   **Bot Factory:** Spawns isolated Agent Worker processes for each deployed bot.
    *   **AI Services:** Handles Prompt Engineering and LLM integration.

### 3. Agent Workers (The Workforce)
*   **Execution:** Detached Node.js processes running in the Backend LXC (Simulated containerization).
*   **Isolation:** Each worker has its own log file and persona context.
*   **Integrations:** Vapi (Voice), WhatsApp (Text), Google Calendar (Scheduling).

---

## 🗺️ Data Flow
`User Browser` $\rightarrow$ `Frontend LXC (Port 5000)` $\rightarrow$ `Backend LXC (Port 3001)` $\rightarrow$ `SQLite DB` $\rightarrow$ `Agent Worker` $\rightarrow$ `External APIs (Vapi/Meta/Google)`

## 🚀 Deployment Strategy
*   **Version Control:** GitHub (`fresha` branch).
*   **CI/CD:** Manual pull $\rightarrow$ `npm run build` $\rightarrow$ `pm2 restart`.
*   **Scaling:** Scale by adding more Worker LXCs as the tenant base grows.
