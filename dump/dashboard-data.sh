#!/bin/bash
echo "📊 Creating dashboard-specific data..."

ES="http://localhost:9200"
TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# Create more comprehensive sample data for dashboard panels
for i in {1..50}; do
  # Vary the status codes for better dashboard visualization
  case $((i % 10)) in
    0|1) status=404; level="error" ;;
    2) status=500; level="error" ;;
    3) status=301; level="info" ;;
    4) status=403; level="warn" ;;
    *) status=200; level="info" ;;
  esac
  
  # Different services
  services=("nginx" "sample-app" "log-generator")
  service=${services[$((i % 3))]}
  
  # Different response times for heatmap
  response_time="0.$((RANDOM % 999 + 100))"
  
  # Different paths
  paths=("/api/users" "/dashboard" "/login" "/api/data" "/health" "/api/search")
  path=${paths[$((i % 6))]}
  
  curl -s -X POST "$ES/logs-sample/_doc" -H "Content-Type: application/json" -d "{
    \"@timestamp\": \"$TIME\",
    \"service\": \"$service\",
    \"message\": \"$service request $i\",
    \"level\": \"$level\",
    \"status\": $status,
    \"response_time\": $response_time,
    \"method\": \"GET\",
    \"path\": \"$path\",
    \"bytes\": $((RANDOM % 5000 + 100)),
    \"remote_ip\": \"192.168.1.$((RANDOM % 254 + 1))\",
    \"user_agent\": \"Mozilla/5.0\"
  }" > /dev/null
done

# Refresh the index
curl -s -X POST "$ES/logs-sample/_refresh" > /dev/null

echo "✅ Dashboard data created!"
echo "📊 Total documents: $(curl -s "$ES/logs-sample/_count" | grep -o '"count":[0-9]*' | cut -d: -f2)"
