#!/bin/bash

# Log generator script untuk ELK Stack Demo - Linux Edition
# Script ini akan menggenerate log secara kontinyu dengan pattern yang realistis untuk Linux

LOG_DIR="./logs"
APACHE_LOG="$LOG_DIR/apache/access.log"
NGINX_LOG="$LOG_DIR/nginx/access.log"
APP_LOG="$LOG_DIR/application/app.log"

# Pastikan direktori log exists
mkdir -p "$LOG_DIR"/{apache,nginx,application}

# Array untuk sample IPs (campuran public dan private)
IPS=(
    "192.168.1.100" "10.0.0.50" "172.16.0.25" "127.0.0.1"  # Private IPs
    "203.0.113.45" "198.51.100.33" "203.0.113.100" "198.51.100.90"  # Public IPs
    "8.8.8.8" "1.1.1.1" "52.86.100.10" "18.191.45.120"  # Known public IPs
)

# Array untuk sample paths (lebih realistis untuk web server Linux)
APACHE_PATHS=(
    "/index.html" "/home" "/about" "/contact" "/blog" "/products" 
    "/api/v1/users" "/api/v1/auth" "/admin/login" "/admin/dashboard"
    "/static/css/main.css" "/static/js/app.js" "/images/logo.png"
    "/wp-admin" "/wp-login.php" "/favicon.ico" "/robots.txt"
    "/search" "/category/linux" "/category/tech" "/downloads"
)

NGINX_PATHS=(
    "/api/v1/users" "/api/v1/orders" "/api/v1/products" "/api/v1/auth"
    "/health" "/metrics" "/status" "/ping" "/ready"
    "/api/v2/users" "/api/v2/data" "/api/v2/analytics"
    "/webhook/github" "/webhook/slack" "/webhook/docker"
    "/graphql" "/api/v1/logs" "/api/v1/monitoring"
)

# Array untuk HTTP methods dengan distribusi realistis
METHODS=("GET" "GET" "GET" "GET" "GET" "POST" "PUT" "DELETE" "PATCH" "OPTIONS")

# Array untuk HTTP status codes dengan distribusi realistis
STATUS_CODES=("200" "200" "200" "200" "201" "204" "301" "302" "400" "401" "403" "404" "500" "502" "503")

# Array untuk user agents yang lebih lengkap
USER_AGENTS=(
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/121.0"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0"
    "curl/8.4.0"
    "wget/1.21.3"
    "Python-requests/2.31.0"
    "PostmanRuntime/7.34.0"
    "Prometheus/2.45.0"
    "Grafana/10.2.0"
    "Docker/24.0.7"
    "kube-probe/1.28"
    "AWS-Internal"
    "Go-http-client/1.1"
    "Apache-HttpClient/4.5.14"
)

# Array untuk log levels dengan distribusi realistis
LOG_LEVELS=("INFO" "INFO" "INFO" "DEBUG" "DEBUG" "WARN" "ERROR" "TRACE")

# Array untuk aplikasi log messages yang lebih realistis
LOG_MESSAGES=(
    "Application started successfully on port 8080"
    "Database connection pool initialized with 10 connections"
    "User authentication successful for user: admin@example.com"
    "Cache hit for key: user_session_12345"
    "Cache miss for key: product_data_67890"
    "Background job completed: cleanup_temp_files"
    "Scheduled backup job started"
    "Redis connection established"
    "Kafka producer initialized"
    "Microservice discovery completed"
    "Health check endpoint called - all services healthy"
    "Rate limit applied for IP: 192.168.1.100"
    "SSL certificate validation successful"
    "Memory usage: 75% of allocated heap"
    "CPU usage spike detected: 89%"
    "Database query executed in 125ms"
    "External API call to payment gateway successful"
    "Session expired for user: guest_user_456"
    "Failed login attempt from IP: 203.0.113.45"
    "Security scan detected and blocked"
    "Disk space warning: 85% used on /var/log"
    "Log rotation completed for application.log"
    "Container scaling event: adding 2 replicas"
    "Load balancer health check passed"
    "Deployment completed successfully"
)

