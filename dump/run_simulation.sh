#!/bin/bash

# Hands-on: Persiapan Simulasi Kafka dan Spark Streaming
# Script untuk automasi workflow simulasi lengkap
# Updated with Application UI support and better error handling

# Function to display colored text
print_color() {
    COLOR=$1
    TEXT=$2
    case $COLOR in
        "green") echo -e "\033[0;32m$TEXT\033[0m" ;;
        "red") echo -e "\033[0;31m$TEXT\033[0m" ;;
        "blue") echo -e "\033[0;34m$TEXT\033[0m" ;;
        "yellow") echo -e "\033[0;33m$TEXT\033[0m" ;;
        "cyan") echo -e "\033[0;36m$TEXT\033[0m" ;;
        "purple") echo -e "\033[0;35m$TEXT\033[0m" ;;
    esac
}

# Function to display banner
show_banner() {
    print_color "cyan" "================================================"
    print_color "cyan" "    HANDS-ON: PERSIAPAN SIMULASI"
    print_color "cyan" "    Kafka dan Spark Streaming"
    print_color "cyan" "    Updated with Application UI Support"
    print_color "cyan" "================================================"
    echo ""
}

# Function to check if Docker is running
check_docker() {
    print_color "blue" "🔍 Checking Docker status..."
    if ! docker info > /dev/null 2>&1; then
        print_color "red" "❌ Error: Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_color "green" "✅ Docker is running"
}

# Function to check prerequisites
check_prerequisites() {
    print_color "blue" "🔍 Verifying prerequisites..."
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_color "red" "❌ docker-compose not found. Please install Docker Compose."
        exit 1
    fi
    
    # Check if files exist
    if [ ! -f "docker-compose.yml" ]; then
        print_color "red" "❌ docker-compose.yml not found. Please run from handson directory."
        exit 1
    fi
    
    print_color "green" "✅ All prerequisites met"
}

# Phase 1: Instalasi dan Setup
install_and_setup() {
    print_color "purple" "📦 PHASE 1: INSTALASI DAN SETUP"
    echo ""
    
    print_color "blue" "1️⃣ Instalasi Apache Kafka..."
    print_color "yellow" "   - Download dan setup lingkungan"
    print_color "yellow" "   - Konfigurasi Zookeeper dan Kafka broker"
    
    print_color "blue" "2️⃣ Instalasi Spark Streaming..."
    print_color "yellow" "   - Konfigurasi Spark master dan worker"
    print_color "yellow" "   - Setup Kafka connector"
    
    print_color "blue" "3️⃣ Starting services..."
    docker-compose up -d
    
    # Wait for services to be ready
    print_color "yellow" "⏳ Waiting for services to initialize..."
    sleep 15
    
    # Install Python dependencies
    print_color "blue" "📦 Installing Python dependencies..."
    docker exec kafka-tools pip install kafka-python pandas > /dev/null 2>&1
    
    print_color "blue" "4️⃣ Verifikasi Instalasi..."
    verify_installation
}

# Function to verify installation
verify_installation() {
    print_color "blue" "🔍 Testing connectivity dan fungsi dasar..."
    
    # Check Kafka
    if docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list > /dev/null 2>&1; then
        print_color "green" "✅ Kafka broker: READY (localhost:9092)"
    else
        print_color "red" "❌ Kafka broker: NOT READY"
        return 1
    fi
    
    # Check Spark Master
    if curl -s http://localhost:8080 > /dev/null 2>&1; then
        print_color "green" "✅ Spark Master UI: READY (http://localhost:8080)"
    else
        print_color "red" "❌ Spark Master UI: NOT READY"
        return 1
    fi
    
    # Check Spark Worker
    if curl -s http://localhost:8081 > /dev/null 2>&1; then
        print_color "green" "✅ Spark Worker UI: READY (http://localhost:8081)"
    else
        print_color "red" "❌ Spark Worker UI: NOT READY"
    fi
    
    print_color "green" "🎉 Environment is ready!"
    print_color "cyan" "📊 Access Points:"
    print_color "cyan" "   - Spark Master UI: http://localhost:8080"
    print_color "cyan" "   - Spark Worker UI: http://localhost:8081"
    print_color "cyan" "   - Spark Application UI: http://localhost:4040 (when app is running)"
    print_color "cyan" "   - Kafka Broker: localhost:9092"
}

