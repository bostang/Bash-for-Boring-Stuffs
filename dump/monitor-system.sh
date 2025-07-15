#!/bin/bash

echo "🖥️  Linux System Monitoring for ELK Stack Demo"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_metric() {
    echo -e "${GREEN}[METRIC]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_critical() {
    echo -e "${RED}[CRITICAL]${NC} $1"
}

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "This script is optimized for Linux systems."
    exit 1
fi

# Function to get container stats
get_container_stats() {
    local container_name=$1
    if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        local stats=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}" "$container_name")
        echo "$stats" | tail -n +2
    else
        echo "$container_name: NOT RUNNING"
    fi
}

# Function to check service health
check_service_health() {
    local service_name=$1
    local url=$2
    
    if curl -s "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $service_name"
    else
        echo -e "${RED}✗${NC} $service_name"
    fi
}

# System Overview
print_header "System Overview"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo "Current User: $(whoami)"
echo "Date: $(date)"
echo

# OS Information
print_header "Linux Distribution"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "OS: $NAME"
    echo "Version: $VERSION"
    echo "ID: $ID"
else
    echo "Could not determine Linux distribution"
fi
echo

# CPU Information
print_header "CPU Information"
CPU_CORES=$(nproc)
CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
echo "CPU Model: $CPU_MODEL"
echo "CPU Cores: $CPU_CORES"

# CPU usage per core
if command -v mpstat > /dev/null 2>&1; then
    echo "CPU Usage per core:"
    mpstat -P ALL 1 1 | grep -v "^$" | tail -n +4
else
    echo "Install sysstat package for detailed CPU statistics"
fi
echo

# Memory Information
print_header "Memory Information"
if command -v free > /dev/null 2>&1; then
    free -h
    
    # Memory usage warnings
    MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "$MEMORY_USAGE" -gt 90 ]; then
        print_critical "Memory usage is at ${MEMORY_USAGE}%"
    elif [ "$MEMORY_USAGE" -gt 80 ]; then
        print_warning "Memory usage is at ${MEMORY_USAGE}%"
    else
        print_metric "Memory usage is at ${MEMORY_USAGE}%"
    fi
fi
echo

# Disk Information
print_header "Disk Usage"
df -h | grep -E "(Filesystem|/dev/)"

# Check disk usage warnings
DISK_USAGE=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    print_critical "Root disk usage is at ${DISK_USAGE}%"
elif [ "$DISK_USAGE" -gt 80 ]; then
    print_warning "Root disk usage is at ${DISK_USAGE}%"
else
    print_metric "Root disk usage is at ${DISK_USAGE}%"
fi
echo

# Network Information
print_header "Network Information"
echo "Active network interfaces:"
ip -brief addr show | grep UP
echo
echo "Network connections:"
ss -tuln | grep -E "(5601|9200|3000|8080|6379)" | head -10
echo

# Docker Information
print_header "Docker Status"
if command -v docker > /dev/null 2>&1; then
    echo "Docker Version: $(docker --version)"
    echo "Docker Status: $(systemctl is-active docker 2>/dev/null || echo 'Unknown')"
    
    # Docker system info
    echo
    echo "Docker System Information:"
    docker system df
    
    echo
    echo "Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    print_critical "Docker is not installed"
fi
echo

# ELK Stack Services Health Check
print_header "ELK Stack Services Health"
check_service_health "Elasticsearch" "http://localhost:9200/_cluster/health"
check_service_health "Kibana" "http://localhost:5601/api/status"
check_service_health "Sample Application" "http://localhost:3000/health"
check_service_health "Nginx" "http://localhost:8080/"

# Check Redis if available
if docker ps --format "{{.Names}}" | grep -q redis; then
    if timeout 5 bash -c "</dev/tcp/localhost/6379" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Redis"
    else
        echo -e "${RED}✗${NC} Redis"
    fi
fi
echo

# Container Resource Usage
print_header "Container Resource Usage"
echo "Container Stats (Live):"
echo "CONTAINER         CPU %     MEM USAGE / LIMIT     MEM %     NET I/O"
echo "--------------------------------------------------------------------------------"

containers=("elasticsearch" "logstash" "kibana" "sample-app" "log-generator" "nginx-demo" "filebeat")
for container in "${containers[@]}"; do
    get_container_stats "$container"
