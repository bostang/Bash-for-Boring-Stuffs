#!/bin/bash

# Test Pipeline Script - Enhanced Multi-Stage CI/CD Pipeline
# This script tests the new Jenkinsfile with multi-approval and Telegram notifications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASS="admin123"
JOB_NAME="demo-pipeline"

# Telegram Configuration
TELEGRAM_BOT_TOKEN="8006705671:AAGBPsg9hlGs3VNehcDh2tm0XdlwTDzkmqI"
TELEGRAM_CHAT_ID="5169274667"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🧪 Enhanced Multi-Stage Pipeline Test Suite${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Function to send test notification
send_test_notification() {
    local message="$1"
    local encoded_message=$(echo "$message" | sed 's/"/\\"/g')
    
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${encoded_message}" \
        -d "parse_mode=HTML" > /dev/null
}

# Function to check Jenkins status
check_jenkins_status() {
    echo -e "${YELLOW}🔍 Checking Jenkins status...${NC}"
    
    if curl -s -f "${JENKINS_URL}/login" > /dev/null; then
        echo -e "${GREEN}✅ Jenkins is accessible at ${JENKINS_URL}${NC}"
        return 0
    else
        echo -e "${RED}❌ Jenkins is not accessible at ${JENKINS_URL}${NC}"
        return 1
    fi
}

# Function to test authentication
test_authentication() {
    echo -e "${YELLOW}🔐 Testing Jenkins authentication...${NC}"
    
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        "${JENKINS_URL}/manage/systemInfo" \
        -u "${JENKINS_USER}:${JENKINS_PASS}")
    
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✅ Authentication successful${NC}"
        return 0
    else
        echo -e "${RED}❌ Authentication failed (HTTP $response)${NC}"
        return 1
    fi
}

# Function to check if job exists
check_job_exists() {
    echo -e "${YELLOW}📋 Checking if job '${JOB_NAME}' exists...${NC}"
    
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        "${JENKINS_URL}/job/${JOB_NAME}/api/json" \
        -u "${JENKINS_USER}:${JENKINS_PASS}")
    
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✅ Job '${JOB_NAME}' exists${NC}"
        return 0
    else
        echo -e "${RED}❌ Job '${JOB_NAME}' not found (HTTP $response)${NC}"
        echo -e "${YELLOW}💡 Creating job from config...${NC}"
        return 1
    fi
}

# Function to create job if not exists
create_job() {
    echo -e "${YELLOW}🛠️ Creating job '${JOB_NAME}'...${NC}"
    
    # Get Jenkins crumb for CSRF protection
    crumb=$(curl -s "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)" \
        -u "${JENKINS_USER}:${JENKINS_PASS}" | cut -d: -f2)
    
    if [ -f "jenkins-config/jobs/${JOB_NAME}/config.xml" ]; then
        response=$(curl -s -w "%{http_code}" -o /dev/null \
            -X POST "${JENKINS_URL}/createItem?name=${JOB_NAME}" \
            -u "${JENKINS_USER}:${JENKINS_PASS}" \
            -H "Jenkins-Crumb: ${crumb}" \
            -H "Content-Type: application/xml" \
            --data-binary "@jenkins-config/jobs/${JOB_NAME}/config.xml")
        
        if [ "$response" = "200" ]; then
            echo -e "${GREEN}✅ Job '${JOB_NAME}' created successfully${NC}"
            return 0
        else
            echo -e "${RED}❌ Failed to create job (HTTP $response)${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Job config file not found${NC}"
        return 1
    fi
}

# Function to test Telegram notification
test_telegram_notification() {
    echo -e "${YELLOW}📱 Testing Telegram notification...${NC}"
    
    test_message="🧪 <b>Pipeline Test Started</b>
━━━━━━━━━━━━━━━━━━━━━━━
🚀 Testing enhanced multi-stage pipeline
📋 Job: ${JOB_NAME}
⏰ Time: $(date '+%Y-%m-%d %H:%M:%S')
🔧 Test Suite: Multi-approval & notifications"
    
    response=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${test_message}" \
        -d "parse_mode=HTML" \
        -w "%{http_code}")
    
    if echo "$response" | grep -q '"ok":true'; then
        echo -e "${GREEN}✅ Telegram notification sent successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Telegram notification failed${NC}"
        echo "Response: $response"
        return 1
    fi
}

