#!/bin/bash
# Backup current machine's SSH keys and configs to security vault

set -e

HOSTNAME=$(hostname)
VAULT_DIR="$HOME/Kódtár/local/security-vault"
MACHINE_DIR="$VAULT_DIR/machines/$HOSTNAME"

echo "🔐 Backing up machine '$HOSTNAME' to security vault..."

# Check if vault exists
if [ ! -d "$VAULT_DIR" ]; then
    echo "❌ Security vault not found: $VAULT_DIR"
    exit 1
fi

# Create machine directory
mkdir -p "$MACHINE_DIR"

# Backup SSH keys
echo "📋 Backing up SSH keys..."
cp ~/.ssh/id_ed25519_* "$MACHINE_DIR/" 2>/dev/null || true

# Backup SSH config.local
echo "📋 Backing up SSH config.local..."
cp ~/.ssh/config.local "$MACHINE_DIR/ssh_config.local" 2>/dev/null || true

# Create machine metadata
cat > "$MACHINE_DIR/metadata.yaml" << METAEOF
hostname: $HOSTNAME
backup_date: $(date -Iseconds)
user: $(whoami)
os: $(uname -o)
kernel: $(uname -r)
ssh_keys:
  - id_ed25519_intermachine
  - id_ed25519_murakami
  - id_ed25519_github_personal
  - id_ed25519_github_work
  - id_ed25519_gitlab_personal
  - id_ed25519_gitlab_work
METAEOF

echo "✅ Machine backup completed: $MACHINE_DIR"

# Git commit and push
echo "📤 Committing to security vault..."
cd "$VAULT_DIR"

# Check if vault is unlocked
if ! git-crypt status &>/dev/null; then
    echo "⚠️  Warning: git-crypt may not be unlocked"
fi

git add .
git commit -m "Backup: $HOSTNAME - $(date '+%Y-%m-%d %H:%M')

Machine: $HOSTNAME
Date: $(date -Iseconds)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" 2>/dev/null || echo "No changes to commit"

# Push to VPS if remote exists
if git remote get-url origin &>/dev/null; then
    echo "📡 Pushing to VPS..."
    git push origin main 2>/dev/null || git push origin master 2>/dev/null || echo "⚠️  Push failed - check remote"
else
    echo "⚠️  No remote configured. Set up with:"
    echo "    cd $VAULT_DIR"
    echo "    git remote add origin palpinter@murakami:/var/git/security-vault.git"
fi

echo "✅ Backup and sync completed"
