#!/bin/bash

# Demo Kafka Spark Streaming - Startup Script
# Author: Streaming Demo
# Description: Launches complete streaming pipeline demo

set -e

echo "🚀 Starting Kafka Spark Streaming Demo..."
echo "=========================================="

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

print_header() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    print_error "docker-compose is not installed. Please install docker-compose first."
    exit 1
fi

# Create necessary directories
print_header "Creating necessary directories..."
mkdir -p data
mkdir -p data/checkpoints
mkdir -p data/checkpoints/alerts
mkdir -p data/checkpoints/processed
print_status "Directories created successfully"

# Stop any existing containers
print_header "Cleaning up existing containers..."
docker-compose down --remove-orphans 2>/dev/null || true
print_status "Cleanup completed"

# Build and start services
print_header "Building and starting services..."
docker-compose up --build -d

# Wait for services to be ready
print_header "Waiting for services to be ready..."

# Function to wait for service
wait_for_service() {
    local service_name=$1
    local max_attempts=$2
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose ps | grep -q "$service_name.*Up"; then
            print_status "$service_name is ready!"
            return 0
        fi
        echo "Waiting for $service_name... (attempt $attempt/$max_attempts)"
        sleep 5
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to start within expected time"
    return 1
}

# Wait for core services
wait_for_service "demo_zookeeper" 12
wait_for_service "demo_kafka" 20
wait_for_service "demo_spark_master" 15

print_status "Core services are ready!"

# Start JavaScript producer and consumer
print_header "Starting JavaScript components..."
docker-compose up -d js-producer js-consumer

# Wait a bit for JavaScript services
sleep 10

print_status "JavaScript producer and consumer started!"

# Display service information
print_header "Service Information:"
echo "📊 Spark Master UI:      http://localhost:8080"
echo "👷 Spark Worker UI:      http://localhost:8081"
echo "🔍 Spark Application UI: http://localhost:4040"
echo "📡 Kafka Topics:"
echo "   - user-events      (input events from JS producer)"
echo "   - processed-events (processed data from Spark)"
echo "   - alerts          (anomaly alerts from Spark)"

# Show container status
print_header "Container Status:"
docker-compose ps

echo ""
echo "🎉 Demo started successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Wait for data to flow (JS producer generates events automatically)"
echo "2. Start Spark streaming job: ./run_spark.sh"
echo "3. Monitor logs: ./monitor.sh"
echo "4. Stop demo: ./stop.sh"
echo ""
echo "📚 Check the data directory for consumer statistics and processed data" 