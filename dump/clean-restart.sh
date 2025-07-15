#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Complete Kafka Environment Reset ===${NC}"

# Stop all containers
echo -e "${YELLOW}🛑 Stopping all containers...${NC}"
docker-compose down --volumes --remove-orphans

# Remove all unused Docker resources
echo -e "${YELLOW}🧹 Cleaning Docker system...${NC}"
docker system prune -f --volumes

# Remove any local checkpoint data
echo -e "${YELLOW}📁 Cleaning local data directories...${NC}"
sudo rm -rf ./spark-data/checkpoints/* 2>/dev/null || true
sudo rm -rf ./spark-data/alerts/* 2>/dev/null || true
sudo rm -rf ./spark-data/notifications/* 2>/dev/null || true
sudo rm -rf ./spark-data/sales_by_category/* 2>/dev/null || true
sudo rm -rf ./spark-data/sales_by_location/* 2>/dev/null || true
sudo rm -rf ./spark-data/top_products/* 2>/dev/null || true
sudo rm -rf ./spark-data/hourly_trends/* 2>/dev/null || true
sudo rm -rf ./spark-data/customer_segments/* 2>/dev/null || true

# Remove any Docker volumes that might still exist
echo -e "${YELLOW}🗂️ Removing any remaining volumes...${NC}"
docker volume rm $(docker volume ls -q --filter name=study-case) 2>/dev/null || true

# Wait a moment for complete cleanup
echo -e "${YELLOW}⏳ Waiting for cleanup to complete...${NC}"
sleep 5

echo -e "${GREEN}✅ Environment completely reset! Ready to start fresh.${NC}"
echo -e "${BLUE}💡 Now run: ./run.sh${NC}" 