# Phase 2: Konfigurasi Kafka
configure_kafka() {
    print_color "purple" "⚙️ PHASE 2: KONFIGURASI KAFKA"
    echo ""
    
    print_color "blue" "📋 Setup Consumer..."
    print_color "yellow" "   - Konfigurasi penerima data: Spark Streaming"
    print_color "yellow" "   - Auto offset management: earliest"
    
    print_color "blue" "📤 Setup Producer..."
    print_color "yellow" "   - Konfigurasi pengirim data: Python Kafka Producer"
    print_color "yellow" "   - JSON serialization enabled"
    
    print_color "blue" "📝 Membuat Topik..."
    print_color "yellow" "   - Definisi kategori pesan: transactions"
    
    # Verify topics
    print_color "blue" "📋 Available Kafka topics:"
    docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list
    
    print_color "green" "✅ Kafka configuration completed"
}

# Phase 3: Setup Spark Streaming
setup_spark_streaming() {
    print_color "purple" "🔧 PHASE 3: SETUP SPARK STREAMING"
    echo ""
    
    print_color "blue" "⚙️ Konfigurasi Spark..."
    print_color "yellow" "   - Setting parameter dan resources"
    print_color "yellow" "   - Master-worker architecture"
    print_color "yellow" "   - Memory: 1GB per worker"
    
    print_color "blue" "🔗 Koneksi dengan Kafka..."
    print_color "yellow" "   - Integrasi source dan sink"
    print_color "yellow" "   - Bootstrap servers: kafka:29092"
    
    print_color "blue" "🔄 Definisi Transformasi..."
    print_color "yellow" "   - Logika pemrosesan data"
    print_color "yellow" "   - Window-based aggregation (1 minute)"
    print_color "yellow" "   - Real-time analytics"
    
    print_color "green" "✅ Spark Streaming setup completed"
}

# Simulation Process
run_simulation_step1() {
    print_color "purple" "🚀 LANGKAH 1: PERSIAPAN DATA"
    echo ""
    
    print_color "blue" "📋 Format data untuk streaming..."
    print_color "yellow" "   - JSON schema: transaction data"
    print_color "yellow" "   - Fields: id, product, category, quantity, price, timestamp"
    
    print_color "blue" "📤 Producer mengirim ke topik..."
    print_color "yellow" "   - Starting Kafka producer..."
    
    # Kill any existing producer process
    docker exec kafka-tools pkill -f kafka_producer.py 2>/dev/null || true
    sleep 2
    
    # Start new producer
    docker exec -d kafka-tools python /app/kafka_producer.py
    
    print_color "blue" "✅ Verifikasi..."
    print_color "yellow" "   - Checking data in broker..."
    sleep 5
    
    # Check if messages are being produced
    MESSAGE_COUNT=$(docker exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic transactions --timeout-ms 3000 --max-messages 1 2>/dev/null | wc -l)
    if [ "$MESSAGE_COUNT" -gt 0 ]; then
        print_color "green" "✅ Data successfully sent to Kafka topic"
    else
        print_color "yellow" "⏳ Waiting for data... (producer may still be starting)"
    fi
}

run_simulation_step2() {
    print_color "purple" "🔄 LANGKAH 2: DATA DI KAFKA"
    echo ""
    
    print_color "blue" "💾 Tersimpan dalam topik..."
    print_color "yellow" "   - Topic: transactions"
    print_color "yellow" "   - Persistent storage enabled"
    
    print_color "blue" "📖 Konsumsi data dari Kafka..."
    print_color "yellow" "   - Spark streaming consumer"
    print_color "yellow" "   - Real-time data ingestion"
    
    print_color "blue" "⚡ Pemrosesan data streaming..."
    print_color "yellow" "   - Starting Spark Streaming application..."
    
    # Start Spark Streaming in background (cluster mode)
    docker exec -d spark-master spark-submit --master spark://spark-master:7077 \
        --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.3.0 \
        --conf spark.sql.adaptive.enabled=true \
        --conf spark.sql.adaptive.coalescePartitions.enabled=true \
        /opt/spark-apps/spark_streaming.py
    
    print_color "green" "✅ Spark Streaming application started (cluster mode)"
    print_color "cyan" "📊 Monitor progress at: http://localhost:8080"
    print_color "cyan" "📊 Application UI will be available at: http://localhost:4040"
}

