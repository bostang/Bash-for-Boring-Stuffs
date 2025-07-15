#!/bin/bash

echo "=== Telegram Bot Setup for Jenkins ==="

# Function to validate input
validate_input() {
    if [ -z "$1" ]; then
        echo "Error: Input cannot be empty!"
        return 1
    fi
    return 0
}

# Get Telegram Bot Token
echo "📱 Setting up Telegram Bot Integration..."
echo ""
echo "First, you need to create a Telegram Bot:"
echo "1. Open Telegram and search for @BotFather"
echo "2. Send /start to BotFather"
echo "3. Send /newbot and follow the instructions"
echo "4. Copy the bot token that BotFather gives you"
echo ""

read -p "Enter your Telegram Bot Token: " BOT_TOKEN
if ! validate_input "$BOT_TOKEN"; then
    exit 1
fi

# Get Chat ID
echo ""
echo "Now we need to get your Chat ID:"
echo "1. Send a message to your bot (search for your bot name)"
echo "2. Send any message like 'Hello'"
echo ""

echo "Getting your Chat ID..."
UPDATES_URL="https://api.telegram.org/bot${BOT_TOKEN}/getUpdates"

echo "Fetching recent messages from your bot..."
RESPONSE=$(curl -s "$UPDATES_URL")

if echo "$RESPONSE" | grep -q '"ok":true'; then
    # Extract chat ID from the response
    CHAT_ID=$(echo "$RESPONSE" | grep -o '"chat":{"id":[^,]*' | grep -o '[0-9-]*' | head -1)
    
    if [ -n "$CHAT_ID" ]; then
        echo "✅ Found Chat ID: $CHAT_ID"
    else
        echo "❌ Could not find Chat ID. Please make sure you sent a message to your bot first."
        echo ""
        read -p "Enter your Chat ID manually: " CHAT_ID
        if ! validate_input "$CHAT_ID"; then
            exit 1
        fi
    fi
else
    echo "❌ Error: Invalid bot token or API error"
    echo "Response: $RESPONSE"
    exit 1
fi

# Test the bot by sending a test message
echo ""
echo "🧪 Testing Telegram bot..."
TEST_MESSAGE="🤖 Jenkins CI/CD Bot Setup Successful!"

curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${TEST_MESSAGE}" \
    -d "parse_mode=HTML" > /dev/null

if [ $? -eq 0 ]; then
    echo "✅ Test message sent successfully!"
else
    echo "❌ Failed to send test message"
    exit 1
fi

# Update telegram-webhook.sh with the credentials
echo ""
echo "💾 Updating webhook script with credentials..."

sed -i.bak "s/BOT_TOKEN=\".*\"/BOT_TOKEN=\"${BOT_TOKEN}\"/" scripts/telegram-webhook.sh
sed -i.bak "s/CHAT_ID=\".*\"/CHAT_ID=\"${CHAT_ID}\"/" scripts/telegram-webhook.sh
rm scripts/telegram-webhook.sh.bak

# Update Jenkinsfile credentials
echo "💾 Updating Jenkinsfile with credentials..."
sed -i.bak "s/TELEGRAM_BOT_TOKEN = '.*'/TELEGRAM_BOT_TOKEN = '${BOT_TOKEN}'/" Jenkinsfile
sed -i.bak "s/TELEGRAM_CHAT_ID = '.*'/TELEGRAM_CHAT_ID = '${CHAT_ID}'/" Jenkinsfile
rm Jenkinsfile.bak

echo ""
echo "🎉 Telegram Integration Setup Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Start Jenkins: ./scripts/setup.sh"
echo "2. Create pipeline job in Jenkins UI"
echo "3. Your credentials are auto-configured!"
echo ""
echo "🧪 Test Commands:"
echo "   ./scripts/telegram-webhook.sh test     # Test message"
echo "   ./scripts/telegram-webhook.sh trigger  # Trigger build"
echo "   ./scripts/telegram-webhook.sh status   # Check status" 