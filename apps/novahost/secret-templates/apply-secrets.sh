#!/bin/bash

# Create secrets apply script for Novahost
# This script applies all Kubernetes secrets required for the Novahost application

echo "Applying Novahost Kubernetes secrets..."

# Ensure novahost namespace exists
kubectl create namespace novahost --dry-run=client -o yaml | kubectl apply -f -

# Apply all secret files
kubectl apply -f database-secret.yaml
kubectl apply -f redis-secret.yaml  
kubectl apply -f oauth-secret.yaml
kubectl apply -f r2-secret.yaml
kubectl apply -f app-secret.yaml
kubectl apply -f build-secret.yaml

echo "All secrets applied successfully!"
echo ""
echo "IMPORTANT: Replace placeholder values with actual credentials before deployment!"
echo "Required placeholders to replace:"
echo "- REPLACE_WITH_PASSWORD (PostgreSQL password)"
echo "- REPLACE_WITH_GOOGLE_CLIENT_ID"
echo "- REPLACE_WITH_GOOGLE_CLIENT_SECRET"
echo "- REPLACE_WITH_GITHUB_CLIENT_ID"
echo "- REPLACE_WITH_GITHUB_CLIENT_SECRET"
echo "- REPLACE_WITH_R2_ACCESS_KEY_ID"
echo "- REPLACE_WITH_R2_SECRET_ACCESS_KEY"
echo "- REPLACE_WITH_R2_ENDPOINT"
echo "- REPLACE_WITH_R2_BUCKET_NAME"
echo "- REPLACE_WITH_R2_BASE_PATH"
echo "- REPLACE_WITH_NEXTAUTH_SECRET"
echo "- REPLACE_WITH_RESEND_API_KEY"
echo "- REPLACE_WITH_EMAIL_FROM"
echo "- REPLACE_WITH_JWT_SECRET"