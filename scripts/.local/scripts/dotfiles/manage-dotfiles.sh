#!/bin/bash
# Manage dotfiles deployment using GNU Stow

set -e

DOTFILES_DIR="$HOME/.dotfiles"
MACHINE_OVERRIDES="$HOME/Dokumentumok/1_Munkaterület/Területek/Adminisztráció/Dotfiles_konfiguráció"
HOSTNAME=$(hostname)

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $(basename "$0") [COMMAND] [PACKAGE]

Commands:
    list                List all available packages
    status              Show which packages are deployed
    deploy [pkg]        Deploy a package (or all if no pkg specified)
    remove [pkg]        Remove a package deployment
    restow [pkg]        Restow a package (useful after config changes)
    deploy-all          Deploy all packages
    help                Show this help message

Examples:
    $(basename "$0") list
    $(basename "$0") deploy zsh
    $(basename "$0") deploy-all
    $(basename "$0") restow alacritty
    $(basename "$0") remove tmux

Packages are managed in: $DOTFILES_DIR
Machine-specific overrides: $MACHINE_OVERRIDES/machines/$HOSTNAME/
EOF
}

list_packages() {
    echo -e "${BLUE}📦 Available Dotfiles Packages:${NC}"
    cd "$DOTFILES_DIR"
    for pkg in */; do
        pkg=${pkg%/}
        # Skip hidden dirs and docs
        if [[ ! "$pkg" =~ ^\. ]] && [[ ! "$pkg" =~ ^(README|CLAUDE|preinstall) ]]; then
            echo "  - $pkg"
        fi
    done
}

check_deployed() {
    local pkg=$1
    local deployed=0

    cd "$DOTFILES_DIR/$pkg" 2>/dev/null || return 1

    # Check if any symlinks exist pointing to this package
    find . -type f -o -type d | while read -r item; do
        # Remove leading ./
        item="${item#./}"
        target="$HOME/$item"

        if [ -L "$target" ]; then
            link=$(readlink "$target")
            if [[ "$link" == *".dotfiles/$pkg"* ]]; then
                deployed=1
                break
            fi
        fi
    done

    return $((1 - deployed))
}

show_status() {
    echo -e "${BLUE}📊 Dotfiles Deployment Status:${NC}"
    cd "$DOTFILES_DIR"

    for pkg in */; do
        pkg=${pkg%/}
        if [[ ! "$pkg" =~ ^\. ]] && [[ ! "$pkg" =~ ^(README|CLAUDE|preinstall) ]]; then
            if check_deployed "$pkg"; then
                echo -e "  ${GREEN}✓${NC} $pkg (deployed)"
            else
                echo -e "  ${YELLOW}○${NC} $pkg (not deployed)"
            fi
        fi
    done
}

deploy_package() {
    local pkg=$1

    if [ ! -d "$DOTFILES_DIR/$pkg" ]; then
        echo -e "${RED}❌ Package not found: $pkg${NC}"
        return 1
    fi

    echo -e "${BLUE}📥 Deploying package: $pkg${NC}"
    cd "$DOTFILES_DIR"

    # Dry run first to check for conflicts
    if stow -nv "$pkg" 2>&1 | grep -q "WARNING"; then
        echo -e "${YELLOW}⚠️  Conflicts detected. Use 'stow --adopt $pkg' to merge, or remove conflicting files first.${NC}"
        stow -nv "$pkg"
        return 1
    fi

    stow "$pkg"
    echo -e "${GREEN}✅ Package deployed: $pkg${NC}"
}

remove_package() {
    local pkg=$1

    if [ ! -d "$DOTFILES_DIR/$pkg" ]; then
        echo -e "${RED}❌ Package not found: $pkg${NC}"
        return 1
    fi

    echo -e "${BLUE}📤 Removing package: $pkg${NC}"
    cd "$DOTFILES_DIR"
    stow -D "$pkg"
    echo -e "${GREEN}✅ Package removed: $pkg${NC}"
}

restow_package() {
    local pkg=$1

    if [ ! -d "$DOTFILES_DIR/$pkg" ]; then
        echo -e "${RED}❌ Package not found: $pkg${NC}"
        return 1
    fi

    echo -e "${BLUE}🔄 Restowing package: $pkg${NC}"
    cd "$DOTFILES_DIR"
    stow -R "$pkg"
    echo -e "${GREEN}✅ Package restowed: $pkg${NC}"
}

deploy_all() {
    echo -e "${BLUE}📦 Deploying all packages...${NC}"
    cd "$DOTFILES_DIR"

    local failed=()

    for pkg in */; do
        pkg=${pkg%/}
        if [[ ! "$pkg" =~ ^\. ]] && [[ ! "$pkg" =~ ^(README|CLAUDE|preinstall) ]]; then
            if ! deploy_package "$pkg"; then
                failed+=("$pkg")
            fi
        fi
    done

    echo ""
    if [ ${#failed[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ All packages deployed successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Some packages failed to deploy:${NC}"
        for pkg in "${failed[@]}"; do
            echo "  - $pkg"
        done
    fi
}

# Main
case "${1:-help}" in
    list)
        list_packages
        ;;
    status)
        show_status
        ;;
    deploy)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Package name required${NC}"
            usage
            exit 1
        fi
        deploy_package "$2"
        ;;
    remove)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Package name required${NC}"
            usage
            exit 1
        fi
        remove_package "$2"
        ;;
    restow)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Package name required${NC}"
            usage
            exit 1
        fi
        restow_package "$2"
        ;;
    deploy-all)
        deploy_all
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
