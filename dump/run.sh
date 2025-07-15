#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Studi Kasus: Real-Time Transaction Analytics ===${NC}"
echo -e "${BLUE}=== Kafka + Spark Streaming + Dashboard ===${NC}"

# Function to check if service is ready
check_service() {
    local service_name=$1
    local max_attempts=30
    local attempt=1
    
    echo -e "${YELLOW}🔍 Checking $service_name status...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose ps $service_name | grep -q "Up"; then
            echo -e "${GREEN}✅ $service_name is ready${NC}"
            return 0
        fi
        echo -e "${YELLOW}⏳ Waiting for $service_name... (attempt $attempt/$max_attempts)${NC}"
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ $service_name failed to start properly${NC}"
    return 1
}

# Function to wait for kafka-setup container to complete
wait_for_kafka_setup() {
    echo -e "${YELLOW}🔍 Waiting for Kafka setup to complete...${NC}"
    
    local max_attempts=60  # Increased timeout
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        # Check if kafka-setup container has completed (exited successfully)
        local container_status=$(docker-compose ps kafka-setup 2>/dev/null | grep "kafka-setup" | awk '{print $NF}')
        
        if [[ "$container_status" == *"Exit 0"* ]] || [[ "$container_status" == *"Exited (0)"* ]]; then
            echo -e "${GREEN}✅ Kafka setup completed successfully${NC}"
            break
        fi
        
        # Check if kafka-setup container failed
        if [[ "$container_status" == *"Exit"* ]] && [[ "$container_status" != *"Exit 0"* ]]; then
            echo -e "${RED}❌ Kafka setup container failed with status: $container_status${NC}"
            echo -e "${YELLOW}🔍 Kafka setup logs:${NC}"
            docker logs kafka-setup 2>&1 | tail -20
            return 1
        fi
        
        # Also check if topics are already available (alternative success indicator)
        if docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null | grep -q "sales_transactions"; then
            echo -e "${GREEN}✅ Kafka topics are ready (setup successful)${NC}"
            break
        fi
        
        echo -e "${YELLOW}⏳ Waiting for Kafka setup... (attempt $attempt/$max_attempts)${NC}"
        sleep 2
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo -e "${YELLOW}⚠️  Kafka setup timeout reached, checking if topics exist anyway...${NC}"
        # Final check if topics exist despite timeout
        if docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null | grep -q "sales_transactions"; then
            echo -e "${GREEN}✅ Kafka topics are available - setup was successful${NC}"
        else
            echo -e "${RED}❌ Kafka setup timed out and topics not found${NC}"
            echo -e "${YELLOW}🔍 Checking kafka-setup logs...${NC}"
            docker logs kafka-setup 2>&1 | tail -20
            return 1
        fi
    fi
    
    # Verify topics are actually created
    echo -e "${YELLOW}🔍 Final verification of Kafka topics...${NC}"
    if docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null | grep -q "sales_transactions"; then
        echo -e "${GREEN}✅ Kafka topics verified:${NC}"
        docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list
        return 0
    else
        echo -e "${RED}❌ Kafka topics verification failed${NC}"
        echo -e "${YELLOW}🔍 Current Kafka logs:${NC}"
        docker logs kafka 2>&1 | tail -20
        return 1
    fi
}

# Stop any existing containers
echo -e "${YELLOW}🛑 Stopping existing containers...${NC}"
docker-compose down 2>/dev/null

