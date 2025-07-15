#!/bin/bash

# Telegram Webhook Script for Jenkins Pipeline Trigger
# This script can be called by external systems or manually to trigger Jenkins builds
# and send notifications to Telegram

BOT_TOKEN="8006705671:AAGBPsg9hlGs3VNehcDh2tm0XdlwTDzkmqI"
CHAT_ID="5169274667"
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JOB_NAME="${JOB_NAME:-jenkins-demo-pipeline}"

# Function to send Telegram message
send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=${message}" \
        -d "parse_mode=HTML"
}

# Function to trigger Jenkins build
trigger_jenkins_build() {
    local jenkins_user="${JENKINS_USER:-admin}"
    local jenkins_token="${JENKINS_TOKEN:-admin123}"
    
    echo "Triggering Jenkins build..."
    
    BUILD_RESPONSE=$(curl -s -X POST \
        --user "${jenkins_user}:${jenkins_token}" \
        "${JENKINS_URL}/job/${JOB_NAME}/build")
    
    if [ $? -eq 0 ]; then
        echo "✅ Jenkins build triggered successfully"
        send_telegram_message "🔄 Jenkins Pipeline Triggered: ${JOB_NAME}"
        return 0
    else
        echo "❌ Failed to trigger Jenkins build"
        send_telegram_message "❌ Failed to trigger Jenkins Pipeline: ${JOB_NAME}"
        return 1
    fi
}

# Main execution
case "${1:-trigger}" in
    "trigger")
        echo "=== Telegram Webhook: Triggering Jenkins Build ==="
        send_telegram_message "🚀 Manual trigger received - Starting Jenkins Pipeline"
        trigger_jenkins_build
        ;;
    "test")
        echo "=== Testing Telegram Integration ==="
        send_telegram_message "🧪 Telegram Webhook Test - Integration Working!"
        ;;
    "status")
        echo "=== Jenkins Status Check ==="
        STATUS_CHECK=$(curl -s -u admin:admin123 "${JENKINS_URL}/api/json" | grep -o '"mode":"[^"]*"' || echo '"mode":"offline"')
        send_telegram_message "📊 Jenkins Status: ${STATUS_CHECK}"
        ;;
    *)
        echo "Usage: $0 {trigger|test|status}"
        echo "  trigger - Trigger Jenkins build and notify via Telegram"
        echo "  test    - Send test message to Telegram"
        echo "  status  - Check Jenkins status and send to Telegram"
        exit 1
        ;;
esac
