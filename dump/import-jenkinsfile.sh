#!/bin/bash

# Import Jenkinsfile Script - Multiple Methods to Import Pipeline
# This script guides you through importing the enhanced Jenkinsfile into Jenkins

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
WORKSPACE_DIR=$(pwd)

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📥 Jenkins Pipeline Import Guide${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Function to check Jenkins status
check_jenkins() {
    echo -e "${YELLOW}🔍 Checking Jenkins status...${NC}"
    
    if curl -s -f "${JENKINS_URL}/login" > /dev/null; then
        echo -e "${GREEN}✅ Jenkins is running at ${JENKINS_URL}${NC}"
        return 0
    else
        echo -e "${RED}❌ Jenkins is not accessible${NC}"
        echo -e "${YELLOW}💡 Start Jenkins with: docker-compose up -d${NC}"
        return 1
    fi
}

# Function to show Jenkinsfile info
show_jenkinsfile_info() {
    echo -e "${YELLOW}📋 Jenkinsfile Information:${NC}"
    echo -e "  📁 Location: ${WORKSPACE_DIR}/Jenkinsfile"
    echo -e "  📏 Size: $(ls -lh Jenkinsfile | awk '{print $5}')"
    echo -e "  📊 Lines: $(wc -l < Jenkinsfile) lines"
    echo -e "  🚀 Stages: 12 enhanced stages"
    echo -e "  🎯 Features: Multi-approval, Telegram notifications"
    echo
}

# Method 1: Import via GUI (Manual)
method_1_gui() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📌 Method 1: Import via Jenkins GUI (Recommended)${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    echo -e "${YELLOW}Step 1: Access Jenkins${NC}"
    echo -e "  🔗 Open: ${JENKINS_URL}"
    echo -e "  👤 Login: admin / admin123"
    echo
    
    echo -e "${YELLOW}Step 2: Create New Pipeline Job${NC}"
    echo -e "  1. Click '+ New Item' in sidebar"
    echo -e "  2. Enter name: ${JOB_NAME}"
    echo -e "  3. Select: Pipeline"
    echo -e "  4. Click: OK"
    echo
    
    echo -e "${YELLOW}Step 3: Configure Pipeline${NC}"
    echo -e "  ${CYAN}Option A: Copy & Paste Jenkinsfile${NC}"
    echo -e "  1. In Pipeline section, select: 'Pipeline script'"
    echo -e "  2. Copy Jenkinsfile content:"
    echo -e "     ${BLUE}cat ${WORKSPACE_DIR}/Jenkinsfile | xclip -selection clipboard${NC} (Linux with xclip)"
    echo -e "     ${BLUE}cat ${WORKSPACE_DIR}/Jenkinsfile | xsel --clipboard${NC} (Linux with xsel)"
    echo -e "  3. Paste into Script text area"
    echo -e "  4. Click: Save"
    echo
    echo -e "  ${CYAN}Option B: Load from SCM (Git)${NC}"
    echo -e "  1. In Pipeline section, select: 'Pipeline script from SCM'"
    echo -e "  2. SCM: Git"
    echo -e "  3. Repository URL: https://github.com/zikazama/jenkins.git"
    echo -e "     (or your forked repository)"
    echo -e "  4. Branch: */main"
    echo -e "  5. Script Path: Jenkinsfile"
    echo -e "  6. Click: Save"
    echo
    
    echo -e "${GREEN}✅ Pipeline imported successfully!${NC}"
    echo
}

# Method 2: Update Existing Job
method_2_update() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📌 Method 2: Update Existing Pipeline Job${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    # Check if job exists
    if curl -s "${JENKINS_URL}/job/${JOB_NAME}/api/json" -u "${JENKINS_USER}:${JENKINS_PASS}" | grep -q '"name"'; then
        echo -e "${GREEN}✅ Job '${JOB_NAME}' exists${NC}"
        echo
        
        echo -e "${YELLOW}Steps to Update:${NC}"
        echo -e "  1. Go to: ${JENKINS_URL}/job/${JOB_NAME}/configure"
        echo -e "  2. Scroll to 'Pipeline' section"
        echo -e "  3. Replace existing script with new Jenkinsfile"
        echo -e "  4. Click: Save"
        echo
        echo -e "${CYAN}Quick Copy Command:${NC}"
        echo -e "  ${BLUE}cat Jenkinsfile | xclip -selection clipboard${NC} (Linux with xclip)"
        echo -e "  ${BLUE}cat Jenkinsfile | xsel --clipboard${NC} (Linux with xsel)"
        echo
    else
        echo -e "${RED}❌ Job '${JOB_NAME}' not found${NC}"
        echo -e "${YELLOW}💡 Create new job using Method 1${NC}"
    fi
    echo
}

# Method 3: Using Jenkins CLI
method_3_cli() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📌 Method 3: Import using Jenkins CLI (Advanced)${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    echo -e "${YELLOW}Step 1: Download Jenkins CLI${NC}"
    echo -e "  ${BLUE}wget ${JENKINS_URL}/jnlpJars/jenkins-cli.jar${NC}"
    echo
    
    echo -e "${YELLOW}Step 2: Create job XML template${NC}"
    cat > /tmp/pipeline-job.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <description>Enhanced Multi-Stage CI/CD Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2.87">
    <script><![CDATA[
SCRIPT_CONTENT_HERE
    ]]></script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
    
    echo -e "${YELLOW}Step 3: Import via CLI${NC}"
    echo -e "  ${BLUE}java -jar jenkins-cli.jar -s ${JENKINS_URL} -auth ${JENKINS_USER}:${JENKINS_PASS} create-job ${JOB_NAME} < pipeline-job.xml${NC}"
    echo
    echo -e "${YELLOW}Note:${NC} This method requires Jenkins CLI setup"
    echo
}

# Method 4: Direct File Import
method_4_direct() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📌 Method 4: Direct Workspace Import${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    echo -e "${YELLOW}For Local Development:${NC}"
    echo -e "  1. Place project in Jenkins workspace:"
    echo -e "     ${BLUE}cp -r ${WORKSPACE_DIR} /var/jenkins_home/workspace/${JOB_NAME}${NC}"
    echo
    echo -e "  2. Create Pipeline job pointing to local Jenkinsfile:"
    echo -e "     - Definition: Pipeline script from SCM"
    echo -e "     - SCM: File System"
    echo -e "     - Path: /var/jenkins_home/workspace/${JOB_NAME}/Jenkinsfile"
    echo
    
    echo -e "${YELLOW}For Docker Jenkins:${NC}"
    echo -e "  ${BLUE}docker cp Jenkinsfile jenkins-demo:/var/jenkins_home/workspace/${JOB_NAME}/Jenkinsfile${NC}"
    echo
}

# Show copy commands for different OS
show_copy_commands() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📋 Copy Jenkinsfile Content Commands${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    echo -e "${YELLOW}Linux (with xclip):${NC}"
    echo -e "  ${BLUE}cat Jenkinsfile | xclip -selection clipboard${NC}"
    echo
    
    echo -e "${YELLOW}Linux (with xsel):${NC}"
    echo -e "  ${BLUE}cat Jenkinsfile | xsel --clipboard${NC}"
    echo
    
    echo -e "${YELLOW}Windows (Git Bash):${NC}"
    echo -e "  ${BLUE}cat Jenkinsfile | clip${NC}"
    echo
    
    echo -e "${YELLOW}View in terminal:${NC}"
    echo -e "  ${BLUE}cat Jenkinsfile${NC}"
    echo -e "  ${BLUE}less Jenkinsfile${NC} (paginated view)"
    echo
}

# Verify pipeline features
verify_features() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}✅ Pipeline Features to Verify After Import${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    echo -e "${YELLOW}1. Pipeline Parameters:${NC}"
    echo -e "   ✓ Deploy Environment (staging/production/both)"
    echo -e "   ✓ Skip Tests (boolean)"
    echo -e "   ✓ Enable Notifications (boolean)"
    echo -e "   ✓ Custom Tag (string)"
    echo
    
    echo -e "${YELLOW}2. Environment Variables:${NC}"
    echo -e "   ✓ Telegram credentials configured"
    echo -e "   ✓ Application settings defined"
    echo -e "   ✓ URLs for staging/production"
    echo
    
    echo -e "${YELLOW}3. Pipeline Stages (12 total):${NC}"
    echo -e "   ✓ Initialization → Checkout → Build"
    echo -e "   ✓ Parallel Testing (Unit, Quality, Security)"
    echo -e "   ✓ Package → Docker Build"
    echo -e "   ✓ Staging Deploy → Tests → QA Approval"
    echo -e "   ✓ Production Deploy → Verification → Report"
    echo
    
    echo -e "${YELLOW}4. Notifications:${NC}"
    echo -e "   ✓ Telegram messages at each stage"
    echo -e "   ✓ Rich formatting with emojis"
    echo -e "   ✓ Approval notifications"
    echo
}

