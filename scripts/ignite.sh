#!/bin/bash

# Vector Store + n8n Platform Startup Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "🚀 Starting Vector Store + n8n Platform..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file from .env.example..."
    cp .env.example .env
    echo "⚠️  Please update .env file with your configuration!"
    echo "Press any key to continue after updating .env..."
    read -n 1 -s
fi

# Source environment variables
set -a
source .env
set +a

# Validate critical environment variables
echo "🔍 Validating environment variables..."
REQUIRED_VARS=(
    "POSTGRES_PASSWORD"
    "POSTGRES_DB"
    "POSTGRES_USER"
    "N8N_DB_PASSWORD"
    "JWT_SECRET"
    "ANON_KEY"
    "SERVICE_ROLE_KEY"
    "SECRET_KEY_BASE"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Missing required environment variable: $var"
        exit 1
    fi
done

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p nginx/ssl
mkdir -p n8n/workflows
mkdir -p n8n/nodes
mkdir -p supabase/functions
mkdir -p volumes/{postgres-data,n8n-data,storage-data,vector-data}

# Set proper permissions
chmod 755 init-db/*.sql
chmod 755 scripts/*.sh

# Check if SSL certificates exist
if [ ! -f nginx/ssl/cert.pem ] || [ ! -f nginx/ssl/key.pem ]; then
    echo "🔐 Generating self-signed SSL certificates..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout nginx/ssl/key.pem \
        -out nginx/ssl/cert.pem \
        -subj "/C=KR/ST=Seoul/L=Seoul/O=VectorPlatform/CN=n8n.shop.co.kr"
fi

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
docker-compose down --remove-orphans || true

# Remove old volumes if they exist (for clean start)
echo "🗑️ Removing old volumes..."
docker volume rm -f \
    vector-n8n-platform_postgres_data \
    vector-n8n-platform_n8n_data \
    vector-n8n-platform_storage_data \
    vector-n8n-platform_redis_data \
    2>/dev/null || true

# Pull latest images
echo "📥 Pulling latest images..."
docker-compose pull

# Start PostgreSQL first and wait for it to be ready
echo "🏗️ Starting PostgreSQL..."
docker-compose up -d postgres

# Wait for PostgreSQL to be fully ready
echo "⏳ Waiting for PostgreSQL to initialize..."
max_attempts=60
attempt=0
while ! docker-compose exec -T postgres pg_isready -U $POSTGRES_USER -d $POSTGRES_DB > /dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ $attempt -eq $max_attempts ]; then
        echo "❌ PostgreSQL failed to start"
        echo "Checking logs..."
        docker-compose logs postgres
        exit 1
    fi
    echo -n "."
    sleep 2
done
echo ""

# Give PostgreSQL extra time to complete initialization
echo "⏳ Waiting for database initialization to complete..."
sleep 10

# Verify roles were created
echo "🔍 Verifying database roles..."
ROLES_CHECK=$(docker-compose exec -T postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -t -c "SELECT COUNT(*) FROM pg_roles WHERE rolname IN ('authenticator', 'anon', 'authenticated', 'service_role', 'n8n_user');" 2>/dev/null || echo "0")
ROLES_COUNT=$(echo $ROLES_CHECK | tr -d ' ')

if [ "$ROLES_COUNT" -lt "5" ]; then
    echo "⚠️ Some roles were not created. Checking PostgreSQL logs..."
    docker-compose logs --tail=50 postgres
    echo ""
    echo "❌ Database initialization failed. Please check the logs above."
    exit 1
fi

echo "✅ Database roles verified"

# Start Redis
echo "🏗️ Starting Redis..."
docker-compose up -d redis

# Wait for Redis
echo "⏳ Waiting for Redis..."
max_attempts=30
attempt=0
while ! docker-compose exec -T redis redis-cli -a $REDIS_PASSWORD ping > /dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ $attempt -eq $max_attempts ]; then
        echo "❌ Redis failed to start"
        exit 1
    fi
    echo -n "."
    sleep 1
done
echo ""

# Start remaining services
echo "🏗️ Starting all services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 15

# Check services health
echo "🏥 Checking services health..."
./scripts/check-health.sh

echo ""
echo "✅ Platform started successfully!"
echo ""
echo "🌐 Access points:"
echo "   - n8n: http://localhost:${N8N_PORT:-5678}"
echo "   - n8n (domain): ${N8N_PROTOCOL}://${N8N_HOST}"
echo "   - API: http://localhost/api/rest/v1/"
echo ""
echo "🔑 Default credentials:"
echo "   - n8n: ${N8N_USER} / ${N8N_PASSWORD}"
echo ""
echo "📚 API Documentation: http://localhost/api/rest/v1/"
echo ""
echo "💡 Tips:"
echo "   - Check logs: docker-compose logs -f [service]"
echo "   - Stop platform: docker-compose down"
echo "   - Reset everything: ./scripts/reset.sh"
echo ""
echo "⚠️  Troubleshooting:"
echo "   - If services fail to start, check: docker-compose logs [service]"
echo "   - For database issues: docker-compose logs postgres"
echo "   - For auth issues: docker-compose logs auth rest"