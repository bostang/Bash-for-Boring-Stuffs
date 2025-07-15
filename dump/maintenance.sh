#!/bin/bash

# Maintenance script for Jenkins CI/CD Demo
# Handles common maintenance tasks

echo "=== Jenkins CI/CD Maintenance ==="
echo ""

case "${1:-help}" in
    "logs")
        echo "📄 Showing recent logs..."
        echo ""
        echo "Jenkins logs (last 50 lines):"
        docker-compose logs --tail=50 jenkins
        echo ""
        echo "Application logs:"
        docker logs jenkins-demo-app-staging 2>/dev/null || echo "Staging app not running"
        docker logs jenkins-demo-app-prod 2>/dev/null || echo "Production app not running"
        ;;
    
    "restart")
        echo "🔄 Restarting Jenkins..."
        docker-compose restart jenkins
        echo "✅ Jenkins restarted"
        ;;
    
    "clean")
        echo "🧹 Cleaning up Docker resources..."
        docker system prune -f
        echo "✅ Docker cleanup completed"
        ;;
    
    "backup")
        echo "💾 Creating backup..."
        backup_dir="backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        
        # Backup jenkins data
        if [ -d "jenkins-data" ]; then
            cp -r jenkins-data "$backup_dir/"
            echo "✅ Jenkins data backed up"
        fi
        
        # Backup configuration
        cp -r jenkins-config "$backup_dir/"
        cp -r scripts "$backup_dir/"
        cp docker-compose.yml "$backup_dir/"
        cp Jenkinsfile "$backup_dir/"
        
        echo "✅ Backup created in $backup_dir"
        ;;
    
    "update")
        echo "🔄 Updating Jenkins image..."
        docker-compose pull jenkins
        docker-compose up -d jenkins
        echo "✅ Jenkins updated"
        ;;
    
    "status")
        echo "📊 System Status:"
        ./scripts/monitor.sh
        ;;
    
    "reset")
        echo "⚠️  WARNING: This will reset everything!"
        read -p "Are you sure? [y/N]: " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            ./scripts/cleanup.sh
            echo "✅ System reset completed"
        else
            echo "❌ Reset cancelled"
        fi
        ;;
    
    "help"|*)
        echo "Usage: $0 {command}"
        echo ""
        echo "Available commands:"
        echo "  logs     - Show recent logs"
        echo "  restart  - Restart Jenkins"
        echo "  clean    - Clean Docker resources"
        echo "  backup   - Create system backup"
        echo "  update   - Update Jenkins image"
        echo "  status   - Show system status"
        echo "  reset    - Reset entire system"
        echo "  help     - Show this help"
        ;;
esac 