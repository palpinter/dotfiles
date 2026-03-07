#!/bin/bash
# Install Git Backup System

echo "🚀 Installing Git Backup System..."

# Make scripts executable
chmod +x ~/.local/scripts/project/vps-create-repo.sh
chmod +x ~/.local/scripts/project/git-backup-to-vps.sh
chmod +x ~/.local/scripts/project/setup-vps-git-structure.sh

# Add aliases to shell config
if ! grep -q "git-backup-vps" ~/.zshrc; then
    {
        echo ""
        echo "# Git Backup System aliases"
        echo "alias git-backup-vps='~/.local/scripts/project/git-backup-to-vps.sh'"
        echo "alias git-backup-check='~/.local/scripts/project/git-backup-to-vps.sh --check'"
    } >> ~/.zshrc
fi

echo "✅ Scripts installed and made executable"
echo "✅ Aliases added to ~/.zshrc"

# Setup VPS structure
echo ""
echo "Setting up VPS..."
~/.local/scripts/project/setup-vps-git-structure.sh

echo ""
echo "🎉 Git Backup System installed!"
echo ""
echo "Usage:"
echo "  source ~/.zshrc  # Reload shell config"
echo "  git-backup-vps   # Backup all repositories"
echo "  git-backup-check # Check for conflicts"
echo ""
echo "VPS Structure:"
echo "  /var/git/github-pal-pinter/"
echo "  /var/git/github-pinter-pal-orgware/"
echo "  /var/git/gitlab-pal-pinter/"
echo "  /var/git/gitlab-pinter-pal/"
echo "  /var/git/local/"