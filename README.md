## Project overview

- Main Project: Novahost — self-hosted cloud hosting platform (Next.js, TypeScript, Bun).
- Goal: Host multiple hobby apps on shared, cost-effective infrastructure.
- Repos: `Novahost` (app code) and `my-infra` (infrastructure, Helm charts, ArgoCD manifests).

## Key decisions (summary)

- Single PostgreSQL instance (TimescaleDB) with multiple databases per app.
- Single Redis instance with logical DB separation per app.
- Shared ingress & load balancer using path-based routing on `novahost.shakalabs.com`.
- cert-manager + Let's Encrypt for TLS.
- GitOps via ArgoCD (app-of-apps); everything deployed via Helm charts.
- Build server runs as Kubernetes Jobs and is internal-only.

## Routing rules

- `novahost.shakalabs.com/` → novahost-web:3000
- `novahost.shakalabs.com/api/*` → novahost-api:9000
- build-server & reverse-proxy: internal only

## Kubernetes layout

- Namespaces:
  - `shared`: postgresql, redis, ingress-nginx, cert-manager, monitoring
  - `novahost`: application components
  - `excalidraw`: future app
  - `argocd`: GitOps
- Secrets: currently manual per-namespace (recommend using a secrets-manager later).

## Folder structure

Use this repo as single source of truth for Helm/ArgoCD:

```text
my-infra/
├── platform/            # ArgoCD app-of-apps / platform-level manifests
├── shared/              # Helm charts for shared infra
│   ├── postgresql/      # Bitnami PostgreSQL + TimescaleDB (values + patches)
│   ├── redis/           # Bitnami Redis
│   ├── nginx-ingress/   # ingress-nginx chart
│   └── cert-manager/    # cert-manager chart
└── apps/
    ├── novahost/        # umbrella Helm chart
    │   ├── Chart.yaml
    │   ├── values.yaml  # global values & common secrets references
    │   └── charts/
    │       ├── web/
    │       ├── api-server/
    │       ├── build-server/
    │       └── reverse-proxy/
    └── excalidraw/      # future umbrella chart
```

## Minimal deployment checklist (order)

1. Provision Kubernetes cluster and DNS for novahost.shakalabs.com.
2. Install argoCd using DO-market place - or bitnami chart.
3. Deploy shared services first in `shared`:
   - cert-manager(From DO-marketplace), ingress-nginx(from DO marketplace), PostgreSQL (with Timescale), Redis.
4. Create per-app namespaces and required Kubernetes secrets (DATABASE_URL, REDIS_URL, TLS/other).
5. Deploy apps via ArgoCD/Helm (start with novahost umbrella chart).
6. Test routing and TLS, then run build-server jobs to validate image/artifact uploads to S3/DO Spaces.
