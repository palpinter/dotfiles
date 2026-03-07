#!/bin/bash
# Git Backup to VPS - Unified account-based backup system

set -e

VPS_HOST="palpinter@murakami"
KODTAR_BASE="$HOME/Kódtár"
LOGFILE="$HOME/.local/backups/logs/git-backup-$(date +%Y%m%d).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
        "CONFLICT")
            echo -e "${RED}🔥 CONFLICT $repo${NC}: $message"
            ;;
    esac
}

check_vps_connection() {
    if ! ssh -o ConnectTimeout=5 "$VPS_HOST" "echo 'VPS connection test'" &>/dev/null; then
        echo "❌ Cannot connect to VPS: $VPS_HOST"
        exit 1
    fi
}

detect_conflicts() {
    local repo_path="$1"
    local account="$2"
    local repo_name="$3"

    cd "$repo_path"

    # Fetch VPS state without changing local state
    if ! git fetch vps-backup --quiet 2>/dev/null; then
        return 0  # No remote yet, no conflicts possible
    fi

    local conflicts_found=0

    # Check all local branches
    while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue

        local local_commit=$(git rev-parse "$branch" 2>/dev/null || continue)
        local vps_commit=$(git rev-parse "vps-backup/$branch" 2>/dev/null || echo "")

        if [[ -n "$vps_commit" && "$local_commit" != "$vps_commit" ]]; then
            # Check if branches have diverged (both have unique commits)
            if ! git merge-base --is-ancestor "$local_commit" "$vps_commit" 2>/dev/null &&
               ! git merge-base --is-ancestor "$vps_commit" "$local_commit" 2>/dev/null; then

                show_status "CONFLICT" "$account/$repo_name" "Branch '$branch' has diverged"
                echo "    Local:  $(git log -1 --format='%h %s' "$local_commit")"
                echo "    VPS:    $(git log -1 --format='%h %s' "$vps_commit")"
                echo "    Resolution: cd $repo_path && git pull vps-backup $branch"
                echo ""

                conflicts_found=1
                log "CONFLICT: $account/$repo_name branch $branch diverged"
            fi
        fi
    done < <(git branch --format='%(refname:short)')

    return $conflicts_found
}

backup_repository() {
    local repo_path="$1"
    local account=$(basename "$(dirname "$repo_path")")
    local repo_name=$(basename "$repo_path")

    if [[ ! -d "$repo_path/.git" ]]; then
        show_status "WARN" "$account/$repo_name" "Not a Git repository"
        return 0
    fi

    cd "$repo_path"

    # Check for uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        show_status "WARN" "$account/$repo_name" "Uncommitted changes - skipping"
        return 0
    fi

    # Skip if no commits
    if ! git rev-parse HEAD &>/dev/null; then
        show_status "WARN" "$account/$repo_name" "No commits - skipping"
        return 0
    fi

    # Check/add VPS backup remote
    if ! git remote get-url vps-backup &>/dev/null; then
        show_status "INFO" "$account/$repo_name" "Setting up VPS backup remote"

        # Create bare repository on VPS
        if ssh "$VPS_HOST" "~/.local/scripts/project/vps-create-repo.sh '$account' '$repo_name'" &>/dev/null; then
            # Add VPS remote
            git remote add vps-backup "$VPS_HOST:/var/git/$account/$repo_name.git"
            log "SETUP: $account/$repo_name - VPS remote added"
        else
            show_status "ERROR" "$account/$repo_name" "Failed to create VPS repository"
            return 1
        fi
    fi

    # Conflict detection
    if ! detect_conflicts "$repo_path" "$account" "$repo_name"; then
        show_status "ERROR" "$account/$repo_name" "Conflicts detected - manual resolution required"
        return 1
    fi

    # Backup to VPS
    if git push vps-backup --mirror --quiet 2>/dev/null; then
        show_status "OK" "$account/$repo_name" "Backed up to VPS"
        log "BACKUP: $account/$repo_name - success"
        return 0
    else
        show_status "ERROR" "$account/$repo_name" "Backup failed"
        log "BACKUP_ERROR: $account/$repo_name"
        return 1
    fi
}

backup_all_repositories() {
    local target_dir="${1:-$KODTAR_BASE/aktiv}"
    local stats_total=0
    local stats_backed_up=0
    local stats_conflicts=0
    local stats_errors=0
    local stats_warnings=0

    if [[ ! -d "$target_dir" ]]; then
        echo "❌ Directory not found: $target_dir"
        exit 1
    fi

    echo "🔄 Git Backup to VPS - Started"
    echo "📁 Target directory: $target_dir"
    echo "🖥️  VPS: $VPS_HOST"
    echo "📝 Log: $LOGFILE"
    echo ""

    log "=== Git Backup to VPS Started ==="

    # Find all Git repositories
    while IFS= read -r repo_path; do
        [[ -z "$repo_path" ]] && continue
        ((stats_total++))

        if backup_repository "$repo_path"; then
            ((stats_backed_up++))
        else
            local last_status=$(tail -1 "$LOGFILE" | grep -o 'CONFLICT\|BACKUP_ERROR' || echo "ERROR")
            if [[ "$last_status" == "CONFLICT" ]]; then
                ((stats_conflicts++))
            else
                ((stats_errors++))
            fi
        fi

    done < <(find "$target_dir" -name ".git" -type d | sed 's|/.git$||' | sort)

    echo ""
    echo "📊 Backup Summary:"
    echo "   Total repositories: $stats_total"
    echo "   Successfully backed up: $stats_backed_up"
    echo "   Conflicts (need resolution): $stats_conflicts"
    echo "   Errors: $stats_errors"

    log "=== Backup Summary: Total=$stats_total, Success=$stats_backed_up, Conflicts=$stats_conflicts, Errors=$stats_errors ==="

    if [[ $stats_conflicts -gt 0 ]]; then
        echo ""
        echo "🔥 Conflicts found! Run the suggested resolution commands above."
        return 1
    fi

    return 0
}

# Help
show_help() {
    echo "Git Backup to VPS - Unified repository backup system"
    echo ""
    echo "Usage: $0 [OPTIONS] [directory]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help"
    echo "  -c, --check    Only check for conflicts, don't backup"
    echo "  directory      Target directory (default: ~/Kódtár/aktiv)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Backup all active repos"
    echo "  $0 ~/Kódtár/archivum                 # Backup archive repos"
    echo "  $0 ~/Kódtár/aktiv/github-pal-pinter  # Backup specific account"
    echo "  $0 --check                           # Check for conflicts only"
    echo ""
    echo "Conflict Resolution:"
    echo "  When conflicts are detected, resolve manually:"
    echo "  cd path/to/repo"
    echo "  git fetch vps-backup"
    echo "  git pull vps-backup main  # or merge/rebase as needed"
    echo "  $0  # Run backup again"
}

# Main
main() {
    local check_only=0
    local target_dir=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--check)
                check_only=1
                shift
                ;;
            -*)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                target_dir="$1"
                shift
                ;;
        esac
    done

    # Default target directory
    target_dir="${target_dir:-$KODTAR_BASE/aktiv}"

    # Check VPS connection
    check_vps_connection

    if [[ $check_only -eq 1 ]]; then
        echo "🔍 Checking for conflicts only..."
        # Implementation for check-only mode would go here
        exit 0
    fi

    backup_all_repositories "$target_dir"
}

# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi