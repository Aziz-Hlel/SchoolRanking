#!/bin/bash


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
POSTGRES_CONTAINER_NAME="schoolranking-db"  #  ? Change if dynamic
POSTGRES_USER="${STAGE__POSTGRES_USER}"
POSTGRES_PASSWORD="${STAGE__POSTGRES_PASSWORD}"
POSTGRES_DB="${STAGE__POSTGRES_DB}"
POSTGRES_PORT="${STAGE__POSTGRES_PORT}"
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d)
BACKUP_FILE="backup_${DATE}.sql.gz"

#  Validation
: "${POSTGRES_USER:?Missing POSTGRES_USER}"
: "${POSTGRES_DB:?Missing POSTGRES_DB}"
: "${POSTGRES_PORT:?Missing POSTGRES_PORT}"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"


echo "📦 Starting backup for database: $POSTGRES_DB on port $POSTGRES_PORT..."
# Backup using docker exec and gzip compression
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRES_CONTAINER_NAME" pg_dump \
  -h "$POSTGRES_CONTAINER_NAME" \
  -p "$POSTGRES_PORT" \
  -U "$POSTGRES_USER" \
  -d "$POSTGRES_DB" \
  --clean --if-exists --create \
  | gzip > "$BACKUP_DIR/$BACKUP_FILE"






# Validate backup file and clean up old backups
if [ -f "$BACKUP_DIR/$BACKUP_FILE" ] && [ -s "$BACKUP_DIR/$BACKUP_FILE" ]; then
    echo "✅ Backup created successfully: $BACKUP_FILE"

    # Cleanup old backups
    find "$BACKUP_DIR" -name "backup_*.sql.gz" -type f -mtime +7 -delete
    echo "🧹 Old backups cleaned up."

    # List current backups
    echo "📁 Current backups:"
    ls -lah "$BACKUP_DIR"/backup_*.sql.gz
else
    echo "❌ Backup failed!"
    exit 1
fi


GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}✅ Backup completed successfully.${NC}"
