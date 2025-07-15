#!/bin/bash

set -e

echo "📊 Setting up Kibana Index Patterns and Dashboards"
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

KIBANA_URL="http://localhost:5601"
ELASTICSEARCH_URL="http://localhost:9200"

# Wait for Kibana to be ready
print_status "Waiting for Kibana to be ready..."
timeout=120
elapsed=0
while ! curl -s "$KIBANA_URL/api/status" > /dev/null 2>&1; do
    if [ $elapsed -ge $timeout ]; then
        print_error "Kibana is not responding after $timeout seconds"
        exit 1
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    echo -n "."
done
echo
print_status "Kibana is ready"

# Function to create index pattern
create_index_pattern() {
    local pattern=$1
    local title=$2
    
    print_status "Creating index pattern: $pattern"
    
    curl -s -X POST "$KIBANA_URL/api/data_views/data_view" \
         -H "Content-Type: application/json" \
         -H "kbn-xsrf: true" \
         -d "{
           \"data_view\": {
             \"title\": \"$pattern\",
             \"name\": \"$title\",
             \"timeFieldName\": \"@timestamp\"
           }
         }" > /dev/null 2>&1 || print_warning "Index pattern $pattern might already exist"
}

# Wait for some data to be indexed
print_status "Waiting for data to be indexed..."
sleep 15

# Check if indices exist
print_status "Checking available indices..."
indices=$(curl -s "$ELASTICSEARCH_URL/_cat/indices?format=json" | grep -o '"index":"[^"]*logs[^"]*"' | sed 's/"index":"//g' | sed 's/"//g' || echo "")

if [ -z "$indices" ]; then
    print_warning "No log indices found yet. You may need to wait longer or generate more traffic."
    print_warning "Run: ./scripts/generate-traffic.sh"
else
    print_status "Found indices: $indices"
fi

# Create index patterns
create_index_pattern "logs-*" "All Logs"
create_index_pattern "logs-nginx-*" "Nginx Logs"
create_index_pattern "logs-application-*" "Application Logs"
create_index_pattern "logs-generator-*" "Generated Logs"

# Create saved searches
print_status "Creating saved searches..."

# Error logs search
curl -s -X POST "$KIBANA_URL/api/saved_objects/search" \
     -H "Content-Type: application/json" \
     -H "kbn-xsrf: true" \
     -d '{
       "attributes": {
         "title": "Error Logs",
         "description": "All error level logs",
         "hits": 0,
         "columns": ["@timestamp", "level", "message", "service"],
         "sort": [["@timestamp", "desc"]],
         "kibanaSavedObjectMeta": {
           "searchSourceJSON": "{\"query\":{\"bool\":{\"must\":[{\"match\":{\"level\":\"ERROR\"}}]}},\"filter\":[],\"index\":\"logs-*\"}"
         }
       }
     }' > /dev/null 2>&1 || print_warning "Error logs search might already exist"

# High response time search
curl -s -X POST "$KIBANA_URL/api/saved_objects/search" \
     -H "Content-Type: application/json" \
     -H "kbn-xsrf: true" \
     -d '{
       "attributes": {
         "title": "Slow Requests",
         "description": "Requests with response time > 1000ms",
         "hits": 0,
         "columns": ["@timestamp", "response_time", "url", "status_code"],
         "sort": [["response_time", "desc"]],
         "kibanaSavedObjectMeta": {
           "searchSourceJSON": "{\"query\":{\"range\":{\"response_time\":{\"gt\":1000}}},\"filter\":[],\"index\":\"logs-*\"}"
         }
       }
     }' > /dev/null 2>&1 || print_warning "Slow requests search might already exist"

print_status "Index patterns and searches created successfully!"

echo
echo "📋 Kibana Setup Complete!"
echo "========================="
echo
echo "📊 Available Index Patterns:"
echo "  • logs-* (All logs)"
echo "  • logs-nginx-* (Nginx access/error logs)"
echo "  • logs-application-* (Application logs)"
echo "  • logs-generator-* (Generated demo logs)"
echo
echo "🔍 Pre-created Searches:"
echo "  • Error Logs (All ERROR level logs)"
echo "  • Slow Requests (Response time > 1000ms)"
echo
echo "📈 Recommended Kibana Workflow:"
echo "  1. Go to Discover → Select 'logs-*' index"
echo "  2. Explore your data and create filters"
echo "  3. Go to Visualize → Create charts and graphs"
echo "  4. Go to Dashboard → Combine visualizations"
echo
echo "💡 Demo Ideas:"
echo "  • Create a line chart of request count over time"
echo "  • Create a pie chart of HTTP status codes"
echo "  • Create a metric showing error rate"
echo "  • Create a data table of top error messages"
echo "  • Create a heat map of response times"
echo
echo "🌐 Open Kibana: $KIBANA_URL" 