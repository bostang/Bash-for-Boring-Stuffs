#!/bin/bash

echo "📋 View Demo Logs"
echo "=================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_menu() {
    echo -e "${BLUE}[MENU]${NC} $1"
}

# Function to show service logs
show_service_logs() {
    local service=$1
    print_status "Showing logs for: $service"
    print_status "Press Ctrl+C to stop following logs"
    echo "=================================================="
    docker-compose logs -f "$service"
}

# Function to show file logs
show_file_logs() {
    local file=$1
    if [ -f "$file" ]; then
        print_status "Showing contents of: $file"
        print_status "Press 'q' to quit, 'F' to follow"
        echo "=================================================="
        less +F "$file"
    else
        print_warning "Log file not found: $file"
        print_warning "Make sure the demo is running and generating logs"
    fi
}

# Main menu
while true; do
    echo
    print_menu "Select logs to view:"
    echo "1) Container Logs"
    echo "   a) Elasticsearch logs"
    echo "   b) Logstash logs" 
    echo "   c) Kibana logs"
    echo "   d) Sample App logs"
    echo "   e) Log Generator logs"
    echo "   f) Filebeat logs"
    echo "   g) Nginx logs"
    echo
    echo "2) File Logs"
    echo "   h) Application log files (sample-app)"
    echo "   i) Generated log files"
    echo "   j) Nginx access logs"
    echo
    echo "3) Elasticsearch Queries"
    echo "   k) View all indices"
    echo "   l) Query recent logs"
    echo "   m) Query error logs"
    echo
    echo "q) Quit"
    echo
    read -p "Enter your choice: " choice

    case $choice in
        a|A)
            show_service_logs "elasticsearch"
            ;;
        b|B)
            show_service_logs "logstash"
            ;;
        c|C)
            show_service_logs "kibana"
            ;;
        d|D)
            show_service_logs "sample-app"
            ;;
        e|E)
            show_service_logs "log-generator"
            ;;
        f|F)
            show_service_logs "filebeat"
            ;;
        g|G)
            show_service_logs "nginx-demo"
            ;;
        h|H)
            echo "Available application log files:"
            ls -la logs/app/ 2>/dev/null || print_warning "No application logs found"
            echo
            read -p "Enter filename to view (or press Enter to skip): " filename
            if [ -n "$filename" ]; then
                show_file_logs "logs/app/$filename"
            fi
            ;;
        i|I)
            echo "Available generated log files:"
            ls -la logs/generator/ 2>/dev/null || print_warning "No generated logs found"
            echo
            read -p "Enter filename to view (or press Enter to skip): " filename
            if [ -n "$filename" ]; then
                show_file_logs "logs/generator/$filename"
            fi
            ;;
        j|J)
            echo "Available nginx log files:"
            ls -la logs/nginx/ 2>/dev/null || print_warning "No nginx logs found"
            echo
            read -p "Enter filename to view (or press Enter to skip): " filename
            if [ -n "$filename" ]; then
                show_file_logs "logs/nginx/$filename"
            fi
            ;;
        k|K)
            print_status "Elasticsearch indices:"
            curl -s "http://localhost:9200/_cat/indices?v" 2>/dev/null || print_warning "Cannot connect to Elasticsearch"
            ;;
        l|L)
            print_status "Recent logs from Elasticsearch:"
            curl -s -X GET "http://localhost:9200/logs-*/_search?size=10&sort=@timestamp:desc&pretty" 2>/dev/null || print_warning "Cannot query Elasticsearch"
            ;;
        m|M)
            print_status "Recent error logs from Elasticsearch:"
            curl -s -X GET "http://localhost:9200/logs-*/_search" \
                 -H "Content-Type: application/json" \
                 -d '{
                   "size": 10,
                   "sort": [{"@timestamp": "desc"}],
                   "query": {
                     "bool": {
                       "should": [
                         {"match": {"level": "ERROR"}},
                         {"range": {"status_code": {"gte": 400}}}
                       ]
                     }
                   }
                 }' 2>/dev/null | jq '.' 2>/dev/null || print_warning "Cannot query Elasticsearch or jq not installed"
            ;;
        q|Q)
            print_status "Goodbye!"
            exit 0
            ;;
        *)
            print_warning "Invalid choice. Please try again."
            ;;
    esac
done 