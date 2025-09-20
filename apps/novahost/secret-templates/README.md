# Secret Templates for Novahost

These are **template files** for Kubernetes secrets required by the Novahost application.

## ⚠️ IMPORTANT: These are templates only

- **DO NOT** put real secret values in these files
- **DO NOT** commit files with actual secrets to git
- These files serve as documentation and infrastructure templates

## Usage Patterns

### Option 1: Manual Secret Creation (Current approach)

```bash
# Copy template, replace values, apply once, then delete the file
cp secret-templates/app-secret.yaml app-secret-filled.yaml
# Edit app-secret-filled.yaml with real values
kubectl apply -f app-secret-filled.yaml
rm app-secret-filled.yaml  # Delete after applying
```

### Option 2: Better Production Approach

Consider using:

- **Sealed Secrets**: Encrypt secrets that can be stored in git
- **External Secrets Operator**: Sync from HashiCorp Vault, AWS Secrets Manager, etc.
- **SOPS + Age**: Encrypt secret files for git storage

## Secret Dependencies

The deployment expects these exact secret names:

- `novahost-database-secret`
- `novahost-redis-secret`
- `novahost-oauth-secret`
- `novahost-r2-secret`
- `novahost-app-secret`
- `novahost-build-secret`

## Benefits of keeping these templates

✅ Infrastructure documentation  
✅ Cluster migration support  
✅ Team onboarding  
✅ Disaster recovery  
✅ Required secret structure visibility
