#!/bin/bash

# Generate secure random keys
echo "Generating secure keys for Supabase..."

# Generate 32-byte (256-bit) keys in hex format
SECRET_KEY_BASE=$(openssl rand -hex 32)
VAULT_ENC_KEY=$(openssl rand -hex 32)
N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)
POSTGRES_PASSWORD=$(openssl rand -base64 32)
LOGFLARE_API_KEY=$(openssl rand -hex 32)

# Generate JWT Secret (should be same for all Supabase services)
JWT_SECRET=$(openssl rand -base64 32)

# Generate new JWT tokens with the new secret
# Note: In production, you should properly generate these with the correct claims
echo ""
echo "Generated keys:"
echo "============================================"
echo "SECRET_KEY_BASE=$SECRET_KEY_BASE"
echo "VAULT_ENC_KEY=$VAULT_ENC_KEY"
echo "N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY"
echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
echo "JWT_SECRET=$JWT_SECRET"
echo "LOGFLARE_API_KEY=$LOGFLARE_API_KEY"
echo ""
echo "IMPORTANT: You need to generate new ANON_KEY and SERVICE_ROLE_KEY"
echo "using the JWT_SECRET above. Visit https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys"
echo "or use the Supabase CLI to generate them."