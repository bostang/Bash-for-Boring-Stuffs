#!/bin/bash

# Quick Start Script for Jenkins CI/CD Demo
# Runs complete setup and validation

set -e  # Exit on any error

echo "🚀 Jenkins CI/CD Demo - Quick Start"
echo "=================================="
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo "❌ curl is not installed. Please install curl first."
    exit 1
fi

echo "✅ All prerequisites met!"
echo ""

# Check if Telegram is already configured
if grep -q "8006705671" scripts/telegram-webhook.sh 2>/dev/null; then
    echo "✅ Telegram already configured, skipping setup..."
else
    echo "📱 Telegram bot not configured. Please run setup first:"
    echo "   ./scripts/setup-telegram.sh"
    echo ""
    read -p "Do you want to configure Telegram now? [y/N]: " setup_telegram
    if [[ $setup_telegram =~ ^[Yy]$ ]]; then
        ./scripts/setup-telegram.sh
    else
        echo "⚠️ Continuing without Telegram notifications..."
    fi
fi

echo ""

# Setup Jenkins
echo "🔧 Setting up Jenkins..."
./scripts/setup.sh

# Wait for Jenkins to be ready
echo ""
echo "⏳ Waiting for Jenkins to be fully ready..."
for i in {1..12}; do
    if curl -s -f http://localhost:8080 > /dev/null 2>&1; then
        echo "✅ Jenkins is ready!"
        break
    fi
    echo "   Waiting... ($i/12)"
    sleep 10
done

# Run health check
echo ""
echo "🔍 Running system health check..."
./scripts/monitor.sh

echo ""
echo "🎉 Quick Start Complete!"
echo ""
echo "📋 What's Ready:"
echo "   ✅ Jenkins: http://localhost:8080 (admin/admin123)"
echo "   ✅ Auto-configured credentials"
echo "   ✅ All scripts executable"
echo ""
echo "📝 Next Steps:"
echo "   1. Create pipeline job in Jenkins"
echo "   2. Configure Git repository"
echo "   3. Run your first build!"
echo ""
echo "🧪 Test Commands:"
echo "   ./scripts/telegram-webhook.sh test"
echo "   ./scripts/monitor.sh"
echo "   ./scripts/test-app.sh http://localhost:8081" 