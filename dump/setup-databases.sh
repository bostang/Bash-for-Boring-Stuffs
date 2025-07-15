#!/bin/bash
# Database Setup Script for Unix/Linux Demo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Helper functions
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_header() { echo -e "${MAGENTA}🚀 $1${NC}"; }

show_help() {
    print_header "Database Setup Script - Help"
    echo ""
    echo -e "${WHITE}Usage: ./setup-databases.sh [database]${NC}"
    echo ""
    echo -e "${WHITE}Parameters:${NC}"
    echo -e "${GRAY}  all        Setup both PostgreSQL and MongoDB (default)${NC}"
    echo -e "${GRAY}  postgres   Setup only PostgreSQL (Neon)${NC}"
    echo -e "${GRAY}  mongodb    Setup only MongoDB (Atlas)${NC}"
    echo ""
    echo -e "${WHITE}Examples:${NC}"
    echo -e "${CYAN}  ./setup-databases.sh${NC}"
    echo -e "${CYAN}  ./setup-databases.sh postgres${NC}"
    echo -e "${CYAN}  ./setup-databases.sh mongodb${NC}"
}

setup_postgresql() {
    print_header "Setting up PostgreSQL (Neon Database)"
    print_info "Please follow these steps to setup your Neon PostgreSQL database:"
    echo ""
    echo -e "${WHITE}1. Go to your Neon Console: ${CYAN}https://console.neon.tech/${NC}"
    echo ""
    echo -e "${WHITE}2. Select your database: ${YELLOW}neondb${NC}"
    echo ""
    echo -e "${WHITE}3. Open the SQL Editor and run the following file:${NC}"
    echo -e "   File: ${YELLOW}setup-databases.sql${NC}"
    echo ""
    echo -e "${WHITE}4. Or copy and paste the SQL commands from:${NC}"
    echo -e "   ${CYAN}$(pwd)/setup-databases.sql${NC}"
    echo ""
    print_warning "Make sure to run all the SQL commands in the file!"
    echo ""
    
    # Check if SQL file exists
    if [ -f "setup-databases.sql" ]; then
        print_info "SQL setup file found: setup-databases.sql"
        echo ""
        echo -e "${WHITE}The SQL file contains:${NC}"
        echo -e "${GRAY}  • CREATE TABLE statements for products and sales${NC}"
        echo -e "${GRAY}  • Sample data for 10 products${NC}"
        echo -e "${GRAY}  • Sample sales data for 6 months${NC}"
        echo -e "${GRAY}  • Performance indexes${NC}"
    else
        print_error "SQL setup file not found! Please make sure setup-databases.sql exists."
        return 1
    fi
    
    echo ""
    read -p "Have you completed the PostgreSQL setup? (y/n): " response
    if [[ "$response" =~ ^[yY]$ ]]; then
        print_success "PostgreSQL setup marked as complete!"
        return 0
    else
        print_warning "Please complete the PostgreSQL setup before proceeding."
        return 1
    fi
}

setup_mongodb() {
    print_header "Setting up MongoDB (Atlas Database)"
    
    # Check if Node.js is available
    if ! command -v node &> /dev/null; then
        print_error "Node.js is required to run the MongoDB setup script."
        print_info "Please install Node.js from: https://nodejs.org/"
        return 1
    fi
    
    local node_version=$(node --version)
    print_info "Node.js found: $node_version"
    
    # Check if setup script exists
    if [ ! -f "setup-mongodb.js" ]; then
        print_error "MongoDB setup script not found! Please make sure setup-mongodb.js exists."
        return 1
    fi
    
    print_info "Running MongoDB Atlas setup script..."
    echo ""
    
    # Run the MongoDB setup script
    if node setup-mongodb.js; then
        print_success "MongoDB Atlas setup completed successfully!"
        return 0
    else
        print_error "MongoDB setup failed"
        return 1
    fi
}

test_database_connections() {
    print_header "Testing Database Connections"
    
    print_info "Starting webapp container to test connections..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not running."
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        return 1
    fi
    
    # Start the webapp temporarily
    print_info "Building and starting webapp container..."
    if docker-compose up -d --build webapp; then
        print_info "Waiting for services to initialize..."
        sleep 10
        
        # Test health endpoint
        if command -v curl &> /dev/null; then
            local health_response=$(curl -s http://localhost:3000/api/health 2>/dev/null)
            if [[ $? -eq 0 ]]; then
                # Check if both services are healthy
                if echo "$health_response" | grep -q '"postgresql":"healthy"' && echo "$health_response" | grep -q '"mongodb":"healthy"'; then
                    print_success "Both databases are connected and healthy!"
                    echo ""
                    echo -e "${WHITE}Database Status:${NC}"
                    echo -e "  PostgreSQL: ${GREEN}✅ Connected${NC}"
                    echo -e "  MongoDB: ${GREEN}✅ Connected${NC}"
                    
                    # Clean up
                    print_info "Stopping test containers..."
                    docker-compose down &> /dev/null
                    return 0
                else
                    print_warning "Database connection issues detected."
                    echo "Health response: $health_response"
                    
                    # Clean up
                    print_info "Stopping test containers..."
                    docker-compose down &> /dev/null
                    return 1
                fi
            else
                print_error "Failed to connect to health endpoint"
                
                # Clean up
                print_info "Stopping test containers..."
                docker-compose down &> /dev/null
                return 1
            fi
        else
            print_warning "curl not found. Please test manually: http://localhost:3000/api/health"
            
            # Clean up
            print_info "Stopping test containers..."
            docker-compose down &> /dev/null
            return 0
        fi
    else
        print_error "Failed to start webapp container"
        return 1
    fi
}

# Main execution
DATABASE=${1:-all}

case $DATABASE in
    help|--help|-h)
        show_help
        exit 0
        ;;
    all|postgres|mongodb)
        ;;
    *)
        print_error "Invalid parameter: $DATABASE"
        show_help
        exit 1
        ;;
esac

print_header "Database Setup for Unix/Linux Demo"
echo ""

postgres_success=true
mongo_success=true

if [[ "$DATABASE" == "all" || "$DATABASE" == "postgres" ]]; then
    if ! setup_postgresql; then
        postgres_success=false
    fi
    echo ""
fi

if [[ "$DATABASE" == "all" || "$DATABASE" == "mongodb" ]]; then
    if ! setup_mongodb; then
        mongo_success=false
    fi
    echo ""
fi

if [[ "$postgres_success" == true && "$mongo_success" == true ]]; then
    print_header "Running Connection Tests"
    if test_database_connections; then
        echo ""
        print_success "🎉 Database setup completed successfully!"
        echo ""
        print_info "You can now run the demo with:"
        echo -e "${CYAN}  ./demo.sh start${NC}"
        echo ""
        print_info "Access the dashboard at:"
        echo -e "${CYAN}  http://localhost:3000${NC}"
    else
        echo ""
        print_warning "Database setup completed but connection tests failed."
        print_info "Please check your database configurations and try again."
    fi
else
    echo ""
    print_error "Database setup incomplete. Please resolve the issues above."
    echo ""
    print_info "For help, run:"
    echo -e "${CYAN}  ./setup-databases.sh help${NC}"
fi 