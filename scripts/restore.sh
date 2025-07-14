#!/bin/bash

# Stop script if any command fails
set -e

# Resolve directory of the script, no matter where it's called from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Assume .env is in the parent of the script directory
ENV_PATH="$SCRIPT_DIR/../.env"

# If .env exists, load it
if [ -f "$ENV_PATH" ]; then
  echo "📦 Loading environment from $ENV_PATH"
  set -a
  source "$ENV_PATH"
  set +a
else
  echo "❌ .env file not found at $ENV_PATH"
  exit 1
fi

# Parse values from .env 
POSTGRES_CONTAINER_NAME="schoolranking-db"
BACKEND_CONTAINER_NAME="schoolranking-backend"
POSTGRES_USER="${PROD__POSTGRES_USER}"
POSTGRES_DB="${PROD__POSTGRES_DB}"
POSTGRES_PORT="${PROD__POSTGRES_PORT}"
BACKUP_DIR="./backups"

# Validate required environment variables
if [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_DB" ] || [ -z "$POSTGRES_PORT" ]; then
    echo "❌ Missing required environment variables: PROD__POSTGRES_USER, PROD__POSTGRES_DB, or PROD__POSTGRES_PORT"
    exit 1
fi

# Check if postgres container is running
if ! docker ps --format '{{.Names}}' | grep -q "$POSTGRES_CONTAINER_NAME"; then
    echo "❌ PostgreSQL container $POSTGRES_CONTAINER_NAME is not running"
    exit 1
fi

# Check if backend container exists (could be running or stopped)
BACKEND_EXISTS=$(docker ps -a --format '{{.Names}}' | grep -c "$BACKEND_CONTAINER_NAME" || echo "0")

# Find the latest backup by modification time
BACKUP_FILE=$(ls -1t "$BACKUP_DIR"/backup_*.sql.gz 2>/dev/null | head -n 1)
if [ -z "$BACKUP_FILE" ]; then
    echo "❌ No backup files found in $BACKUP_DIR"
    exit 1
fi

# Extract just the filename from the full path
BACKUP_FILE=$(basename "$BACKUP_FILE")

# Check if the backup file exists
if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: $BACKUP_DIR/$BACKUP_FILE"
    exit 1
fi

# Test if backup file is valid
if ! gunzip -t "$BACKUP_DIR/$BACKUP_FILE" 2>/dev/null; then
    echo "❌ Backup file is corrupted: $BACKUP_FILE"
    exit 1
fi

echo "⚠️  WARNING: This will replace your current database!"
echo "Database: $POSTGRES_DB"
echo "Backup file: $BACKUP_FILE"
if [ "$BACKEND_EXISTS" -gt 0 ]; then
    echo "Backend container: $BACKEND_CONTAINER_NAME (will be restarted)"
else
    echo "Backend container: $BACKEND_CONTAINER_NAME (not found - will skip restart)"
fi
read -p "Type 'yes' to continue: " confirm

if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Step 1: Stop backend container if it exists and is running
if [ "$BACKEND_EXISTS" -gt 0 ]; then
    if docker ps --format '{{.Names}}' | grep -q "$BACKEND_CONTAINER_NAME"; then
        echo "🛑 Stopping backend container..."
        docker stop "$BACKEND_CONTAINER_NAME"
        BACKEND_WAS_RUNNING=true
    else
        echo "📋 Backend container is already stopped"
        BACKEND_WAS_RUNNING=false
    fi
else
    echo "📋 Backend container not found, skipping stop"
    BACKEND_WAS_RUNNING=false
fi

echo "🔄 Restoring database..."

# Step 2: Terminate active connections
echo "Disconnecting active users..."
docker exec -e PGPASSWORD="$PROD__POSTGRES_PASSWORD" -i "$POSTGRES_CONTAINER_NAME" psql \
  -h localhost \
  -p "$POSTGRES_PORT" \
  -U "$POSTGRES_USER" \
  -d postgres \
  -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$POSTGRES_DB' AND pid <> pg_backend_pid();" > /dev/null 2>&1 || true

# Step 3: Drop and recreate database
echo "Recreating database..."
docker exec -e PGPASSWORD="$PROD__POSTGRES_PASSWORD" -i "$POSTGRES_CONTAINER_NAME" psql \
  -h localhost \
  -p "$POSTGRES_PORT" \
  -U "$POSTGRES_USER" \
  -d postgres \
  -c "DROP DATABASE IF EXISTS $POSTGRES_DB;"

docker exec -e PGPASSWORD="$PROD__POSTGRES_PASSWORD" -i "$POSTGRES_CONTAINER_NAME" psql \
  -h localhost \
  -p "$POSTGRES_PORT" \
  -U "$POSTGRES_USER" \
  -d postgres \
  -c "CREATE DATABASE $POSTGRES_DB;"

# Step 4: Restore the backup
echo "Restoring backup data..."
gunzip -c "$BACKUP_DIR/$BACKUP_FILE" | docker exec -e PGPASSWORD="$PROD__POSTGRES_PASSWORD" -i "$POSTGRES_CONTAINER_NAME" psql \
  -h localhost \
  -p "$POSTGRES_PORT" \
  -U "$POSTGRES_USER" \
  -d "$POSTGRES_DB"


# Check if restore was successful
if [ $? -eq 0 ]; then
    echo "✅ Database restored successfully!"
else
    echo "❌ Database restore failed"
    exit 1
fi

# Step 5: Restart backend container if it was running
if [ "$BACKEND_EXISTS" -gt 0 ]; then
    if [ "$BACKEND_WAS_RUNNING" = true ]; then
        echo "🔄 Starting backend container..."
        docker start "$BACKEND_CONTAINER_NAME"
        
        # Wait a moment for the container to start
        sleep 2
        
        # Check if backend started successfully
        if docker ps --format '{{.Names}}' | grep -q "$BACKEND_CONTAINER_NAME"; then
            echo "✅ Backend container started successfully!"
        else
            echo "⚠️  Backend container failed to start. Check logs with: docker logs $BACKEND_CONTAINER_NAME"
        fi
    else
        echo "📋 Backend container was not running before, leaving it stopped"
    fi
fi

GREEN='\033[0;32m'
NC='\033[0m' 
echo -e "${GREEN}🎉 Database restore completed!${NC}"
echo "Next steps:"
echo "  - Check your application logs: docker logs $BACKEND_CONTAINER_NAME"
echo "  - Test your application endpoints"