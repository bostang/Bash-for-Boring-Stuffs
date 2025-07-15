#!/bin/bash
echo "🚀 Quick Data Injection..."

ELASTICSEARCH_URL="http://localhost:9200"
KIBANA_URL="http://localhost:5601"
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
TODAY=$(date +"%Y.%m.%d")

echo "💉 Injecting sample data..."

# Create bulk data
cat << BULK > /tmp/bulk_data.json
{"index":{"_index":"logs-nginx-$TODAY"}}
{"@timestamp":"$CURRENT_TIME","service":"nginx","message":"GET / HTTP/1.1 200","level":"info","host":"nginx-demo","path":"/","status":200,"response_time":0.05,"method":"GET","user_agent":"curl/7.68.0","remote_ip":"172.18.0.1","bytes":1234}
{"index":{"_index":"logs-nginx-$TODAY"}}
{"@timestamp":"$CURRENT_TIME","service":"nginx","message":"GET /api/users HTTP/1.1 200","level":"info","host":"nginx-demo","path":"/api/users","status":200,"response_time":0.12,"method":"GET","user_agent":"curl/7.68.0","remote_ip":"172.18.0.2","bytes":2048}
{"index":{"_index":"logs-nginx-$TODAY"}}
{"@timestamp":"$CURRENT_TIME","service":"nginx","message":"GET /nonexistent HTTP/1.1 404","level":"error","host":"nginx-demo","path":"/nonexistent","status":404,"response_time":0.02,"method":"GET","user_agent":"curl/7.68.0","remote_ip":"172.18.0.3","bytes":162}
{"index":{"_index":"logs-app-$TODAY"}}
{"@timestamp":"$CURRENT_TIME","service":"sample-app","message":"User login successful","level":"info","host":"sample-app","path":"/login","status":200,"response_time":0.25,"method":"POST","user_agent":"Mozilla/5.0","remote_ip":"172.18.0.4","bytes":512}
{"index":{"_index":"logs-app-$TODAY"}}
{"@timestamp":"$CURRENT_TIME","service":"sample-app","message":"Database connection error","level":"error","host":"sample-app","path":"/api/data","status":500,"response_time":2.1,"method":"GET","user_agent":"Mozilla/5.0","remote_ip":"172.18.0.5","bytes":256}
{"index":{"_index":"logs-generator-$TODAY"}}
{"@timestamp":"$CURRENT_TIME","service":"log-generator","message":"Processing batch job","level":"info","host":"log-generator","path":"/batch","status":200,"response_time":1.5,"method":"POST","user_agent":"internal","remote_ip":"127.0.0.1","bytes":1024}
BULK

# Inject data
curl -s -X POST "$ELASTICSEARCH_URL/_bulk" -H "Content-Type: application/x-ndjson" --data-binary @/tmp/bulk_data.json

# Refresh indices
curl -s -X POST "$ELASTICSEARCH_URL/logs-*/_refresh"

# Create data view
curl -s -X POST "$KIBANA_URL/api/data_views/data_view" -H "Content-Type: application/json" -H "kbn-xsrf: true" -d '{"data_view":{"title":"logs-*","name":"Logs Data View","timeFieldName":"@timestamp"}}'

rm -f /tmp/bulk_data.json
echo "✅ Done!"
