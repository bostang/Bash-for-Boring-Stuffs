#!/bin/bash

set -e

echo "🚀 Starting Log ETL and Monitoring Demo"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose > /dev/null 2>&1; then
    print_error "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Create logs directories
print_step "Creating log directories..."
mkdir -p logs/{app,nginx,generator}
print_status "Log directories created"

# Stop any existing containers
print_step "Stopping existing containers..."
docker-compose down > /dev/null 2>&1 || true
print_status "Stopped existing containers"

# Pull the latest images
print_step "Pulling Docker images..."
docker-compose pull

# Build custom applications
print_step "Building sample applications..."
docker-compose build

# Start the services
print_step "Starting ELK stack and applications..."
docker-compose up -d

# Wait for services to be healthy
print_step "Waiting for services to be ready..."

# Wait for Elasticsearch
print_status "Waiting for Elasticsearch..."
timeout=300
elapsed=0
while ! curl -s http://localhost:9200/_cluster/health > /dev/null 2>&1; do
    if [ $elapsed -ge $timeout ]; then
        print_error "Elasticsearch failed to start within $timeout seconds"
        exit 1
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    echo -n "."
done
echo
print_status "Elasticsearch is ready"

# Wait for Kibana
print_status "Waiting for Kibana..."
timeout=300
elapsed=0
while ! curl -s http://localhost:5601/api/status > /dev/null 2>&1; do
    if [ $elapsed -ge $timeout ]; then
        print_error "Kibana failed to start within $timeout seconds"
        exit 1
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    echo -n "."
done
echo
print_status "Kibana is ready"

# Wait for sample app
print_status "Waiting for sample application..."
timeout=60
elapsed=0
while ! curl -s http://localhost:3000/health > /dev/null 2>&1; do
    if [ $elapsed -ge $timeout ]; then
        print_warning "Sample application might not be ready yet"
        break
    fi
    sleep 2
    elapsed=$((elapsed + 2))
    echo -n "."
done
echo
print_status "Sample application is ready"

# Generate some initial traffic
print_step "Generating initial traffic and logs..."
for i in {1..10}; do
    curl -s http://localhost:3000/ > /dev/null 2>&1 || true
    curl -s http://localhost:3000/api/users > /dev/null 2>&1 || true
    curl -s http://localhost:8080/ > /dev/null 2>&1 || true
    sleep 1
done

# Create Kibana index patterns (after some data is available)
sleep 10
print_step "Setting up Kibana index patterns..."
./scripts/setup-kibana.sh

echo
echo "🎉 Demo environment is ready!"
echo "==============================="
echo
echo "📊 Access Points:"
echo "  • Kibana Dashboard: http://localhost:5601"
echo "  • Sample Application: http://localhost:3000"
echo "  • Nginx Demo: http://localhost:8080"
echo "  • Elasticsearch: http://localhost:9200"
echo
echo "📋 Available Scripts:"
echo "  • Generate traffic: ./scripts/generate-traffic.sh"
echo "  • View logs: ./scripts/view-logs.sh"
echo "  • Stop demo: ./scripts/stop-demo.sh"
echo "  • Setup Kibana: ./scripts/setup-kibana.sh"
echo
echo "📝 Next steps:"
echo "  1. Open Kibana at http://localhost:5601"
echo "  2. Go to 'Discover' to explore logs"
echo "  3. Create visualizations and dashboards"
echo "  4. Run traffic generator for more data"
echo
print_status "Demo started successfully!" 