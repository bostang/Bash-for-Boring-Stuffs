#!/bin/bash

set -e

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                 ELK Stack Demo - Linux                      ║"
echo "║          Elasticsearch + Logstash + Kibana + Filebeat       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Detect Linux distribution
detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        DISTRO="unknown"
        VERSION="unknown"
    fi
}

# Fungsi untuk print dengan warna
print_step() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Detect Docker Compose command (Linux prefers 'docker compose' over 'docker-compose')
detect_docker_compose_cmd() {
    if command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker compose"
    elif command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker-compose"
    else
        print_error "Docker Compose tidak ditemukan! Install dengan:"
        echo "  Ubuntu/Debian: sudo apt-get install docker-compose-plugin"
        echo "  RHEL/CentOS: sudo dnf install docker-compose-plugin"
        echo "  Atau: pip install docker-compose"
        exit 1
    fi
    print_info "Menggunakan: $DOCKER_COMPOSE_CMD"
}

# Fungsi untuk memeriksa apakah Docker sudah berjalan
check_docker() {
    print_step "Memeriksa Docker..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker tidak terinstall!"
        echo "Install Docker dengan:"
        echo "  curl -fsSL https://get.docker.com -o get-docker.sh"
        echo "  sudo sh get-docker.sh"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker tidak berjalan! Jalankan dengan:"
        echo "  sudo systemctl start docker"
        echo "  sudo systemctl enable docker"
        echo "  Atau tambahkan user ke group docker: sudo usermod -aG docker \$USER"
        exit 1
    fi
    print_success "Docker sudah berjalan"
}

# Fungsi untuk memeriksa docker-compose
check_docker_compose() {
    print_step "Memeriksa Docker Compose..."
    detect_docker_compose_cmd
    print_success "Docker Compose tersedia"
}

# Check system requirements for Linux
check_system_requirements() {
    print_step "Memeriksa system requirements..."
    
    # Check available memory
    TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$TOTAL_MEM" -lt 4096 ]; then
        print_warning "RAM tersedia: ${TOTAL_MEM}MB. Direkomendasikan minimal 4GB untuk ELK Stack"
        print_info "Demo tetap bisa berjalan tapi mungkin lambat..."
    else
        print_success "RAM tersedia: ${TOTAL_MEM}MB"
    fi
    
    # Check disk space
    AVAILABLE_SPACE=$(df -BM . | awk 'NR==2 {print $4}' | sed 's/M//')
    if [ "$AVAILABLE_SPACE" -lt 2048 ]; then
        print_warning "Disk space tersedia: ${AVAILABLE_SPACE}MB. Direkomendasikan minimal 2GB"
    else
        print_success "Disk space tersedia: ${AVAILABLE_SPACE}MB"
    fi
    
    # Check if vm.max_map_count is set properly for Elasticsearch
    if [ -f /proc/sys/vm/max_map_count ]; then
        CURRENT_MAP_COUNT=$(cat /proc/sys/vm/max_map_count)
        if [ "$CURRENT_MAP_COUNT" -lt 262144 ]; then
            print_warning "vm.max_map_count terlalu rendah ($CURRENT_MAP_COUNT). Setting optimal value..."
            if [ "$EUID" -eq 0 ]; then
                sysctl -w vm.max_map_count=262144
                print_success "vm.max_map_count sudah disesuaikan"
            else
                print_info "Untuk performance optimal, jalankan: sudo sysctl -w vm.max_map_count=262144"
            fi
        else
            print_success "vm.max_map_count sudah optimal ($CURRENT_MAP_COUNT)"
        fi
    fi
}

# Fungsi untuk membersihkan container lama
cleanup_old_containers() {
    print_step "Membersihkan container lama..."
    $DOCKER_COMPOSE_CMD down -v --remove-orphans 2>/dev/null || true
    print_success "Container lama sudah dibersihkan"
}

