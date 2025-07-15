#!/bin/bash

# Database Fix Script for Linux DD Simple
# Optimized for various Linux distributions

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color support detection for Linux terminals
setup_colors() {
    if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
        RED=$(tput setaf 1)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
        MAGENTA=$(tput setaf 5)
        CYAN=$(tput setaf 6)
        WHITE=$(tput setaf 7)
        BOLD=$(tput bold)
        NC=$(tput sgr0)
    else
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        MAGENTA=''
        CYAN=''
        WHITE=''
        BOLD=''
        NC=''
    fi
}

# Initialize colors
setup_colors

# Helper functions with Linux-specific features
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_header() { echo -e "${MAGENTA}${BOLD}🐧 $1${NC}"; }

# System information detection
detect_system() {
    if command -v lsb_release >/dev/null 2>&1; then
        DISTRO=$(lsb_release -si)
        VERSION=$(lsb_release -sr)
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=$NAME
        VERSION=$VERSION_ID
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO=$(cat /etc/redhat-release | cut -d' ' -f1)
        VERSION=$(cat /etc/redhat-release | sed 's/.*release \([0-9.]*\).*/\1/')
    else
        DISTRO="Unknown"
        VERSION="Unknown"
    fi
    
    ARCH=$(uname -m)
    KERNEL=$(uname -r)
    SHELL_NAME=$(basename "$SHELL")
}

# Performance monitoring
show_system_info() {
    detect_system
    print_info "System: $DISTRO $VERSION ($ARCH)"
    print_info "Kernel: $KERNEL"
    print_info "Shell: $SHELL_NAME"
    print_info "Terminal: ${TERM:-Unknown}"
    
    # Memory info (Linux-specific)
    if [[ -f /proc/meminfo ]]; then
        MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024/1024)}')
        MEM_AVAIL=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024/1024)}')
        print_info "Memory: ${MEM_AVAIL}GB available / ${MEM_TOTAL}GB total"
    fi
    
    # Load average (Linux-specific)
    if [[ -f /proc/loadavg ]]; then
        LOAD_AVG=$(cat /proc/loadavg | cut -d' ' -f1-3)
        print_info "Load Average: $LOAD_AVG"
    fi
}

# Check prerequisites with Linux package manager detection
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Node.js
    if ! command -v node >/dev/null 2>&1; then
        print_error "Node.js is required but not installed."
        print_info "Installation commands for common Linux distributions:"
        echo "  ${CYAN}Ubuntu/Debian:${NC} sudo apt update && sudo apt install nodejs npm"
        echo "  ${CYAN}CentOS/RHEL:${NC}  sudo yum install nodejs npm"
        echo "  ${CYAN}Fedora:${NC}       sudo dnf install nodejs npm"
        echo "  ${CYAN}Arch Linux:${NC}   sudo pacman -S nodejs npm"
        echo "  ${CYAN}openSUSE:${NC}     sudo zypper install nodejs npm"
        echo "  ${CYAN}Alpine:${NC}       sudo apk add nodejs npm"
        return 1
    fi
    
    NODE_VERSION=$(node --version)
    print_success "Node.js found: $NODE_VERSION"
    
    # Check npm
    if ! command -v npm >/dev/null 2>&1; then
        print_error "npm is required but not installed."
        return 1
    fi
    
    NPM_VERSION=$(npm --version)
    print_success "npm found: $NPM_VERSION"
    
    # Check network connectivity (Linux-specific)
    if command -v ping >/dev/null 2>&1; then
        if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
            print_success "Network connectivity: OK"
        else
            print_warning "Network connectivity issues detected"
            print_info "Try: sudo systemctl restart NetworkManager"
        fi
    fi
    
    return 0
}

# Enhanced dependency installation with progress
install_dependencies() {
    if [[ ! -d "node_modules" ]]; then
        print_info "Installing npm dependencies..."
        
        # Use npm ci for faster, reliable installation if package-lock.json exists
        if [[ -f "package-lock.json" ]]; then
            npm ci --progress=true
        else
            npm install --progress=true
        fi
        
        if [[ $? -eq 0 ]]; then
            print_success "Dependencies installed successfully"
        else
            print_error "Failed to install dependencies"
            return 1
        fi
    else
        print_success "Dependencies already installed"
    fi
}

