#!/bin/bash

# Git Repository Setup Script
echo "=== Git Repository Setup ==="
echo ""

# Check current git status
echo "📋 Current Git Configuration:"
if git remote -v; then
    echo ""
else
    echo "❌ No git repository initialized"
    exit 1
fi

echo "🔍 Current repository: $(git remote get-url origin 2>/dev/null || echo 'No origin set')"
echo ""

# Ask user what they want to do
echo "What would you like to do?"
echo "1. Keep current repository (https://github.com/zikazama/jenkins.git)"
echo "2. Change to your own repository"
echo "3. Fork the repository on GitHub"
echo ""

read -p "Choose option [1-3]: " choice

case $choice in
    1)
        echo "✅ Keeping current repository configuration"
        echo "Repository: https://github.com/zikazama/jenkins.git"
        echo ""
        echo "⚠️ Note: You need write access to push to this repository"
        echo "If you get permission denied, try option 2 or 3"
        ;;
    2)
        echo ""
        read -p "Enter your GitHub username: " username
        read -p "Enter your repository name (default: jenkins-demo): " reponame
        reponame=${reponame:-jenkins-demo}
        
        new_repo="https://github.com/${username}/${reponame}.git"
        
        echo "🔄 Changing repository to: $new_repo"
        git remote remove origin
        git remote add origin $new_repo
        
        echo "✅ Repository updated!"
        echo "📝 Don't forget to create the repository on GitHub first:"
        echo "   https://github.com/new"
        echo ""
        echo "🚀 To push your code:"
        echo "   git push -u origin main"
        ;;
    3)
        echo ""
        echo "📱 To fork the repository:"
        echo "1. Go to: https://github.com/zikazama/jenkins"
        echo "2. Click 'Fork' button"
        echo "3. Run this script again and choose option 2"
        echo "4. Use your forked repository URL"
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

echo ""
echo "📋 Final Git Configuration:"
git remote -v
echo ""
echo "🎉 Git setup complete!" 