#!/bin/bash
# Backup status dashboard
echo "📊 Backup Status Dashboard"
echo "========================="
echo "Machine: $(hostname)"
echo "Date: $(date)"
echo ""

echo "💾 Local Backup Storage:"
du -sh ~/.local/backups/* 2>/dev/null | sed 's/^/  /'
echo ""

echo "📡 VPS Backup Status:"
if ssh -o BatchMode=yes -o ConnectTimeout=10 murakami true 2>/dev/null; then
    ssh murakami "du -sh .local/backups/tier1-continuous/clients/$(hostname)/* 2>/dev/null" | sed 's/^/  /'
else
    echo "  ❌ VPS not reachable"
fi
echo ""

echo "📄 Recent Backup Logs:"
find ~/.local/backups/logs -name "backup-*.log" -mtime -7 2>/dev/null | sort -r | head -5 | while read -r log; do
    echo "  $(basename "$log"): $(tail -1 "$log")"
done
