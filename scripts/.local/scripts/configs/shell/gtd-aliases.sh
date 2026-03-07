#!/bin/bash
# GTD aliases and functions

# Core GTD - single letter commands
alias i='~/.local/scripts/gtd/quick-capture.sh'        # Gyors rögzítés
alias ,='~/.local/scripts/gtd/quick-capture.sh'        # Még gyorsabb rögzítés

# Quick functions
beerkezo() {
    local gtd_dir="$HOME/Dokumentumok/1_Munkaterület/Területek/GTD"
    if [ -f "$gtd_dir/beerkezo.md" ]; then
        cat "$gtd_dir/beerkezo.md"
    else
        echo "GTD beérkező nem található. Először állítsd be a Syncthinget."
    fi
}

# Context lists
lc() {
    local gtd_dir="$HOME/Dokumentumok/1_Munkaterület/Területek/GTD"
    if [ -f "$gtd_dir/kontextusok/@szamitogep.md" ]; then
        echo "💻 @számítógép feladatok:"
        grep "^- \[ \]" "$gtd_dir/kontextusok/@szamitogep.md" 2>/dev/null | head -10
    else
        echo "Nincsenek @számítógép feladatok"
    fi
}

# Projekt váltó alias
alias p='~/.local/scripts/project/project-switcher.sh'

# Git státusz minden repóhoz
alias gs='~/.local/scripts/project/git-status-all.sh'

# Biztonsági mentés
alias backup='~/.local/scripts/backup/multi-tier-backup.sh'
alias backup-status='~/.local/scripts/monitoring/backup-status.sh'

# GTD file openers
alias gtd='cd ~/Dokumentumok/1_Munkaterület/Területek/GTD && ls -la'
alias kovetkezo='cat ~/Dokumentumok/1_Munkaterület/Területek/GTD/kovetkezo.md'
alias projektek='cat ~/Dokumentumok/1_Munkaterület/Területek/GTD/projektek.md'
alias varakozas='cat ~/Dokumentumok/1_Munkaterület/Területek/GTD/varakozas.md'

# Context switcher
ctx() {
    local gtd_dir="$HOME/Dokumentumok/1_Munkaterület/Területek/GTD/kontextusok"
    local context="${1:-@szamitogep}"

    if [ -f "$gtd_dir/${context}.md" ]; then
        cat "$gtd_dir/${context}.md"
    else
        echo "Elérhető kontextusok:"
        ls -1 "$gtd_dir" | sed 's/.md$//'
    fi
}

# Quick edit
gtd-edit() {
    local gtd_dir="$HOME/Dokumentumok/1_Munkaterület/Területek/GTD"
    local file="${1:-beerkezo}"

    if [ -f "$gtd_dir/${file}.md" ]; then
        ${EDITOR:-vim} "$gtd_dir/${file}.md"
    else
        echo "Fájl nem található: ${file}.md"
        echo "Próbáld: beerkezo, kovetkezo, projektek, varakozas, talan-majd"
    fi
}

# Start of day
sod() {
    echo "🌅 Nap Kezdete - $(date '+%Y-%m-%d %H:%M')"
    echo "========================================"
    echo ""
    local gtd_dir="$HOME/Dokumentumok/1_Munkaterület/Területek/GTD"
    echo "📧 Beérkező: $([ -f "$gtd_dir/beerkezo.md" ] && grep -c "^- \[ \]" "$gtd_dir/beerkezo.md" 2>/dev/null || echo "0") elem"
    echo ""
    echo "💻 Számítógépes feladatok (top 5):"
    grep "^- \[ \]" "$gtd_dir/kontextusok/@szamitogep.md" 2>/dev/null | head -5
    echo ""
    echo "🎯 Mai célok (következő.md):"
    grep -A 5 "Prioritás: Magas" "$gtd_dir/kovetkezo.md" 2>/dev/null | grep "^- \[ \]" | head -3
    echo ""
    echo "💡 Javaslat:"
    echo "1. Beérkező feldolgozása ha > 5 elem"
    echo "2. Top 3 prioritás kiválasztása"
    echo "3. Kezdés a legfontosabb feladattal"
}

# End of day
eod() {
    echo "🌙 Nap Vége - $(date '+%Y-%m-%d %H:%M')"
    echo "========================================"
    echo ""
    echo "📋 Napi lezárás:"
    echo "1. Beérkező feldolgozása"
    echo "2. Holnapi top 3 kiválasztása"
    echo "3. Nyitott feladatok áttekintése"
    echo ""
    echo "💭 Reflexió:"
    echo "   - Mi működött jól ma?"
    echo "   - Mit csinálnék másképp?"
}

# Dashboard
dash() {
    echo "📊 Fejlesztői Környezet & GTD Állapot"
    echo "====================================="
    echo "🖥️  Gép: $(hostname)"
    echo "📅 Dátum: $(date '+%Y-%m-%d %H:%M')"
    echo ""
    local gtd_dir="$HOME/Dokumentumok/1_Munkaterület/Területek/GTD"
    echo "📧 GTD Beérkező: $([ -f "$gtd_dir/beerkezo.md" ] && grep -c "^- \[ \]" "$gtd_dir/beerkezo.md" 2>/dev/null || echo "0") elem"
    echo "🎯 Aktív projektek: $([ -f "$gtd_dir/projektek.md" ] && grep -c "^### " "$gtd_dir/projektek.md" 2>/dev/null || echo "0")"
    echo "💻 @számítógép: $([ -f "$gtd_dir/kontextusok/@szamitogep.md" ] && grep -c "^- \[ \]" "$gtd_dir/kontextusok/@szamitogep.md" 2>/dev/null || echo "0") feladat"
    echo ""
    echo "📡 Syncthing: $(systemctl --user is-active syncthing 2>/dev/null || echo 'nem fut')"
    echo "🔄 Utolsó backup: $(ls -t ~/.local/backups/logs/backup-*.log 2>/dev/null | head -1 | xargs stat -c %y 2>/dev/null | cut -d' ' -f1 || echo "Soha")"
}
