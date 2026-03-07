#!/bin/bash
# Simple Git Backup - Sequential backup with progress

set -e

VPS_HOST="palpinter@murakami"
BACKUP_LOG="$HOME/.local/backups/logs/git-backup-$(date +%Y%m%d_%H%M%S).log"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$BACKUP_LOG"
}

echo "🔄 Git Backup - Sequential Mode"
echo "📝 Log: $BACKUP_LOG"
echo ""

total=0
success=0
skipped=0
errors=0

# Find all repos (use array to avoid stdin issues)
mapfile -t repos < <(find ~/Kódtár/aktiv -name ".git" -type d | sed 's|/.git$||' | sort)
total_count=${#repos[@]}

echo "Found $total_count repositories"
echo ""

for repo_path in "${repos[@]}"; do
    [[ -z "$repo_path" ]] && continue
    ((total++))

    account=$(basename "$(dirname "$repo_path")")
    repo_name=$(basename "$repo_path")

    echo -n "[$total/$total_count] $account/$repo_name ... "

    # Check if Git repo
    if [[ ! -d "$repo_path/.git" ]]; then
        echo -e "${YELLOW}SKIP (not a repo)${NC}"
        ((skipped++))
        continue
    fi

    cd "$repo_path"

    # Check for uncommitted changes
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        echo -e "${YELLOW}SKIP (uncommitted changes)${NC}"
        log "SKIP: $account/$repo_name - uncommitted changes"
        ((skipped++))
        continue
    fi

    # Check if has commits
    if ! git rev-parse HEAD &>/dev/null; then
        echo -e "${YELLOW}SKIP (no commits)${NC}"
        ((skipped++))
        continue
    fi

    # Check/add VPS remote
    if ! git remote get-url vps-backup &>/dev/null 2>&1; then
        # Create VPS repo
        if ssh "$VPS_HOST" "mkdir -p /var/git/$account && git init --bare /var/git/$account/$repo_name.git" &>/dev/null; then
            git remote add vps-backup "$VPS_HOST:/var/git/$account/$repo_name.git"
        else
            echo -e "${RED}ERROR (VPS setup failed)${NC}"
            log "ERROR: $account/$repo_name - VPS setup failed"
            ((errors++))
            continue
        fi
    fi

    # Push to VPS
    if git push vps-backup --mirror --quiet 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
        log "SUCCESS: $account/$repo_name"
        ((success++))
    else
        echo -e "${RED}ERROR (push failed)${NC}"
        log "ERROR: $account/$repo_name - push failed"
        ((errors++))
    fi

done

echo ""
echo "📊 Summary:"
echo "   Total: $total"
echo "   Success: $success"
echo "   Skipped: $skipped"
echo "   Errors: $errors"
echo ""
echo "📝 Log: $BACKUP_LOG"
