#!/bin/bash
set -e

# Ensure working directory matches Dockerfile
cd /rails

# Remove a pre-existing server.pid for Rails
rm -f tmp/pids/server.pid

# Wait for PostgreSQL to be ready (using DATABASE_URL)
echo "Waiting for PostgreSQL to be ready..."
until bundle exec rails db:prepare 2>/dev/null; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

echo "PostgreSQL is up - starting app..."

exec "$@"
