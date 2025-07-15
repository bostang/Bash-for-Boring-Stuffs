#!/bin/bash

# Linux DD Simple - Service Installation Script
# Installs the application as a systemd user service

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_header() { echo -e "${MAGENTA}🐧 $1${NC}"; }

# Check if systemd is available
check_systemd() {
    if ! command -v systemctl >/dev/null 2>&1; then
        print_error "systemd is not available on this system"
        print_info "This script requires systemd for service management"
        return 1
    fi
    
    # Check if user services are supported
    if ! systemctl --user --version >/dev/null 2>&1; then
        print_error "systemd user services are not available"
        return 1
    fi
    
    print_success "systemd user services available"
    return 0
}

# Install the service
install_service() {
    local service_dir="$HOME/.config/systemd/user"
    local service_file="$service_dir/node-demo.service"
    local current_dir=$(pwd)
    
    print_info "Installing systemd user service..."
    
    # Create systemd user directory if it doesn't exist
    mkdir -p "$service_dir"
    
    # Copy service file and substitute variables
    sed "s|%h/linux-dd-simple|$current_dir|g" node-demo.service > "$service_file"
    
    # Reload systemd user daemon
    systemctl --user daemon-reload
    
    print_success "Service file installed: $service_file"
    
    # Enable the service (optional)
    read -p "$(echo -e "${CYAN}Enable service to start automatically? (y/N):${NC} ")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl --user enable node-demo.service
        print_success "Service enabled for automatic startup"
    else
        print_info "Service installed but not enabled"
    fi
}

# Show service management commands
show_usage() {
    print_header "Service Management Commands"
    echo
    echo -e "${CYAN}Start service:${NC}       systemctl --user start node-demo"
    echo -e "${CYAN}Stop service:${NC}        systemctl --user stop node-demo"
    echo -e "${CYAN}Restart service:${NC}     systemctl --user restart node-demo"
    echo -e "${CYAN}Check status:${NC}        systemctl --user status node-demo"
    echo -e "${CYAN}View logs:${NC}           journalctl --user -f -u node-demo"
    echo -e "${CYAN}Enable autostart:${NC}    systemctl --user enable node-demo"
    echo -e "${CYAN}Disable autostart:${NC}   systemctl --user disable node-demo"
    echo
    echo -e "${CYAN}Enable user lingering (persist after logout):${NC}"
    echo -e "  sudo loginctl enable-linger $USER"
    echo
}

# Main function
main() {
    print_header "Linux DD Simple - Service Installation"
    echo
    
    # Check prerequisites
    if ! check_systemd; then
        exit 1
    fi
    
    # Verify we're in the right directory
    if [[ ! -f "server.js" ]] || [[ ! -f "node-demo.service" ]]; then
        print_error "Please run this script from the linux-dd-simple directory"
        print_info "Required files: server.js, node-demo.service"
        exit 1
    fi
    
    # Install the service
    install_service
    
    echo
    show_usage
    
    echo
    print_success "🎉 Service installation completed!"
    print_info "You can now manage the application as a systemd user service"
}

main "$@" 