# New function for local mode
run_spark_local() {
    print_color "purple" "🔄 SPARK LOCAL MODE"
    echo ""
    
    print_color "blue" "⚡ Starting Spark in local mode..."
    print_color "yellow" "   - Better for development and testing"
    print_color "yellow" "   - Application UI on port 4040"
    
    # Kill any existing Spark applications
    docker exec spark-master pkill -f spark-submit 2>/dev/null || true
    sleep 2
    
    # Start Spark Streaming in local mode (quoted to handle zsh)
    docker exec -d spark-master spark-submit --master "local[2]" \
        --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.3.0 \
        --conf spark.sql.adaptive.enabled=true \
        --conf spark.sql.adaptive.coalescePartitions.enabled=true \
        /opt/spark-apps/spark_streaming.py
    
    print_color "green" "✅ Spark Streaming application started (local mode)"
    print_color "cyan" "📊 Application UI: http://localhost:4040"
    
    # Wait and verify application UI
    print_color "blue" "⏳ Waiting for Application UI to start..."
    sleep 10
    
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:4040 | grep -q "200\|302"; then
        print_color "green" "✅ Application UI is accessible at http://localhost:4040"
    else
        print_color "yellow" "⏳ Application UI may still be starting..."
    fi
}

run_simulation_step3() {
    print_color "purple" "📊 LANGKAH 3: PROSES DATA"
    echo ""
    
    print_color "blue" "🔍 Filter dan analisis..."
    print_color "yellow" "   - Data transformation pipeline"
    print_color "yellow" "   - Real-time filtering"
    
    print_color "blue" "📈 Penghitungan statistik..."
    print_color "yellow" "   - Aggregations by category"
    print_color "yellow" "   - Top products analysis"
    print_color "yellow" "   - Windowed calculations (1-minute)"
    
    print_color "blue" "👁️ Monitor..."
    print_color "yellow" "   - Pantau kinerja dan hasil"
    print_color "yellow" "   - Console output monitoring"
    
    print_color "blue" "💾 Hasilkan Output..."
    print_color "yellow" "   - Simpan atau visualisasikan hasil"
    print_color "yellow" "   - Real-time console display"
    
    print_color "green" "✅ Data processing pipeline active"
    print_color "cyan" "📋 Check Spark logs for real-time results"
}

# Transaction analysis demo
show_transaction_analysis() {
    print_color "purple" "📊 CONTOH: ANALISIS TRANSAKSI"
    echo ""
    
    print_color "blue" "🏷️ Data Transaksi:"
    print_color "yellow" "   - ID Transaksi: Unique identifier"
    print_color "yellow" "   - Produk: Product name dan category"
    print_color "yellow" "   - Jumlah: Quantity information"
    print_color "yellow" "   - Harga: Price per unit dan total"
    print_color "yellow" "   - Waktu: Timestamp untuk windowing"
    
    print_color "blue" "📈 Analisis Real-time:"
    print_color "yellow" "   - Total penjualan per menit"
    print_color "yellow" "   - Produk terlaris"
    print_color "yellow" "   - Deteksi anomali (future feature)"
    
    print_color "cyan" "💡 View live results in Spark UI: http://localhost:8080"
    print_color "cyan" "💡 Application details: http://localhost:4040"
}

# Function to show streaming logs
show_streaming_logs() {
    print_color "blue" "📊 Showing Spark Streaming logs..."
    print_color "yellow" "Press Ctrl+C to stop viewing logs"
    echo ""
    docker logs -f spark-master 2>/dev/null | grep -E "(INFO|ERROR|WARN)" || true
}

# Function to test UI ports
test_ui_ports() {
    print_color "blue" "🌐 TESTING UI PORTS"
    echo ""
    
    # Test Spark Master UI
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
        print_color "green" "✅ Spark Master UI: http://localhost:8080"
    else
        print_color "red" "❌ Spark Master UI: NOT ACCESSIBLE"
    fi
    
    # Test Spark Worker UI
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 | grep -q "200"; then
        print_color "green" "✅ Spark Worker UI: http://localhost:8081"
    else
        print_color "red" "❌ Spark Worker UI: NOT ACCESSIBLE"
    fi
    
    # Test Spark Application UI
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4040)
    if echo "$HTTP_CODE" | grep -q "200\|302"; then
        print_color "green" "✅ Spark Application UI: http://localhost:4040"
    else
        print_color "yellow" "⏳ Spark Application UI: NOT READY (HTTP $HTTP_CODE)"
        print_color "yellow" "   Start a Spark application first"
    fi
    
    # Test additional application ports
    HTTP_CODE_4041=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4041)
    if echo "$HTTP_CODE_4041" | grep -q "200\|302"; then
        print_color "green" "✅ Additional App UI: http://localhost:4041"
    else
        print_color "yellow" "⏳ Port 4041: NOT USED"
    fi
}

