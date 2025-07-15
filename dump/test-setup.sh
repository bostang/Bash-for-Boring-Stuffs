#!/bin/bash

set -e

echo "🧪 Testing Demo Setup"
echo "====================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASSED=$((PASSED + 1))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAILED=$((FAILED + 1))
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Test 1: Directory Structure
print_test "Checking directory structure..."
required_dirs=(
    "config/filebeat"
    "config/kibana" 
    "config/logstash/pipeline"
    "config/nginx"
    "scripts"
    "sample-app"
    "log-generator"
    "logs/app"
    "logs/nginx"
    "logs/generator"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        print_pass "Directory exists: $dir"
    else
        print_fail "Missing directory: $dir"
    fi
done

# Test 2: Required Files
print_test "Checking required files..."
required_files=(
    "docker-compose.yml"
    "README.md"
    "config/filebeat/filebeat.yml"
    "config/kibana/kibana.yml"
    "config/kibana/sample-dashboard.json"
    "config/logstash/logstash.yml"
    "config/logstash/pipeline/logstash.conf"
    "config/nginx/nginx.conf"
    "sample-app/package.json"
    "sample-app/server.js"
    "sample-app/Dockerfile"
    "log-generator/requirements.txt"
    "log-generator/generator.py"
    "log-generator/Dockerfile"
    "scripts/start-demo.sh"
    "scripts/stop-demo.sh"
    "scripts/setup-kibana.sh"
    "scripts/generate-traffic.sh"
    "scripts/view-logs.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_pass "File exists: $file"
    else
        print_fail "Missing file: $file"
    fi
done

# Test 3: Script Permissions
print_test "Checking script permissions..."
for script in scripts/*.sh; do
    if [ -x "$script" ]; then
        print_pass "Executable: $script"
    else
        print_fail "Not executable: $script"
    fi
done

# Test 4: Docker Configuration
print_test "Validating Docker Compose configuration..."
if docker-compose config > /dev/null 2>&1; then
    print_pass "Docker Compose configuration is valid"
else
    print_fail "Docker Compose configuration has errors"
fi

# Test 5: Python Syntax
print_test "Checking Python syntax..."
if python3 -m py_compile log-generator/generator.py 2>/dev/null; then
    print_pass "Python syntax is valid"
else
    print_fail "Python syntax has errors"
fi

# Test 6: Node.js Dependencies
print_test "Checking Node.js package.json..."
if [ -f "sample-app/package.json" ]; then
    if cat sample-app/package.json | python3 -m json.tool > /dev/null 2>&1; then
        print_pass "package.json is valid JSON"
    else
        print_fail "package.json has invalid JSON"
    fi
fi

# Test 7: Required Ports
print_test "Checking if required ports are available..."
required_ports=(3000 5601 8080 9200)
for port in "${required_ports[@]}"; do
    if ! lsof -i :$port > /dev/null 2>&1; then
        print_pass "Port $port is available"
    else
        print_warning "Port $port is already in use"
    fi
done

# Test 8: Docker Availability
print_test "Checking Docker availability..."
if command -v docker > /dev/null 2>&1; then
    if docker info > /dev/null 2>&1; then
        print_pass "Docker is running"
    else
        print_fail "Docker is not running"
    fi
else
    print_fail "Docker is not installed"
fi

# Test 9: Configuration File Content
print_test "Validating configuration files..."

# Check Logstash config
if grep -q "input {" config/logstash/pipeline/logstash.conf && \
   grep -q "filter {" config/logstash/pipeline/logstash.conf && \
   grep -q "output {" config/logstash/pipeline/logstash.conf; then
    print_pass "Logstash pipeline configuration is complete"
else
    print_fail "Logstash pipeline configuration is incomplete"
fi

# Check Filebeat config
if grep -q "filebeat.inputs:" config/filebeat/filebeat.yml && \
   grep -q "output.logstash:" config/filebeat/filebeat.yml; then
    print_pass "Filebeat configuration is complete"
else
    print_fail "Filebeat configuration is incomplete"
fi

# Test 10: README Completeness
print_test "Checking README completeness..."
readme_sections=(
    "Demo 1"
    "Demo 2" 
    "ETL"
    "Kibana"
    "Quick Start"
    "Prerequisites"
)

for section in "${readme_sections[@]}"; do
    if grep -q "$section" README.md; then
        print_pass "README contains: $section"
    else
        print_fail "README missing: $section"
    fi
done

# Summary
echo
echo "🎯 Test Summary"
echo "==============="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! Demo is ready to run.${NC}"
    echo
    echo "🚀 To start the demo:"
    echo "   ./scripts/start-demo.sh"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please fix the issues above.${NC}"
    exit 1
fi 