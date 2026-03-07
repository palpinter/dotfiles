#!/bin/bash
# Setup VPS Git Structure
# Creates the basic directory structure on VPS

VPS_HOST="palpinter@murakami"
VPS_GIT_BASE="/var/git"

setup_vps_structure() {
    echo "🏗️  Setting up VPS Git structure..."

    # Create base directories on VPS
    ssh "$VPS_HOST" "
        sudo mkdir -p $VPS_GIT_BASE/{github-pal-pinter,github-pinter-pal-orgware,gitlab-pal-pinter,gitlab-pinter-pal,local}
        sudo chown -R palpinter:palpinter $VPS_GIT_BASE
        chmod 755 $VPS_GIT_BASE

        # Copy repo creation script to VPS
        mkdir -p ~/.local/scripts/project
    "

    # Copy VPS repo creation script
    scp ~/.local/scripts/project/vps-create-repo.sh "$VPS_HOST:~/.local/scripts/project/"
    ssh "$VPS_HOST" "chmod +x ~/.local/scripts/project/vps-create-repo.sh"

    echo "✅ VPS Git structure ready:"
    ssh "$VPS_HOST" "tree $VPS_GIT_BASE -L 2 2>/dev/null || ls -la $VPS_GIT_BASE"
}

# Check VPS connection
if ! ssh -o ConnectTimeout=5 "$VPS_HOST" "echo 'Connection test'" &>/dev/null; then
    echo "❌ Cannot connect to VPS: $VPS_HOST"
    exit 1
fi

setup_vps_structure