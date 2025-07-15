#!/bin/bash

set -e

echo "🛑 Stopping Log ETL and Monitoring Demo"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Stop all containers
print_status "Stopping Docker containers..."
docker-compose down

# Ask if user wants to remove volumes (data)
echo
read -p "Do you want to remove all data (Elasticsearch indices, logs)? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Removing all volumes and data..."
    docker-compose down -v
    docker volume prune -f
    
    # Remove log files
    if [ -d "logs" ]; then
        print_warning "Removing log files..."
        rm -rf logs/*
    fi
    
    print_status "All data removed"
else
    print_status "Data preserved for next run"
fi

echo
print_status "Demo stopped successfully!" 