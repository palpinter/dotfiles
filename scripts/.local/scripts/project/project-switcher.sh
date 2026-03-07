#!/bin/bash
# Project switcher with fuzzy finder

set -e

PROJECTS_DIR="$HOME/Kódtár/aktiv"
DOCS_DIR="$HOME/Dokumentumok/1_Munkaterület/Projektek"

# Function to list all projects
list_projects() {
    echo "Git Projects:"
    find "$PROJECTS_DIR" -mindepth 2 -maxdepth 2 -type d 2>/dev/null | sed "s|$PROJECTS_DIR/||" | sort

    if [ -d "$DOCS_DIR" ]; then
        echo "Doc Projects:"
        find "$DOCS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sed "s|$DOCS_DIR/||" | sort
    fi
}

# Use fzf if available, otherwise simple selection
if command -v fzf &> /dev/null; then
    PROJECT=$(list_projects | fzf --prompt="Select project: ")
else
    echo "Available projects:"
    list_projects
    echo -n "Enter project name: "
    read PROJECT
fi

if [ -z "$PROJECT" ]; then
    echo "No project selected"
    exit 1
fi

# Check if it's a Git project or Doc project
if [[ "$PROJECT" == *"/"* ]]; then
    # Git project
    PROJECT_PATH="$PROJECTS_DIR/$PROJECT"
    if [ -d "$PROJECT_PATH" ]; then
        echo "🔄 Switching to Git project: $PROJECT"
        cd "$PROJECT_PATH"
        git status 2>/dev/null || echo "Not a Git repository"
    else
        echo "❌ Project not found: $PROJECT_PATH"
        exit 1
    fi
else
    # Doc project
    PROJECT_PATH="$DOCS_DIR/$PROJECT"
    if [ -d "$PROJECT_PATH" ]; then
        echo "📁 Opening documentation project: $PROJECT"
        cd "$PROJECT_PATH"
        ls -la
    else
        echo "❌ Project not found: $PROJECT_PATH"
        exit 1
    fi
fi