done

# Check for Redis container
if docker ps --format "{{.Names}}" | grep -q redis; then
    get_container_stats "redis-cache"
fi
echo

# Elasticsearch Specific Checks
print_header "Elasticsearch Health Details"
if curl -s http://localhost:9200/_cluster/health > /dev/null 2>&1; then
    echo "Cluster Health:"
    curl -s http://localhost:9200/_cluster/health?pretty | jq -r '
        "Status: \(.status)",
        "Nodes: \(.number_of_nodes)",
        "Data Nodes: \(.number_of_data_nodes)",
        "Active Shards: \(.active_shards)",
        "Relocating Shards: \(.relocating_shards)",
        "Initializing Shards: \(.initializing_shards)",
        "Unassigned Shards: \(.unassigned_shards)"
    ' 2>/dev/null || curl -s http://localhost:9200/_cluster/health
    
    echo
    echo "Indices:"
    curl -s http://localhost:9200/_cat/indices?v 2>/dev/null | head -10
    
    echo
    echo "Node Stats:"
    curl -s http://localhost:9200/_nodes/stats?pretty | jq -r '
        .nodes[] | 
        "JVM Heap Used: \(.jvm.mem.heap_used_percent)%",
        "JVM Heap Max: \(.jvm.mem.heap_max_in_bytes / 1024 / 1024 | floor)MB",
        "OS Memory: \(.os.mem.used_percent)%"
    ' 2>/dev/null | head -10
else
    print_critical "Elasticsearch is not responding"
fi
echo

# System Processes
print_header "Top CPU/Memory Processes"
echo "Top 10 processes by CPU usage:"
ps aux --sort=-%cpu | head -11

echo
echo "Top 10 processes by Memory usage:"
ps aux --sort=-%mem | head -11
echo

# Log file sizes
print_header "Log File Sizes"
if [ -d "logs" ]; then
    echo "Demo log files:"
    find logs -name "*.log" -exec ls -lh {} \; 2>/dev/null | awk '{print $5, $9}' | sort -hr
else
    echo "No logs directory found"
fi
echo

# System limits that affect Elasticsearch
print_header "System Limits (Important for Elasticsearch)"
echo "vm.max_map_count: $(sysctl -n vm.max_map_count 2>/dev/null || echo 'Unable to read')"
echo "File descriptor limits:"
ulimit -n
echo "Max processes:"
ulimit -u
echo

# Network port usage
print_header "ELK Stack Port Usage"
echo "Port usage for ELK stack:"
netstat -tuln 2>/dev/null | grep -E "(9200|5601|5044|3000|8080|6379)" || ss -tuln | grep -E "(9200|5601|5044|3000|8080|6379)"
echo

# Performance recommendations
print_header "Performance Recommendations"

# Check memory
TOTAL_MEM_GB=$(free -g | awk 'NR==2{print $2}')
if [ "$TOTAL_MEM_GB" -lt 8 ]; then
    print_warning "Consider upgrading to at least 8GB RAM for optimal performance"
fi

# Check CPU
if [ "$CPU_CORES" -lt 4 ]; then
    print_warning "Consider upgrading to at least 4 CPU cores for optimal performance"
fi

# Check swap
SWAP_USAGE=$(free | awk 'NR==3{if($2>0) printf "%.0f", $3*100/$2; else print "0"}')
if [ "$SWAP_USAGE" -gt 10 ]; then
    print_warning "Swap usage is at ${SWAP_USAGE}%. Consider adding more RAM."
fi

# Check vm.max_map_count
MAX_MAP_COUNT=$(sysctl -n vm.max_map_count 2>/dev/null || echo "0")
if [ "$MAX_MAP_COUNT" -lt 262144 ]; then
    print_warning "vm.max_map_count should be at least 262144 for Elasticsearch"
    echo "Run: sudo sysctl -w vm.max_map_count=262144"
fi

echo
print_header "Monitoring Complete"
echo "For continuous monitoring, consider installing:"
echo "- htop (interactive process viewer)"
echo "- iotop (I/O monitoring)"
echo "- nethogs (network monitoring per process)"
echo "- glances (all-in-one monitoring tool)"
echo
echo "Install with: sudo apt install htop iotop nethogs glances"
echo "Or: sudo yum install htop iotop nethogs glances" 