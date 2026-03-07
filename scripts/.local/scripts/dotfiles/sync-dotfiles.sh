#!/bin/bash
# Sync dotfiles with GitHub repository

set -e

DOTFILES_DIR="$HOME/.dotfiles"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $(basename "$0") [COMMAND]

Commands:
    status      Show git status
    pull        Pull latest changes from GitHub
    push        Push local changes to GitHub
    commit      Stage all changes and commit
    sync        Pull, then push (full sync)
    diff        Show uncommitted changes
    log         Show recent commits

Examples:
    $(basename "$0") status
    $(basename "$0") pull
    $(basename "$0") commit
    $(basename "$0") sync

Repository: $DOTFILES_DIR
EOF
}

show_status() {
    echo -e "${BLUE}📊 Dotfiles Git Status:${NC}"
    cd "$DOTFILES_DIR"
    git status
}

pull_changes() {
    echo -e "${BLUE}📥 Pulling latest changes from GitHub...${NC}"
    cd "$DOTFILES_DIR"

    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || {
        echo -e "${RED}❌ Pull failed${NC}"
        return 1
    }

    echo -e "${GREEN}✅ Dotfiles updated${NC}"
}

push_changes() {
    echo -e "${BLUE}📤 Pushing changes to GitHub...${NC}"
    cd "$DOTFILES_DIR"

    # Check if there are commits to push
    if git diff --quiet && git diff --cached --quiet; then
        if [ "$(git rev-list --count @{u}.. 2>/dev/null || echo 0)" -eq 0 ]; then
            echo -e "${YELLOW}⚠️  No changes to push${NC}"
            return 0
        fi
    fi

    git push origin main 2>/dev/null || git push origin master 2>/dev/null || {
        echo -e "${RED}❌ Push failed${NC}"
        return 1
    }

    echo -e "${GREEN}✅ Changes pushed to GitHub${NC}"
}

commit_changes() {
    echo -e "${BLUE}📝 Committing dotfiles changes...${NC}"
    cd "$DOTFILES_DIR"

    # Check if there are changes
    if git diff --quiet && git diff --cached --quiet; then
        echo -e "${YELLOW}⚠️  No changes to commit${NC}"
        return 0
    fi

    # Show status
    echo ""
    git status --short
    echo ""

    # Stage all changes
    git add -A

    # Get hostname for commit message
    HOSTNAME=$(hostname)

    # Commit with automatic message
    git commit -m "Update dotfiles: $HOSTNAME - $(date '+%Y-%m-%d %H:%M')

Hostname: $HOSTNAME
Date: $(date -Iseconds)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" || {
        echo -e "${RED}❌ Commit failed${NC}"
        return 1
    }

    echo -e "${GREEN}✅ Changes committed${NC}"
}

sync_all() {
    echo -e "${BLUE}🔄 Full dotfiles sync...${NC}"

    # Pull first
    pull_changes || return 1

    # Check if there are local changes
    cd "$DOTFILES_DIR"
    if ! git diff --quiet || ! git diff --cached --quiet; then
        # Commit local changes
        commit_changes || return 1
    fi

    # Push
    push_changes || return 1

    echo -e "${GREEN}✅ Dotfiles fully synced${NC}"
}

show_diff() {
    echo -e "${BLUE}📋 Uncommitted changes:${NC}"
    cd "$DOTFILES_DIR"
    git diff
    git diff --cached
}

show_log() {
    echo -e "${BLUE}📜 Recent commits:${NC}"
    cd "$DOTFILES_DIR"
    git log --oneline --graph --decorate -10
}

# Main
case "${1:-status}" in
    status)
        show_status
        ;;
    pull)
        pull_changes
        ;;
    push)
        push_changes
        ;;
    commit)
        commit_changes
        ;;
    sync)
        sync_all
        ;;
    diff)
        show_diff
        ;;
    log)
        show_log
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        usage
        exit 1
        ;;
esac