# Quick test after import
quick_test() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🧪 Quick Test After Import${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    echo -e "${YELLOW}1. Test Build:${NC}"
    echo -e "   Go to: ${JENKINS_URL}/job/${JOB_NAME}/"
    echo -e "   Click: 'Build with Parameters' or 'Build Now'"
    echo
    
    echo -e "${YELLOW}2. Monitor:${NC}"
    echo -e "   Console: ${JENKINS_URL}/job/${JOB_NAME}/lastBuild/console"
    echo -e "   Pipeline: ${JENKINS_URL}/job/${JOB_NAME}/lastBuild/pipeline"
    echo
    
    echo -e "${YELLOW}3. Check Telegram:${NC}"
    echo -e "   You should receive notifications for each stage"
    echo
}

# Main menu
show_menu() {
    echo -e "${CYAN}Choose import method:${NC}"
    echo -e "  ${YELLOW}1)${NC} GUI Import (Step-by-step guide)"
    echo -e "  ${YELLOW}2)${NC} Update Existing Job"
    echo -e "  ${YELLOW}3)${NC} Jenkins CLI Method"
    echo -e "  ${YELLOW}4)${NC} Direct Workspace Import"
    echo -e "  ${YELLOW}5)${NC} Show Copy Commands"
    echo -e "  ${YELLOW}6)${NC} Verify Pipeline Features"
    echo -e "  ${YELLOW}7)${NC} View Jenkinsfile Content"
    echo -e "  ${YELLOW}8)${NC} Exit"
    echo
}

