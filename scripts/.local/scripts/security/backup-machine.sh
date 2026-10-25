#!/bin/bash
# Backup current machine's SSH keys and configs to the security vault
set -euo pipefail

HOSTNAME=$(hostname)
VAULT_DIR="$HOME/Kódtár/local/security-vault"
MACHINE_DIR="$VAULT_DIR/machines/$HOSTNAME"

echo "🔐 Backing up machine '$HOSTNAME' to security vault..."

[ -d "$VAULT_DIR/.git" ] || { echo "❌ Security vault not found: $VAULT_DIR"; exit 1; }

# Refuse to write private keys into a vault that is not encrypted or still locked
# (git crypt status succeeds even when locked – the key under .git/git-crypt only exists after unlock)
if ! grep -q '^machines/\*\* filter=git-crypt' "$VAULT_DIR/.gitattributes" 2>/dev/null; then
    echo "❌ machines/** is not covered by git-crypt in .gitattributes – private keys would be stored in plain text"
    exit 1
fi
if [ ! -d "$(git -C "$VAULT_DIR" rev-parse --absolute-git-dir)/git-crypt/keys" ]; then
    echo "❌ Vault is locked – run: git -C $VAULT_DIR crypt unlock   (needs the vault GPG key)"
    exit 1
fi

mkdir -p "$MACHINE_DIR"
cp ~/.ssh/id_ed25519_* "$MACHINE_DIR/"
cp ~/.ssh/config.local "$MACHINE_DIR/ssh_config.local" 2>/dev/null || true

{
    echo "hostname: $HOSTNAME"
    echo "backup_date: $(date -Iseconds)"
    echo "user: $(whoami)"
    echo "os: $(. /etc/os-release && echo "$PRETTY_NAME")"
    echo "kernel: $(uname -r)"
    echo "ssh_keys:"
    for k in ~/.ssh/id_ed25519_*.pub; do echo "  - $(basename "$k" .pub)"; done
} > "$MACHINE_DIR/metadata.yaml"

echo "✅ Machine backup completed: $MACHINE_DIR"
echo "💡 Commit and push: git -C $VAULT_DIR add -A && git -C $VAULT_DIR commit -m 'backup $HOSTNAME' && git -C $VAULT_DIR push"
