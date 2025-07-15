#!/bin/bash

# Deployment script for Jenkins Demo App
APP_NAME="jenkins-demo-app"
VERSION=${1:-latest}
ENVIRONMENT=${2:-staging}

echo "=== Deploying $APP_NAME:$VERSION to $ENVIRONMENT ==="

# Build the application
echo "Building the application..."
cd sample-spring-app
mvn clean package -DskipTests
cd ..

# Build Docker image
echo "Building Docker image..."
docker build -t $APP_NAME:$VERSION -f docker/Dockerfile .

# Deploy based on environment
case $ENVIRONMENT in
    "staging")
        PORT=8081
        ;;
    "production")
        PORT=8090
        ;;
    *)
        echo "Unknown environment: $ENVIRONMENT"
        exit 1
        ;;
esac

# Stop existing container
echo "Stopping existing container..."
docker stop $APP_NAME-$ENVIRONMENT 2>/dev/null || true
docker rm $APP_NAME-$ENVIRONMENT 2>/dev/null || true

# Start new container
echo "Starting new container on port $PORT..."
docker run -d \
    --name $APP_NAME-$ENVIRONMENT \
    -p $PORT:8080 \
    $APP_NAME:$VERSION

# Wait for application to start
echo "Waiting for application to start..."
sleep 15

# Health check
if curl -f http://localhost:$PORT/health >/dev/null 2>&1; then
    echo "✅ Deployment successful!"
    echo "🌐 Application is running at: http://localhost:$PORT"
    echo "🔍 Health check: http://localhost:$PORT/health"
else
    echo "❌ Deployment failed. Check container logs:"
    docker logs $APP_NAME-$ENVIRONMENT
    exit 1
fi 