#!/bin/bash
# Ultra-simple Git Backup - No colors, no fancy output

VPS_HOST="palpinter@murakami"
BACKUP_LOG="$HOME/.local/backups/logs/git-backup-$(date +%Y%m%d_%H%M%S).log"

echo "Git Backup to VPS"
echo "Log: $BACKUP_LOG"
echo ""

success=0
skipped=0
errors=0
total=0

# Get all repos into array
mapfile -t repos < <(find ~/Kódtár/aktiv -name ".git" -type d | sed 's|/.git$||' | sort)

echo "Found ${#repos[@]} repositories"
echo ""

for repo_path in "${repos[@]}"; do
    ((total++))

    account=$(basename "$(dirname "$repo_path")")
    repo_name=$(basename "$repo_path")

    echo "[$total/${#repos[@]}] $account/$repo_name"

    cd "$repo_path" || { echo "  ERROR: Cannot cd"; ((errors++)); continue; }

    # Check dirty
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        echo "  SKIP: uncommitted changes"
        ((skipped++))
        continue
    fi

    # Check has commits
    if ! git rev-parse HEAD &>/dev/null; then
        echo "  SKIP: no commits"
        ((skipped++))
        continue
    fi

    # Add remote if needed
    if ! git remote get-url vps-backup &>/dev/null 2>&1; then
        echo "  Creating VPS repo..."
        if ssh "$VPS_HOST" "mkdir -p /var/git/$account && git init --bare /var/git/$account/$repo_name.git" &>/dev/null; then
            git remote add vps-backup "$VPS_HOST:/var/git/$account/$repo_name.git"
            echo "  Remote added"
        else
            echo "  ERROR: VPS setup failed"
            ((errors++))
            continue
        fi
    fi

    # Push
    echo "  Pushing..."
    if git push vps-backup --mirror --quiet 2>/dev/null; then
        echo "  SUCCESS"
        ((success++))
    else
        echo "  ERROR: push failed"
        ((errors++))
    fi

    echo ""
done

echo "Summary:"
echo "  Total: $total"
echo "  Success: $success"
echo "  Skipped: $skipped"
echo "  Errors: $errors"
