#!/bin/bash
# Test Git multi-account setup

echo "🧪 Testing Git Multi-Account Setup"
echo "=================================="

# Test GitHub Personal
echo ""
echo "🐙 Testing GitHub Personal..."
cd ~/Kódtár/aktiv/github-pal-pinter
mkdir -p test-repo && cd test-repo
git init
echo "# Test" > README.md
git add README.md
git commit -m "Test commit"
echo "Git identity: $(git config user.email)"
cd .. && rm -rf test-repo

# Test GitHub Work
echo ""
echo "🐙 Testing GitHub Work..."
cd ~/Kódtár/aktiv/github-pinter-pal-orgware
mkdir -p test-repo && cd test-repo
git init
echo "# Test" > README.md
git add README.md
git commit -m "Test commit"
echo "Git identity: $(git config user.email)"
cd .. && rm -rf test-repo

# Test GitLab Personal
echo ""
echo "🦊 Testing GitLab Personal..."
cd ~/Kódtár/aktiv/gitlab-pal-pinter
mkdir -p test-repo && cd test-repo
git init
echo "# Test" > README.md
git add README.md
git commit -m "Test commit"
echo "Git identity: $(git config user.email)"
cd .. && rm -rf test-repo

# Test GitLab Work
echo ""
echo "🦊 Testing GitLab Work..."
cd ~/Kódtár/aktiv/gitlab-pinter-pal
mkdir -p test-repo && cd test-repo
git init
echo "# Test" > README.md
git add README.md
git commit -m "Test commit"
echo "Git identity: $(git config user.email)"
cd .. && rm -rf test-repo

echo ""
echo "✅ Git multi-account test completed"
