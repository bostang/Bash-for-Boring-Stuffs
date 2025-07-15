#!/bin/bash

# Practice Environment Setup Script
# Multi-Source Data Analysis dengan PostgreSQL dan MongoDB

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_status "Docker is running ✓"
}

# Function to check if Docker Compose is available
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
        print_error "Docker Compose is not available. Please install Docker Compose."
        exit 1
    fi
    print_status "Docker Compose is available ✓"
}

# Function to start services
start_services() {
    print_header "Starting Practice Environment"
    
    print_status "Building and starting containers..."
    docker-compose up -d
    
    print_status "Waiting for services to be ready..."
    
    # Wait for PostgreSQL
    print_status "Waiting for PostgreSQL to be ready..."
    until docker exec practice-postgresql pg_isready -U practice_user -d ecommerce_practice > /dev/null 2>&1; do
        printf '.'
        sleep 2
    done
    echo ""
    print_status "PostgreSQL is ready ✓"
    
    # Wait for MongoDB
    print_status "Waiting for MongoDB to be ready..."
    until docker exec practice-mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
        printf '.'
        sleep 2
    done
    echo ""
    print_status "MongoDB is ready ✓"
    
    print_header "Services Started Successfully!"
    show_connection_info
}

# Function to stop services
stop_services() {
    print_header "Stopping Practice Environment"
    docker-compose stop
    print_status "All services stopped ✓"
}

# Function to remove services and data
cleanup_services() {
    print_header "Cleaning Up Practice Environment"
    print_warning "This will remove all containers and data!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose down -v
        print_status "Environment cleaned up ✓"
    else
        print_status "Cleanup cancelled"
    fi
}

# Function to show service status
show_status() {
    print_header "Service Status"
    docker-compose ps
}

# Function to show connection information
show_connection_info() {
    print_header "Database Connection Information"
    
    echo -e "${GREEN}PostgreSQL Database:${NC}"
    echo "  Host: localhost"
    echo "  Port: 5433"
    echo "  Database: ecommerce_practice"
    echo "  Username: practice_user"
    echo "  Password: practice_pass"
    echo "  Connection String: postgresql://practice_user:practice_pass@localhost:5433/ecommerce_practice"
    echo ""
    
    echo -e "${GREEN}MongoDB Database:${NC}"
    echo "  Host: localhost"
    echo "  Port: 27018"
    echo "  Database: ecommerce_practice"
    echo "  Username: practice_user"
    echo "  Password: practice_pass"
    echo "  Connection String: mongodb://practice_user:practice_pass@localhost:27018/ecommerce_practice"
    echo ""
    
    echo -e "${GREEN}MongoDB Express (Web UI):${NC}"
    echo "  URL: http://localhost:8082"
    echo "  Username: admin"
    echo "  Password: admin123"
    echo ""
}

# Function to show logs
show_logs() {
    service=${1:-}
    if [ -z "$service" ]; then
        print_status "Showing logs for all services..."
        docker-compose logs -f
    else
        print_status "Showing logs for $service..."
        docker-compose logs -f "$service"
    fi
}

# Function to open database shells
connect_postgres() {
    print_status "Connecting to PostgreSQL..."
    docker exec -it practice-postgresql psql -U practice_user -d ecommerce_practice
}

connect_mongo() {
    print_status "Connecting to MongoDB..."
    docker exec -it practice-mongodb mongosh --username practice_user --password practice_pass --authenticationDatabase ecommerce_practice ecommerce_practice
}

# Function to run sample queries
run_sample_queries() {
    print_header "Running Sample Queries"
    
    print_status "PostgreSQL Sample Query - Top spending customers (last 6 months):"
    docker exec practice-postgresql psql -U practice_user -d ecommerce_practice -c "
    SELECT
        c.customer_id,
        c.name,
        c.email,
        SUM(o.total_amount) AS total_spent
    FROM
        customers c
    JOIN
        orders o ON c.customer_id = o.customer_id
    WHERE
        o.order_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY
        c.customer_id,
        c.name,
        c.email
    ORDER BY
        total_spent DESC
    LIMIT 10;"
    
    echo ""
    print_status "MongoDB Sample Query - Customer interactions aggregation:"
    docker exec practice-mongodb mongosh --username practice_user --password practice_pass --authenticationDatabase ecommerce_practice ecommerce_practice --eval "
    db.customers.aggregate([
      { \$lookup: {
          from: 'interactions',
          localField: 'customer_id',
          foreignField: 'customer_id',
          as: 'customer_interactions'
      }},
      { \$project: {
          customer_id: 1,
          name: 1,
          email: 1,
          interaction_count: { \$size: '\$customer_interactions' }
      }},
      { \$sort: { interaction_count: -1 }},
      { \$limit: 10 }
    ]).pretty();"
}

# Function to show help
show_help() {
    echo "Practice Environment Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start           Start all services"
    echo "  stop            Stop all services"
    echo "  restart         Restart all services"
    echo "  status          Show service status"
    echo "  cleanup         Remove all containers and data"
    echo "  info            Show connection information"
    echo "  logs [service]  Show logs (optional: specify service)"
    echo "  psql            Connect to PostgreSQL"
    echo "  mongo           Connect to MongoDB"
    echo "  query           Run sample queries"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start                    # Start the environment"
    echo "  $0 logs postgresql          # Show PostgreSQL logs"
    echo "  $0 psql                     # Connect to PostgreSQL"
    echo "  $0 query                    # Run sample queries"
}

# Main script logic
main() {
    case "${1:-}" in
        start)
            check_docker
            check_docker_compose
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            stop_services
            sleep 3
            start_services
            ;;
        status)
            show_status
            ;;
        cleanup)
            cleanup_services
            ;;
        info)
            show_connection_info
            ;;
        logs)
            show_logs "${2:-}"
            ;;
        psql)
            connect_postgres
            ;;
        mongo)
            connect_mongo
            ;;
        query)
            run_sample_queries
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: ${1:-}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 