# 🚀 Azure Deployment Guide for PolicyPilot

## Overview
This guide covers deploying PolicyPilot on Microsoft Azure with:
- **Frontend**: Azure Static Web Apps (React)
- **Backend**: Azure Container Apps (FastAPI)
- **Database**: Azure Database for PostgreSQL
- **Storage**: Azure Blob Storage for documents
- **AI**: Azure OpenAI (already configured)

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Azure Static  │    │  Azure Container│    │ Azure Database  │
│   Web Apps      │───▶│     Apps        │───▶│ for PostgreSQL  │
│   (React)       │    │   (FastAPI)     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Azure CDN     │    │  Azure Blob     │    │  Azure OpenAI   │
│   (Optional)    │    │   Storage       │    │   Service       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Prerequisites

1. **Azure Account**: Active Azure subscription
2. **Azure CLI**: Install from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
3. **Docker**: For container builds
4. **Git**: For repository management
5. **Node.js 18+**: For frontend builds

## 🗄️ Database Migration

Since your current app uses file-based storage, we need to migrate to a proper database.

### 1. Update Backend Dependencies

First, let's add database dependencies to your requirements.txt:
