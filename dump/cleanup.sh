#!/bin/bash

echo "=== Jenkins CI/CD Demo Cleanup ==="

# Stop and remove all containers
echo "Stopping and removing containers..."
docker-compose down

# Remove application containers
echo "Removing application containers..."
docker stop jenkins-demo-app-staging jenkins-demo-app-prod 2>/dev/null || true
docker rm jenkins-demo-app-staging jenkins-demo-app-prod 2>/dev/null || true

# Remove Jenkins images
echo "Removing Docker images..."
docker rmi jenkins-demo-app:latest 2>/dev/null || true
docker rmi $(docker images | grep jenkins-demo-app | awk '{print $3}') 2>/dev/null || true

# Clean up Docker system (optional)
read -p "Do you want to clean up Docker system (remove unused containers, networks, images)? [y/N]: " cleanup_docker
if [[ $cleanup_docker =~ ^[Yy]$ ]]; then
    echo "Cleaning up Docker system..."
    docker system prune -f
fi

# Remove Jenkins data (optional)
read -p "Do you want to remove Jenkins data (jenkins-data/ folder)? This will delete all Jenkins configuration! [y/N]: " cleanup_data
if [[ $cleanup_data =~ ^[Yy]$ ]]; then
    echo "Removing Jenkins data..."
    sudo rm -rf jenkins-data/
fi

echo "✅ Cleanup completed!" 