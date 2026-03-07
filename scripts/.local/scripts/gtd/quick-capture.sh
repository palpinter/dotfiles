#!/bin/bash
# Quick GTD capture to inbox

set -e

GTD_DIR="$HOME/Dokumentumok/1_Munkaterület/Területek/GTD"
INBOX_FILE="$GTD_DIR/beerkezo.md"

# Check if GTD directory exists (Syncthing must be set up)
if [ ! -d "$GTD_DIR" ]; then
    echo "❌ GTD directory not found: $GTD_DIR"
    echo "Please set up Syncthing first"
    exit 1
fi

# Create inbox file if it doesn't exist
if [ ! -f "$INBOX_FILE" ]; then
    cat > "$INBOX_FILE" << 'INBOXEOF'
# GTD Beérkező

Minden itt kerül rögzítésre. Rendszeresen feldolgozni.

## Elemek

INBOXEOF
fi

# Get input
if [ $# -eq 0 ]; then
    echo -n "📝 Quick capture: "
    read ITEM
else
    ITEM="$*"
fi

if [ -z "$ITEM" ]; then
    echo "No item entered"
    exit 1
fi

# Add to inbox with timestamp
echo "- [ ] $ITEM [$(date '+%Y-%m-%d %H:%M')]" >> "$INBOX_FILE"
echo "✅ Hozzáadva a beérkezőhöz: $ITEM"
