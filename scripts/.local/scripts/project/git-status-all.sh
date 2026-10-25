#!/bin/bash
# Show Git status for all repositories under ~/Kódtár/aktiv/<account>/<repo>
PROJECTS_DIR="$HOME/Kódtár/aktiv"

echo "🔍 Git Status - All Repositories"
echo "================================="

for account_dir in "$PROJECTS_DIR"/*/; do
    echo ""
    echo "📂 $(basename "$account_dir")"
    for project_dir in "$account_dir"*/; do
        [ -d "$project_dir" ] || continue
        printf '  %s: ' "$(basename "$project_dir")"
        if ! git -C "$project_dir" rev-parse --git-dir &>/dev/null; then
            echo "❌ Not a Git repository"
            continue
        fi
        changes=$(git -C "$project_dir" status --porcelain)   # includes untracked files
        ahead=$(git -C "$project_dir" rev-list --count @{u}..HEAD 2>/dev/null || echo "?")
        if [ -z "$changes" ]; then
            echo "✅ Clean (unpushed: $ahead)"
        else
            echo "⚠️  Changes (unpushed: $ahead)"
            echo "$changes" | sed 's/^/    /'
        fi
    done
done
