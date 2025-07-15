#!/bin/bash

# Run Spark Streaming Job
echo "🔥 Starting Spark Streaming Job..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if containers are running
if ! docker-compose ps | grep -q "demo_spark_master.*Up"; then
    echo "❌ Spark cluster is not running. Please run ./start.sh first"
    exit 1
fi

print_status "Submitting Spark streaming job..."

# Submit Spark job
docker exec demo_spark_master spark-submit \
    --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.3.0 \
    --driver-memory 1g \
    --executor-memory 1g \
    --executor-cores 1 \
    --total-executor-cores 2 \
    /opt/spark-apps/spark_streaming_demo.py

print_status "Spark streaming job started!"
print_warning "Check the console output above for streaming results"
print_warning "Monitor Spark UI at http://localhost:4040" 