# Fungsi untuk membangun dan menjalankan container
start_elk_stack() {
    print_step "Membangun dan menjalankan ELK Stack..."
    
    # Set appropriate memory limits for Linux
    export ES_JAVA_OPTS="-Xms512m -Xmx512m"
    export LS_JAVA_OPTS="-Xmx256m -Xms256m"
    
    $DOCKER_COMPOSE_CMD up -d
    print_success "ELK Stack container sudah dimulai"
}

# Fungsi untuk menunggu service siap
wait_for_services() {
    print_step "Menunggu service siap..."
    
    print_info "Menunggu Elasticsearch..."
    COUNTER=0
    MAX_WAIT=60
    until curl -s http://localhost:9200/_cluster/health >/dev/null 2>&1; do
        echo -n "."
        sleep 5
        COUNTER=$((COUNTER + 5))
        if [ $COUNTER -ge $MAX_WAIT ]; then
            print_error "Elasticsearch tidak merespons setelah ${MAX_WAIT}s"
            print_info "Cek logs: $DOCKER_COMPOSE_CMD logs elasticsearch"
            exit 1
        fi
    done
    print_success "Elasticsearch siap!"
    
    print_info "Menunggu Kibana..."
    COUNTER=0
    until curl -s http://localhost:5601/api/status >/dev/null 2>&1; do
        echo -n "."
        sleep 5
        COUNTER=$((COUNTER + 5))
        if [ $COUNTER -ge $MAX_WAIT ]; then
            print_error "Kibana tidak merespons setelah ${MAX_WAIT}s"
            print_info "Cek logs: $DOCKER_COMPOSE_CMD logs kibana"
            exit 1
        fi
    done
    print_success "Kibana siap!"
}

# Fungsi untuk membuat index pattern di Kibana
setup_kibana_index_pattern() {
    print_step "Membuat index pattern di Kibana..."
    
    # Tunggu beberapa detik untuk memastikan log sudah masuk
    sleep 15
    
    # Delete existing index pattern if exists
    curl -X DELETE "localhost:5601/api/saved_objects/index-pattern/demo-logs" \
        -H "kbn-xsrf: true" >/dev/null 2>&1 || true
    
    sleep 2
    
    # Buat index pattern baru
    curl -X POST "localhost:5601/api/saved_objects/index-pattern" \
        -H "kbn-xsrf: true" \
        -H "Content-Type: application/json" \
        -d '{
            "attributes": {
                "title": "demo-logs-*",
                "timeFieldName": "@timestamp"
            }
        }' >/dev/null 2>&1 || true
    
    print_success "Index pattern dibuat (demo-logs-*)"
}

# Fungsi untuk menampilkan status service
show_service_status() {
    print_step "Status service:"
    echo -e "${CYAN}"
    $DOCKER_COMPOSE_CMD ps
    echo -e "${NC}"
}

# Fungsi untuk menampilkan URL akses
show_access_urls() {
    echo -e "${GREEN}"
    echo "🌐 URL Akses Service:"
    echo "   📊 Kibana Dashboard: http://localhost:5601"
    echo "   🔍 Elasticsearch:    http://localhost:9200"
    echo "   ⚙️  Logstash:         http://localhost:9600"
    echo -e "${NC}"
}

# Fungsi untuk menjalankan log generator
start_log_generator() {
    print_step "Memulai log generator..."
    chmod +x scripts/generate_logs.sh
    
    print_info "Log generator akan berjalan di background..."
    print_info "File log akan diupdate secara real-time"
    
    # Ensure log directories exist with proper permissions
    mkdir -p logs/{apache,nginx,application}
    chmod 755 logs/{apache,nginx,application}
    
    # Jalankan log generator di background
    nohup ./scripts/generate_logs.sh > log_generator.out 2>&1 &
    LOG_GENERATOR_PID=$!
    echo $LOG_GENERATOR_PID > log_generator.pid
    
    print_success "Log generator dimulai (PID: $LOG_GENERATOR_PID)"
}

# Fungsi untuk menghentikan log generator
stop_log_generator() {
    if [ -f log_generator.pid ]; then
        LOG_GENERATOR_PID=$(cat log_generator.pid)
        if kill -0 $LOG_GENERATOR_PID 2>/dev/null; then
            kill $LOG_GENERATOR_PID
            print_success "Log generator dihentikan"
        fi
        rm -f log_generator.pid log_generator.out
    fi
}