# Function untuk generate Apache log dengan pattern yang realistis
generate_apache_log() {
    local ip=${IPS[$RANDOM % ${#IPS[@]}]}
    local path=${APACHE_PATHS[$RANDOM % ${#APACHE_PATHS[@]}]}
    local method=${METHODS[$RANDOM % ${#METHODS[@]}]}
    local status=${STATUS_CODES[$RANDOM % ${#STATUS_CODES[@]}]}
    local size=$((RANDOM % 50000 + 100))
    local user_agent=${USER_AGENTS[$RANDOM % ${#USER_AGENTS[@]}]}
    local timestamp=$(date '+%d/%b/%Y:%H:%M:%S %z')
    local referrer=""
    
    # Generate realistic referrer
    if [ $((RANDOM % 3)) -eq 0 ]; then
        referrer="https://www.google.com/search"
    elif [ $((RANDOM % 4)) -eq 0 ]; then
        referrer="https://github.com/"
    else
        referrer="-"
    fi
    
    echo "$ip - - [$timestamp] \"$method $path HTTP/1.1\" $status $size \"$referrer\" \"$user_agent\"" >> "$APACHE_LOG"
}

# Function untuk generate Nginx log
generate_nginx_log() {
    local ip=${IPS[$RANDOM % ${#IPS[@]}]}
    local path=${NGINX_PATHS[$RANDOM % ${#NGINX_PATHS[@]}]}
    local method=${METHODS[$RANDOM % ${#METHODS[@]}]}
    local status=${STATUS_CODES[$RANDOM % ${#STATUS_CODES[@]}]}
    local size=$((RANDOM % 10000 + 50))
    local user_agent=${USER_AGENTS[$RANDOM % ${#USER_AGENTS[@]}]}
    local timestamp=$(date '+%d/%b/%Y:%H:%M:%S %z')
    local referrer=""
    
    # Generate API-appropriate referrer
    if [[ $path == /api/* ]]; then
        referrer="https://api.example.com/"
    elif [[ $path == /webhook/* ]]; then
        referrer="-"
    else
        referrer="https://dashboard.example.com/"
    fi
    
    echo "$ip - - [$timestamp] \"$method $path HTTP/1.1\" $status $size \"$referrer\" \"$user_agent\"" >> "$NGINX_LOG"
}

# Function untuk generate application log
generate_application_log() {
    local level=${LOG_LEVELS[$RANDOM % ${#LOG_LEVELS[@]}]}
    local message=${LOG_MESSAGES[$RANDOM % ${#LOG_MESSAGES[@]}]}
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S,%3N')
    local thread="thread-$((RANDOM % 20 + 1))"
    
    # Add thread info for some messages
    if [ $((RANDOM % 3)) -eq 0 ]; then
        echo "[$timestamp] [$thread] $level: $message" >> "$APP_LOG"
    else
        echo "[$timestamp] $level: $message" >> "$APP_LOG"
    fi
}

# Function untuk generate system logs (bonus)
generate_system_log() {
    local timestamp=$(date '+%b %d %H:%M:%S')
    local hostname="linux-server"
    local process="systemd"
    local pid=$((RANDOM % 9999 + 1000))
    local messages=(
        "Started session 123 of user admin"
        "Service nginx.service started"
        "Service docker.service reloaded"
        "Mounting /dev/sda1 on /var/log"
        "Network interface eth0 up"
        "CPU temperature: 45°C"
        "Memory usage: 2.1GB/4.0GB"
    )
    local message=${messages[$RANDOM % ${#messages[@]}]}
    
    # Create syslog if directory exists
    if [ -d "$LOG_DIR/system" ]; then
        echo "$timestamp $hostname $process[$pid]: $message" >> "$LOG_DIR/system/syslog"
    fi
}

# Signal handler untuk graceful shutdown
cleanup() {
    echo ""
    echo "🛑 Log generator dihentikan"
    echo "📊 Total logs yang dihasilkan:"
    [ -f "$APACHE_LOG" ] && echo "   Apache: $(wc -l < "$APACHE_LOG") lines"
    [ -f "$NGINX_LOG" ] && echo "   Nginx:  $(wc -l < "$NGINX_LOG") lines"
    [ -f "$APP_LOG" ] && echo "   App:    $(wc -l < "$APP_LOG") lines"
    exit 0
}

# Setup signal handlers
trap cleanup SIGINT SIGTERM

echo "🚀 Memulai ELK Stack Log Generator untuk Linux..."
echo "📁 Log directory: $LOG_DIR"
echo "🐧 Optimized untuk environment Linux"
echo "⏹️  Tekan Ctrl+C untuk menghentikan"
echo ""

# Create initial log entries
generate_apache_log
generate_nginx_log
generate_application_log

# Counter untuk menampilkan progress
COUNTER=0

# Main loop dengan distribusi yang realistis
while true; do
    COUNTER=$((COUNTER + 1))
    
    # Generate Apache log (70% chance)
    if [ $((RANDOM % 10)) -lt 7 ]; then
        generate_apache_log
        [ $((COUNTER % 20)) -eq 0 ] && echo "📄 Apache log generated (total: $COUNTER cycles)"
    fi
    
    # Generate Nginx log (60% chance) 
    if [ $((RANDOM % 10)) -lt 6 ]; then
        generate_nginx_log
        [ $((COUNTER % 25)) -eq 0 ] && echo "🌐 Nginx log generated"
    fi
    
    # Generate Application log (50% chance)
    if [ $((RANDOM % 10)) -lt 5 ]; then
        generate_application_log
        [ $((COUNTER % 30)) -eq 0 ] && echo "💻 Application log generated"
    fi
    
    # Generate system log occasionally (10% chance)
    if [ $((RANDOM % 10)) -eq 0 ]; then
        generate_system_log
        [ $((COUNTER % 50)) -eq 0 ] && echo "⚙️  System log generated"
    fi
    
    # Show progress every 100 cycles
    if [ $((COUNTER % 100)) -eq 0 ]; then
        echo "✨ Generated $COUNTER log cycles - $(date '+%H:%M:%S')"
    fi
    
    # Variable sleep time untuk pattern yang lebih natural
    sleep_time=$((RANDOM % 4 + 1))  # 1-4 seconds
    sleep $sleep_time
done 