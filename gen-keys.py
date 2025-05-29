#!/usr/bin/env python3
"""
Complete Supabase + n8n Environment File Generator
Generates a production-ready .env file with all secure keys
"""

import secrets
import base64
import json
import time
import hmac
import hashlib
from datetime import datetime
from typing import Dict, Tuple

def base64url_encode(data: bytes) -> str:
    """Base64url encode without padding"""
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('ascii')

def generate_jwt(payload: Dict, secret: str) -> str:
    """Generate JWT token with HS256 algorithm"""
    header = {"alg": "HS256", "typ": "JWT"}
    
    header_encoded = base64url_encode(json.dumps(header).encode('utf-8'))
    payload_encoded = base64url_encode(json.dumps(payload).encode('utf-8'))
    
    message = f"{header_encoded}.{payload_encoded}".encode('utf-8')
    signature = hmac.new(secret.encode('utf-8'), message, hashlib.sha256).digest()
    signature_encoded = base64url_encode(signature)
    
    return f"{header_encoded}.{payload_encoded}.{signature_encoded}"

def generate_secure_key(length: int = 32, format: str = 'hex') -> str:
    """Generate cryptographically secure random key"""
    random_bytes = secrets.token_bytes(length)
    
    if format == 'hex':
        return random_bytes.hex()
    elif format == 'base64':
        return base64.b64encode(random_bytes).decode('ascii')
    elif format == 'base64url':
        return base64.urlsafe_b64encode(random_bytes).decode('ascii').rstrip('=')
    else:
        raise ValueError(f"Unknown format: {format}")

def generate_strong_password(length: int = 32) -> str:
    """Generate a strong password with mixed characters"""
    charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+"
    return ''.join(secrets.choice(charset) for _ in range(length))

def generate_complete_env() -> str:
    """Generate complete .env file content"""
    
    # Generate base keys
    jwt_secret = generate_secure_key(32, 'base64url')
    postgres_password = generate_secure_key(24, 'base64url')
    
    # Generate JWT tokens
    now = int(time.time())
    exp = now + (58 * 365 * 24 * 60 * 60)  # 58 years
    
    anon_key = generate_jwt(
        {"role": "anon", "iss": "supabase", "iat": now, "exp": exp},
        jwt_secret
    )
    
    service_role_key = generate_jwt(
        {"role": "service_role", "iss": "supabase", "iat": now, "exp": exp},
        jwt_secret
    )
    
    # Generate all other keys
    keys = {
        'JWT_SECRET': jwt_secret,
        'POSTGRES_PASSWORD': postgres_password,
        'ANON_KEY': anon_key,
        'SERVICE_ROLE_KEY': service_role_key,
        'DASHBOARD_USERNAME': f'admin_{secrets.token_hex(4)}',
        'DASHBOARD_PASSWORD': generate_strong_password(48),
        'SECRET_KEY_BASE': generate_secure_key(32, 'hex'),
        'VAULT_ENC_KEY': generate_secure_key(32, 'base64url'),
        'N8N_ENCRYPTION_KEY': generate_secure_key(32, 'hex'),
        'SMTP_USER': f'smtp_{secrets.token_hex(4)}',
        'SMTP_PASS': generate_strong_password(24),
        'POOLER_TENANT_ID': f'prod-{datetime.now().year}-{secrets.token_hex(4)}-{secrets.token_hex(2)}-{secrets.token_hex(2)}-{secrets.token_hex(2)}-{secrets.token_hex(6)}',
        'LOGFLARE_API_KEY': generate_secure_key(32, 'hex'),
        'LOGFLARE_LOGGER_BACKEND_API_KEY': generate_secure_key(32, 'hex'),
    }
    
    # Complete .env template
    env_template = f"""############
# Secrets
# PRODUCTION-READY CONFIGURATION - KEEP THESE VALUES SECURE
# Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
############

# PostgreSQL Database Password (64-character secure password)
POSTGRES_PASSWORD={keys['POSTGRES_PASSWORD']}

# JWT Secret (64-character high-security secret key)
JWT_SECRET={keys['JWT_SECRET']}

# Supabase Anonymous Key (JWT token with 'anon' role)
ANON_KEY={keys['ANON_KEY']}

# Supabase Service Role Key (JWT token with 'service_role' role)
SERVICE_ROLE_KEY={keys['SERVICE_ROLE_KEY']}

# Dashboard Authentication (Enhanced Security)
DASHBOARD_USERNAME={keys['DASHBOARD_USERNAME']}
DASHBOARD_PASSWORD={keys['DASHBOARD_PASSWORD']}

# Encryption Keys
SECRET_KEY_BASE={keys['SECRET_KEY_BASE']}
VAULT_ENC_KEY={keys['VAULT_ENC_KEY']}

# n8n Encryption Key (32-character n8n-specific encryption key)
N8N_ENCRYPTION_KEY={keys['N8N_ENCRYPTION_KEY']}
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
N8N_RUNNERS_ENABLED=true
OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS=true

############
# Database - You can change these to any PostgreSQL database that has logical replication enabled.
############

POSTGRES_HOST=db
POSTGRES_DB=postgres
POSTGRES_PORT=5432
# default user is postgres

############
# Supavisor -- Database pooler
############

POOLER_PROXY_PORT_TRANSACTION=6543
POOLER_DEFAULT_POOL_SIZE=20
POOLER_MAX_CLIENT_CONN=100
# Unique Tenant ID (UUID format)
POOLER_TENANT_ID={keys['POOLER_TENANT_ID']}

############
# API - Configuration for PostgREST.
############

PGRST_DB_SCHEMAS=public,storage,graphql_public

############
# Auth - Configuration for the GoTrue authentication server.
############

## General
SITE_URL=http://localhost:3000
ADDITIONAL_REDIRECT_URLS=
JWT_EXPIRY=3600
DISABLE_SIGNUP=false
API_EXTERNAL_URL=http://localhost:8000

## Mailer Config
MAILER_URLPATHS_CONFIRMATION="/auth/v1/verify"
MAILER_URLPATHS_INVITE="/auth/v1/verify"
MAILER_URLPATHS_RECOVERY="/auth/v1/verify"
MAILER_URLPATHS_EMAIL_CHANGE="/auth/v1/verify"

## Email auth
ENABLE_EMAIL_SIGNUP=true
ENABLE_EMAIL_AUTOCONFIRM=false
SMTP_ADMIN_EMAIL=admin@example.com
SMTP_HOST=supabase-mail
SMTP_PORT=2500
SMTP_USER={keys['SMTP_USER']}
SMTP_PASS={keys['SMTP_PASS']}
SMTP_SENDER_NAME=System Notification
ENABLE_ANONYMOUS_USERS=false

## Phone auth
ENABLE_PHONE_SIGNUP=true
ENABLE_PHONE_AUTOCONFIRM=true

############
# Studio - Configuration for the Dashboard
############

STUDIO_DEFAULT_ORGANIZATION=Production Organization
STUDIO_DEFAULT_PROJECT=Production Project

STUDIO_PORT=3000
# replace if you intend to use Studio outside of localhost
SUPABASE_PUBLIC_URL=http://localhost:8000

# Enable webp support
IMGPROXY_ENABLE_WEBP_DETECTION=true

# Add your OpenAI API key to enable SQL Editor Assistant
OPENAI_API_KEY=

############
# Functions - Configuration for Functions
############

# NOTE: VERIFY_JWT applies to all functions. Per-function VERIFY_JWT is not supported yet.
FUNCTIONS_VERIFY_JWT=false

############
# Logs - Configuration for Logflare
# Please refer to https://supabase.com/docs/reference/self-hosting-analytics/introduction
############

# Logflare API Keys (64-character high-security keys)
LOGFLARE_LOGGER_BACKEND_API_KEY={keys['LOGFLARE_LOGGER_BACKEND_API_KEY']}
LOGFLARE_API_KEY={keys['LOGFLARE_API_KEY']}

# Docker socket location - this value will differ depending on your OS
DOCKER_SOCKET_LOCATION=/var/run/docker.sock

# Google Cloud Project details (update with actual project info if needed)
GOOGLE_PROJECT_ID=
GOOGLE_PROJECT_NUMBER=
"""
    
    return env_template, keys

