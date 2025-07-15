#!/bin/bash

echo "=========================================="
echo "    Testing Neon PostgreSQL Connection"
echo "=========================================="
echo

# Test connection using docker
echo "[INFO] Testing Neon PostgreSQL connection..."

# Use a temporary container to test the connection
docker run --rm -it postgres:13 psql "postgresql://neondb_owner:npg_G47bTrUPvdfo@ep-falling-cake-a1j2rvpd-pooler.ap-southeast-1.aws.neon.tech/airflow?sslmode=require" -c "SELECT version();"

if [ $? -eq 0 ]; then
    echo
    echo "✅ SUCCESS: Connection to Neon PostgreSQL is working!"
    echo
    echo "Your Airflow services can now use the Neon database."
    echo "You can start Airflow with: docker-compose up -d"
else
    echo
    echo "❌ ERROR: Failed to connect to Neon PostgreSQL"
    echo
    echo "Please check:"
    echo "1. Your internet connection"
    echo "2. The Neon database credentials"
    echo "3. That the Neon database is running"
    echo "4. Firewall settings"
fi

echo
echo "==========================================" 