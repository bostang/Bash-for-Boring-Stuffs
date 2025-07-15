#!/bin/bash

# Fix credentials and restart Jenkins
echo "=== Fixing Jenkins Credentials Issue ==="
echo ""

echo "🔄 Stopping Jenkins..."
docker-compose down

echo "🧹 Removing potentially corrupted Jenkins data..."
read -p "Remove Jenkins data directory to fix credentials? This will reset Jenkins config [y/N]: " reset_jenkins
if [[ $reset_jenkins =~ ^[Yy]$ ]]; then
    sudo rm -rf jenkins-data/
    echo "✅ Jenkins data reset"
fi

echo "🚀 Starting Jenkins with updated plugins..."
docker-compose up -d

echo "⏳ Waiting for Jenkins to start (this may take 2-3 minutes)..."
for i in {1..18}; do
    if curl -s -f http://localhost:8080 > /dev/null 2>&1; then
        echo "✅ Jenkins is ready!"
        break
    fi
    echo "   Waiting... ($i/18) - Installing plugins..."
    sleep 10
done

echo ""
echo "🔍 Checking credentials configuration..."
sleep 5

# Check logs for configuration status
echo "📄 Checking configuration logs:"
docker-compose logs jenkins | grep -E "(telegram|credential|configuration)" | tail -10

echo ""
echo "🧪 Testing Telegram integration..."
./scripts/telegram-webhook.sh test

echo ""
echo "✅ Credentials fix completed!"
echo ""
echo "📋 Next steps:"
echo "1. Access Jenkins: http://localhost:8080"
echo "2. Login: admin/admin123"
echo "3. Create your pipeline job"
echo "4. Test the pipeline!" 