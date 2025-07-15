#!/bin/bash

# Enhanced Elasticsearch sample data script for Linux
# Author: Generated for Linux optimization
# Date: $(date)

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if curl is available
if ! command -v curl &> /dev/null; then
    error "curl is not installed. Please install curl first."
    exit 1
fi

# Check if jq is available (optional but helpful)
if command -v jq &> /dev/null; then
    USE_JQ=true
    log "jq found - will format JSON output"
else
    USE_JQ=false
    warning "jq not found - JSON output will not be formatted"
fi

# Configuration
ES_HOST="localhost:9200"
MAX_RETRIES=30
RETRY_INTERVAL=5

# Function to check Elasticsearch health
check_elasticsearch() {
    local retries=0
    log "Checking Elasticsearch health..."
    
    while [ $retries -lt $MAX_RETRIES ]; do
        if curl -s -f "http://${ES_HOST}/_cluster/health" > /dev/null 2>&1; then
            success "Elasticsearch is healthy!"
            return 0
        fi
        
        retries=$((retries + 1))
        log "Elasticsearch not ready yet. Attempt $retries/$MAX_RETRIES. Waiting ${RETRY_INTERVAL}s..."
        sleep $RETRY_INTERVAL
    done
    
    error "Elasticsearch failed to become healthy after $MAX_RETRIES attempts"
    return 1
}

# Function to create index
create_index() {
    log "Creating products index..."
    
    local response
    response=$(curl -s -w "\n%{http_code}" -X PUT "http://${ES_HOST}/products" -H "Content-Type: application/json" -d'{
        "settings": {
            "number_of_shards": 1,
            "number_of_replicas": 0,
            "refresh_interval": "1s"
        },
        "mappings": {
            "properties": {
                "name": {
                    "type": "text",
                    "analyzer": "standard"
                },
                "price": {
                    "type": "float"
                },
                "in_stock": {
                    "type": "integer"
                },
                "category": {
                    "type": "keyword"
                },
                "tags": {
                    "type": "keyword"
                },
                "created_at": {
                    "type": "date"
                }
            }
        }
    }')
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        success "Products index created successfully"
        if [ "$USE_JQ" = true ]; then
            echo "$body" | jq .
        fi
    else
        error "Failed to create index. HTTP code: $http_code"
        echo "$body"
        return 1
    fi
}

# Function to add a product
add_product() {
    local name="$1"
    local price="$2"
    local stock="$3"
    local category="$4"
    local tags="$5"
    
    log "Adding product: $name"
    
    local current_date=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local response
    response=$(curl -s -w "\n%{http_code}" -X POST "http://${ES_HOST}/products/_doc" -H "Content-Type: application/json" -d"{
        \"name\": \"$name\",
        \"price\": $price,
        \"in_stock\": $stock,
        \"category\": \"$category\",
        \"tags\": $tags,
        \"created_at\": \"$current_date\"
    }")
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        success "Added $name successfully"
        if [ "$USE_JQ" = true ]; then
            echo "$body" | jq -r '._id'
        fi
    else
        error "Failed to add $name. HTTP code: $http_code"
        echo "$body"
        return 1
    fi
}

# Function to verify data
verify_data() {
    log "Verifying indexed data..."
    
    # Refresh index first
    curl -s -X POST "http://${ES_HOST}/products/_refresh" > /dev/null
    
    local response
    response=$(curl -s "http://${ES_HOST}/products/_count")
    
    if [ "$USE_JQ" = true ]; then
        local count=$(echo "$response" | jq -r '.count')
        success "Total documents indexed: $count"
    else
        success "Data verification complete"
        echo "$response"
    fi
}

# Main execution
main() {
    log "Starting Elasticsearch sample data loading script for Linux"
    
    # Check Elasticsearch health
    if ! check_elasticsearch; then
        exit 1
    fi
    
    # Create index
    if ! create_index; then
        exit 1
    fi
    
    # Add sample products
    log "Adding sample products..."
    
    add_product "Laptop" 999.99 10 "electronics" '["computer", "work", "portable"]'
    add_product "Smartphone" 699.99 15 "electronics" '["mobile", "communication"]'
    add_product "Headphones" 149.99 8 "electronics" '["audio", "music", "wireless"]'
    add_product "Coffee Maker" 89.99 5 "kitchen" '["appliance", "morning", "beverage"]'
    add_product "Blender" 49.99 12 "kitchen" '["appliance", "cooking"]'
    add_product "Gaming Mouse" 79.99 20 "electronics" '["gaming", "computer", "precision"]'
    add_product "Mechanical Keyboard" 129.99 7 "electronics" '["gaming", "computer", "typing"]'
    add_product "Air Fryer" 159.99 6 "kitchen" '["appliance", "healthy", "cooking"]'
    
    # Verify data
    verify_data
    
    success "Sample data loading completed successfully!"
    log "You can now access:"
    log "  - Elasticsearch: http://${ES_HOST}"
    log "  - Kibana: http://localhost:5601"
}

# Trap to handle script interruption
trap 'error "Script interrupted by user"; exit 130' INT TERM

# Run main function
main "$@" 