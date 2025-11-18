#!/usr/bin/env bash

set -e

echo "Stopping containers..."
docker compose down

echo "Removing bundle volume..."
docker volume rm commitly_bundle || echo "Volume commitly_bundle does not exist or already removed"

echo "Rebuilding and starting containers..."
docker compose up -d --build

echo "Done! Bundle has been reset and containers are running."
