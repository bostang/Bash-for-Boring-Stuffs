#!/bin/bash

# Comprehensive test script for Spring Boot application
APP_URL=${1:-"http://localhost:8080"}
ENVIRONMENT=${2:-"development"}

echo "=== Testing Spring Boot Application ==="
echo "Application URL: $APP_URL"
echo "Environment: $ENVIRONMENT"
echo "Timestamp: $(date)"
echo ""

# Function to test endpoint
test_endpoint() {
    local endpoint="$1"
    local name="$2"
    local url="$APP_URL$endpoint"
    
    echo "🔍 Testing $name endpoint..."
    echo "   URL: $url"
    
    if response=$(curl -s -w "\n%{http_code}" "$url" 2>/dev/null); then
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | head -n -1)
        
        if [ "$http_code" = "200" ]; then
            echo "   ✅ Status: $http_code OK"
            if command -v jq &> /dev/null && echo "$body" | jq . &>/dev/null; then
                echo "   📄 Response: $(echo "$body" | jq -c .)"
            else
                echo "   📄 Response: $body"
            fi
        else
            echo "   ⚠️  Status: $http_code"
            echo "   📄 Response: $body"
        fi
    else
        echo "   ❌ Connection failed"
        return 1
    fi
    echo ""
    return 0
}

# Test all endpoints
endpoints=(
    "/ Home"
    "/health Health"
    "/info Info"
    "/actuator/health Actuator-Health"
)

success_count=0
total_count=${#endpoints[@]}

for endpoint_info in "${endpoints[@]}"; do
    endpoint=$(echo $endpoint_info | cut -d' ' -f1)
    name=$(echo $endpoint_info | cut -d' ' -f2)
    
    if test_endpoint "$endpoint" "$name"; then
        ((success_count++))
    fi
done

# Performance test (simple)
echo "⚡ Performance Test:"
if command -v curl &> /dev/null; then
    echo "   Testing response time..."
    time_result=$(curl -w "@-" -o /dev/null -s "$APP_URL/" <<< 'time_total: %{time_total}s\ntime_connect: %{time_connect}s\ntime_starttransfer: %{time_starttransfer}s\n')
    echo "   $time_result"
else
    echo "   ⚠️ curl not available for performance test"
fi
echo ""

# Summary
echo "📊 Test Summary:"
echo "   Endpoints tested: $total_count"
echo "   Successful: $success_count"
echo "   Failed: $((total_count - success_count))"

if [ $success_count -eq $total_count ]; then
    echo "   ✅ All tests passed!"
    exit 0
else
    echo "   ❌ Some tests failed!"
    exit 1
fi 