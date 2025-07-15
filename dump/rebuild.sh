#!/bin/bash

# Rebuild JavaScript containers with fresh npm install
echo "🔄 Rebuilding JavaScript containers..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Stop JavaScript containers
print_status "Stopping JavaScript containers..."
docker-compose stop js-producer js-consumer

# Remove existing containers and images
print_status "Removing existing containers and images..."
docker-compose rm -f js-producer js-consumer
docker rmi -f demo_js-producer demo_js-consumer 2>/dev/null || true

# Remove node_modules if exists locally (to ensure clean build)
print_status "Cleaning local node_modules..."
rm -rf js-producer/node_modules js-producer/package-lock.json
rm -rf js-consumer/node_modules js-consumer/package-lock.json

# Build containers with no cache
print_status "Rebuilding containers with no cache..."
docker-compose build --no-cache js-producer js-consumer

# Start containers
print_status "Starting JavaScript containers..."
docker-compose up -d js-producer js-consumer

# Wait a moment for containers to start
sleep 5

# Check container status
print_status "Checking container status..."
docker-compose ps js-producer js-consumer

# Check logs for any errors
print_warning "Checking producer logs..."
docker-compose logs --tail=20 js-producer

print_warning "Checking consumer logs..."
docker-compose logs --tail=20 js-consumer

print_status "Rebuild completed!"
print_warning "If you still see errors, run: docker-compose logs js-producer js-consumer" 