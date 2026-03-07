#!/bin/bash
# Development Environment Manager - Client Installation Script

set -e

echo "🚀 Development Environment Manager - Client Setup"
echo "=================================================="

# Check if running on Arch Linux
if ! command -v pacman &> /dev/null; then
    echo "❌ This script is designed for Arch Linux"
    exit 1
fi

# Check if running as correct user
if [ "$USER" != "palpinter" ]; then
    echo "❌ This script must be run as user 'palpinter'"
    exit 1
fi

HOSTNAME=$(hostname)
echo "🖥️  Setting up client machine: $HOSTNAME"

# Add ~/.local/scripts to PATH if not already there
if ! echo "$PATH" | grep -q "$HOME/.local/scripts"; then
    echo 'export PATH="$HOME/.local/scripts:$PATH"' >> ~/.bashrc
    echo "✅ Added ~/.local/scripts to PATH"
fi

# Source the updated PATH
export PATH="$HOME/.local/scripts:$PATH"

echo "✅ Installation completed successfully!"
echo ""
echo "Next steps:"
echo "1. Configure Syncthing: http://localhost:8384"
echo "2. Add other devices and share ~/Sync folder"
echo "3. Upload SSH public keys to GitHub/GitLab"
echo "4. Test Git multi-account setup"
echo "5. Configure security vault access"
