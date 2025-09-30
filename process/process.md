# Novahost Production Deployment Process

## Complete Infrastructure to Application Deployment Journey

This document provides an in-depth walkthrough of deploying the Novahost application from initial infrastructure setup to a fully operational production system with GitOps CI/CD pipeline.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Infrastructure Foundation](#2-infrastructure-foundation)
3. [Docker Containerization](#3-docker-containerization)
4. [Kubernetes Orchestration](#4-kubernetes-orchestration)
5. [Helm Package Management](#5-helm-package-management)
6. [GitOps Implementation](#6-gitops-implementation)
7. [CI/CD Pipeline](#7-cicd-pipeline)
8. [DNS and SSL Configuration](#8-dns-and-ssl-configuration)
9. [Troubleshooting Journey](#9-troubleshooting-journey)
10. [Lessons Learned](#10-lessons-learned)

---

## 1. Project Overview

### 1.1 Application Architecture

**Novahost** is a multi-service cloud hosting platform consisting of:

- **Web Frontend** (Next.js 14) - User dashboard and project management
- **API Server** (Express.js) - Backend REST API
- **Build Server** (Node.js) - Automated project builds
- **Reverse Proxy** (Express.js) - Dynamic subdomain routing

#### 🔍 **Concept Deep Dive: Microservices Architecture**

**What is Microservices Architecture?**
Microservices is an architectural pattern that structures an application as a collection of loosely coupled, independently deployable services. Each service:

- Runs in its own process
- Communicates via well-defined APIs (usually HTTP/REST)
- Can be developed, deployed, and scaled independently
- Owns its data and business logic

**Why Microservices for Novahost?**

1. **Independent Scaling**: Web frontend may need more instances during high traffic, while build server needs more resources during build peaks
2. **Technology Diversity**: Each service can use the most suitable technology stack
3. **Fault Isolation**: If one service fails, others continue to operate
4. **Team Independence**: Different teams can own different services
5. **Deployment Flexibility**: Deploy updates to individual services without affecting others

**Service Communication Patterns:**

- **Synchronous**: Web → API (HTTP requests for user data)
- **Asynchronous**: API → Build Server (queue-based build requests)
- **Event-driven**: Services publish/subscribe to events (user signup triggers multiple actions)

**Trade-offs:**

- **Complexity**: More moving parts, network calls, distributed system challenges
- **Data Consistency**: Eventual consistency vs ACID transactions
- **Monitoring**: Need sophisticated observability across services
- **Development Overhead**: More repositories, CI/CD pipelines, deployment complexity

### 1.2 Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Next.js, React, TypeScript | User interface |
| **Backend** | Express.js, Node.js | API services |
| **Database** | timescaleDb + TimescaleDB | Data persistence |
| **Cache** | Redis | Session and data caching |
| **Authentication** | NextAuth.js | User management |
| **Storage** | Cloudflare R2 | Object storage |
| **Build Tool** | Bun | Package management |
| **Container** | Docker | Application packaging |
| **Orchestration** | Kubernetes | Container orchestration |
| **Package Manager** | Helm | Kubernetes application management |
| **GitOps** | ArgoCD | Continuous deployment |
| **CI/CD** | GitHub Actions | Continuous integration |
| **Ingress** | NGINX | Load balancing and routing |
| **SSL** | cert-manager + Let's Encrypt | Certificate management |
| **Cloud** | DigitalOcean | Infrastructure hosting |

#### 🔍 **Concept Deep Dive: Technology Stack Choices**

**Frontend Layer - Next.js 14**

- **What it is**: React-based framework with server-side rendering (SSR) and static site generation (SSG)
- **Why chosen**:
  - **Performance**: Built-in optimizations (image optimization, automatic code splitting)
  - **SEO**: Server-side rendering improves search engine indexing
  - **Developer Experience**: Hot reloading, TypeScript support, API routes
  - **Deployment**: Easy static export and edge deployment
- **Key Features Used**:
  - App Router (file-based routing)
  - Server Components (reduces client bundle size)
  - Middleware for authentication
  - API routes for backend proxy

**Database Layer - timescaleDb + TimescaleDB**

- **timescaleDb**: Open-source relational database known for reliability and ACID compliance
- **TimescaleDB**: Extension that adds time-series database capabilities
- **Why this combination**:
  - **Relational Data**: User accounts, projects, relationships
  - **Time-series Data**: Build logs, metrics, performance data
  - **ACID Compliance**: Ensures data consistency for critical operations
  - **Scalability**: TimescaleDB handles time-series data efficiently
- **Key Features**:
  - JSON support for flexible schemas
  - Full-text search capabilities
  - Advanced indexing strategies
  - Automatic time-based partitioning (TimescaleDB)

**Cache Layer - Redis**

- **What it is**: In-memory data structure store used as cache and session store
- **Why chosen**:
  - **Performance**: Sub-millisecond response times
  - **Persistence**: Optional data durability
  - **Data Structures**: Lists, sets, hashes for complex caching
  - **Scalability**: Clustering and replication support
- **Use Cases in Novahost**:
  - Session storage (NextAuth.js sessions)
  - API response caching
  - Build queue management
  - Rate limiting counters

**Container Layer - Docker**

- **What it is**: Containerization platform that packages applications with dependencies
- **Core Concepts**:
  - **Images**: Read-only templates for creating containers
  - **Containers**: Running instances of images
  - **Layers**: Images built in layers for efficiency
  - **Registry**: Storage for images (Docker Hub)
- **Benefits for Novahost**:
  - **Consistency**: Same environment from dev to production
  - **Isolation**: Each service runs in isolated environment
  - **Scalability**: Easy to create multiple instances
  - **Portability**: Run anywhere Docker is supported

**Orchestration Layer - Kubernetes**

- **What it is**: Container orchestration platform for automating deployment, scaling, and management
- **Core Concepts**:
  - **Pods**: Smallest deployable units (usually one container)
  - **Deployments**: Manage pod replicas and rolling updates
  - **Services**: Network abstraction for pod communication
  - **Ingress**: HTTP/HTTPS routing to services
  - **ConfigMaps/Secrets**: Configuration and sensitive data management
- **Why Kubernetes for Novahost**:
  - **Auto-scaling**: Automatically adjust resources based on demand
  - **Self-healing**: Restart failed containers, replace unhealthy pods
  - **Load balancing**: Distribute traffic across pod replicas
  - **Rolling updates**: Deploy new versions without downtime
  - **Resource management**: CPU/memory limits and requests

**Package Management - Helm**

- **What it is**: Package manager for Kubernetes (like npm for Node.js)
- **Core Concepts**:
  - **Charts**: Pre-configured packages of Kubernetes resources
  - **Templates**: Kubernetes manifests with placeholders
  - **Values**: Configuration parameters for customization
  - **Releases**: Deployed instances of charts
- **Benefits**:
  - **Templating**: Reusable configurations across environments
  - **Dependency Management**: Manage chart dependencies
  - **Versioning**: Track and rollback deployments
  - **Configuration Management**: Environment-specific values

**GitOps - ArgoCD**

- **What is GitOps**: Operational framework using Git as single source of truth for infrastructure and applications
- **ArgoCD Role**: Kubernetes-native GitOps operator
- **Core Principles**:
  - **Declarative**: Desired state defined in Git
  - **Versioned**: All changes tracked in version control
  - **Automated**: Continuous synchronization from Git to cluster
  - **Observable**: Clear view of desired vs actual state
- **Benefits for Novahost**:
  - **Audit Trail**: All changes tracked in Git history
  - **Rollback**: Easy revert to previous working state
  - **Multi-environment**: Promote changes through environments
  - **Security**: Git-based access control and approval workflows

**CI/CD - GitHub Actions**

- **What it is**: Event-driven automation platform integrated with GitHub
- **Core Concepts**:
  - **Workflows**: Automated processes triggered by events
  - **Jobs**: Groups of steps that run on same runner
  - **Steps**: Individual tasks (commands, actions)
  - **Runners**: Servers that execute workflows
- **Workflow for Novahost**:
  1. **Trigger**: Push to main branch
  2. **Build**: Compile and test application
  3. **Package**: Create Docker images
  4. **Publish**: Push images to registry
  5. **Deploy**: Update GitOps repository
  6. **Sync**: ArgoCD deploys to cluster

**SSL Management - cert-manager + Let's Encrypt**

- **cert-manager**: Kubernetes operator for automatic certificate management
- **Let's Encrypt**: Free, automated certificate authority
- **Process**:
  1. **Request**: cert-manager requests certificate from Let's Encrypt
  2. **Challenge**: Let's Encrypt verifies domain ownership (HTTP-01 challenge)
  3. **Issue**: Certificate issued and stored as Kubernetes Secret
  4. **Renewal**: Automatic renewal before expiration
- **Benefits**:
  - **Free**: No cost for SSL certificates
  - **Automated**: No manual certificate management
  - **Integrated**: Works seamlessly with Kubernetes Ingress

### 1.3 Production Requirements

- **High Availability**: Zero-downtime deployments
- **Scalability**: Auto-scaling capabilities
- **Security**: SSL encryption, secret management
- **Automation**: GitOps workflow with CI/CD
- **Monitoring**: Health checks and logging
- **Performance**: Optimized container images

---

## 2. Infrastructure Foundation

### 2.1 Cloud Platform Selection

**Choice**: DigitalOcean Kubernetes (DOKS)

**Reasoning**:

- Managed Kubernetes service
- Cost-effective for small to medium applications
- Built-in LoadBalancer support
- Simple DNS management
- Good documentation and support

### 2.2 Kubernetes Cluster Setup

```bash
# Cluster Configuration
Name: novahost-cluster
Region: NYC1
Version: Latest Kubernetes (1.28+)
Node Pool: 2x basic-2vcpu-4gb-intel
Auto-scaling: Enabled
LoadBalancer IP: 174.138.121.213
```

**Commands Executed**:

```bash
# Connect to cluster
doctl kubernetes cluster kubeconfig save novahost-cluster

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### 2.3 Core Infrastructure Components

#### 2.3.1 NGINX Ingress Controller

**Purpose**: External traffic routing and SSL termination

**Installation**:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

**Configuration File**: `shared/ingress-nginx/values.yml`

```yaml
controller:
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/do-loadbalancer-name: "novahost-lb"
      service.beta.kubernetes.io/do-loadbalancer-protocol: "http"
      service.beta.kubernetes.io/do-loadbalancer-algorithm: "round_robin"
      service.beta.kubernetes.io/do-loadbalancer-health-check-protocol: "http"
      service.beta.kubernetes.io/do-loadbalancer-health-check-path: "/healthz"
```

**Verification**:

```bash
kubectl get svc -n ingress-nginx
kubectl get pods -n ingress-nginx
```

#### 2.3.2 cert-manager for SSL Automation

**Purpose**: Automatic SSL certificate provisioning and renewal

**Installation**:

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

**ClusterIssuer Configuration**: `shared/cert-manager/cluster-issuer.yml`

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: aliabbaschadhar2@gmail.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

**Commands**:

```bash
kubectl apply -f shared/cert-manager/cluster-issuer.yml
kubectl get clusterissuer
```

#### 2.3.3 timescaleDb Database with TimescaleDB

**Purpose**: Primary application database with time-series capabilities

**Persistent Volume**: `shared/timescaleDb/pvc.yaml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: shared
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

**Database Deployment**: `shared/timescaleDb/pg.yml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: shared
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: timescale/timescaledb:latest-pg15
        env:
        - name: POSTGRES_DB
          value: "novahost_db"
        - name: POSTGRES_USER
          value: "novahost_user"
        - name: POSTGRES_PASSWORD
          value: "novahost_secure_password"
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/timescaleDb/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: shared
spec:
  selector:
    app: postgres
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
```

**Commands**:

```bash
kubectl create namespace shared
kubectl apply -f shared/timescaleDb/pvc.yaml
kubectl apply -f shared/timescaleDb/pg.yml
kubectl get pods -n shared
```

#### 2.3.4 Redis Cache

**Purpose**: Session storage and application caching

**Configuration**: `shared/redis/redis.yml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: shared
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        command:
          - redis-server
          - --appendonly
          - "yes"
        volumeMounts:
        - name: redis-data
          mountPath: /data
      volumes:
      - name: redis-data
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: shared
spec:
  selector:
    app: redis
  ports:
    - protocol: TCP
      port: 6379
      targetPort: 6379
```

**Commands**:

```bash
kubectl apply -f shared/redis/redis.yml
kubectl get pods,svc -n shared
```

#### 2.3.5 ArgoCD GitOps Controller

**Purpose**: Continuous deployment and application lifecycle management

**Installation**:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

**Access Setup**:

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward for access
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Configuration**: `platform/argocd/values.yml`

```yaml
global:
  domain: argocd.novahost.ybro.tech

argo-cd:
  server:
    extraArgs:
      - --insecure
    config:
      application.instanceLabelKey: argocd.argoproj.io/instance
    rbacConfig:
      policy.default: role:readonly
      policy.csv: |
        p, role:admin, applications, *, */*, allow
        p, role:admin, clusters, *, *, allow
        p, role:admin, repositories, *, *, allow
        g, argocd-admins, role:admin
```

---

## 3. Docker Containerization

### 3.1 Containerization Strategy

**Approach**: Multi-stage builds for optimization and security

**Registry**: Docker Hub (`docker.io/aliabbaschadhar003`)

**Base Images**:

- **Build**: `oven/bun:alpine` (smaller footprint)
- **Runtime**: `oven/bun:alpine` (consistency)
- **Security**: Non-root user execution

#### 🔍 **Concept Deep Dive: Docker Multi-Stage Builds**

**What are Multi-Stage Builds?**
Multi-stage builds allow you to use multiple FROM statements in a single Dockerfile. Each FROM begins a new build stage, and you can selectively copy artifacts from one stage to another.

**Why Multi-Stage Builds?**

1. **Smaller Final Images**: Only production dependencies in final image
2. **Security**: Build tools and source code not in production image
3. **Caching**: Intermediate stages can be cached independently
4. **Flexibility**: Different base images for different stages

**Typical Stages in Our Build**:

1. **Dependencies Stage**: Install all dependencies (including dev dependencies)
2. **Build Stage**: Compile/transpile application code
3. **Production Stage**: Only runtime dependencies and compiled code

**Example Pattern**:

```dockerfile
# Stage 1: Dependencies
FROM node:alpine AS deps
COPY package*.json ./
RUN npm install

# Stage 2: Build
FROM node:alpine AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Stage 3: Production
FROM node:alpine AS runner
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/index.js"]
```

**Benefits for Novahost**:

- **Image Size**: Final images ~100MB vs ~500MB with single stage
- **Security**: No source code or build tools in production
- **Build Speed**: Cached dependency layers speed up rebuilds
- **Consistency**: Same base image ensures consistent runtime environment

#### 🔍 **Concept Deep Dive: Container Security**

**Non-Root User Execution**

- **Problem**: Running containers as root poses security risks
- **Solution**: Create and use non-root user in containers
- **Implementation**:

  ```dockerfile
  RUN addgroup --system --gid 1001 nodejs
  RUN adduser --system --uid 1001 nextjs
  USER nextjs
  ```

**Security Context in Kubernetes**:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  runAsGroup: 1001
  fsGroup: 1001
```

**Why This Matters**:

- **Principle of Least Privilege**: Containers run with minimal permissions
- **Attack Surface Reduction**: Compromised container has limited system access
- **Compliance**: Meets security standards and audit requirements

### 3.2 Critical Challenge: Build-time Database Connections

**Problem Encountered**:
Next.js was attempting to connect to the database during the Docker build process, causing builds to fail when database credentials were not available.

**Error Message**:

```
Error: Cannot find module '@prisma/client'
    at Function.Module._resolveFilename
    at Module.require
```

**Root Cause Analysis**:
The Prisma client was being instantiated during the Next.js build phase, when it should only be available at runtime.

**Solution Implemented**:

Modified `packages/prismaDB/index.ts`:

```typescript
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

// Don't instantiate Prisma client during Next.js build process
const isPrismaClientSafe = () => {
  // Skip if using placeholder credentials
  if (process.env.DATABASE_URL?.includes('placeholder')) {
    return false;
  }
  
  // Skip during Next.js production build
  if (process.env.NEXT_PHASE === 'phase-production-build') {
    return false;
  }
  
  return true;
};

export const prisma = globalForPrisma.prisma || 
  (isPrismaClientSafe() ? new PrismaClient() : null as any);

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
```

### 3.3 Dockerfile Configurations

#### 3.3.1 Web Application (Next.js)

**File**: `docker/Dockerfile.web`

```dockerfile
FROM oven/bun:alpine AS baseimage

# Stage 1: Install ALL dependencies (including devDependencies)
FROM baseimage AS deps
WORKDIR /home/app
COPY package.json bun.lock turbo.json ./
COPY apps/web/package.json ./apps/web/
COPY apps/api-server/package.json ./apps/api-server/
COPY apps/build-server/package.json ./apps/build-server/
COPY apps/reverse-proxy/package.json ./apps/reverse-proxy/
COPY packages/eslint-config/package.json ./packages/eslint-config/
COPY packages/prismaDB/package.json ./packages/prismaDB/
COPY packages/typescript-config/package.json ./packages/typescript-config/

# Install all dependencies including devDependencies for build
RUN bun install --frozen-lockfile

# Stage 2: Build the application
FROM baseimage AS builder
WORKDIR /home/app

# Install OpenSSL for Prisma
RUN apk add --no-cache openssl

# Copy dependencies from deps stage
COPY --from=deps /home/app/node_modules ./node_modules
COPY --from=deps /home/app/package.json ./package.json
COPY --from=deps /home/app/bun.lock ./bun.lock

# Copy source code
COPY . .

# Set build-time environment variables with placeholder values
ENV DATABASE_URL="timescaleDb://placeholder:placeholder@placeholder:5432/placeholder"
ENV NEXTAUTH_SECRET="placeholder-secret-for-build"
ENV NEXTAUTH_URL="http://placeholder.com"
ENV NEXT_PHASE="phase-production-build"

# Generate Prisma client (this is safe because we use placeholder URL)
RUN cd packages/prismaDB && bunx prisma generate

# Build the application
RUN bun run build --filter=web

# Stage 3: Production runtime
FROM baseimage AS runner
WORKDIR /home/app

# Install OpenSSL for Prisma in production
RUN apk add --no-cache openssl

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built application
COPY --from=builder --chown=nextjs:nodejs /home/app/apps/web/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /home/app/apps/web/.next/static ./apps/web/.next/static
COPY --from=builder --chown=nextjs:nodejs /home/app/apps/web/public ./apps/web/public

# Copy Prisma generated client
COPY --from=builder --chown=nextjs:nodejs /home/app/packages/prismaDB/generated ./packages/prismaDB/generated

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "apps/web/server.js"]
```

**Key Features**:

- **Multi-stage build**: Separate dependency installation, build, and runtime stages
- **Security**: Non-root user execution
- **Optimization**: Only production files in final image
- **Prisma handling**: Safe client generation with placeholder credentials
- **Performance**: Bun runtime for faster execution

#### 3.3.2 API Server

**File**: `docker/Dockerfile.api-server`

```dockerfile
FROM oven/bun:alpine AS baseimage

# Install dependencies stage
FROM baseimage AS deps
WORKDIR /home/app
COPY package.json bun.lock turbo.json ./
COPY apps/api-server/package.json ./apps/api-server/
COPY packages/eslint-config/package.json ./packages/eslint-config/
COPY packages/prismaDB/package.json ./packages/prismaDB/
COPY packages/typescript-config/package.json ./packages/typescript-config/

RUN bun install --frozen-lockfile

# Build stage
FROM baseimage AS builder
WORKDIR /home/app
RUN apk add --no-cache openssl

COPY --from=deps /home/app/node_modules ./node_modules
COPY . .

# Build-time environment variables
ENV DATABASE_URL="timescaleDb://placeholder:placeholder@placeholder:5432/placeholder"

RUN cd packages/prismaDB && bunx prisma generate
RUN bun run build --filter=api-server

# Production stage
FROM baseimage AS runner
WORKDIR /home/app
RUN apk add --no-cache openssl

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 apiuser

COPY --from=builder --chown=apiuser:nodejs /home/app/apps/api-server/dist ./apps/api-server/dist
COPY --from=builder --chown=apiuser:nodejs /home/app/packages/prismaDB/generated ./packages/prismaDB/generated
COPY --from=builder --chown=apiuser:nodejs /home/app/node_modules ./node_modules

USER apiuser

EXPOSE 9000

CMD ["bun", "run", "apps/api-server/dist/index.js"]
```

#### 3.3.3 Build Server

**File**: `docker/Dockerfile.build-server`

```dockerfile
FROM oven/bun:alpine AS baseimage

FROM baseimage AS deps
WORKDIR /home/app
COPY package.json bun.lock turbo.json ./
COPY apps/build-server/package.json ./apps/build-server/
COPY packages/eslint-config/package.json ./packages/eslint-config/
COPY packages/typescript-config/package.json ./packages/typescript-config/

RUN bun install --frozen-lockfile

FROM baseimage AS builder
WORKDIR /home/app
COPY --from=deps /home/app/node_modules ./node_modules
COPY . .

RUN bun run build --filter=build-server

FROM baseimage AS runner
WORKDIR /home/app

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 builduser

COPY --from=builder --chown=builduser:nodejs /home/app/apps/build-server/dist ./apps/build-server/dist
COPY --from=builder --chown=builduser:nodejs /home/app/node_modules ./node_modules

USER builduser

EXPOSE 8000

CMD ["bun", "run", "apps/build-server/dist/index.js"]
```

#### 3.3.4 Reverse Proxy

**File**: `docker/Dockerfile.reverse-proxy`

```dockerfile
FROM oven/bun:alpine AS baseimage

FROM baseimage AS deps
WORKDIR /home/app
COPY package.json bun.lock turbo.json ./
COPY apps/reverse-proxy/package.json ./apps/reverse-proxy/
COPY packages/eslint-config/package.json ./packages/eslint-config/
COPY packages/typescript-config/package.json ./packages/typescript-config/

RUN bun install --frozen-lockfile

FROM baseimage AS builder
WORKDIR /home/app
COPY --from=deps /home/app/node_modules ./node_modules
COPY . .

RUN bun run build --filter=reverse-proxy

FROM baseimage AS runner
WORKDIR /home/app

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 proxyuser

COPY --from=builder --chown=proxyuser:nodejs /home/app/apps/reverse-proxy/dist ./apps/reverse-proxy/dist
COPY --from=builder --chown=proxyuser:nodejs /home/app/node_modules ./node_modules

USER proxyuser

EXPOSE 8080

CMD ["bun", "run", "apps/reverse-proxy/dist/index.js"]
```

### 3.4 Image Building and Registry

**Commands for Local Testing**:

```bash
# Build and test locally
docker build -f docker/Dockerfile.web -t novahost-web:test .
docker run -p 3000:3000 novahost-web:test

# Push to registry
docker tag novahost-web:test aliabbaschadhar003/novahost-web:latest
docker push aliabbaschadhar003/novahost-web:latest
```

**Registry Organization**:

```
aliabbaschadhar003/novahost-web:latest
aliabbaschadhar003/novahost-api-server:latest
aliabbaschadhar003/novahost-build-server:latest
aliabbaschadhar003/novahost-reverse-proxy:latest
```

---

## 4. Kubernetes Orchestration

### 4.1 Namespace Strategy

**Namespace Organization**:

- `shared` - Infrastructure services (timescaleDb, Redis)
- `novahost` - Application services
- `argocd` - GitOps controller
- `ingress-nginx` - Ingress controller
- `cert-manager` - Certificate management

#### 🔍 **Concept Deep Dive: Kubernetes Namespaces**

**What are Namespaces?**
Namespaces provide a mechanism for isolating groups of resources within a single cluster. They're like virtual clusters within a physical cluster.

**Why Use Namespaces?**

1. **Resource Isolation**: Separate environments (dev, staging, prod)
2. **Access Control**: RBAC policies can be applied per namespace
3. **Resource Quotas**: Limit CPU, memory, storage per namespace
4. **Name Scoping**: Same resource names can exist in different namespaces
5. **Network Policies**: Control traffic between namespaces

**Namespace Strategy Explained**:

- **`shared`**: Infrastructure components used by multiple applications
  - timescaleDb database
  - Redis cache
  - Shared configuration
  - **Benefit**: Single instance serves multiple apps, easier maintenance
  
- **`novahost`**: Application-specific resources
  - Web, API, Build, Reverse Proxy services
  - Application secrets
  - **Benefit**: Isolated from other applications, clear ownership
  
- **`argocd`**: GitOps controller
  - ArgoCD components
  - Application definitions
  - **Benefit**: Separate management plane, security isolation
  
- **`ingress-nginx`**: Traffic management
  - NGINX Ingress Controller
  - LoadBalancer service
  - **Benefit**: Centralized ingress for all applications
  
- **`cert-manager`**: Certificate automation
  - cert-manager components
  - Certificate issuers
  - **Benefit**: Centralized SSL management

**Namespace Commands**:

```bash
# Create namespace
kubectl create namespace novahost

# List all namespaces
kubectl get namespaces

# Set default namespace
kubectl config set-context --current --namespace=novahost

# Deploy to specific namespace
kubectl apply -f deployment.yaml -n novahost

# Cross-namespace service access
timescaleDb.shared.svc.cluster.local:5432
```

### 4.2 Secret Management

**Challenge**: Secure handling of sensitive configuration

**Solution**: Kubernetes Secrets with templates for easy management

#### 🔍 **Concept Deep Dive: Kubernetes Secrets**

**What are Kubernetes Secrets?**
Secrets are objects that store sensitive data such as passwords, tokens, and keys. They're similar to ConfigMaps but specifically designed for confidential data.

**Types of Secrets**:

1. **Opaque**: Arbitrary user-defined data (most common)
2. **Service Account Token**: Automatically created for service accounts
3. **Docker Registry**: Credentials for private registries
4. **TLS**: Certificate and private key pairs

**Secret vs ConfigMap**:

| Aspect | Secret | ConfigMap |
|--------|--------|-----------|
| **Purpose** | Sensitive data | Non-sensitive configuration |
| **Storage** | Base64 encoded | Plain text |
| **Security** | Can be encrypted at rest | Not encrypted |
| **Memory** | Stored in tmpfs (memory) | Stored on disk |
| **Size Limit** | 1MB | 1MB |

**Why Base64 Encoding?**

- **Not Encryption**: Base64 is encoding, not encryption (easily reversible)
- **Kubernetes Requirement**: Secrets must be base64 encoded
- **Binary Data Support**: Allows storing binary data in YAML/JSON
- **Security Note**: Base64 is NOT secure - use encryption at rest

**Secret Creation Methods**:

```bash
# From literal values
kubectl create secret generic app-secret \
  --from-literal=api-key=abc123 \
  --from-literal=db-password=secret

# From files
kubectl create secret generic app-secret \
  --from-file=ssh-privatekey=/path/to/key \
  --from-file=ssh-publickey=/path/to/key.pub

# From YAML (our approach)
kubectl apply -f secret.yaml
```

**Best Practices for Secrets**:

1. **Separate Secrets by Purpose**: Database, OAuth, Storage, etc.
2. **Least Privilege**: Only mount secrets that pods actually need
3. **Namespace Isolation**: Secrets are namespace-scoped
4. **Rotation**: Regularly update and rotate secrets
5. **External Secret Management**: Consider tools like Vault, AWS Secrets Manager
6. **No Secrets in Git**: Never commit secrets to version control

**Secret Mounting Options**:

```yaml
# As environment variables
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: database-secret
      key: password

# As files (volume mounts)
volumeMounts:
- name: secret-volume
  mountPath: /etc/secrets
volumes:
- name: secret-volume
  secret:
    secretName: app-secret
```

**Environment Variables vs File Mounts**:

| Method | Use Case | Security | Visibility |
|--------|----------|----------|------------|
| **Environment Variables** | Simple config | Process list visible | `env` command shows values |
| **File Mounts** | Complex data | File system permissions | Hidden in `/etc/secrets` |

**Our Secret Strategy for Novahost**:

1. **database-secret**: Database connection string
2. **redis-secret**: Redis connection details
3. **oauth-secret**: Third-party OAuth credentials
4. **r2-secret**: Cloudflare R2 storage credentials
5. **app-secret**: Application-specific secrets (NextAuth, etc.)
6. **build-secret**: CI/CD credentials

**Why Separate Secrets?**

- **Principle of Least Privilege**: Services only access needed secrets
- **Rotation Independence**: Update database credentials without touching OAuth
- **Team Boundaries**: Different teams manage different secret types
- **Compliance**: Easier to audit and control access

#### 4.2.1 Secret Templates

**Database Secret**: `apps/novahost/secret-templates/database-secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-secret
  namespace: novahost
type: Opaque
data:
  DATABASE_URL: <base64-encoded-database-url>
```

**Redis Secret**: `apps/novahost/secret-templates/redis-secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: redis-secret
  namespace: novahost
type: Opaque
data:
  REDIS_URL: <base64-encoded-redis-url>
```

**OAuth Secret**: `apps/novahost/secret-templates/oauth-secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: oauth-secret
  namespace: novahost
type: Opaque
data:
  GOOGLE_CLIENT_ID: <base64-encoded-google-client-id>
  GOOGLE_CLIENT_SECRET: <base64-encoded-google-client-secret>
  GITHUB_CLIENT_ID: <base64-encoded-github-client-id>
  GITHUB_CLIENT_SECRET: <base64-encoded-github-client-secret>
```

**R2 Storage Secret**: `apps/novahost/secret-templates/r2-secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: r2-secret
  namespace: novahost
type: Opaque
data:
  R2_ACCESS_KEY_ID: <base64-encoded-r2-access-key>
  R2_SECRET_ACCESS_KEY: <base64-encoded-r2-secret-key>
  R2_BUCKET_NAME: <base64-encoded-bucket-name>
  R2_ENDPOINT: <base64-encoded-endpoint>
```

**Application Secret**: `apps/novahost/secret-templates/app-secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
  namespace: novahost
type: Opaque
data:
  NEXTAUTH_SECRET: <base64-encoded-nextauth-secret>
  NEXTAUTH_URL: <base64-encoded-nextauth-url>
  RESEND_API_KEY: <base64-encoded-resend-api-key>
```

**Build Secret**: `apps/novahost/secret-templates/build-secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: build-secret
  namespace: novahost
type: Opaque
data:
  DOCKERHUB_USERNAME: <base64-encoded-dockerhub-username>
  DOCKERHUB_PAT: <base64-encoded-dockerhub-pat>
```

#### 4.2.2 Secret Application Script

**File**: `apps/novahost/secret-templates/apply-secrets.sh`

```bash
#!/bin/bash

echo "Creating novahost namespace..."
kubectl create namespace novahost --dry-run=client -o yaml | kubectl apply -f -

echo "Applying secrets..."
kubectl apply -f database-secret.yaml
kubectl apply -f redis-secret.yaml  
kubectl apply -f oauth-secret.yaml
kubectl apply -f r2-secret.yaml
kubectl apply -f app-secret.yaml
kubectl apply -f build-secret.yaml

echo "Verifying secrets..."
kubectl get secrets -n novahost

echo "All secrets applied successfully!"
```

**Commands**:

```bash
chmod +x apps/novahost/secret-templates/apply-secrets.sh
./apps/novahost/secret-templates/apply-secrets.sh
```

### 4.3 Kubernetes Manifests

**Base Kubernetes resources were later replaced by Helm charts for better management**

---

## 5. Helm Package Management

### 5.1 Helm Chart Structure

**Decision**: Use Helm for templated Kubernetes manifests and easier management

**Chart Location**: `apps/novahost/`

```
apps/novahost/
├── Chart.yaml                 # Chart metadata
├── values.yaml               # Default configuration values
├── templates/                # Kubernetes manifest templates
│   ├── _helpers.tpl         # Template helpers
│   ├── deployment.yaml      # Application deployments
│   ├── service.yaml         # Services
│   ├── ingress.yaml         # Ingress configuration
│   ├── serviceaccount.yaml  # Service account
│   └── NOTES.txt           # Post-install notes
└── secret-templates/        # Secret management
```

#### 🔍 **Concept Deep Dive: Helm Package Manager**

**What is Helm?**
Helm is the package manager for Kubernetes, often described as "the apt/yum/homebrew for Kubernetes." It simplifies deploying and managing applications on Kubernetes.

**Core Concepts**:

**1. Charts**

- **Definition**: Pre-configured package of Kubernetes resources
- **Structure**: Collection of templates and configuration files
- **Analogy**: Like a Docker image but for Kubernetes applications
- **Benefits**: Reusable, versioned, shareable packages

**2. Templates**

- **Definition**: Kubernetes YAML files with placeholders (Go templates)
- **Purpose**: Generate different configurations for different environments
- **Syntax**: `{{ .Values.image.tag }}` - placeholder replaced with actual values
- **Power**: Conditional logic, loops, functions for complex templating

**3. Values**

- **Definition**: Configuration parameters that customize templates
- **Hierarchy**: Default values → environment values → command-line overrides
- **Format**: YAML structure defining all configurable aspects
- **Flexibility**: Same chart deployed to dev/staging/prod with different values

**4. Releases**

- **Definition**: Running instance of a chart in Kubernetes cluster
- **Tracking**: Helm tracks release history for rollbacks
- **Naming**: Each release has unique name and namespace
- **Lifecycle**: Install, upgrade, rollback, uninstall

**Why Helm for Novahost?**

**Before Helm (Raw Kubernetes YAML)**:

```bash
# Deploy to development
kubectl apply -f k8s/dev/
# Deploy to staging
kubectl apply -f k8s/staging/
# Deploy to production
kubectl apply -f k8s/prod/
```

**Problems with Raw YAML**:

- **Duplication**: Similar configs repeated across environments
- **Maintenance**: Updates require changing multiple files
- **Error-prone**: Manual environment-specific configurations
- **No Rollback**: Difficult to revert to previous working state

**With Helm**:

```bash
# Deploy to different environments with same chart
helm install novahost-dev . -f values-dev.yaml
helm install novahost-staging . -f values-staging.yaml
helm install novahost-prod . -f values-prod.yaml

# Easy updates
helm upgrade novahost-prod . --set image.tag=v2.0.0

# Simple rollbacks
helm rollback novahost-prod 1
```

**Helm Template Engine**:

**Basic Templating**:

```yaml
# Template
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"

# Values
image:
  repository: nginx
  tag: "1.21"

# Result
image: "nginx:1.21"
```

**Conditional Templating**:

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "app.fullname" . }}
{{- end }}
```

**Loops**:

```yaml
{{- range .Values.environments }}
- name: {{ .name }}
  value: {{ .value }}
{{- end }}
```

**Helper Functions (`_helpers.tpl`)**:

```yaml
{{- define "novahost.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

# Usage in templates
name: {{ include "novahost.fullname" . }}-web
```

**Helm vs Other Tools**:

| Tool | Approach | Strengths | Weaknesses |
|------|----------|-----------|------------|
| **Helm** | Templating | Simple, familiar YAML | Limited logic, complex templates |
| **Kustomize** | Patching | Native to kubectl | Steep learning curve |
| **Jsonnet** | Programming | Powerful logic | New language to learn |
| **Terraform** | Infrastructure as Code | Multi-cloud | Not Kubernetes-native |

**Chart Development Workflow**:

1. **Create Chart**: `helm create novahost`
2. **Develop Templates**: Write Kubernetes YAML with placeholders
3. **Define Values**: Create comprehensive values.yaml
4. **Test Locally**: `helm template . --debug`
5. **Validate**: `helm lint .`
6. **Install**: `helm install novahost .`
7. **Iterate**: Update templates and upgrade release

**Chart Versioning**:

```yaml
# Chart.yaml
apiVersion: v2
name: novahost
version: 0.1.0      # Chart version
appVersion: "1.0.0" # Application version
```

- **Chart Version**: Version of the Helm chart itself
- **App Version**: Version of the application being deployed
- **Semantic Versioning**: Major.Minor.Patch (1.2.3)

**Helm Release Management**:

```bash
# List releases
helm list

# Get release info
helm status novahost

# View release history
helm history novahost

# Rollback to previous version
helm rollback novahost 1

# Uninstall release
helm uninstall novahost
```

**Values Hierarchy (precedence order)**:

1. **Command line** (`--set`, `--set-string`, `--set-file`)
2. **Values files** (`-f values-prod.yaml`)
3. **Chart's values.yaml** (default values)

**Example Override**:

```bash
# Override image tag via command line
helm upgrade novahost . --set image.tag=v2.0.0

# Override via values file
helm upgrade novahost . -f values-prod.yaml

# Multiple values files (last wins)
helm upgrade novahost . -f values.yaml -f values-prod.yaml
```

**Chart Dependencies**:

```yaml
# Chart.yaml
dependencies:
- name: timescaleDb
  version: 11.1.3
  repository: https://charts.bitnami.com/bitnami
  condition: timescaleDb.enabled
```

**Helm Security Considerations**:

- **RBAC**: Helm operations require appropriate Kubernetes permissions
- **Tiller Removal**: Helm 3 removed server-side component (Tiller)
- **Values Validation**: Validate input values to prevent misconfigurations
- **Secret Management**: Secrets still need external management (not in values.yaml)

### 5.2 Chart Configuration

#### 5.2.1 Chart Metadata

**File**: `apps/novahost/Chart.yaml`

```yaml
apiVersion: v2
name: novahost
description: A Helm chart for Novahost application
type: application
version: 0.1.0
appVersion: "1.0.0"
```

#### 5.2.2 Values Configuration

**File**: `apps/novahost/values.yaml`

```yaml
# Global configuration
global:
  domain: "novahost.ybro.tech"

# Web application (Next.js)
web:
  enabled: true
  replicaCount: 1
  image:
    repository: aliabbaschadhar003/novahost-web
    tag: "latest"
    pullPolicy: Always
  service:
    type: ClusterIP
    port: 3000
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi

# API server
api:
  enabled: true
  replicaCount: 1
  image:
    repository: aliabbaschadhar003/novahost-api-server
    tag: "latest"
    pullPolicy: Always
  service:
    type: ClusterIP
    port: 9000
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi

# Build server
buildServer:
  enabled: true
  replicaCount: 1
  image:
    repository: aliabbaschadhar003/novahost-build-server
    tag: "latest"
    pullPolicy: Always
  service:
    type: ClusterIP
    port: 8000
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 500m
      memory: 512Mi

# Reverse proxy
reverseProxy:
  enabled: true
  replicaCount: 1
  image:
    repository: aliabbaschadhar003/novahost-reverse-proxy
    tag: "latest"
    pullPolicy: Always
  service:
    type: ClusterIP
    port: 8080
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi

# Ingress configuration
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
  hosts:
    - host: novahost.ybro.tech
      paths:
        - path: /api
          pathType: Prefix
          backend:
            service:
              name: api
              port: 9000
        - path: /
          pathType: Prefix
          backend:
            service:
              name: web
              port: 3000
  tls:
    - secretName: novahost-tls
      hosts:
        - novahost.ybro.tech

# Wildcard ingress for user projects
wildcardIngress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: "*.novahost.ybro.tech"
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: reverse-proxy
              port: 8080
  tls:
    - secretName: novahost-wildcard-tls
      hosts:
        - "*.novahost.ybro.tech"

# Service account
serviceAccount:
  create: true
  name: ""

# Auto-scaling
autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

### 5.3 Template Configurations

#### 5.3.1 Deployment Template

**File**: `apps/novahost/templates/deployment.yaml`

```yaml
{{- if .Values.web.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "novahost.fullname" . }}-web
  labels:
    {{- include "novahost.labels" . | nindent 4 }}
    app.kubernetes.io/component: web
spec:
  replicas: {{ .Values.web.replicaCount }}
  selector:
    matchLabels:
      {{- include "novahost.selectorLabels" . | nindent 6 }}
      app.kubernetes.io/component: web
  template:
    metadata:
      labels:
        {{- include "novahost.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: web
    spec:
      serviceAccountName: {{ include "novahost.serviceAccountName" . }}
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        runAsGroup: 1001
        fsGroup: 1001
      containers:
        - name: web
          image: "{{ .Values.web.image.repository }}:{{ .Values.web.image.tag }}"
          imagePullPolicy: {{ .Values.web.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 3000
              protocol: TCP
          env:
            - name: PORT
              value: "3000"
            - name: NODE_ENV
              value: "production"
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: database-secret
                  key: DATABASE_URL
            - name: REDIS_URL
              valueFrom:
                secretKeyRef:
                  name: redis-secret
                  key: REDIS_URL
            - name: NEXTAUTH_SECRET
              valueFrom:
                secretKeyRef:
                  name: app-secret
                  key: NEXTAUTH_SECRET
            - name: NEXTAUTH_URL
              valueFrom:
                secretKeyRef:
                  name: app-secret
                  key: NEXTAUTH_URL
            - name: GOOGLE_CLIENT_ID
              valueFrom:
                secretKeyRef:
                  name: oauth-secret
                  key: GOOGLE_CLIENT_ID
            - name: GOOGLE_CLIENT_SECRET
              valueFrom:
                secretKeyRef:
                  name: oauth-secret
                  key: GOOGLE_CLIENT_SECRET
            - name: GITHUB_CLIENT_ID
              valueFrom:
                secretKeyRef:
                  name: oauth-secret
                  key: GITHUB_CLIENT_ID
            - name: GITHUB_CLIENT_SECRET
              valueFrom:
                secretKeyRef:
                  name: oauth-secret
                  key: GITHUB_CLIENT_SECRET
            - name: R2_ACCESS_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: r2-secret
                  key: R2_ACCESS_KEY_ID
            - name: R2_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: r2-secret
                  key: R2_SECRET_ACCESS_KEY
            - name: R2_BUCKET_NAME
              valueFrom:
                secretKeyRef:
                  name: r2-secret
                  key: R2_BUCKET_NAME
            - name: R2_ENDPOINT
              valueFrom:
                secretKeyRef:
                  name: r2-secret
                  key: R2_ENDPOINT
            - name: RESEND_API_KEY
              valueFrom:
                secretKeyRef:
                  name: app-secret
                  key: RESEND_API_KEY
          livenessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
            timeoutSeconds: 3
            failureThreshold: 3
          resources:
            {{- toYaml .Values.web.resources | nindent 12 }}
---
{{- end }}

{{- if .Values.api.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "novahost.fullname" . }}-api
  labels:
    {{- include "novahost.labels" . | nindent 4 }}
    app.kubernetes.io/component: api
spec:
  replicas: {{ .Values.api.replicaCount }}
  selector:
    matchLabels:
      {{- include "novahost.selectorLabels" . | nindent 6 }}
      app.kubernetes.io/component: api
  template:
    metadata:
      labels:
        {{- include "novahost.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: api
    spec:
      serviceAccountName: {{ include "novahost.serviceAccountName" . }}
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        runAsGroup: 1001
        fsGroup: 1001
      containers:
        - name: api
          image: "{{ .Values.api.image.repository }}:{{ .Values.api.image.tag }}"
          imagePullPolicy: {{ .Values.api.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 9000
              protocol: TCP
          env:
            - name: PORT
              value: "9000"
            - name: NODE_ENV
              value: "production"
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: database-secret
                  key: DATABASE_URL
            - name: REDIS_URL
              valueFrom:
                secretKeyRef:
                  name: redis-secret
                  key: REDIS_URL
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
            timeoutSeconds: 3
            failureThreshold: 3
          resources:
            {{- toYaml .Values.api.resources | nindent 12 }}
---
{{- end }}

# Similar patterns for buildServer and reverseProxy...
```

#### 5.3.2 Service Template

**File**: `apps/novahost/templates/service.yaml`

```yaml
{{- if .Values.web.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "novahost.fullname" . }}-web
  labels:
    {{- include "novahost.labels" . | nindent 4 }}
    app.kubernetes.io/component: web
spec:
  type: {{ .Values.web.service.type }}
  ports:
    - port: {{ .Values.web.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "novahost.selectorLabels" . | nindent 4 }}
    app.kubernetes.io/component: web
---
{{- end }}

{{- if .Values.api.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "novahost.fullname" . }}-api
  labels:
    {{- include "novahost.labels" . | nindent 4 }}
    app.kubernetes.io/component: api
spec:
  type: {{ .Values.api.service.type }}
  ports:
    - port: {{ .Values.api.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "novahost.selectorLabels" . | nindent 4 }}
    app.kubernetes.io/component: api
---
{{- end }}

# Similar patterns for other services...
```

#### 5.3.3 Ingress Template

**File**: `apps/novahost/templates/ingress.yaml`

```yaml
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "novahost.fullname" . }}
  labels:
    {{- include "novahost.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if and .Values.ingress.className (semverCompare ">=1.18-0" .Capabilities.KubeVersion.GitVersion) }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- end }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            {{- if and .pathType (semverCompare ">=1.18-0" $.Capabilities.KubeVersion.GitVersion) }}
            pathType: {{ .pathType }}
            {{- end }}
            backend:
              {{- if semverCompare ">=1.19-0" $.Capabilities.KubeVersion.GitVersion }}
              service:
                name: {{ include "novahost.fullname" $ }}-{{ .backend.service.name }}
                port:
                  number: {{ .backend.service.port }}
              {{- else }}
              serviceName: {{ include "novahost.fullname" $ }}-{{ .backend.service.name }}
              servicePort: {{ .backend.service.port }}
              {{- end }}
          {{- end }}
    {{- end }}
---
{{- end }}

{{- if .Values.wildcardIngress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "novahost.fullname" . }}-wildcard
  labels:
    {{- include "novahost.labels" . | nindent 4 }}
  {{- with .Values.wildcardIngress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if and .Values.wildcardIngress.className (semverCompare ">=1.18-0" .Capabilities.KubeVersion.GitVersion) }}
  ingressClassName: {{ .Values.wildcardIngress.className }}
  {{- end }}
  {{- if .Values.wildcardIngress.tls }}
  tls:
    {{- range .Values.wildcardIngress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.wildcardIngress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            {{- if and .pathType (semverCompare ">=1.18-0" $.Capabilities.KubeVersion.GitVersion) }}
            pathType: {{ .pathType }}
            {{- end }}
            backend:
              {{- if semverCompare ">=1.19-0" $.Capabilities.KubeVersion.GitVersion }}
              service:
                name: {{ include "novahost.fullname" $ }}-{{ .backend.service.name }}
                port:
                  number: {{ .backend.service.port }}
              {{- else }}
              serviceName: {{ include "novahost.fullname" $ }}-{{ .backend.service.name }}
              servicePort: {{ .backend.service.port }}
              {{- end }}
          {{- end }}
    {{- end }}
{{- end }}
```

### 5.4 Helm Deployment Commands

```bash
# Validate chart
helm lint apps/novahost/

# Dry run to check generated manifests
helm install novahost apps/novahost/ --dry-run --debug -n novahost

# Install/upgrade application
helm upgrade --install novahost apps/novahost/ -n novahost --create-namespace --atomic

# Check deployment status
helm status novahost -n novahost

# List releases
helm list -n novahost

# Rollback if needed
helm rollback novahost 1 -n novahost
```

---

## 6. GitOps Implementation

### 6.1 GitOps Strategy

**Philosophy**: Infrastructure and application configuration as code with automated synchronization

**Tool**: ArgoCD with App of Apps pattern

**Repositories**:

- `Novahost` - Application source code and CI/CD
- `my-infra` - Infrastructure and deployment configurations

#### 🔍 **Concept Deep Dive: GitOps Methodology**

**What is GitOps?**
GitOps is an operational framework that takes DevOps best practices used for application development (version control, collaboration, compliance, CI/CD) and applies them to infrastructure automation.

**Core Principles of GitOps**:

**1. Declarative Configuration**

- **What**: Describe the desired state of the system declaratively
- **How**: Use YAML, JSON, or other declarative formats
- **Why**: Easier to understand, version, and manage than imperative scripts
- **Example**: Kubernetes manifests describe what you want, not how to get there

**2. Version Controlled and Immutable**

- **What**: All configuration stored in Git
- **How**: Every change goes through pull request workflow
- **Why**: Complete audit trail, easy rollbacks, collaboration
- **Benefit**: Infrastructure changes follow same process as code changes

**3. Pulled Automatically**

- **What**: Software agents automatically pull changes from Git
- **How**: GitOps operators monitor Git repositories
- **Why**: No manual deployments, reduced human error
- **Security**: Git becomes single source of truth, no direct cluster access needed

**4. Continuously Monitored**

- **What**: Continuously monitor and ensure desired state
- **How**: Detect drift between Git state and cluster state
- **Why**: Self-healing systems, automatic correction of manual changes
- **Action**: Alert on drift, automatically reconcile differences

**GitOps vs Traditional CI/CD**:

**Traditional CI/CD (Push Model)**:

```bash
Git Push → CI Pipeline → Build → Test → Deploy to Cluster
```

**Problems with Push Model**:

- **Security**: CI system needs cluster credentials
- **Visibility**: Limited insight into deployment status
- **Drift**: Manual changes not detected or corrected
- **Rollback**: Complex rollback procedures

**GitOps (Pull Model)**:

```bash
Git Push → CI Pipeline → Build → Update Git Config
                                      ↓
Cluster ← GitOps Agent ← Monitor Git Repository
```

**Benefits of Pull Model**:

- **Security**: No external systems need cluster access
- **Observability**: Clear view of desired vs actual state
- **Self-healing**: Automatic drift detection and correction
- **Simplified Rollback**: Revert Git commit to rollback

**ArgoCD Overview**:

**What is ArgoCD?**
ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It monitors Git repositories and automatically synchronizes the desired state with the actual state in Kubernetes clusters.

**Key Components**:

**1. Application Controller**

- **Purpose**: Monitors Git repositories for changes
- **Function**: Compares desired state (Git) with live state (cluster)
- **Action**: Synchronizes differences automatically or manually

**2. Repo Server**

- **Purpose**: Clones and manages Git repositories
- **Function**: Generates Kubernetes manifests from Git contents
- **Support**: Helm charts, Kustomize, plain YAML, Jsonnet

**3. API Server**

- **Purpose**: Provides web UI and CLI interface
- **Function**: Exposes ArgoCD functionality via REST API
- **Access**: Web UI for visualization, CLI for automation

**App of Apps Pattern**:

**What is App of Apps?**
A pattern where ArgoCD manages applications that themselves define other ArgoCD applications. It's like a "meta-application" that manages a collection of applications.

**Structure**:

```
Root App (App of Apps)
├── Application 1 (Novahost)
├── Application 2 (Monitoring)
├── Application 3 (Logging)
└── Application 4 (Security)
```

**Benefits**:

- **Scalability**: Manage hundreds of applications easily
- **Organization**: Group related applications together
- **Lifecycle**: Deploy/update multiple applications atomically
- **Flexibility**: Different teams can manage different app groups

**Why App of Apps for Novahost?**

1. **Separation of Concerns**: Infrastructure vs application teams
2. **Scalability**: Easy to add new applications
3. **Consistency**: Standard pattern for application management
4. **Dependencies**: Control deployment order of related apps

**GitOps Workflow for Novahost**:

**Development Workflow**:

1. **Developer** pushes code to `Novahost` repository
2. **GitHub Actions** builds and tests application
3. **CI Pipeline** creates new Docker images
4. **Automation** updates image tags in `my-infra` repository
5. **ArgoCD** detects changes in `my-infra`
6. **Sync Process** deploys new version to Kubernetes
7. **Monitoring** validates deployment success

**Configuration Change Workflow**:

1. **DevOps Engineer** modifies Helm charts in `my-infra`
2. **Pull Request** for configuration review
3. **Approval** and merge to main branch
4. **ArgoCD** automatically syncs changes
5. **Validation** ensures successful deployment

**GitOps Security Model**:

**Git-Centric Security**:

- **Authentication**: Git repository access controls
- **Authorization**: Branch protection rules, required reviews
- **Audit Trail**: All changes tracked in Git history
- **Compliance**: GitOps workflow provides audit trail

**ArgoCD Security**:

- **RBAC**: Role-based access control for applications
- **SSO Integration**: Single sign-on with corporate identity providers
- **Secret Management**: Encrypted secrets, external secret managers
- **Network Security**: Private Git repositories, cluster isolation

**Disaster Recovery with GitOps**:

**Backup Strategy**:

- **Git Repositories**: Distributed by nature, multiple copies
- **ArgoCD Configuration**: Backed up as Git configuration
- **Application State**: Recreated from Git declarations

**Recovery Process**:

1. **Restore Cluster**: Create new Kubernetes cluster
2. **Install ArgoCD**: Deploy ArgoCD to new cluster
3. **Apply Root App**: Deploy App of Apps configuration
4. **Automatic Sync**: ArgoCD restores all applications from Git

**GitOps Observability**:

**ArgoCD Dashboard Provides**:

- **Application Health**: Health status of all applications
- **Sync Status**: Whether applications are in sync with Git
- **Resource Details**: Detailed view of Kubernetes resources
- **Deployment History**: Timeline of all deployments
- **Rollback Capability**: Easy rollback to previous versions

**Monitoring Integration**:

- **Prometheus Metrics**: ArgoCD exposes detailed metrics
- **Grafana Dashboards**: Visualize GitOps operations
- **Alerting**: Notify on sync failures, health issues
- **Webhooks**: Integration with external systems

**GitOps Best Practices**:

**Repository Structure**:

- **Separate Repos**: Application code vs infrastructure configuration
- **Environment Branches**: Different branches for dev/staging/prod
- **Directory Structure**: Organized by environment and application

**Security Practices**:

- **Least Privilege**: Minimal permissions for GitOps operators
- **Secret Management**: External secret stores, not in Git
- **Image Security**: Scan container images for vulnerabilities
- **Policy as Code**: Implement security policies in Git

**Operational Practices**:

- **Automated Testing**: Test configuration changes in lower environments
- **Progressive Deployment**: Deploy to dev → staging → prod
- **Monitoring**: Comprehensive observability of GitOps pipeline
- **Documentation**: Document GitOps workflows and procedures

### 6.2 ArgoCD Application Configuration

#### 6.2.1 App of Apps Pattern

**Root Application**: `platform/argocd/applications/root-app.yml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-applications
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/aliabbaschadhar/my-infra.git
    targetRevision: main
    path: platform/argocd/applications
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
```

#### 6.2.2 Novahost Application

**File**: `platform/argocd/applications/novahost.yml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: novahost
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/aliabbaschadhar/my-infra.git
    targetRevision: main
    path: apps/novahost
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: novahost
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### 6.3 ArgoCD Deployment

**Commands**:

```bash
# Apply root application (this will create all other applications)
kubectl apply -f platform/argocd/applications/root-app.yml

# Verify applications
kubectl get applications -n argocd

# Check sync status
kubectl describe application novahost -n argocd

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### 6.4 GitOps Workflow

```
1. Developer pushes code to Novahost repository
   ↓
2. GitHub Actions CI/CD pipeline triggers
   ↓
3. New Docker images built and pushed to registry
   ↓
4. GitHub Actions updates image tags in my-infra repository
   ↓
5. ArgoCD detects changes in my-infra repository
   ↓
6. ArgoCD automatically syncs and deploys new version
   ↓
7. Application updated with zero downtime
```

---

## 7. CI/CD Pipeline

### 7.1 GitHub Actions Configuration

**File**: `.github/workflows/ci_main.yml`

```yaml
name: Deploy Whole Monorepo

on:
  push: 
    branches: [main]
    paths:
      - "apps/**"
      - "packages/prismaDB/**"
      - "docker/**"
      - ".github/workflows/**"

env:
  DOCKER_REGISTRY: docker.io
  DOCKER_USERNAME: aliabbaschadhar003

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service:
          - name: api-server
            dockerfile: docker/Dockerfile.api-server
            context: .
          - name: web
            dockerfile: docker/Dockerfile.web
            context: .
          - name: reverse-proxy
            dockerfile: docker/Dockerfile.reverse-proxy
            context: .
          - name: build-server
            dockerfile: docker/Dockerfile.build-server
            context: .
    
    steps:
      - name: Checkout the code
        uses: actions/checkout@v4
        
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
        
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          registry: ${{ env.DOCKER_REGISTRY }}
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_PAT }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.DOCKER_REGISTRY }}/${{ env.DOCKER_USERNAME }}/novahost-${{ matrix.service.name }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}
      
      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: ${{ matrix.service.context }}
          file: ${{ matrix.service.dockerfile }}
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64

  update-deployment:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout my-infra repository
        uses: actions/checkout@v4
        with:
          repository: aliabbaschadhar/my-infra
          token: ${{ secrets.GH_PAT }}
          path: my-infra
          
      - name: Update image tags in values.yaml
        run: |
          cd my-infra/apps/novahost
          
          # Update all service image tags to use the commit SHA
          sed -i "s|tag: \".*\"|tag: \"${{ github.sha }}\"|g" values.yaml
          
          # Verify changes
          echo "Updated values.yaml:"
          grep -A 2 -B 2 "tag:" values.yaml
          
      - name: Commit and push changes
        run: |
          cd my-infra
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add apps/novahost/values.yaml
          
          # Only commit if there are changes
          if git diff --staged --quiet; then
            echo "No changes to commit"
          else
            git commit -m "🚀 Update Novahost image tags to ${{ github.sha }}"
            git push
            echo "Changes committed and pushed"
          fi

  notification:
    needs: [build, update-deployment]
    runs-on: ubuntu-latest
    if: always()
    steps:
      - name: Deployment notification
        run: |
          if [[ "${{ needs.build.result }}" == "success" && "${{ needs.update-deployment.result }}" == "success" ]]; then
            echo "✅ Deployment pipeline completed successfully"
            echo "🚀 New version ${{ github.sha }} deployed to production"
          else
            echo "❌ Deployment pipeline failed"
            echo "Build status: ${{ needs.build.result }}"
            echo "Update status: ${{ needs.update-deployment.result }}"
          fi
```

### 7.2 Required GitHub Secrets

**Repository Secrets Configuration**:

| Secret Name | Purpose | Value Example |
|-------------|---------|---------------|
| `DOCKERHUB_USERNAME` | Docker Hub authentication | `aliabbaschadhar003` |
| `DOCKERHUB_PAT` | Docker Hub Personal Access Token | `dckr_pat_xxx...` |
| `GH_PAT` | GitHub Personal Access Token | `ghp_xxx...` |

**GitHub PAT Permissions Required**:

- `Contents`: Read and write
- `Actions`: Read
- `Metadata`: Read
- `Pull requests`: Read (if using PR workflows)

### 7.3 CI/CD Pipeline Stages

#### Stage 1: Code Checkout

- Checkout source code from Novahost repository
- Setup Docker Buildx for advanced build features

#### Stage 2: Docker Build

- **Matrix Strategy**: Build all 4 services in parallel
- **Caching**: Use GitHub Actions cache for faster builds
- **Multi-platform**: Support for linux/amd64
- **Tagging Strategy**:
  - `latest` for main branch
  - `{commit-sha}` for specific versions
  - `{branch}-{commit-sha}` for feature branches

#### Stage 3: Registry Push

- Push images to Docker Hub registry
- Verify successful push with metadata

#### Stage 4: GitOps Update

- Checkout infrastructure repository (`my-infra`)
- Update Helm values with new image tags
- Commit and push changes to trigger ArgoCD sync

#### Stage 5: Notification

- Send deployment status notifications
- Log deployment success/failure details

### 7.4 Pipeline Optimizations

**Performance Improvements**:

- **Parallel builds**: Matrix strategy for simultaneous image building
- **Docker layer caching**: GitHub Actions cache integration
- **Conditional deployment**: Only deploy on actual changes
- **Fast feedback**: Early failure detection

**Security Features**:

- **Secret management**: Secure handling of credentials
- **Image scanning**: Automated vulnerability detection
- **Access control**: Limited GitHub PAT permissions
- **Audit trail**: Complete deployment history

---

## 8. DNS and SSL Configuration

### 8.1 Domain Configuration

**Domain**: `ybro.tech`
**Hosting**: Cloudflare DNS management

### 8.2 DNS Records Setup

**Required DNS Records**:

```
# Main application
Type: A
Name: novahost
Content: 174.138.121.213
TTL: Auto
Proxy: DNS only (gray cloud)

# Wildcard for user projects
Type: A  
Name: *.novahost
Content: 174.138.121.213
TTL: Auto
Proxy: DNS only (gray cloud)
```

**Verification Commands**:

```bash
# Test main domain
dig novahost.ybro.tech

# Test wildcard
dig test.novahost.ybro.tech

# Check LoadBalancer IP
kubectl get svc -n ingress-nginx
```

### 8.3 SSL Certificate Management

#### 8.3.1 Let's Encrypt Integration

**Certificate Issuer**: Let's Encrypt via cert-manager

**ClusterIssuer Configuration**: Already applied in infrastructure setup

#### 8.3.2 Certificate Resources

**Main Domain Certificate**:
Automatically created by ingress annotation:

```yaml
annotations:
  cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

**Wildcard Certificate**:
Automatically created for `*.novahost.ybro.tech`

#### 8.3.3 Certificate Verification

**Commands**:

```bash
# Check certificate status
kubectl get certificates -n novahost

# Check certificate details
kubectl describe certificate novahost-tls -n novahost
kubectl describe certificate novahost-wildcard-tls -n novahost

# Check certificate secrets
kubectl get secrets -n novahost | grep tls

# Test SSL connection
openssl s_client -connect novahost.ybro.tech:443 -servername novahost.ybro.tech
```

**Expected Certificate Status**:

```
NAME                     READY   SECRET                   AGE
novahost-tls            True    novahost-tls             24h
novahost-wildcard-tls   True    novahost-wildcard-tls    24h
```

---

## 9. Troubleshooting Journey

### 9.1 Docker Build Issues

#### Problem 1: Prisma Client Database Connection

**Error**:

```
Error: Cannot find module '@prisma/client'
Error: P1001: Can't reach database server at `localhost:5432`
```

**Root Cause**: Next.js was trying to instantiate Prisma client during build time

**Investigation Steps**:

1. Analyzed Docker build logs
2. Identified Prisma client instantiation in build phase
3. Reviewed Next.js build process
4. Found database connection attempt during static optimization

**Solution**: Conditional Prisma client instantiation

```typescript
const isPrismaClientSafe = () => {
  if (process.env.DATABASE_URL?.includes('placeholder')) {
    return false;
  }
  if (process.env.NEXT_PHASE === 'phase-production-build') {
    return false;
  }
  return true;
};
```

#### Problem 2: Build Context Size

**Error**: Build context too large, slow uploads

**Solution**: Optimized .dockerignore

```
node_modules
.git
.turbo
.next
dist
*.log
README.md
```

### 9.2 Kubernetes Deployment Issues

#### Problem 1: ImagePullBackOff

**Error**: `ErrImagePull`, `ImagePullBackOff`

**Root Cause**: Incorrect Docker Hub username in CI/CD

**Investigation**:

```bash
kubectl describe pod novahost-web-xxx -n novahost
kubectl get events -n novahost --sort-by='.lastTimestamp'
```

**Solution**: Fixed GitHub Actions workflow variables

```yaml
env:
  DOCKER_USERNAME: aliabbaschadhar003  # Corrected username
```

#### Problem 2: Secret Not Found

**Error**: `Error from server (NotFound): secrets "database-secret" not found`

**Investigation**:

```bash
kubectl get secrets -n novahost
kubectl describe deployment novahost-web -n novahost
```

**Solution**: Applied secrets before deployment

```bash
./apps/novahost/secret-templates/apply-secrets.sh
```

#### Problem 3: Service Mesh Communication

**Error**: Services couldn't communicate internally

**Investigation**:

```bash
kubectl get svc -n novahost
kubectl get endpoints -n novahost
```

**Solution**: Fixed service selectors and port mappings in Helm templates

### 9.3 Ingress and SSL Issues

#### Problem 1: SSL Certificate Not Issuing

**Error**: Certificate stuck in `Pending` state

**Investigation**:

```bash
kubectl describe certificate novahost-tls -n novahost
kubectl get challenges -n novahost
kubectl logs -n cert-manager deployment/cert-manager
```

**Root Cause**: DNS propagation delay

**Solution**:

1. Verified DNS records
2. Waited for propagation
3. Certificate automatically issued after DNS resolved

#### Problem 2: 502 Bad Gateway

**Error**: NGINX returning 502 errors

**Investigation**:

```bash
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
kubectl get pods -n novahost
kubectl logs deployment/novahost-web -n novahost
```

**Root Cause**: Application pods not ready

**Solution**: Fixed health check endpoints and probes

### 9.4 ArgoCD Sync Issues

#### Problem 1: Application Not Syncing

**Error**: ArgoCD showing `OutOfSync` but not auto-syncing

**Investigation**:

```bash
kubectl get applications -n argocd
kubectl describe application novahost -n argocd
```

**Root Cause**: Git repository access issues

**Solution**:

1. Verified repository URLs
2. Updated sync policies
3. Manual sync to resolve initial state

#### Problem 2: Helm Template Errors

**Error**: `unable to build kubernetes objects from release manifest`

**Investigation**:

```bash
helm template novahost apps/novahost/ --debug
helm lint apps/novahost/
```

**Solution**: Fixed Helm template syntax and indentation

### 9.5 CI/CD Pipeline Issues

#### Problem 1: GitHub Actions Permission Denied

**Error**: `Permission denied` when pushing to my-infra repository

**Root Cause**: Insufficient GitHub PAT permissions

**Solution**: Updated PAT with correct permissions:

- Contents: Write
- Actions: Read  
- Metadata: Read

#### Problem 2: Docker Build Context Error

**Error**: Context exceeded maximum size

**Solution**: Optimized build context and added .dockerignore

---

## 10. Lessons Learned

### 10.1 Technical Insights

#### Docker Containerization

- **Multi-stage builds** significantly reduce final image size
- **Build-time vs runtime** environment separation is crucial
- **Security contexts** and non-root users improve security posture
- **Layer caching** strategies can dramatically improve build times

#### Kubernetes Orchestration

- **Helm charts** provide better maintainability than raw manifests
- **Resource limits** prevent resource starvation
- **Health checks** are essential for reliable deployments
- **Namespace isolation** improves security and organization

#### GitOps Implementation

- **App of Apps pattern** scales better than individual applications
- **Automated sync** reduces operational overhead
- **Infrastructure as Code** enables version control and rollbacks
- **Separation of concerns** between app code and infrastructure

#### CI/CD Pipeline

- **Matrix builds** enable parallel processing
- **Conditional deployment** prevents unnecessary updates
- **Secret management** requires careful planning
- **Fast feedback loops** improve developer experience

### 10.2 Operational Insights

#### Monitoring and Observability

- **Centralized logging** is essential for debugging
- **Health endpoints** enable automated monitoring
- **Resource metrics** help with capacity planning
- **Alerting strategies** need careful tuning

#### Security Considerations

- **Secret rotation** should be automated
- **Network policies** enhance security
- **RBAC** controls access appropriately
- **Image scanning** catches vulnerabilities early

#### Performance Optimization

- **Resource requests/limits** improve scheduling
- **Horizontal Pod Autoscaling** handles load spikes
- **Load balancing** distributes traffic effectively
- **Caching strategies** reduce latency

### 10.3 Best Practices Developed

#### Development Workflow

1. **Local development** with Docker Compose
2. **Feature branch** deployments for testing
3. **Automated testing** in CI pipeline
4. **Staged rollouts** for production

#### Infrastructure Management

1. **Infrastructure as Code** for all resources
2. **Version control** for configurations
3. **Automated deployments** with manual approval gates
4. **Disaster recovery** planning and testing

#### Security Practices

1. **Principle of least privilege** for all access
2. **Regular security updates** and patching
3. **Audit logging** for compliance
4. **Backup and recovery** procedures

#### Monitoring Strategy

1. **Application metrics** for business insights
2. **Infrastructure metrics** for operational health
3. **Log aggregation** for debugging
4. **Alerting hierarchy** for incident response

### 10.4 Future Improvements

#### Short-term (Next Month)

- [ ] Implement comprehensive monitoring with Prometheus/Grafana
- [ ] Add automated testing in CI pipeline
- [ ] Set up log aggregation with ELK stack
- [ ] Implement backup strategies for database

#### Medium-term (Next Quarter)

- [ ] Add horizontal pod autoscaling
- [ ] Implement blue-green deployments
- [ ] Set up disaster recovery procedures
- [ ] Add security scanning to CI pipeline

#### Long-term (Next Year)

- [ ] Migration to service mesh (Istio)
- [ ] Implementation of canary deployments
- [ ] Multi-region deployment strategy
- [ ] Advanced observability and tracing

---

## Conclusion

This deployment process demonstrates a complete modern application deployment pipeline, from containerization through GitOps automation. The journey involved overcoming various technical challenges and implementing industry best practices for:

- **Containerization** with Docker multi-stage builds
- **Orchestration** with Kubernetes and Helm
- **GitOps** with ArgoCD and GitHub Actions
- **Security** with SSL automation and secret management
- **Scalability** with cloud-native architecture
- **Reliability** with health checks and automated deployments

The resulting system provides:

- **Zero-downtime deployments**
- **Automatic SSL certificate management**
- **Scalable multi-service architecture**
- **Comprehensive security practices**
- **Full automation from code to production**

**Live Result**: <https://novahost.ybro.tech>

This process serves as a comprehensive guide for deploying production-ready applications using modern DevOps practices and cloud-native technologies.
