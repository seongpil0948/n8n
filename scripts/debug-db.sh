#!/bin/bash

# Database debugging script

echo "🔍 Checking PostgreSQL roles and databases..."

# Source environment variables
set -a
source .env
set +a

# Check if PostgreSQL is running
if ! docker-compose ps | grep -q "vector_postgres.*Up"; then
    echo "❌ PostgreSQL is not running"
    exit 1
fi

echo ""
echo "📋 Existing Roles:"
docker-compose exec -T postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "\du" 2>/dev/null || echo "Failed to list roles"

echo ""
echo "📋 Existing Databases:"
docker-compose exec -T postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "\l" 2>/dev/null || echo "Failed to list databases"

echo ""
echo "🔍 Checking specific roles:"
for role in authenticator anon authenticated service_role n8n_user supabase_admin supabase_auth_admin; do
    EXISTS=$(docker-compose exec -T postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -t -c "SELECT 1 FROM pg_roles WHERE rolname='$role';" 2>/dev/null || echo "0")
    if [ "$(echo $EXISTS | tr -d ' ')" = "1" ]; then
        echo "✅ Role '$role' exists"
    else
        echo "❌ Role '$role' is missing"
    fi
done

echo ""
echo "🔍 Checking n8n database access:"
docker-compose exec -T postgres psql -U $POSTGRES_USER -c "\c n8n" -c "SELECT current_user, current_database();" 2>/dev/null || echo "❌ Cannot connect to n8n database"

echo ""
echo "🔍 Checking extensions:"
docker-compose exec -T postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT extname, extversion FROM pg_extension ORDER BY extname;" 2>/dev/null || echo "Failed to list extensions"

echo ""
echo "📋 Recent PostgreSQL logs:"
docker-compose logs --tail=20 postgres 2>/dev/null | grep -E "(ERROR|FATAL|WARNING|NOTICE)" || echo "No recent errors found"

echo ""
echo "✅ Debug information collected"