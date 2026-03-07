#!/bin/bash
# Show Git status for all repositories

set -e

PROJECTS_DIR="$HOME/Kódtár/aktiv"

echo "🔍 Git Status - All Repositories"
echo "================================="

for account_dir in "$PROJECTS_DIR"/*/; do
    if [ -d "$account_dir" ]; then
        account=$(basename "$account_dir")
        echo ""
        echo "📂 $account"
        echo "$(printf '%.0s-' {1..40})"

        for project_dir in "$account_dir"*/; do
            if [ -d "$project_dir" ]; then
                project=$(basename "$project_dir")
                echo -n "  $project: "

                cd "$project_dir"
                if [ -d ".git" ]; then
                    # Check if repository is clean
                    if git diff-index --quiet HEAD -- 2>/dev/null; then
                        echo "✅ Clean"
                    else
                        echo "⚠️  Changes"
                        git status --porcelain | sed 's/^/    /'
                    fi
                else
                    echo "❌ Not a Git repository"
                fi
            fi
        done
    fi
done
