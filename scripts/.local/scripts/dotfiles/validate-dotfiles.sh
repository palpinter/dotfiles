#!/bin/bash
# Validate dotfiles syntax and configuration

set -e

DOTFILES_DIR="$HOME/.dotfiles"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

errors=0
warnings=0

check_shell_scripts() {
    echo -e "${BLUE}🔍 Checking shell scripts...${NC}"

    local scripts=$(find "$DOTFILES_DIR" -name "*.sh" -type f -not -path "*/.git/*")

    if [ -z "$scripts" ]; then
        echo -e "${YELLOW}⚠️  No shell scripts found${NC}"
        return 0
    fi

    while IFS= read -r script; do
        # Check if shellcheck is available
        if command -v shellcheck &> /dev/null; then
            if ! shellcheck -x "$script" 2>/dev/null; then
                echo -e "${RED}❌ Shellcheck failed: $script${NC}"
                ((errors++))
            else
                echo -e "${GREEN}✓${NC} $script"
            fi
        else
            # Basic syntax check with bash -n
            if ! bash -n "$script" 2>/dev/null; then
                echo -e "${RED}❌ Syntax error: $script${NC}"
                ((errors++))
            else
                echo -e "${GREEN}✓${NC} $script"
            fi
        fi
    done <<< "$scripts"
}

check_toml_files() {
    echo -e "\n${BLUE}🔍 Checking TOML files...${NC}"

    local toml_files=$(find "$DOTFILES_DIR" -name "*.toml" -type f -not -path "*/.git/*")

    if [ -z "$toml_files" ]; then
        echo -e "${YELLOW}⚠️  No TOML files found${NC}"
        return 0
    fi

    # Check if toml-cli or python toml module is available
    if command -v python3 &> /dev/null; then
        while IFS= read -r toml; do
            if python3 -c "import tomllib; tomllib.load(open('$toml', 'rb'))" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} $toml"
            else
                echo -e "${RED}❌ TOML syntax error: $toml${NC}"
                ((errors++))
            fi
        done <<< "$toml_files"
    else
        echo -e "${YELLOW}⚠️  Python3 not available, skipping TOML validation${NC}"
        ((warnings++))
    fi
}

check_lua_files() {
    echo -e "\n${BLUE}🔍 Checking Lua files...${NC}"

    local lua_files=$(find "$DOTFILES_DIR" -name "*.lua" -type f -not -path "*/.git/*")

    if [ -z "$lua_files" ]; then
        echo -e "${YELLOW}⚠️  No Lua files found${NC}"
        return 0
    fi

    if command -v luac &> /dev/null; then
        while IFS= read -r lua; do
            if luac -p "$lua" &>/dev/null; then
                echo -e "${GREEN}✓${NC} $lua"
            else
                echo -e "${RED}❌ Lua syntax error: $lua${NC}"
                ((errors++))
            fi
        done <<< "$lua_files"
    else
        echo -e "${YELLOW}⚠️  Lua compiler not available, skipping Lua validation${NC}"
        ((warnings++))
    fi
}

check_symlinks() {
    echo -e "\n${BLUE}🔍 Checking deployed symlinks...${NC}"

    # Check if any symlinks are broken
    local broken=0
    while IFS= read -r link; do
        if [ ! -e "$link" ]; then
            echo -e "${RED}❌ Broken symlink: $link${NC}"
            ((errors++))
            ((broken++))
        fi
    done < <(find "$HOME" -maxdepth 3 -type l -lname "*/.dotfiles/*" 2>/dev/null)

    if [ $broken -eq 0 ]; then
        echo -e "${GREEN}✓${NC} All symlinks valid"
    fi
}

check_permissions() {
    echo -e "\n${BLUE}🔍 Checking executable permissions...${NC}"

    # Check that .sh files in scripts/ are executable
    local non_exec=$(find "$DOTFILES_DIR/scripts" -name "*.sh" -type f ! -executable 2>/dev/null)

    if [ -n "$non_exec" ]; then
        while IFS= read -r file; do
            echo -e "${YELLOW}⚠️  Not executable: $file${NC}"
            ((warnings++))
        done <<< "$non_exec"
    else
        echo -e "${GREEN}✓${NC} All scripts have correct permissions"
    fi
}

print_summary() {
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}📊 Validation Summary${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"

    if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
        echo -e "${GREEN}✅ All checks passed!${NC}"
        return 0
    elif [ $errors -eq 0 ]; then
        echo -e "${YELLOW}⚠️  ${warnings} warning(s), but no errors${NC}"
        return 0
    else
        echo -e "${RED}❌ ${errors} error(s), ${warnings} warning(s)${NC}"
        return 1
    fi
}

# Main
echo -e "${BLUE}🔍 Validating dotfiles configuration...${NC}"
echo -e "${BLUE}Directory: $DOTFILES_DIR${NC}\n"

check_shell_scripts
check_toml_files
check_lua_files
check_symlinks
check_permissions
print_summary
