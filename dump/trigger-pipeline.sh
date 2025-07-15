#!/bin/bash

# Manual Pipeline Trigger Script
# This script triggers the pipeline manually using different methods

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASS="admin123"
JOB_NAME="demo-pipeline"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🚀 Manual Pipeline Trigger${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Function to reload job configuration
reload_job_config() {
    echo -e "${YELLOW}🔄 Reloading job configuration...${NC}"
    
    # This will force Jenkins to reload the Jenkinsfile from SCM
    curl -s -X POST "${JENKINS_URL}/job/${JOB_NAME}/build" \
        -u "${JENKINS_USER}:${JENKINS_PASS}" \
        -d "delay=0sec" > /dev/null 2>&1 || true
    
    echo -e "${GREEN}✅ Job configuration reload triggered${NC}"
}

# Function to trigger via GUI
trigger_via_gui() {
    echo -e "${YELLOW}🖱️ Manual GUI Trigger Instructions:${NC}"
    echo
    echo -e "${CYAN}1. Open Jenkins in browser: ${JENKINS_URL}${NC}"
    echo -e "${CYAN}2. Navigate to job: ${JENKINS_URL}/job/${JOB_NAME}/${NC}"
    echo -e "${CYAN}3. Click 'Build with Parameters' (if available) or 'Build Now'${NC}"
    echo -e "${CYAN}4. Select your parameters:${NC}"
    echo -e "   🎯 Deploy Environment: staging/production/both"
    echo -e "   🧪 Skip Tests: false (recommended)"
    echo -e "   📱 Enable Notifications: true"
    echo -e "   🏷️ Custom Tag: leave empty for auto"
    echo -e "${CYAN}5. Click 'Build'${NC}"
    echo
}

# Function to show job info
show_job_info() {
    echo -e "${YELLOW}📋 Job Information:${NC}"
    echo -e "  🔗 Job URL: ${JENKINS_URL}/job/${JOB_NAME}/"
    echo -e "  📊 Job API: ${JENKINS_URL}/job/${JOB_NAME}/api/json"
    echo -e "  ⚙️ Configure: ${JENKINS_URL}/job/${JOB_NAME}/configure"
    echo
    
    # Get last build info
    echo -e "${YELLOW}📈 Last Build Info:${NC}"
    last_build=$(curl -s "${JENKINS_URL}/job/${JOB_NAME}/api/json" \
        -u "${JENKINS_USER}:${JENKINS_PASS}" | \
        grep -o '"lastBuild":{"number":[0-9]*' | \
        grep -o '[0-9]*$' || echo "none")
    
    if [ "$last_build" != "none" ]; then
        echo -e "  🔢 Last Build: #${last_build}"
        echo -e "  🔗 Console: ${JENKINS_URL}/job/${JOB_NAME}/${last_build}/console"
        
        # Get build status
        status=$(curl -s "${JENKINS_URL}/job/${JOB_NAME}/${last_build}/api/json" \
            -u "${JENKINS_USER}:${JENKINS_PASS}" | \
            grep -o '"result":"[^"]*' | cut -d'"' -f4 || echo "UNKNOWN")
        
        case "$status" in
            "SUCCESS") echo -e "  ✅ Status: ${GREEN}SUCCESS${NC}" ;;
            "FAILURE") echo -e "  ❌ Status: ${RED}FAILURE${NC}" ;;
            "RUNNING") echo -e "  ⏳ Status: ${YELLOW}RUNNING${NC}" ;;
            "null") echo -e "  ⏳ Status: ${YELLOW}RUNNING${NC}" ;;
            *) echo -e "  ❓ Status: ${status}" ;;
        esac
    else
        echo -e "  📝 No builds yet"
    fi
    echo
}

# Function to test simple build trigger (bypass CSRF for testing)
test_simple_trigger() {
    echo -e "${YELLOW}🧪 Testing Simple Build Trigger...${NC}"
    
    # Try to trigger without CSRF first to see what happens
    response=$(curl -s -w "%{http_code}" -o /tmp/jenkins_response.txt \
        -X POST "${JENKINS_URL}/job/${JOB_NAME}/build" \
        -u "${JENKINS_USER}:${JENKINS_PASS}")
    
    if [ "$response" = "201" ]; then
        echo -e "${GREEN}✅ Build triggered successfully!${NC}"
        return 0
    elif [ "$response" = "403" ]; then
        echo -e "${YELLOW}⚠️ CSRF protection active (expected in Jenkins 2.504)${NC}"
        echo -e "${CYAN}💡 Use GUI method or configure Jenkins CLI${NC}"
        return 1
    else
        echo -e "${RED}❌ Unexpected response: HTTP $response${NC}"
        cat /tmp/jenkins_response.txt
        return 1
    fi
}