# Remove any stale checkpoint data that might cause issues
echo -e "${YELLOW}🧹 Cleaning checkpoint data...${NC}"
sudo rm -rf ./spark-data/checkpoints/* 2>/dev/null || true

# Build the dashboard container first to ensure proper dependency installation
echo -e "${YELLOW}🏗️  Building the dashboard container...${NC}"
if ! docker-compose build streamlit-dashboard; then
    echo -e "${RED}❌ Failed to build dashboard container${NC}"
    exit 1
fi

# Start core services first (excluding kafka-setup for proper timing)
echo -e "${YELLOW}🚀 Starting Kafka, Spark, and Dashboard services...${NC}"
if ! docker-compose up -d zookeeper kafka spark-master spark-worker python-kafka streamlit-dashboard; then
    echo -e "${RED}❌ Failed to start core services${NC}"
    exit 1
fi

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 10

# Check each service
for service in zookeeper kafka spark-master spark-worker; do
    if ! check_service $service; then
        echo -e "${RED}❌ Service startup failed${NC}"
        echo -e "${YELLOW}🔍 Checking container logs...${NC}"
        docker logs $service 2>&1 | tail -20
        exit 1
    fi
done

# Wait for Kafka to be fully ready before starting setup
echo -e "${YELLOW}⏳ Ensuring Kafka is fully ready for topic creation...${NC}"
sleep 15

# Start kafka-setup container manually to ensure proper timing
echo -e "${YELLOW}🔧 Starting Kafka setup container...${NC}"
docker-compose up -d kafka-setup

# Wait for Kafka setup to complete
if ! wait_for_kafka_setup; then
    echo -e "${RED}❌ Kafka setup failed${NC}"
    exit 1
fi

# Install dependencies in the Python Kafka container
echo -e "${YELLOW}📦 Installing dependencies in Python Kafka container...${NC}"
if ! docker exec python-kafka pip install kafka-python==2.0.2; then
    echo -e "${RED}❌ Failed to install Python dependencies${NC}"
    exit 1
fi

# Create data directories with proper permissions
echo -e "${YELLOW}📁 Creating data directories...${NC}"
docker exec spark-master mkdir -p /opt/spark-data/top_products /opt/spark-data/sales_by_category /opt/spark-data/sales_by_location /opt/spark-data/hourly_trends /opt/spark-data/customer_segments /opt/spark-data/notifications /opt/spark-data/notifications/popular_products /opt/spark-data/alerts /opt/spark-data/checkpoints
docker exec spark-master chmod -R 777 /opt/spark-data

# Wait a bit more for Spark to be fully ready
echo -e "${YELLOW}⏳ Ensuring Spark cluster is fully initialized...${NC}"
sleep 15

# Check Spark Master UI accessibility
echo -e "${YELLOW}🔍 Checking Spark Master UI...${NC}"
if curl -s http://localhost:8080 > /dev/null; then
    echo -e "${GREEN}✅ Spark Master UI accessible at http://localhost:8080${NC}"
else
    echo -e "${YELLOW}⚠️  Spark Master UI not yet accessible${NC}"
fi

# Run Spark streaming job
echo -e "${YELLOW}⚡ Starting Spark streaming job...${NC}"
docker exec spark-master spark-submit \
    --master spark://spark-master:7077 \
    --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.3.0 \
    --conf spark.sql.adaptive.enabled=true \
    --conf spark.sql.adaptive.coalescePartitions.enabled=true \
    --driver-memory 1g \
    --executor-memory 1g \
    /opt/spark-apps/spark_streaming.py &

# Store the background job PID
SPARK_PID=$!

# Wait for Spark job to initialize
echo -e "${YELLOW}⏳ Waiting for Spark job to initialize...${NC}"
sleep 20

# Check if Spark job is still running
if ! kill -0 $SPARK_PID 2>/dev/null; then
    echo -e "${RED}❌ Spark streaming job failed to start${NC}"
    echo -e "${YELLOW}🔍 Checking Spark logs...${NC}"
    docker logs spark-master 2>&1 | tail -50
    exit 1
fi

# Run Kafka producer to generate data
echo -e "${YELLOW}📊 Starting Kafka producer to generate transaction data...${NC}"
docker exec -d python-kafka python /app/kafka_producer.py

# Wait for data generation to start
sleep 10

# Final status check
echo -e "${GREEN}✅ All services are running!${NC}"
echo ""
echo -e "${BLUE}🌐 Access Points:${NC}"
echo -e "  📊 Dashboard:        http://localhost:8501"
echo -e "  ⚡ Spark Master UI:  http://localhost:8080"
echo -e "  🔧 Spark Worker UI:  http://localhost:8081"
echo -e "  📱 Spark Apps UI:    http://localhost:4040"
echo ""
echo -e "${BLUE}🔍 Monitoring:${NC}"
echo -e "  View Spark logs:     docker logs spark-master"
echo -e "  View Kafka logs:     docker logs kafka"
echo -e "  View Dashboard logs: docker logs streamlit-dashboard"
echo ""
echo -e "${BLUE}🛑 To stop all services:${NC}"
echo -e "  ./stop.sh"