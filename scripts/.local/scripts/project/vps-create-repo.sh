#!/bin/bash
# VPS Git Repository Creator
# Használat: ssh palpinter@murakami "create-repo.sh account repo-name"

set -e

VPS_GIT_BASE="/var/git"

create_repo() {
    local account="$1"
    local repo_name="$2"

    if [[ -z "$account" || -z "$repo_name" ]]; then
        echo "Usage: $0 <account> <repo-name>"
        echo "Example: $0 github-pal-pinter my-project"
        exit 1
    fi

    local repo_path="$VPS_GIT_BASE/$account/$repo_name.git"

    if [[ -d "$repo_path" ]]; then
        echo "ℹ️  Repository already exists: $repo_path"
        return 0
    fi

    echo "📦 Creating bare repository: $account/$repo_name"

    # Create directory structure
    mkdir -p "$(dirname "$repo_path")"

    # Initialize bare repository
    git init --bare "$repo_path"

    # Set ownership
    chown -R palpinter:palpinter "$repo_path"

    # Set description
    echo "$account/$repo_name - Auto-created backup repository" > "$repo_path/description"

    echo "✅ Created: $repo_path"
    return 0
}

# If called with arguments
if [[ $# -gt 0 ]]; then
    create_repo "$@"
fi