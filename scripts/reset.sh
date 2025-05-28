#!/bin/bash

# Reset script for Vector Store + n8n Platform

echo "⚠️  WARNING: This will delete all data and reset the platform!"
echo "Are you sure you want to continue? (yes/no)"
read -r response

if [ "$response" != "yes" ]; then
    echo "Operation cancelled."
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "🛑 Stopping all containers..."
docker-compose down -v --remove-orphans

echo "🗑️ Removing volumes..."
docker volume rm -f \
    vector-n8n-platform_postgres_data \
    vector-n8n-platform_n8n_data \
    vector-n8n-platform_storage_data \
    vector-n8n-platform_redis_data \
    2>/dev/null || true

echo "🧹 Cleaning up directories..."
rm -rf volumes/postgres-data/*
rm -rf volumes/n8n-data/*
rm -rf volumes/storage-data/*
rm -rf volumes/vector-data/*

echo "🔄 Resetting .env file..."
if [ -f .env.example ]; then
    cp .env.example .env
    echo "✅ .env file reset from .env.example"
else
    echo "⚠️  .env.example not found"
fi

echo ""
echo "✅ Reset completed!"
echo ""
echo "To start fresh, run: ./scripts/ignite.sh"