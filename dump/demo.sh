#!/bin/bash

# Demo Multi-Source Data Visualization Management Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_header() { echo -e "${PURPLE}🚀 $1${NC}"; }

check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        if ! docker compose version &> /dev/null; then
            print_error "Docker Compose is not available."
            exit 1
        else
            DOCKER_COMPOSE_CMD="docker compose"
        fi
    else
        DOCKER_COMPOSE_CMD="docker-compose"
    fi
}

start_demo() {
    print_header "Starting Demo Environment"
    check_docker
    check_docker_compose
    
    print_info "Building and starting containers..."
    $DOCKER_COMPOSE_CMD up -d --build
    
    print_info "Waiting for services to be ready..."
    sleep 10
    
    print_success "Demo environment started!"
    print_info "Access the demo at: ${CYAN}http://localhost:3000${NC}"
    print_info "MongoDB Express: ${CYAN}http://localhost:8083${NC}"
}

stop_demo() {
    print_header "Stopping Demo Environment"
    check_docker_compose
    $DOCKER_COMPOSE_CMD down
    print_success "Demo environment stopped!"
}

restart_demo() {
    stop_demo
    sleep 2
    start_demo
}

check_status() {
    print_header "Demo Environment Status"
    check_docker_compose
    $DOCKER_COMPOSE_CMD ps
}

view_logs() {
    check_docker_compose
    if [ -z "$2" ]; then
        $DOCKER_COMPOSE_CMD logs -f
    else
        $DOCKER_COMPOSE_CMD logs -f "$2"
    fi
}

cleanup_demo() {
    print_header "Cleaning Up Demo Environment"
    check_docker_compose
    print_warning "This will remove all containers and volumes. Continue? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        $DOCKER_COMPOSE_CMD down -v --remove-orphans
        print_success "Cleanup completed!"
    fi
}

show_info() {
    print_header "Demo Connection Information"
    echo ""
    print_info "🌐 Web Application: http://localhost:3000"
    print_info "🐘 PostgreSQL: localhost:5434 (demo_user/demo_password)"
    print_info "🍃 MongoDB: localhost:27019 (demo_admin/demo_password)"
    print_info "🌿 MongoDB Express: http://localhost:8083"
}

show_help() {
    print_header "Demo Multi-Source Data Visualization - Help"
    echo ""
    echo "Commands:"
    echo "  start       Start the demo environment"
    echo "  stop        Stop the demo environment"
    echo "  restart     Restart the demo environment"
    echo "  status      Show status of services"
    echo "  logs [svc]  Show logs"
    echo "  cleanup     Remove containers and volumes"
    echo "  info        Show connection information"
    echo "  help        Show this help"
}

case $1 in
    start) start_demo ;;
    stop) stop_demo ;;
    restart) restart_demo ;;
    status) check_status ;;
    logs) view_logs "$@" ;;
    cleanup) cleanup_demo ;;
    info) show_info ;;
    help|--help|-h) show_help ;;
    "") print_error "No command specified. Use 'help' for commands."; show_help ;;
    *) print_error "Unknown command: $1"; show_help; exit 1 ;;
esac