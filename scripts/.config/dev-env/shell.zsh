# Development Environment Manager – shell integration
S="$HOME/.local/scripts"
typeset -U path
path=("$S" "$S"/{backup,gtd,monitoring,project,security,ssh} $path)

GTD_DIR="$HOME/Dokumentumok/03_Területek/GTD"

# Older GTD helpers (gtd, ctx, eod, gtd-edit, …) if present – the definitions below override overlapping ones
[ -f "$S/configs/shell/gtd-aliases.sh" ] && source "$S/configs/shell/gtd-aliases.sh"
unalias p gs backup backup-status 2>/dev/null   # an alias named p breaks the p function below

# GTD
alias i="$S/gtd/quick-capture.sh"     # Gyors rögzítés
alias ,="$S/gtd/quick-capture.sh"     # Még gyorsabb rögzítés

beerkezo() {
    if [ -f "$GTD_DIR/beerkezo.md" ]; then cat "$GTD_DIR/beerkezo.md"
    else echo "GTD beérkező nem található. Először állítsd be a Syncthinget."; fi
}

_inbox_count() {
    if [ -f "$GTD_DIR/beerkezo.md" ]; then grep -c '^- \[ \]' "$GTD_DIR/beerkezo.md"; else echo 0; fi
}

lc() {
    if [ -f "$GTD_DIR/kontextusok/@szamitogep.md" ]; then
        echo "💻 @számítógép feladatok:"
        grep '^- \[ \]' "$GTD_DIR/kontextusok/@szamitogep.md" | head -10
    else
        echo "Nincsenek @számítógép feladatok"
    fi
}

# Projects – the function does the cd, the script only selects
function p { local dir; dir=$("$S/project/project-switcher.sh" "$@") && cd "$dir" && { git status -sb 2>/dev/null || ls; }; }
alias gs="$S/project/git-status-all.sh"

# Backup
alias backup="$S/backup/multi-tier-backup.sh"
alias backup-status="$S/monitoring/backup-status.sh"

sod() {
    echo "🌅 Nap Kezdete"
    echo "==============="
    echo "📧 Beérkező: $(_inbox_count) elem"
    lc | head -6
    echo ""
    echo "🎯 Mai fókusz:"
    echo "1. Beérkező feldolgozása ha > 5 elem"
    echo "2. Prioritásos feladatok áttekintése"
    echo "3. Legfontosabb projekttel kezdés"
}

dash() {
    local -a logs=(~/.local/backups/logs/backup-*.log(Nom))   # (N): no error when empty, (om): newest first
    local last=${logs[1]}
    echo "📊 Fejlesztői Környezet Állapota"
    echo "================================="
    echo "🖥️  Gép: $(hostname)"
    echo "📅 Dátum: $(date '+%Y-%m-%d %H:%M')"
    echo "📧 GTD Beérkező: $(_inbox_count) elem"
    echo "📡 Syncthing: $(systemctl --user is-active syncthing)"
    if [ -n "$last" ]; then echo "🔄 Utolsó mentés: $(date -r "$last" '+%Y-%m-%d %H:%M')"; else echo "🔄 Utolsó mentés: Soha"; fi
}
