#!/bin/bash

# Monitor Kafka Spark Streaming Demo
echo "📊 Monitoring Kafka Spark Streaming Demo"
echo "========================================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

show_menu() {
    echo ""
    echo "Select monitoring option:"
    echo "1) Show container status"
    echo "2) View JavaScript producer logs"
    echo "3) View JavaScript consumer logs"
    echo "4) View Spark master logs"
    echo "5) View Kafka topics and messages"
    echo "6) Show consumer statistics"
    echo "7) View all logs (tail -f)"
    echo "8) Check Kafka topic details"
    echo "9) Show service URLs"
    echo "0) Exit"
    echo ""
    read -p "Enter your choice: " choice
}

while true; do
    show_menu
    
    case $choice in
        1)
            print_section "Container Status"
            docker-compose ps
            ;;
        2)
            print_section "JavaScript Producer Logs"
            docker-compose logs --tail=50 js-producer
            ;;
        3)
            print_section "JavaScript Consumer Logs"
            docker-compose logs --tail=50 js-consumer
            ;;
        4)
            print_section "Spark Master Logs"
            docker-compose logs --tail=50 spark-master
            ;;
        5)
            print_section "Kafka Topics and Recent Messages"
            echo "📋 Available topics:"
            # docker exec demo_kafka kafka-topics --bootstrap-server localhost:9092 --list
            docker exec demo_kafka kafka-topics --bootstrap-server localhost:9093 --list
            echo ""
            echo "📧 Recent messages from user-events topic (last 5):"
            docker exec demo_kafka kafka-console-consumer \
                # --bootstrap-server localhost:9092 \
                --bootstrap-server localhost:9093 \
                --topic user-events \
                --from-beginning \
                --max-messages 5 \
                --timeout-ms 5000 2>/dev/null || echo "No messages available"
            ;;
        6)
            print_section "Consumer Statistics"
            if [ -f "./data/consumer_stats.json" ]; then
                echo "📈 Latest consumer statistics:"
                cat ./data/consumer_stats.json | python3 -m json.tool
            else
                echo "⚠️  No statistics file found. Consumer may not be running or no data processed yet."
            fi
            ;;
        7)
            print_section "All Logs (Live Tail)"
            echo "🔄 Press Ctrl+C to stop live monitoring"
            docker-compose logs -f
            ;;
        8)
            print_section "Kafka Topic Details"
            echo "📊 Topic: user-events"
            # docker exec demo_kafka kafka-topics --bootstrap-server localhost:9092 --describe --topic user-events
            docker exec demo_kafka kafka-topics --bootstrap-server localhost:9093 --describe --topic user-events
            echo ""
            echo "📊 Topic: processed-events"
            # docker exec demo_kafka kafka-topics --bootstrap-server localhost:9092 --describe --topic processed-events
            docker exec demo_kafka kafka-topics --bootstrap-server localhost:9093 --describe --topic processed-events
            echo ""
            echo "📊 Topic: alerts"
            # docker exec demo_kafka kafka-topics --bootstrap-server localhost:9092 --describe --topic alerts
            docker exec demo_kafka kafka-topics --bootstrap-server localhost:9093 --describe --topic alerts
            ;;
        9)
            print_section "Service URLs"
            echo "🌐 Spark Master UI:      http://localhost:8080"
            echo "👷 Spark Worker UI:      http://localhost:8081"
            echo "🔍 Spark Application UI: http://localhost:4040"
            echo ""
            echo "📊 Data Directory:       ./data/"
            echo "📄 Consumer Stats:       ./data/consumer_stats.json"
            ;;
        0)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please try again."
            ;;
    esac
done 