# Function to trigger pipeline with parameters
trigger_pipeline() {
    local environment="$1"
    local skip_tests="$2"
    local enable_notifications="$3"
    local custom_tag="$4"
    
    echo -e "${YELLOW}🚀 Triggering pipeline with parameters:${NC}"
    echo -e "  🎯 Environment: ${CYAN}${environment}${NC}"
    echo -e "  🧪 Skip Tests: ${CYAN}${skip_tests}${NC}"
    echo -e "  📱 Notifications: ${CYAN}${enable_notifications}${NC}"
    echo -e "  🏷️ Custom Tag: ${CYAN}${custom_tag:-"auto"}${NC}"
    
    # Get Jenkins crumb for CSRF protection
    crumb=$(curl -s "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)" \
        -u "${JENKINS_USER}:${JENKINS_PASS}" | cut -d: -f2)
    
    # Prepare parameters
    local params=""
    params+="DEPLOY_ENVIRONMENT=${environment}&"
    params+="SKIP_TESTS=${skip_tests}&"
    params+="ENABLE_NOTIFICATIONS=${enable_notifications}&"
    params+="CUSTOM_TAG=${custom_tag}&"
    
    # Trigger build
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -X POST "${JENKINS_URL}/job/${JOB_NAME}/buildWithParameters" \
        -u "${JENKINS_USER}:${JENKINS_PASS}" \
        -H "Jenkins-Crumb: ${crumb}" \
        -d "${params}")
    
    if [ "$response" = "201" ]; then
        echo -e "${GREEN}✅ Pipeline triggered successfully${NC}"
        
        # Send notification about test trigger
        if [ "$enable_notifications" = "true" ]; then
            send_test_notification "🚀 <b>Test Pipeline Triggered</b>
🎯 Environment: ${environment}
🧪 Skip Tests: ${skip_tests}
📱 Notifications: ${enable_notifications}
🏷️ Tag: ${custom_tag:-"auto"}
🔗 Jenkins: ${JENKINS_URL}/job/${JOB_NAME}/"
        fi
        
        return 0
    else
        echo -e "${RED}❌ Failed to trigger pipeline (HTTP $response)${NC}"
        return 1
    fi
}

# Function to get build status
get_build_status() {
    local build_number="$1"
    
    if [ -z "$build_number" ]; then
        # Get latest build number
        build_number=$(curl -s "${JENKINS_URL}/job/${JOB_NAME}/api/json" \
            -u "${JENKINS_USER}:${JENKINS_PASS}" | \
            grep -o '"lastBuild":{"number":[0-9]*' | \
            grep -o '[0-9]*$')
    fi
    
    if [ -z "$build_number" ]; then
        echo "unknown"
        return 1
    fi
    
    status=$(curl -s "${JENKINS_URL}/job/${JOB_NAME}/${build_number}/api/json" \
        -u "${JENKINS_USER}:${JENKINS_PASS}" | \
        grep -o '"result":"[^"]*' | cut -d'"' -f4)
    
    if [ -z "$status" ] || [ "$status" = "null" ]; then
        echo "RUNNING"
    else
        echo "$status"
    fi
}

# Function to monitor build progress
monitor_build() {
    local build_number="$1"
    local max_wait=1800  # 30 minutes
    local wait_time=0
    
    echo -e "${YELLOW}📊 Monitoring build progress...${NC}"
    echo -e "${CYAN}🔗 Build URL: ${JENKINS_URL}/job/${JOB_NAME}/${build_number}/console${NC}"
    
    while [ $wait_time -lt $max_wait ]; do
        status=$(get_build_status "$build_number")
        
        case "$status" in
            "RUNNING")
                echo -ne "\r${YELLOW}⏳ Build #${build_number} is running... (${wait_time}s)${NC}"
                ;;
            "SUCCESS")
                echo -e "\n${GREEN}✅ Build #${build_number} completed successfully!${NC}"
                return 0
                ;;
            "FAILURE")
                echo -e "\n${RED}❌ Build #${build_number} failed!${NC}"
                return 1
                ;;
            "ABORTED")
                echo -e "\n${YELLOW}🛑 Build #${build_number} was aborted!${NC}"
                return 1
                ;;
            "UNSTABLE")
                echo -e "\n${YELLOW}⚠️ Build #${build_number} is unstable!${NC}"
                return 1
                ;;
            *)
                echo -ne "\r${YELLOW}❓ Build #${build_number} status: ${status} (${wait_time}s)${NC}"
                ;;
        esac
        
        sleep 10
        wait_time=$((wait_time + 10))
    done
    
    echo -e "\n${RED}⏰ Build monitoring timed out after ${max_wait} seconds${NC}"
    return 1
}

# Function to test different scenarios
test_scenarios() {
    echo -e "${PURPLE}🎯 Testing Different Pipeline Scenarios${NC}"
    echo
    
    # Scenario 1: Staging deployment with tests
    echo -e "${CYAN}📋 Scenario 1: Staging deployment with full tests${NC}"
    if trigger_pipeline "staging" "false" "true" "test-v1.0"; then
        echo -e "${GREEN}✅ Scenario 1 triggered successfully${NC}"
    else
        echo -e "${RED}❌ Scenario 1 failed to trigger${NC}"
    fi
    echo
    
    sleep 5
    
    # Scenario 2: Production deployment (will need approval)
    echo -e "${CYAN}📋 Scenario 2: Production deployment (manual approval required)${NC}"
    if trigger_pipeline "production" "false" "true" "prod-v1.0"; then
        echo -e "${GREEN}✅ Scenario 2 triggered successfully${NC}"
        echo -e "${YELLOW}⚠️ This will require manual approval in Jenkins UI${NC}"
    else
        echo -e "${RED}❌ Scenario 2 failed to trigger${NC}"
    fi
    echo
    
    sleep 5
    
    # Scenario 3: Both environments
    echo -e "${CYAN}📋 Scenario 3: Deploy to both staging and production${NC}"
    if trigger_pipeline "both" "true" "true" "both-v1.0"; then
        echo -e "${GREEN}✅ Scenario 3 triggered successfully${NC}"
        echo -e "${YELLOW}⚠️ This will require manual approvals for production${NC}"
    else
        echo -e "${RED}❌ Scenario 3 failed to trigger${NC}"
    fi
    echo
}

