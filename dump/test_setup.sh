#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}🔧 STUDY-CASE SETUP VERIFICATION 🔧${NC}"
echo -e "${BLUE}=====================================${NC}"

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
        return 0
    else
        echo -e "${RED}❌ $1${NC}"
        return 1
    fi
}

echo -e "\n${YELLOW}1. Docker Compose Configuration Test${NC}"
echo "-------------------------------------------"
docker-compose config > /dev/null 2>&1
check_status "Docker Compose configuration is valid"

echo -e "\n${YELLOW}2. Container Status Check${NC}"
echo "-------------------------------------------"
TOTAL_CONTAINERS=$(docker-compose ps --services | wc -l)
RUNNING_CONTAINERS=$(docker-compose ps | grep "Up" | wc -l)
echo -e "Total containers defined: ${BLUE}$TOTAL_CONTAINERS${NC}"
echo -e "Running containers: ${BLUE}$RUNNING_CONTAINERS${NC}"

if [ "$RUNNING_CONTAINERS" -eq "$TOTAL_CONTAINERS" ]; then
    echo -e "${GREEN}✅ All containers are running${NC}"
else
    echo -e "${RED}❌ Some containers are not running${NC}"
    docker-compose ps
fi

echo -e "\n${YELLOW}3. Network Connectivity Test${NC}"
echo "-------------------------------------------"

# Test Spark Master UI
echo -n "Testing Spark Master UI (localhost:8080): "
curl -s http://localhost:8080 > /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Accessible${NC}"
else
    echo -e "${RED}❌ Not accessible${NC}"
fi

# Test Spark Worker UI
echo -n "Testing Spark Worker UI (localhost:8081): "
curl -s http://localhost:8081 > /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Accessible${NC}"
else
    echo -e "${RED}❌ Not accessible${NC}"
fi

# Test Spark Application UI
echo -n "Testing Spark Application UI (localhost:4040): "
curl -s http://localhost:4040 > /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Accessible${NC}"
else
    echo -e "${YELLOW}⚠️  Not accessible (may be normal if no apps running)${NC}"
fi

# Test Dashboard
echo -n "Testing Dashboard (localhost:8501): "
curl -s http://localhost:8501 > /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Accessible${NC}"
else
    echo -e "${RED}❌ Not accessible${NC}"
fi

echo -e "\n${YELLOW}4. Kafka Health Check${NC}"
echo "-------------------------------------------"

# Test Kafka broker connectivity
echo -n "Testing Kafka broker connectivity: "
if docker exec kafka kafka-broker-api-versions --bootstrap-server kafka:29092 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Kafka broker is accessible${NC}"
else
    echo -e "${RED}❌ Kafka broker is not accessible${NC}"
fi

# List topics
echo "Kafka topics:"
docker exec kafka kafka-topics --bootstrap-server kafka:29092 --list 2>/dev/null | while read topic; do
    echo -e "  🔹 ${BLUE}$topic${NC}"
done

echo -e "\n${YELLOW}5. Spark Cluster Status${NC}"
echo "-------------------------------------------"

# Check Spark Master logs for errors
echo "Checking Spark Master for critical errors:"
SPARK_ERRORS=$(docker logs spark-master 2>&1 | grep -i "error\|exception\|failed" | tail -3)
if [ -z "$SPARK_ERRORS" ]; then
    echo -e "${GREEN}✅ No critical errors found${NC}"
else
    echo -e "${YELLOW}⚠️  Recent errors found:${NC}"
    echo "$SPARK_ERRORS"
fi

# Check if worker is connected
echo -n "Checking Spark Worker connection: "
WORKER_CONNECTED=$(docker logs spark-master 2>&1 | grep -c "Registering worker\|Worker registered")
if [ "$WORKER_CONNECTED" -gt 0 ]; then
    echo -e "${GREEN}✅ Worker is connected${NC}"
else
    echo -e "${RED}❌ Worker connection issues${NC}"
fi

echo -e "\n${YELLOW}6. Python Dependencies Check${NC}"
echo "-------------------------------------------"
echo -n "Testing kafka-python installation: "
if docker exec python-kafka python -c "import kafka; print('kafka-python version:', kafka.__version__)" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ kafka-python is installed and importable${NC}"
else
    echo -e "${RED}❌ kafka-python is not installed or not working${NC}"
fi

echo -e "\n${YELLOW}7. Data Directory Structure${NC}"
echo "-------------------------------------------"
echo "Checking Spark data directories:"
docker exec spark-master find /opt/spark-data -type d 2>/dev/null | head -20 | while read dir; do
    echo -e "  📁 ${BLUE}$dir${NC}"
done

echo -e "\n${YELLOW}8. Active Spark Applications${NC}"
echo "-------------------------------------------"
SPARK_APPS=$(docker exec spark-master curl -s http://spark-master:8080/json 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    apps = data.get('activeapps', [])
    print(f'Active applications: {len(apps)}')
    for app in apps:
        print(f'  - {app.get(\"name\", \"Unknown\")} (ID: {app.get(\"id\", \"N/A\")})')
except:
    print('Could not parse Spark Master status')
" 2>/dev/null)

if [ -n "$SPARK_APPS" ]; then
    echo "$SPARK_APPS"
else
    echo -e "${YELLOW}⚠️  No active applications or cannot connect to Spark Master${NC}"
fi

echo -e "\n${YELLOW}9. Recent Container Logs Check${NC}"
echo "-------------------------------------------"
echo "Recent important log entries:"

# Check for Spark streaming application
echo -e "\n${BLUE}Spark Master (last 5 lines):${NC}"
docker logs spark-master 2>&1 | tail -5

echo -e "\n${BLUE}Kafka (last 3 lines):${NC}"
docker logs kafka 2>&1 | tail -3

echo -e "\n${BLUE}Dashboard (last 3 lines):${NC}"
docker logs streamlit-dashboard 2>&1 | tail -3

echo -e "\n${YELLOW}10. System Resource Check${NC}"
echo "-------------------------------------------"
echo "Docker system resource usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -10

echo -e "\n${BLUE}=====================================${NC}"
echo -e "${BLUE}🏁 TEST SUMMARY COMPLETE${NC}"
echo -e "${BLUE}=====================================${NC}"

echo -e "\n${YELLOW}📋 Next Steps:${NC}"
echo "1. If containers are not running: ./run.sh"
echo "2. If Kafka topics missing: Check kafka-setup container logs"
echo "3. If Spark errors: Check Spark Master logs with 'docker logs spark-master'"
echo "4. If dashboard not accessible: Check 'docker logs streamlit-dashboard'"
echo "5. For streaming issues: Look for '❌ Failed to start streaming queries' in logs" 