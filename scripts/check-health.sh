#!/bin/bash

# Health check script for all services

set -e

echo "🏥 Checking service health..."

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check function
check_service() {
    local service_name=$1
    local check_command=$2
    
    echo -n "Checking $service_name... "
    
    if eval $check_command > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Healthy${NC}"
        return 0
    else
        echo -e "${RED}✗ Unhealthy${NC}"
        return 1
    fi
}

# Check PostgreSQL
check_service "PostgreSQL" "docker-compose exec -T postgres pg_isready -U postgres"

# Check Redis
check_service "Redis" "docker-compose exec -T redis redis-cli -a \$REDIS_PASSWORD ping"

# Check n8n
check_service "n8n" "curl -s -o /dev/null -w '%{http_code}' http://localhost:5678/healthz | grep -q 200"

# Check PostgREST
check_service "PostgREST" "curl -s -o /dev/null -w '%{http_code}' http://localhost/api/rest/v1/ | grep -q 200"

# Check Auth
check_service "Supabase Auth" "docker-compose exec -T auth wget --no-verbose --tries=1 --spider http://localhost:9999/health"

# Check Storage
check_service "Supabase Storage" "docker-compose exec -T storage wget --no-verbose --tries=1 --spider http://localhost:5000/status"

# Check Realtime
check_service "Supabase Realtime" "docker-compose exec -T realtime curl -s -o /dev/null -w '%{http_code}' http://localhost:4000/api/tenants/realtime-dev/health | grep -q 200"

# Check Nginx
check_service "Nginx" "curl -s -o /dev/null -w '%{http_code}' http://localhost/health | grep -q 200"

# Database connectivity check
echo ""
echo "🔍 Checking database connectivity..."

# Check if n8n database exists
if docker-compose exec -T postgres psql -U postgres -lqt | cut -d \| -f 1 | grep -qw n8n; then
    echo -e "${GREEN}✓ n8n database exists${NC}"
else
    echo -e "${RED}✗ n8n database not found${NC}"
fi

# Check if vector extension is installed
if docker-compose exec -T postgres psql -U postgres -d postgres -c "SELECT 1 FROM pg_extension WHERE extname='vector';" | grep -q 1; then
    echo -e "${GREEN}✓ pgvector extension installed${NC}"
else
    echo -e "${RED}✗ pgvector extension not installed${NC}"
fi

echo ""
echo "✅ Health check completed!"