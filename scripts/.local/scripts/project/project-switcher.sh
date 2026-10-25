#!/bin/bash
# Print the path of a project chosen with fzf (used by the `p` shell function)
set -euo pipefail

PROJECTS_DIR="$HOME/Kódtár/aktiv"
DOCS_DIR="$HOME/Dokumentumok/02_Projektek"

list_projects() {
    find "$PROJECTS_DIR" -mindepth 2 -maxdepth 2 -type d 2>/dev/null | sort
    [ -d "$DOCS_DIR" ] && find "$DOCS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort
    return 0
}

if command -v fzf &>/dev/null; then
    PROJECT=$(list_projects | fzf --prompt="Projekt: " --query="${1:-}" --select-1) || exit 1
else
    PROJECT=$(list_projects | grep -i -- "${1:-.}" | head -1)
fi

[ -n "$PROJECT" ] && [ -d "$PROJECT" ] || { echo "Nincs kiválasztott projekt" >&2; exit 1; }
echo "$PROJECT"
