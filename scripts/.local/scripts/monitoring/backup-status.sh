#!/bin/bash
# Backup status dashboard

echo "📊 Backup Status Dashboard"
echo "========================="
echo "Machine: $(hostname)"
echo "Date: $(date)"
echo ""

# Local backup directories
echo "💾 Local Backup Storage:"
if [ -d ~/.local/backups ]; then
    du -sh ~/.local/backups/* 2>/dev/null | sed 's/^/  /'
else
    echo "  No local backups found"
fi

echo ""

# VPS backup status
echo "📡 VPS Backup Status:"
if ping -c 1 murakami.yourdomain.com &> /dev/null; then
    ssh palpinter@murakami.yourdomain.com "du -sh ~/.local/backups/tier1-continuous/clients/$(hostname)/* 2>/dev/null" | sed 's/^/  /' || echo "  No VPS backups found"
else
    echo "  ❌ VPS not reachable"
fi

echo ""

# Recent backup logs
echo "📄 Recent Backup Logs:"
find ~/.local/backups/logs -name "backup-*.log" -mtime -7 2>/dev/null | sort -r | head -5 | while read log; do
    echo "  $(basename "$log"): $(stat -c %y "$log" | cut -d' ' -f1)"
done