# Function to check deployment status
check_deployments() {
    echo -e "${YELLOW}🔍 Checking deployment status...${NC}"
    
    # Check staging
    if curl -s -f "http://localhost:8081/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Staging deployment is healthy (http://localhost:8081)${NC}"
    else
        echo -e "${YELLOW}⚠️ Staging deployment not accessible${NC}"
    fi
    
    # Check production
    if curl -s -f "http://localhost:8090/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Production deployment is healthy (http://localhost:8090)${NC}"
    else
        echo -e "${YELLOW}⚠️ Production deployment not accessible${NC}"
    fi
}

# Function to cleanup test artifacts
cleanup_test_artifacts() {
    echo -e "${YELLOW}🧹 Cleaning up test artifacts...${NC}"
    
    # Remove test containers
    docker stop jenkins-demo-app-staging jenkins-demo-app-prod 2>/dev/null || true
    docker rm jenkins-demo-app-staging jenkins-demo-app-prod 2>/dev/null || true
    
    # Remove test images
    docker images | grep "jenkins-demo-app:test-" | awk '{print $3}' | xargs -r docker rmi || true
    docker images | grep "jenkins-demo-app:prod-" | awk '{print $3}' | xargs -r docker rmi || true
    docker images | grep "jenkins-demo-app:both-" | awk '{print $3}' | xargs -r docker rmi || true
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Main test execution
main() {
    echo -e "${CYAN}Starting Enhanced Pipeline Test Suite...${NC}"
    echo
    
    # Pre-test cleanup
    cleanup_test_artifacts
    
    # Basic checks
    if ! check_jenkins_status; then
        echo -e "${RED}💥 Jenkins is not running. Please start Jenkins first.${NC}"
        echo -e "${YELLOW}💡 Run: docker-compose up -d${NC}"
        exit 1
    fi
    
    if ! test_authentication; then
        echo -e "${RED}💥 Authentication failed. Check credentials.${NC}"
        exit 1
    fi
    
    # Check/create job
    if ! check_job_exists; then
        if ! create_job; then
            echo -e "${RED}💥 Failed to create job. Manual intervention required.${NC}"
            exit 1
        fi
    fi
    
    # Test Telegram notification
    if ! test_telegram_notification; then
        echo -e "${YELLOW}⚠️ Telegram notifications may not work properly${NC}"
    fi
    
    echo
    echo -e "${GREEN}🎉 Pre-tests completed successfully!${NC}"
    echo
    
    # Interactive mode
    echo -e "${CYAN}Choose test mode:${NC}"
    echo -e "  ${YELLOW}1)${NC} Run all scenarios automatically"
    echo -e "  ${YELLOW}2)${NC} Manual scenario selection"
    echo -e "  ${YELLOW}3)${NC} Check current deployments only"
    echo -e "  ${YELLOW}4)${NC} Cleanup and exit"
    echo
    read -p "Enter your choice (1-4): " choice
    
    case $choice in
        1)
            test_scenarios
            ;;
        2)
            echo -e "${CYAN}Select scenario:${NC}"
            echo -e "  ${YELLOW}1)${NC} Staging only"
            echo -e "  ${YELLOW}2)${NC} Production only (requires approval)"
            echo -e "  ${YELLOW}3)${NC} Both environments (requires approval)"
            echo
            read -p "Enter scenario (1-3): " scenario
            
            case $scenario in
                1) trigger_pipeline "staging" "false" "true" "manual-staging" ;;
                2) trigger_pipeline "production" "false" "true" "manual-prod" ;;
                3) trigger_pipeline "both" "false" "true" "manual-both" ;;
                *) echo -e "${RED}Invalid scenario${NC}" ;;
            esac
            ;;
        3)
            check_deployments
            ;;
        4)
            cleanup_test_artifacts
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
    
    echo
    echo -e "${GREEN}📊 Test Summary:${NC}"
    echo -e "  🔗 Jenkins: ${JENKINS_URL}"
    echo -e "  📋 Job: ${JENKINS_URL}/job/${JOB_NAME}/"
    echo -e "  🎯 Staging: http://localhost:8081"
    echo -e "  🚀 Production: http://localhost:8090"
    echo
    echo -e "${YELLOW}💡 Tips:${NC}"
    echo -e "  • Monitor builds in Jenkins console"
    echo -e "  • Check Telegram for notifications"
    echo -e "  • Approve production deployments when prompted"
    echo -e "  • Use 'docker ps' to see running containers"
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 Enhanced Pipeline Test Completed!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Run main function
main "$@" 