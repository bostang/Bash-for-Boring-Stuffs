#!/bin/bash

echo "🚀 Starting Data Injection and Kibana Setup..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
KIBANA_URL="http://localhost:5601"
ELASTICSEARCH_URL="http://localhost:9200"

# Function to wait for service
wait_for_service() {
    local service_url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    echo -e "${YELLOW}⏳ Waiting for $service_name to be ready...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$service_url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name is ready!${NC}"
            return 0
        fi
        echo "   Attempt $attempt/$max_attempts - waiting..."
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ $service_name failed to start after $max_attempts attempts${NC}"
    return 1
}

# Function to generate sample traffic
generate_traffic() {
    echo -e "${YELLOW}📊 Generating sample traffic...${NC}"
    
    # Generate traffic to nginx
    for i in {1..50}; do
        # Mix of successful and error requests
        if [ $((i % 10)) -eq 0 ]; then
            # Generate 404 errors
            curl -s http://localhost:8080/nonexistent-page > /dev/null 2>&1
        elif [ $((i % 15)) -eq 0 ]; then
            # Generate different response codes
            curl -s http://localhost:8080/api/error > /dev/null 2>&1
        else
            # Normal requests
            curl -s http://localhost:8080/ > /dev/null 2>&1
        fi
        
        # Generate traffic to sample app
        if [ $((i % 5)) -eq 0 ]; then
            curl -s http://localhost:3000/api/test > /dev/null 2>&1
        else
            curl -s http://localhost:3000/ > /dev/null 2>&1
        fi
        
        # Small delay to spread requests over time
        sleep 0.1
    done
    
    echo -e "${GREEN}✅ Generated 100+ sample requests${NC}"
}

# Function to create Elasticsearch index template
create_index_template() {
    echo -e "${YELLOW}🔧 Creating Elasticsearch index template...${NC}"
    
    curl -X PUT "$ELASTICSEARCH_URL/_index_template/logs-template" \
         -H "Content-Type: application/json" \
         -d '{
           "index_patterns": ["logs-*"],
           "template": {
             "settings": {
               "number_of_shards": 1,
               "number_of_replicas": 0
             },
             "mappings": {
               "properties": {
                 "@timestamp": {
                   "type": "date"
                 },
                 "service": {
                   "type": "keyword"
                 },
                 "message": {
                   "type": "text"
                 },
                 "level": {
                   "type": "keyword"
                 },
                 "host": {
                   "type": "keyword"
                 },
                 "path": {
                   "type": "text",
                   "fields": {
                     "keyword": {
                       "type": "keyword"
                     }
                   }
                 },
                 "status": {
                   "type": "integer"
                 },
                 "response_time": {
                   "type": "float"
                 },
                 "method": {
                   "type": "keyword"
                 },
                 "user_agent": {
                   "type": "text",
                   "fields": {
                     "keyword": {
                       "type": "keyword"
                     }
                   }
                 },
                 "remote_ip": {
                   "type": "ip"
                 },
                 "bytes": {
                   "type": "long"
                 }
               }
             }
           }
         }' > /dev/null 2>&1
    
    echo -e "${GREEN}✅ Index template created${NC}"
}

