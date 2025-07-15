#!/bin/bash

# Elasticsearch Monitoring Script

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_service() {
    local service=$1
    local port=$2
    
    if curl -s -f "http://localhost:$port" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $service is running on port $port"
        return 0
    else
        echo -e "${RED}✗${NC} $service is not responding on port $port"
        return 1
    fi
}

echo -e "${BLUE}=== Elasticsearch Monitoring ===${NC}"
echo "Timestamp: $(date)"
echo

# Check services
check_service "Elasticsearch" "9200"
check_service "Kibana" "5601"

echo

# Check Elasticsearch cluster health
if curl -s "http://localhost:9200/_cluster/health" > /dev/null 2>&1; then
    echo -e "${BLUE}Cluster Health:${NC}"
    curl -s "http://localhost:9200/_cluster/health?pretty" | jq -r '
        "Status: \(.status)",
        "Nodes: \(.number_of_nodes)",
        "Active Shards: \(.active_shards)",
        "Relocating Shards: \(.relocating_shards)",
        "Unassigned Shards: \(.unassigned_shards)"
    ' 2>/dev/null || curl -s "http://localhost:9200/_cluster/health?pretty"
    
    echo
    echo -e "${BLUE}Memory Usage:${NC}"
    curl -s "http://localhost:9200/_cat/nodes?h=name,heap.percent,ram.percent,cpu&format=json" | jq -r '
        .[] | "Heap: \(.["heap.percent"])%, RAM: \(.["ram.percent"])%, CPU: \(.cpu)%"
    ' 2>/dev/null || curl -s "http://localhost:9200/_cat/nodes?h=name,heap.percent,ram.percent,cpu&v"
fi

echo
echo -e "${BLUE}Docker Containers:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(elasticsearch|kibana)"

echo
echo -e "${BLUE}System Resources:${NC}"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3"/"$2}')"
echo "Disk: $(df -h . | awk 'NR==2 {print $3"/"$2" ("$5" used)"}')"
echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
