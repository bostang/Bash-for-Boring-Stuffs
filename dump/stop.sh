#!/bin/bash

# Stop all containers
echo "Stopping all containers..."
docker-compose down

# Remove any dangling volumes
echo "Cleaning up volumes..."
docker volume prune -f

echo "All services stopped and cleaned up."