# Function to inject sample data directly to Elasticsearch
inject_sample_data() {
    echo -e "${YELLOW}💉 Injecting sample log data...${NC}"
    
    # Current timestamp
    current_time=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    
    # Sample log entries
    cat << EOF > /tmp/sample_logs.json
{"index":{"_index":"logs-nginx-$(date +%Y.%m.%d)"}}
{"@timestamp":"$current_time","service":"nginx","message":"GET / HTTP/1.1","level":"info","host":"nginx-demo","path":"/","status":200,"response_time":0.05,"method":"GET","user_agent":"curl/7.68.0","remote_ip":"172.18.0.1","bytes":1234}
{"index":{"_index":"logs-nginx-$(date +%Y.%m.%d)"}}
{"@timestamp":"$(date -u -d '1 minute ago' +"%Y-%m-%dT%H:%M:%S.000Z")","service":"nginx","message":"GET /api/users HTTP/1.1","level":"info","host":"nginx-demo","path":"/api/users","status":200,"response_time":0.12,"method":"GET","user_agent":"curl/7.68.0","remote_ip":"172.18.0.2","bytes":2048}
{"index":{"_index":"logs-nginx-$(date +%Y.%m.%d)"}}
{"@timestamp":"$(date -u -d '2 minutes ago' +"%Y-%m-%dT%H:%M:%S.000Z")","service":"nginx","message":"GET /nonexistent HTTP/1.1","level":"error","host":"nginx-demo","path":"/nonexistent","status":404,"response_time":0.02,"method":"GET","user_agent":"curl/7.68.0","remote_ip":"172.18.0.3","bytes":162}
{"index":{"_index":"logs-app-$(date +%Y.%m.%d)"}}
{"@timestamp":"$current_time","service":"sample-app","message":"User login successful","level":"info","host":"sample-app","path":"/login","status":200,"response_time":0.25,"method":"POST","user_agent":"Mozilla/5.0","remote_ip":"172.18.0.4","bytes":512}
{"index":{"_index":"logs-app-$(date +%Y.%m.%d)"}}
{"@timestamp":"$(date -u -d '30 seconds ago' +"%Y-%m-%dT%H:%M:%S.000Z")","service":"sample-app","message":"Database connection error","level":"error","host":"sample-app","path":"/api/data","status":500,"response_time":2.1,"method":"GET","user_agent":"Mozilla/5.0","remote_ip":"172.18.0.5","bytes":256}
{"index":{"_index":"logs-generator-$(date +%Y.%m.%d)"}}
{"@timestamp":"$current_time","service":"log-generator","message":"Processing batch job","level":"info","host":"log-generator","path":"/batch","status":200,"response_time":1.5,"method":"POST","user_agent":"internal","remote_ip":"127.0.0.1","bytes":1024}
EOF

    # Inject the data
    curl -X POST "$ELASTICSEARCH_URL/_bulk" \
         -H "Content-Type: application/x-ndjson" \
         --data-binary @/tmp/sample_logs.json > /dev/null 2>&1
    
    # Add more diverse data
    for i in {1..50}; do
        timestamp=$(date -u -d "$i minutes ago" +"%Y-%m-%dT%H:%M:%S.000Z")
        status_codes=(200 200 200 200 404 500 301 403)
        services=("nginx" "sample-app" "log-generator")
        levels=("info" "info" "info" "warn" "error")
        
        status=${status_codes[$((RANDOM % ${#status_codes[@]}))]}
        service=${services[$((RANDOM % ${#services[@]}))]}
        level=${levels[$((RANDOM % ${#levels[@]}))]}
        response_time=$(awk "BEGIN {printf \"%.3f\", $RANDOM / 10000}")
        
        cat << EOF > /tmp/single_log.json
{"index":{"_index":"logs-$service-$(date +%Y.%m.%d)"}}
{"@timestamp":"$timestamp","service":"$service","message":"Sample log entry $i","level":"$level","host":"$service","path":"/api/endpoint$i","status":$status,"response_time":$response_time,"method":"GET","user_agent":"curl/7.68.0","remote_ip":"172.18.0.$((RANDOM % 254 + 1))","bytes":$((RANDOM % 5000 + 100))}
EOF
        
        curl -X POST "$ELASTICSEARCH_URL/_bulk" \
             -H "Content-Type: application/x-ndjson" \
             --data-binary @/tmp/single_log.json > /dev/null 2>&1
    done
    
    rm -f /tmp/sample_logs.json /tmp/single_log.json
    echo -e "${GREEN}✅ Sample data injected into Elasticsearch${NC}"
}

# Function to create Kibana data view
create_kibana_data_view() {
    echo -e "${YELLOW}🔍 Creating Kibana data view...${NC}"
    
    # Wait a bit for Kibana to be fully ready
    sleep 5
    
    # Create the data view
    curl -X POST "$KIBANA_URL/api/data_views/data_view" \
         -H "Content-Type: application/json" \
         -H "kbn-xsrf: true" \
         -d '{
           "data_view": {
             "title": "logs-*",
             "name": "Logs Data View",
             "timeFieldName": "@timestamp"
           }
         }' > /dev/null 2>&1
    
    echo -e "${GREEN}✅ Kibana data view 'logs-*' created${NC}"
}

# Function to refresh indices
refresh_indices() {
    echo -e "${YELLOW}🔄 Refreshing Elasticsearch indices...${NC}"
    curl -X POST "$ELASTICSEARCH_URL/logs-*/_refresh" > /dev/null 2>&1
    echo -e "${GREEN}✅ Indices refreshed${NC}"
}

# Function to show summary
show_summary() {
    echo -e "\n${GREEN}🎉 Setup Complete!${NC}"
    echo -e "\n📊 ${YELLOW}Access your services:${NC}"
    echo -e "   • Kibana: http://localhost:5601"
    echo -e "   • Elasticsearch: http://localhost:9200"
    echo -e "   • Sample App: http://localhost:3000"
    echo -e "   • Nginx Demo: http://localhost:8080"
    echo -e "\n🔍 ${YELLOW}In Kibana:${NC}"
    echo -e "   1. Go to Analytics > Discover"
    echo -e "   2. Select 'logs-*' data view"
    echo -e "   3. You should see the injected log data"
    echo -e "   4. Go to Analytics > Dashboard to view your dashboard"
    echo -e "\n📈 ${YELLOW}Sample data includes:${NC}"
    echo -e "   • HTTP requests with various status codes"
    echo -e "   • Response times for performance analysis"
    echo -e "   • Error logs for monitoring"
    echo -e "   • Multiple services (nginx, sample-app, log-generator)"
}

# Main execution
main() {
    echo -e "${YELLOW}🔧 ELK Stack Data Injection Setup${NC}"
    echo -e "This script will:"
    echo -e "  1. Wait for services to be ready"
    echo -e "  2. Create index templates"
    echo -e "  3. Generate traffic"
    echo -e "  4. Inject sample data"
    echo -e "  5. Create Kibana data views"
    echo -e "  6. Refresh indices"
    echo ""
    
    # Wait for services
    wait_for_service "$ELASTICSEARCH_URL" "Elasticsearch" || exit 1
    wait_for_service "$KIBANA_URL/api/status" "Kibana" || exit 1
    
    # Setup sequence
    create_index_template
    sleep 2
    
    generate_traffic
    sleep 2
    
    inject_sample_data
    sleep 3
    
    create_kibana_data_view
    sleep 2
    
    refresh_indices
    
    show_summary
}

# Run main function
main 