# Function to monitor current builds
monitor_builds() {
    echo -e "${YELLOW}📊 Monitoring Current Builds...${NC}"
    
    # Get build queue
    queue=$(curl -s "${JENKINS_URL}/queue/api/json" -u "${JENKINS_USER}:${JENKINS_PASS}" | \
        grep -o '"items":\[.*\]' | grep -o '\[.*\]')
    
    if [ "$queue" = "[]" ]; then
        echo -e "${GREEN}📭 No builds in queue${NC}"
    else
        echo -e "${YELLOW}📬 Builds in queue:${NC}"
        echo "$queue"
    fi
    
    # Check if any build is running
    is_building=$(curl -s "${JENKINS_URL}/job/${JOB_NAME}/api/json" \
        -u "${JENKINS_USER}:${JENKINS_PASS}" | \
        grep -o '"lastBuild":{"number":[0-9]*' | \
        grep -o '[0-9]*$')
    
    if [ -n "$is_building" ]; then
        build_status=$(curl -s "${JENKINS_URL}/job/${JOB_NAME}/${is_building}/api/json" \
            -u "${JENKINS_USER}:${JENKINS_PASS}" | \
            grep -o '"building":[^,]*' | cut -d: -f2)
        
        if [ "$build_status" = "true" ]; then
            echo -e "${YELLOW}⏳ Build #${is_building} is currently running${NC}"
            echo -e "${CYAN}🔗 Monitor: ${JENKINS_URL}/job/${JOB_NAME}/${is_building}/console${NC}"
        else
            echo -e "${GREEN}💤 No builds currently running${NC}"
        fi
    fi
    echo
}

# Function to check deployments
check_deployments() {
    echo -e "${YELLOW}🔍 Checking Current Deployments:${NC}"
    
    # Check staging
    if curl -s -f "http://localhost:8081/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Staging (8081): Healthy${NC}"
    elif curl -s -f "http://localhost:8081/" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ Staging (8081): Running but no health endpoint${NC}"
    else
        echo -e "${RED}❌ Staging (8081): Not accessible${NC}"
    fi
    
    # Check production
    if curl -s -f "http://localhost:8090/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Production (8090): Healthy${NC}"
    elif curl -s -f "http://localhost:8090/" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ Production (8090): Running but no health endpoint${NC}"
    else
        echo -e "${RED}❌ Production (8090): Not accessible${NC}"
    fi
    
    echo
    echo -e "${CYAN}🐳 Docker Containers:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(staging|prod|demo-app)" || echo "No deployment containers found"
    echo
}

# Function to send test notification
send_test_notification() {
    echo -e "${YELLOW}📱 Sending Test Notification...${NC}"
    
    test_message="🧪 <b>Manual Pipeline Test</b>
━━━━━━━━━━━━━━━━━━━━━━━
🚀 Testing manual trigger functionality
📋 Job: ${JOB_NAME}
⏰ Time: $(date '+%Y-%m-%d %H:%M:%S')
🔗 Jenkins: ${JENKINS_URL}/job/${JOB_NAME}/"
    
    response=$(curl -s -X POST "https://api.telegram.org/bot8006705671:AAGBPsg9hlGs3VNehcDh2tm0XdlwTDzkmqI/sendMessage" \
        -d "chat_id=5169274667" \
        -d "text=${test_message}" \
        -d "parse_mode=HTML")
    
    if echo "$response" | grep -q '"ok":true'; then
        echo -e "${GREEN}✅ Test notification sent to Telegram${NC}"
    else
        echo -e "${RED}❌ Failed to send Telegram notification${NC}"
    fi
    echo
}

# Main function
main() {
    echo -e "${CYAN}Starting Manual Pipeline Trigger...${NC}"
    echo
    
    # Show job information
    show_job_info
    
    # Monitor current state
    monitor_builds
    
    # Check deployments
    check_deployments
    
    # Interactive menu
    echo -e "${CYAN}What would you like to do?${NC}"
    echo -e "  ${YELLOW}1)${NC} Show GUI trigger instructions"
    echo -e "  ${YELLOW}2)${NC} Test simple build trigger"
    echo -e "  ${YELLOW}3)${NC} Send test Telegram notification"
    echo -e "  ${YELLOW}4)${NC} Monitor builds only"
    echo -e "  ${YELLOW}5)${NC} Check deployments only"
    echo -e "  ${YELLOW}6)${NC} Reload job configuration"
    echo
    read -p "Enter your choice (1-6): " choice
    
    case $choice in
        1)
            trigger_via_gui
            ;;
        2)
            test_simple_trigger
            ;;
        3)
            send_test_notification
            ;;
        4)
            monitor_builds
            ;;
        5)
            check_deployments
            ;;
        6)
            reload_job_config
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
    
    echo
    echo -e "${GREEN}📋 Next Steps:${NC}"
    echo -e "  🔗 Open Jenkins: ${JENKINS_URL}"
    echo -e "  📱 Check Telegram for notifications"
    echo -e "  🐳 Monitor containers: docker ps"
    echo -e "  📊 View console logs in Jenkins"
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 Manual Trigger Completed!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Run main function
main "$@" 