def main():
    """Main execution function"""
    print("🔐 Supabase + n8n Production Environment Generator")
    print("=" * 70)
    print(f"📅 Generated at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)
    
    # Generate environment file
    env_content, keys = generate_complete_env()
    
    # Save to file
    output_file = '.env.production'
    with open(output_file, 'w') as f:
        f.write(env_content)
    
    print("\n✅ Environment file generated successfully!")
    print(f"📄 Saved to: {output_file}")
    
    # Display summary
    print("\n🔑 Generated Keys Summary:")
    print("-" * 70)
    print(f"JWT_SECRET (first 20 chars): {keys['JWT_SECRET'][:20]}...")
    print(f"POSTGRES_PASSWORD (first 20 chars): {keys['POSTGRES_PASSWORD'][:20]}...")
    print(f"DASHBOARD_USERNAME: {keys['DASHBOARD_USERNAME']}")
    print(f"POOLER_TENANT_ID: {keys['POOLER_TENANT_ID']}")
    
    # Verify JWT tokens
    print("\n🔍 JWT Token Verification:")
    print("-" * 70)
    
    # Decode and display ANON_KEY
    anon_parts = keys['ANON_KEY'].split('.')
    anon_payload = json.loads(base64.urlsafe_b64decode(anon_parts[1] + '=='))
    print("ANON_KEY Payload:")
    print(json.dumps(anon_payload, indent=2))
    
    # Decode and display SERVICE_ROLE_KEY
    service_parts = keys['SERVICE_ROLE_KEY'].split('.')
    service_payload = json.loads(base64.urlsafe_b64decode(service_parts[1] + '=='))
    print("\nSERVICE_ROLE_KEY Payload:")
    print(json.dumps(service_payload, indent=2))
    
    # Security warnings
    print("\n⚠️  SECURITY WARNINGS:")
    print("-" * 70)
    print("1. NEVER commit this file to version control")
    print("2. SERVICE_ROLE_KEY should NEVER be exposed to browsers")
    print("3. Use ANON_KEY only for client-side applications")
    print("4. Rotate all keys regularly in production")
    print("5. Update SMTP_ADMIN_EMAIL and SUPABASE_PUBLIC_URL for production")
    
    print("\n🚀 Next Steps:")
    print("1. Review and update production-specific values")
    print("2. Rename to .env: mv .env.production .env")
    print("3. Secure the file: chmod 600 .env")
    print("4. Start services: docker-compose up -d")

if __name__ == "__main__":
    main()