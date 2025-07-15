#!/bin/bash

echo "🚗 Generating Traffic for Demo"
echo "==============================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if services are running
if ! curl -s http://localhost:3000/health > /dev/null 2>&1; then
    print_warning "Sample application is not responding. Make sure the demo is running."
    exit 1
fi

print_status "Starting traffic generation..."
print_status "Press Ctrl+C to stop"

# Array of endpoints for sample app
sample_app_endpoints=(
    "http://localhost:3000/"
    "http://localhost:3000/api/users"
    "http://localhost:3000/api/analytics"
    "http://localhost:3000/health"
    "http://localhost:3000/api/slow"
    "http://localhost:3000/api/random-error"
    "http://localhost:3000/api/error"
    "http://localhost:3000/nonexistent"
)

# Array of endpoints for nginx
nginx_endpoints=(
    "http://localhost:8080/"
    "http://localhost:8080/api"
    "http://localhost:8080/slow"
    "http://localhost:8080/error"
    "http://localhost:8080/nonexistent"
)

# Function to make requests
make_request() {
    local url=$1
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    echo "$(date '+%H:%M:%S') - $url -> $response_code"
}

# Traffic generation loop
counter=0
while true; do
    # Generate traffic to sample app
    endpoint=${sample_app_endpoints[$RANDOM % ${#sample_app_endpoints[@]}]}
    make_request "$endpoint"
    
    # Generate traffic to nginx (less frequently)
    if [ $((counter % 3)) -eq 0 ]; then
        nginx_endpoint=${nginx_endpoints[$RANDOM % ${#nginx_endpoints[@]}]}
        make_request "$nginx_endpoint"
    fi
    
    # Sometimes send POST requests
    if [ $((counter % 5)) -eq 0 ]; then
        echo "$(date '+%H:%M:%S') - Creating user via POST"
        curl -s -X POST http://localhost:3000/api/users \
             -H "Content-Type: application/json" \
             -d '{"name":"Test User","email":"test@example.com"}' > /dev/null 2>&1 || true
    fi
    
    counter=$((counter + 1))
    
    # Random delay between requests (1-5 seconds)
    sleep $((1 + RANDOM % 5))
done 