#!/bin/bash

# HomeScope Database Setup Script
# This script creates the PostgreSQL database and runs migrations

set -e

echo "🏠 HomeScope Database Setup"
echo "============================"
echo ""

# Configuration
DB_NAME=${DB_NAME:-homescope}
DB_USER=${DB_USER:-homescope}
DB_PASS=${DB_PASS:-homescope}
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}

echo "📋 Configuration:"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo ""

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL is not installed or not in PATH"
    echo ""
    echo "Install PostgreSQL first:"
    echo "  macOS:   brew install postgresql@16"
    echo "  Ubuntu:  sudo apt install postgresql postgresql-contrib"
    exit 1
fi

echo "✅ PostgreSQL found"
echo ""

# Check if database exists
DB_EXISTS=$(psql -h $DB_HOST -p $DB_PORT -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" 2>/dev/null || echo "")

if [ "$DB_EXISTS" != "1" ]; then
    echo "📦 Creating database and user..."

    psql -h $DB_HOST -p $DB_PORT -U postgres <<EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
\c $DB_NAME
GRANT ALL ON SCHEMA public TO $DB_USER;
EOF

    echo "✅ Database created"
else
    echo "ℹ️  Database already exists"
fi

echo ""
echo "🔄 Running migrations..."
echo ""

# Run migrations
MIGRATION_FILE="$(dirname "$0")/../backend/migrations/001_create_tables.sql"

if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ Migration file not found: $MIGRATION_FILE"
    exit 1
fi

psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$MIGRATION_FILE"

echo ""
echo "✅ Migrations complete"
echo ""

# Verify tables
echo "📊 Verifying tables..."
TABLE_COUNT=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name IN ('analyses', 'leads')")

if [ "$TABLE_COUNT" = "2" ]; then
    echo "✅ Tables created successfully:"
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "\dt"
else
    echo "⚠️  Warning: Expected 2 tables, found $TABLE_COUNT"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Connection string:"
echo "  postgresql://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME"
echo ""
echo "Add this to backend/.env:"
echo "  DATABASE_URL=postgresql://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME"
echo ""
