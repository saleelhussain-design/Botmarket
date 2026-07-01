# 📋 BotMarket.me Scrum Backlog

**Strategy:** Reverse-build the backend infrastructure to support the features currently showcased on the frontend.

---

## 🏃 Sprint 1: The Multi-Tenant Engine (Backend Foundation)
*Goal: Establish the ability to serve multiple clients with isolated data and configurations.*
**🎯 Expected Outcome:** A functional Backend API with database isolation, where we can securely create and manage multiple client accounts and their basic agent profiles.

### 🟢 Done
- [x] **Task 1.1: Monorepo Restructuring**
- [x] **Task 1.2: Database Schema Design**
- [x] **Task 1.4: Core API Gateway**

### 🟡 In Progress
- [ ] **Task 1.3: Authentication System**

### 🔴 Blocked
- [ ] *None*

---

## 📅 Sprint 2: The Persona & Template Engine
*Goal: Turn static profiles into dynamic, configurable AI agents.*
**🎯 Expected Outcome:** A reusable persona engine that can ingest JSON definitions and knowledge bases to spin up fully functional AI agents on demand.

### 🟢 Done
- [x] **Task 2.1: Persona JSON Schema**
- [x] **Task 2.2: Knowledge Ingestion (RAG Lite)**
- [x] **Task 2.3: Template Cloner**

### 🟡 In Progress
- [ ] *None*

### 🔴 Blocked
- [ ] *None*

---

## 📞 Sprint 3: The Integration Layer
*Goal: Enable real-world communication (Voice, Text, Calendar).*
**🎯 Expected Outcome:** The AI agents are no longer "trapped" in the backend; they can actively listen to WhatsApp messages, answer phone calls via Vapi, and manage user schedules.

### 🟢 Done
- [x] **Task 3.1: WhatsApp/Twilio Integration**
- [x] **Task 3.2: Voice Orchestration (Vapi/Retell)**
- [x] **Task 3.3: Calendar Sync (Google/Calendly)**

### 🟡 In Progress
- [ ] *None*

### 🔴 Blocked
- [ ] *None*

---

## 🏭 Sprint 4: The Bot Factory (Automation)
*Goal: Create the "Wizard" onboarding experience.*
**🎯 Expected Outcome:** A complete, automated customer journey from landing on the website to having a live, integrated AI agent running in minutes.

### 🟢 Ready for Development
- [ ] **Task 4.1: Onboarding Wizard API**
- [ ] **Task 4.2: Automated Container Deployment**
- [ ] **Task 4.3: Automated "Welcome" Sequence**