# Function to stop applications
stop_applications() {
    print_color "blue" "🛑 Stopping Spark applications..."
    docker exec spark-master pkill -f spark-submit 2>/dev/null || true
    docker exec kafka-tools pkill -f kafka_producer.py 2>/dev/null || true
    print_color "green" "✅ Applications stopped"
}

# Function to stop the environment
stop_environment() {
    print_color "blue" "🛑 Stopping the environment..."
    stop_applications
    docker-compose down
    print_color "green" "✅ Environment stopped successfully!"
    print_color "cyan" "🧹 All containers and networks cleaned up"
}

# Function to show status
show_status() {
    print_color "blue" "📊 SYSTEM STATUS"
    echo ""
    
    print_color "blue" "🐳 Docker Containers:"
    docker-compose ps
    
    echo ""
    print_color "blue" "📋 Kafka Topics:"
    docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null || print_color "red" "❌ Kafka not accessible"
    
    echo ""
    print_color "blue" "🌐 Service Endpoints:"
    print_color "cyan" "   - Spark Master UI: http://localhost:8080"
    print_color "cyan" "   - Spark Worker UI: http://localhost:8081"
    print_color "cyan" "   - Spark Application UI: http://localhost:4040 (when running)"
    print_color "cyan" "   - Kafka Broker: localhost:9092"
    
    echo ""
    # Show running applications
    RUNNING_APPS=$(curl -s http://localhost:8080 2>/dev/null | grep -o "Running Applications ([0-9]*)" | grep -o "[0-9]*")
    if [ ! -z "$RUNNING_APPS" ]; then
        print_color "blue" "🚀 Running Spark Applications: $RUNNING_APPS"
    else
        print_color "yellow" "⏳ No Spark applications currently running"
    fi
}

# Main menu
show_menu() {
    echo ""
    print_color "blue" "=== KAFKA DAN SPARK STREAMING SIMULATION ==="
    echo ""
    print_color "cyan" "📋 SETUP & CONFIGURATION:"
    echo "1. 🚀 Install and Setup Environment"
    echo "2. ⚙️ Configure Kafka"
    echo "3. 🔧 Setup Spark Streaming"
    echo ""
    print_color "cyan" "🎯 SIMULATION WORKFLOW:"
    echo "4. 📋 Step 1: Persiapan Data"
    echo "5. 🔄 Step 2: Data di Kafka (Cluster Mode)"
    echo "6. 📊 Step 3: Proses Data"
    echo "7. ⚡ Run Spark Local Mode (Recommended for UI)"
    echo ""
    print_color "cyan" "📊 MONITORING & ANALYSIS:"
    echo "8. 📈 Show Transaction Analysis Demo"
    echo "9. 📋 Show System Status"
    echo "10. 📊 View Streaming Logs"
    echo "11. 🌐 Test UI Ports"
    echo ""
    print_color "cyan" "🎮 CONTROL:"
    echo "12. 🛑 Stop Applications Only"
    echo "13. 🛑 Stop Environment"
    echo "14. 🚪 Exit"
    echo ""
}

# Main execution
main() {
    show_banner
    check_docker
    check_prerequisites
    
    # Main loop
    while true; do
        show_menu
        read -p "$(print_color 'yellow' 'Enter your choice (1-14): ')" choice
        
        case $choice in
            1) install_and_setup ;;
            2) configure_kafka ;;
            3) setup_spark_streaming ;;
            4) run_simulation_step1 ;;
            5) run_simulation_step2 ;;
            6) run_simulation_step3 ;;
            7) run_spark_local ;;
            8) show_transaction_analysis ;;
            9) show_status ;;
            10) show_streaming_logs ;;
            11) test_ui_ports ;;
            12) stop_applications ;;
            13) stop_environment ;;
            14) print_color "green" "👋 Exiting... Terima kasih!"; exit 0 ;;
            *) print_color "red" "❌ Invalid option. Please try again." ;;
        esac
        
        echo ""
        read -p "$(print_color 'cyan' 'Press Enter to continue...')"
    done
}

# Run main function
main