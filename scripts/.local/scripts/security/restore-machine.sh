#!/bin/bash
# Restore SSH keys and configs from security vault to current machine

set -e

MACHINE_NAME="${1:-$(hostname)}"
VAULT_DIR="$HOME/Kódtár/local/security-vault"
MACHINE_DIR="$VAULT_DIR/machines/$MACHINE_NAME"

echo "🔓 Restoring machine '$MACHINE_NAME' from security vault..."

# Check if vault exists
if [ ! -d "$VAULT_DIR" ]; then
    echo "❌ Security vault not found: $VAULT_DIR"
    echo "💡 Clone it first:"
    echo "    git clone palpinter@murakami:/var/git/security-vault.git ~/Kódtár/local/security-vault"
    exit 1
fi

# Check if machine backup exists
if [ ! -d "$MACHINE_DIR" ]; then
    echo "❌ Machine backup not found: $MACHINE_DIR"
    echo "Available machines:"
    ls -1 "$VAULT_DIR/machines/" 2>/dev/null || echo "  None"
    exit 1
fi

# Check if vault is unlocked
if ! git-crypt status &>/dev/null; then
    echo "⚠️  Vault may be locked. Attempting unlock..."
    cd "$VAULT_DIR"
    git-crypt unlock || {
        echo "❌ Failed to unlock vault. Import GPG key first:"
        echo "    gpg --import $VAULT_DIR/gpg-keys/gadamer-private-key.asc"
        exit 1
    }
fi

# Backup existing SSH directory
if [ -d ~/.ssh ]; then
    BACKUP_DIR=~/.ssh.backup.$(date +%Y%m%d_%H%M%S)
    echo "📋 Backing up existing ~/.ssh to $BACKUP_DIR"
    cp -r ~/.ssh "$BACKUP_DIR"
fi

# Restore SSH keys
echo "📥 Restoring SSH keys..."
mkdir -p ~/.ssh
cp "$MACHINE_DIR"/id_ed25519_* ~/.ssh/ 2>/dev/null || true

# Restore SSH config.local
if [ -f "$MACHINE_DIR/ssh_config.local" ]; then
    echo "📥 Restoring SSH config.local..."
    cp "$MACHINE_DIR/ssh_config.local" ~/.ssh/config.local
fi

# Set proper permissions
echo "🔒 Setting permissions..."
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519_* 2>/dev/null || true
chmod 644 ~/.ssh/id_ed25519_*.pub 2>/dev/null || true
chmod 600 ~/.ssh/config* 2>/dev/null || true

# Show metadata
if [ -f "$MACHINE_DIR/metadata.yaml" ]; then
    echo ""
    echo "📄 Machine metadata:"
    cat "$MACHINE_DIR/metadata.yaml"
fi

echo ""
echo "✅ Restore completed for machine: $MACHINE_NAME"
echo "🔑 SSH keys restored to ~/.ssh/"
