#!/bin/bash
# Quick GTD capture to inbox
set -euo pipefail

GTD_DIR="$HOME/Dokumentumok/03_Területek/GTD"
INBOX_FILE="$GTD_DIR/beerkezo.md"

if [ ! -d "$GTD_DIR" ]; then
    echo "❌ GTD directory not found: $GTD_DIR"
    echo "Please set up Syncthing first"
    exit 1
fi

if [ ! -f "$INBOX_FILE" ]; then
    printf '# GTD Beérkező\n\nMinden itt kerül rögzítésre. Rendszeresen feldolgozni.\n\n## Elemek\n\n' > "$INBOX_FILE"
fi

if [ $# -eq 0 ]; then
    read -r -p "📝 Quick capture: " ITEM
else
    ITEM="$*"
fi

[ -n "$ITEM" ] || { echo "No item entered"; exit 1; }

echo "- [ ] $ITEM [$(date '+%Y-%m-%d %H:%M')]" >> "$INBOX_FILE"
echo "✅ Hozzáadva a beérkezőhöz: $ITEM"
