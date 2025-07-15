#!/bin/bash
echo "🚀 Simple Data Injection..."

ES="http://localhost:9200"
KB="http://localhost:5601"
TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

echo "📝 Creating indices and injecting data..."

# Create simple indices first
curl -s -X PUT "$ES/logs-sample" -H "Content-Type: application/json" -d '{
  "mappings": {
    "properties": {
      "@timestamp": {"type": "date"},
      "service": {"type": "keyword"},
      "message": {"type": "text"},
      "level": {"type": "keyword"},
      "status": {"type": "integer"},
      "response_time": {"type": "float"},
      "method": {"type": "keyword"},
      "path": {"type": "keyword"}
    }
  }
}'

# Insert sample documents
for i in {1..10}; do
  status=$((200 + (i % 3) * 100))
  level="info"
  if [ $status -eq 404 ]; then level="error"; fi
  if [ $status -eq 500 ]; then level="error"; fi
  
  curl -s -X POST "$ES/logs-sample/_doc" -H "Content-Type: application/json" -d "{
    \"@timestamp\": \"$TIME\",
    \"service\": \"nginx\",
    \"message\": \"Request $i processed\",
    \"level\": \"$level\",
    \"status\": $status,
    \"response_time\": 0.$(($RANDOM % 999 + 1)),
    \"method\": \"GET\",
    \"path\": \"/api/test$i\"
  }" > /dev/null
done

# Refresh index
curl -s -X POST "$ES/logs-sample/_refresh" > /dev/null

echo "✅ Data injected!"
echo "🔍 Verify: curl 'http://localhost:9200/logs-sample/_search?size=1&pretty'"