# View Jenkinsfile content
view_jenkinsfile() {
    echo -e "${CYAN}Jenkinsfile Preview (first 50 lines):${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    head -50 Jenkinsfile
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}... ($(wc -l < Jenkinsfile) total lines)${NC}"
    echo
    echo -e "${CYAN}View full file:${NC} cat Jenkinsfile | less"
    echo
}

# Main execution
main() {
    # Check Jenkins status
    if ! check_jenkins; then
        exit 1
    fi
    
    # Show Jenkinsfile info
    show_jenkinsfile_info
    
    # Interactive menu loop
    while true; do
        show_menu
        read -p "Enter your choice (1-8): " choice
        
        case $choice in
            1) method_1_gui ;;
            2) method_2_update ;;
            3) method_3_cli ;;
            4) method_4_direct ;;
            5) show_copy_commands ;;
            6) verify_features ;;
            7) view_jenkinsfile ;;
            8) 
                echo -e "${GREEN}✅ Exiting import guide${NC}"
                break 
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
        clear
    done
    
    # Final instructions
    echo
    echo -e "${GREEN}📋 Import Summary:${NC}"
    echo -e "  ✅ Jenkinsfile location: ${WORKSPACE_DIR}/Jenkinsfile"
    echo -e "  ✅ Target job: ${JOB_NAME}"
    echo -e "  ✅ Jenkins URL: ${JENKINS_URL}"
    echo
    echo -e "${CYAN}Next Steps:${NC}"
    echo -e "  1. Import Jenkinsfile using your preferred method"
    echo -e "  2. Run a test build"
    echo -e "  3. Monitor Telegram notifications"
    echo -e "  4. Check deployment URLs"
    echo
    quick_test
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 Jenkins Pipeline Import Guide Completed!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Run main function
main "$@" 