#!/bin/bash

# Apache Airflow Setup Script for Ubuntu Linux
# This script automates the setup process for Ubuntu systems

set -e  # Exit on any error

echo "🐧 Apache Airflow Setup for Ubuntu Linux"
echo "========================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Ubuntu
check_ubuntu() {
    print_status "Checking Ubuntu version..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            print_success "Ubuntu $VERSION_ID detected"
            
            # Check Ubuntu version
            version_major=$(echo $VERSION_ID | cut -d. -f1)
            if [ "$version_major" -lt 18 ]; then
                print_warning "Ubuntu 18.04 LTS or later is recommended. You have $VERSION_ID"
            fi
        else
            print_warning "This script is optimized for Ubuntu. Detected: $PRETTY_NAME"
        fi
    else
        print_warning "Could not detect OS version"
    fi
}

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check memory
    memory_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$memory_gb" -lt 4 ]; then
        print_warning "Low memory detected: ${memory_gb}GB. 4GB+ recommended"
    else
        print_success "Memory: ${memory_gb}GB (adequate)"
    fi
    
    # Check CPU cores
    cpu_cores=$(nproc)
    if [ "$cpu_cores" -lt 2 ]; then
        print_warning "Low CPU cores: ${cpu_cores}. 2+ cores recommended"
    else
        print_success "CPU cores: ${cpu_cores} (adequate)"
    fi
    
    # Check disk space
    disk_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$disk_space" -lt 10 ]; then
        print_warning "Low disk space: ${disk_space}GB. 10GB+ recommended"
    else
        print_success "Disk space: ${disk_space}GB (adequate)"
    fi
}

# Check if Docker is installed
check_docker() {
    print_status "Checking Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        print_warning "Docker not found. Installing Docker..."
        install_docker
    else
        print_success "Docker is installed: $(docker --version)"
        
        # Check if user is in docker group
        if ! groups $USER | grep -q docker; then
            print_warning "User $USER is not in docker group"
            sudo usermod -aG docker $USER
            print_warning "Added $USER to docker group. Please logout and login again, then re-run this script"
            exit 1
        else
            print_success "User $USER is in docker group"
        fi
    fi
}

# Install Docker
install_docker() {
    print_status "Installing Docker on Ubuntu..."
    
    # Update package index
    sudo apt update
    
    # Install Docker
    sudo apt install docker.io -y
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    print_success "Docker installed successfully"
    print_warning "Please logout and login again to use Docker without sudo, then re-run this script"
    exit 1
}

# Check if Docker Compose is installed
check_docker_compose() {
    print_status "Checking Docker Compose installation..."
    
    if ! command -v docker-compose &> /dev/null; then
        print_warning "Docker Compose not found. Installing..."
        install_docker_compose
    else
        print_success "Docker Compose is installed: $(docker-compose --version)"
    fi
}

# Install Docker Compose
install_docker_compose() {
    print_status "Installing Docker Compose..."
    
    # Install via apt (Ubuntu 20.04+)
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install docker-compose -y
        print_success "Docker Compose installed via apt"
    else
        # Fallback to manual installation
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        print_success "Docker Compose installed manually"
    fi
}

# Setup AIRFLOW_UID
setup_airflow_uid() {
    print_status "Setting up AIRFLOW_UID for Ubuntu..."
    
    current_uid=$(id -u)
    
    if [ -f .env ]; then
        if grep -q "AIRFLOW_UID" .env; then
            existing_uid=$(grep "AIRFLOW_UID" .env | cut -d= -f2)
            if [ "$existing_uid" != "$current_uid" ]; then
                print_warning "Updating AIRFLOW_UID from $existing_uid to $current_uid"
                sed -i "s/AIRFLOW_UID=.*/AIRFLOW_UID=$current_uid/" .env
            else
                print_success "AIRFLOW_UID already set correctly: $current_uid"
            fi
        else
            echo "AIRFLOW_UID=$current_uid" >> .env
            print_success "Added AIRFLOW_UID to .env: $current_uid"
        fi
    else
        echo "AIRFLOW_UID=$current_uid" > .env
        print_success "Created .env with AIRFLOW_UID: $current_uid"
    fi
}

# Create required directories
setup_directories() {
    print_status "Setting up directories with proper permissions..."
    
    mkdir -p dags logs plugins data
    
    # Set proper permissions for Ubuntu
    chmod 755 dags logs plugins data
    
    print_success "Directories created with proper permissions"
}

# Initialize Airflow
initialize_airflow() {
    print_status "Initializing Airflow..."
    
    # Pull images first
    print_status "Pulling Docker images..."
    docker-compose pull
    
    # Initialize Airflow database
    print_status "Initializing Airflow database (this may take a few minutes)..."
    docker-compose up airflow-init
    
    if [ $? -eq 0 ]; then
        print_success "Airflow initialized successfully"
    else
        print_error "Failed to initialize Airflow"
        exit 1
    fi
}

# Start services
start_services() {
    print_status "Starting Airflow services..."
    
    docker-compose up -d
    
    if [ $? -eq 0 ]; then
        print_success "Airflow services started successfully"
        
        # Wait for services to be ready
        print_status "Waiting for services to be ready..."
        sleep 30
        
        # Check if webserver is responding
        if curl -s http://localhost:8080/health > /dev/null; then
            print_success "Airflow webserver is ready!"
        else
            print_warning "Webserver might still be starting up. Please wait a moment."
        fi
    else
        print_error "Failed to start Airflow services"
        exit 1
    fi
}

# Display final information
show_completion_info() {
    echo ""
    echo "🎉 Ubuntu Airflow Setup Complete!"
    echo "================================="
    echo ""
    echo "📊 Access Information:"
    echo "  • Web UI: http://localhost:8080"
    echo "  • Username: admin"
    echo "  • Password: admin"
    echo ""
    echo "🔧 Useful Commands:"
    echo "  • View status: docker-compose ps"
    echo "  • View logs: docker-compose logs"
    echo "  • Stop services: docker-compose down"
    echo "  • Restart services: docker-compose restart"
    echo ""
    echo "📁 Directory Structure:"
    echo "  • DAGs: ./dags/"
    echo "  • Logs: ./logs/"
    echo "  • Data: ./data/"
    echo "  • Plugins: ./plugins/"
    echo ""
    echo "🐛 Troubleshooting:"
    echo "  • Check system resources: htop"
    echo "  • Check Docker stats: docker stats"
    echo "  • View service logs: docker-compose logs [service-name]"
    echo ""
    print_success "Happy Data Engineering on Ubuntu! 🐧✈️"
}

# Main execution
main() {
    echo ""
    
    # Run all checks and setup
    check_ubuntu
    check_requirements
    check_docker
    check_docker_compose
    setup_airflow_uid
    setup_directories
    
    # Ask user if they want to proceed with initialization
    echo ""
    read -p "Do you want to initialize and start Airflow now? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        initialize_airflow
        start_services
        show_completion_info
    else
        print_status "Setup completed. To start Airflow later, run:"
        echo "  docker-compose up airflow-init"
        echo "  docker-compose up -d"
    fi
}

# Check if script is run from correct directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please run this script from the linux-airflow directory."
    exit 1
fi

# Run main function
main 