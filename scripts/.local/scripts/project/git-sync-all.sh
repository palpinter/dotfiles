#!/bin/bash
# Git Sync All - Frissíti az összes Git repository-t a Kódtár-ban

set -e

KODTAR_BASE="$HOME/Kódtár"
LOGFILE="$HOME/.local/backups/logs/git-sync-$(date +%Y%m%d).log"

# Színek
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

show_status() {
    local status=$1
    local repo=$2
    local message=$3

    case $status in
        "OK")
            echo -e "${GREEN}✅ $repo${NC}: $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  $repo${NC}: $message"
            ;;
        "ERROR")
            echo -e "${RED}❌ $repo${NC}: $message"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $repo${NC}: $message"
            ;;
    esac
}

sync_repository() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    local account=$(basename $(dirname "$repo_path"))

    if [[ ! -d "$repo_path/.git" ]]; then
        show_status "WARN" "$account/$repo_name" "Not a Git repository"
        return 0
    fi

    cd "$repo_path"

    # Git status ellenőrzése
    if ! git status &>/dev/null; then
        show_status "ERROR" "$account/$repo_name" "Git status failed"
        return 1
    fi

    # Dirty working directory ellenőrzése
    if [[ -n $(git status --porcelain) ]]; then
        show_status "WARN" "$account/$repo_name" "Dirty working directory - skipping"
        log "SKIP: $account/$repo_name - uncommitted changes"
        return 0
    fi

    # Remote ellenőrzése
    if ! git remote get-url origin &>/dev/null; then
        show_status "WARN" "$account/$repo_name" "No remote origin - skipping"
        return 0
    fi

    # Fetch all remotes
    if git fetch --all --prune &>/dev/null; then
        show_status "OK" "$account/$repo_name" "Fetch successful"
        log "FETCH: $account/$repo_name - success"
    else
        show_status "ERROR" "$account/$repo_name" "Fetch failed"
        log "FETCH_ERROR: $account/$repo_name"
        return 1
    fi

    # Current branch
    local current_branch=$(git branch --show-current)
    if [[ -z "$current_branch" ]]; then
        show_status "WARN" "$account/$repo_name" "Detached HEAD - skipping pull"
        return 0
    fi

    # Check if remote tracking branch exists
    local upstream=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "")
    if [[ -z "$upstream" ]]; then
        show_status "INFO" "$account/$repo_name" "No upstream branch for $current_branch"
        return 0
    fi

    # Check if pull is needed
    local local_commit=$(git rev-parse HEAD)
    local remote_commit=$(git rev-parse @{upstream})

    if [[ "$local_commit" == "$remote_commit" ]]; then
        show_status "OK" "$account/$repo_name" "Already up to date"
        return 0
    fi

    # Fast-forward only pull
    if git pull --ff-only &>/dev/null; then
        show_status "OK" "$account/$repo_name" "Pulled successfully"
        log "PULL: $account/$repo_name - success"
    else
        show_status "WARN" "$account/$repo_name" "Cannot fast-forward - manual merge needed"
        log "PULL_CONFLICT: $account/$repo_name - needs manual merge"
    fi
}

main() {
    local target_dir="${1:-$KODTAR_BASE/aktiv}"
    local stats_total=0
    local stats_synced=0
    local stats_errors=0
    local stats_warnings=0

    if [[ ! -d "$target_dir" ]]; then
        echo "❌ Directory not found: $target_dir"
        exit 1
    fi

    echo "🔄 Git Sync All - Started"
    echo "📁 Target directory: $target_dir"
    echo "📝 Log file: $LOGFILE"
    echo ""
    log "=== Git Sync All Started ==="

    # Find all Git repositories
    while IFS= read -r -d '' repo_path; do
        ((stats_total++))

        if sync_repository "$repo_path"; then
            if [[ $(git -C "$repo_path" status --porcelain) ]]; then
                ((stats_warnings++))
            else
                ((stats_synced++))
            fi
        else
            ((stats_errors++))
        fi

    done < <(find "$target_dir" -name ".git" -type d -print0 | sed 's|/.git||g' | sort -z)

    echo ""
    echo "📊 Summary:"
    echo "   Total repositories: $stats_total"
    echo "   Successfully synced: $stats_synced"
    echo "   Warnings: $stats_warnings"
    echo "   Errors: $stats_errors"

    log "=== Git Sync Summary: Total=$stats_total, Synced=$stats_synced, Warnings=$stats_warnings, Errors=$stats_errors ==="

    # Archívum is szinkronizálása (opcionális)
    if [[ "$target_dir" == "$KODTAR_BASE/aktiv" ]] && [[ -d "$KODTAR_BASE/archivum" ]]; then
        echo ""
        echo "🗃️  Also syncing archivum..."
        main "$KODTAR_BASE/archivum"
    fi
}

# Help
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Git Sync All - Sync all Git repositories"
    echo ""
    echo "Usage: $0 [directory]"
    echo ""
    echo "Options:"
    echo "  directory    Target directory (default: ~/Kódtár/aktiv)"
    echo "  -h, --help   Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                           # Sync all aktiv repositories"
    echo "  $0 ~/Kódtár/archivum        # Sync only archivum"
    echo "  $0 ~/Kódtár/aktiv/github-pal-pinter  # Sync only personal GitHub repos"
    exit 0
fi

main "$@"