# Database setup with timeout and retry
setup_database() {
    local db_type="$1"
    local script_name="$2"
    local timeout=60
    
    print_header "Setting up $db_type"
    
    # Run with timeout (Linux-specific)
    if timeout $timeout node "$script_name"; then
        print_success "$db_type setup completed successfully!"
        return 0
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            print_error "$db_type setup timed out after ${timeout}s"
        else
            print_error "$db_type setup failed with exit code $exit_code"
        fi
        return 1
    fi
}

# Service management for Linux
start_demo_service() {
    print_info "Starting demo application..."
    
    # Start in background with proper Linux process handling
    ./demo.sh start >/dev/null 2>&1 &
    local demo_pid=$!
    
    # Wait for service to start
    print_info "Waiting for services to initialize..."
    sleep 8
    
    return $demo_pid
}

# Advanced health checking with curl alternatives
test_endpoint() {
    local endpoint="$1"
    local description="$2"
    
    print_info "Testing $description..."
    
    # Try curl first, fallback to wget or Python
    local response=""
    if command -v curl >/dev/null 2>&1; then
        response=$(curl -s --connect-timeout 5 --max-time 10 "$endpoint" 2>/dev/null || echo "ERROR")
    elif command -v wget >/dev/null 2>&1; then
        response=$(wget -qO- --timeout=10 "$endpoint" 2>/dev/null || echo "ERROR")
    elif command -v python3 >/dev/null 2>&1; then
        response=$(python3 -c "
import urllib.request
import urllib.error
try:
    with urllib.request.urlopen('$endpoint', timeout=10) as f:
        print(f.read().decode())
except:
    print('ERROR')
" 2>/dev/null || echo "ERROR")
    else
        print_warning "No HTTP client available (curl, wget, or python3)"
        return 1
    fi
    
    if [[ "$response" != "ERROR" ]] && [[ -n "$response" ]]; then
        print_success "$description: OK"
        return 0
    else
        print_warning "$description: Failed"
        return 1
    fi
}

# Main execution
main() {
    print_header "Database Fix Script for Linux DD Simple"
    echo
    
    # Show system information
    show_system_info
    echo
    
    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi
    echo
    
    # Install dependencies
    if ! install_dependencies; then
        exit 1
    fi
    echo
    
    # Setup PostgreSQL
    if ! setup_database "PostgreSQL (Neon Database)" "setup-postgres-auto.js"; then
        exit 1
    fi
    echo
    
    # Setup MongoDB
    if ! setup_database "MongoDB (Atlas Database)" "setup-mongodb.js"; then
        exit 1
    fi
    echo
    
    # Test database connections
    print_header "Testing Database Connections"
    
    # Start demo service
    start_demo_service
    demo_pid=$?
    
    # Test endpoints
    endpoint_tests=(
        "http://localhost:3000/api/health|Health endpoint"
        "http://localhost:3000/api/postgres/sales|PostgreSQL data"
        "http://localhost:3000/api/mongodb/customers|MongoDB data"
        "http://localhost:3000/api/combined/dashboard|Combined analytics"
    )
    
    all_tests_passed=true
    for test in "${endpoint_tests[@]}"; do
        IFS='|' read -r url desc <<< "$test"
        if ! test_endpoint "$url" "$desc"; then
            all_tests_passed=false
        fi
    done
    
    # Stop demo service
    print_info "Stopping test application..."
    ./demo.sh stop >/dev/null 2>&1 || true
    
    echo
    print_header "Database Fix Complete!"
    echo
    
    if $all_tests_passed; then
        print_success "🎉 All databases and endpoints are working correctly!"
    else
        print_warning "⚠️  Some tests failed, but basic setup is complete"
    fi
    
    echo
    print_info "You can now run the demo with:"
    echo "  ${CYAN}./demo.sh start${NC}"
    echo
    print_info "Access the dashboard at:"
    echo "  ${CYAN}http://localhost:3000${NC}"
    echo
    print_info "Linux-specific commands:"
    echo "  ${CYAN}systemctl --user status node-demo${NC}    # Check service status"
    echo "  ${CYAN}journalctl --user -f -u node-demo${NC}    # View logs"
    echo "  ${CYAN}htop${NC}                                  # Monitor system resources"
    echo
}

# Signal handling for graceful shutdown
trap 'echo; print_warning "Script interrupted. Cleaning up..."; ./demo.sh stop >/dev/null 2>&1 || true; exit 130' INT TERM

# Execute main function
main "$@" 