# Fungsi untuk shutdown
shutdown_demo() {
    print_step "Menghentikan demo..."
    stop_log_generator
    $DOCKER_COMPOSE_CMD down -v
    print_success "Demo dihentikan"
}

# Fungsi untuk menampilkan bantuan
show_help() {
    echo -e "${CYAN}"
    echo "ELK Stack Demo untuk Linux - Perintah yang tersedia:"
    echo ""
    echo "  start     - Memulai ELK Stack demo"
    echo "  stop      - Menghentikan demo"
    echo "  restart   - Restart demo"
    echo "  logs      - Menampilkan logs container"
    echo "  status    - Menampilkan status container"
    echo "  monitor   - Monitor sistem resources"
    echo "  cleanup   - Bersihkan semua data (reset)"
    echo "  help      - Menampilkan bantuan ini"
    echo ""
    echo "System Requirements:"
    echo "  - Docker & Docker Compose"
    echo "  - 4GB+ RAM (minimal 2GB)"
    echo "  - 2GB+ free disk space"
    echo "  - Linux kernel 3.10+"
    echo -e "${NC}"
}

# Monitor system resources
monitor_system() {
    print_step "Monitoring sistem..."
    echo -e "${CYAN}"
    echo "=== System Resources ==="
    echo "Memory Usage:"
    free -h
    echo ""
    echo "Disk Usage:"
    df -h .
    echo ""
    echo "Docker Stats:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
    echo -e "${NC}"
}

# Cleanup function for complete reset
cleanup_all() {
    print_step "Membersihkan semua data demo..."
    
    stop_log_generator
    $DOCKER_COMPOSE_CMD down -v --rmi local --remove-orphans 2>/dev/null || true
    
    # Remove generated logs
    if [ -d "logs" ]; then
        find logs -name "*.log" -type f -delete 2>/dev/null || true
    fi
    
    # Remove any leftover files
    rm -f log_generator.out log_generator.pid
    
    print_success "Cleanup selesai"
}

# Fungsi utama untuk memulai demo
start_demo() {
    print_step "Memulai ELK Stack Demo untuk Linux..."
    
    detect_linux_distro
    print_info "Detected: $DISTRO $VERSION"
    
    check_docker
    check_docker_compose
    check_system_requirements
    cleanup_old_containers
    start_elk_stack
    wait_for_services
    start_log_generator
    setup_kibana_index_pattern
    show_service_status
    show_access_urls
    
    echo -e "${GREEN}"
    echo "🎉 ELK Stack Demo berhasil dimulai di Linux!"
    echo ""
    echo "📝 Langkah selanjutnya:"
    echo "   1. Buka Kibana di http://localhost:5601"
    echo "   2. Pergi ke Analytics > Discover"
    echo "   3. Pilih index pattern 'demo-logs-*'"
    echo "   4. Lihat log real-time yang masuk"
    echo "   5. Buat visualisasi dan dashboard"
    echo ""
    echo "🔧 Monitoring:"
    echo "   - Monitor system: ./run-elk-demo.sh monitor"
    echo "   - Lihat logs: ./run-elk-demo.sh logs"
    echo "   - Status: ./run-elk-demo.sh status"
    echo ""
    echo "⏹️  Untuk menghentikan demo: ./run-elk-demo.sh stop"
    echo -e "${NC}"
}

# Main script logic
case "${1:-start}" in
    "start")
        start_demo
        ;;
    "stop")
        shutdown_demo
        ;;
    "restart")
        shutdown_demo
        sleep 3
        start_demo
        ;;
    "logs")
        if [ -n "$2" ]; then
            $DOCKER_COMPOSE_CMD logs -f "$2"
        else
            $DOCKER_COMPOSE_CMD logs -f
        fi
        ;;
    "status")
        show_service_status
        ;;
    "monitor")
        monitor_system
        ;;
    "cleanup")
        cleanup_all
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Perintah tidak dikenal: $1"
        show_help
        exit 1
        ;;
esac 