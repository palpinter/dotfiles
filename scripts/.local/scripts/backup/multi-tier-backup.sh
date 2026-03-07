#!/bin/bash
# Multi-tier backup system

set -e

HOSTNAME=$(hostname)
BACKUP_LOG="$HOME/.local/backups/logs/backup-$(date +%Y%m%d_%H%M%S).log"

echo "🔄 Multi-Tier Backup System" | tee "$BACKUP_LOG"
echo "============================" | tee -a "$BACKUP_LOG"
echo "Machine: $HOSTNAME" | tee -a "$BACKUP_LOG"
echo "Date: $(date)" | tee -a "$BACKUP_LOG"
echo "" | tee -a "$BACKUP_LOG"

# Tier 1: VPS Backup (continuous)
echo "📡 Tier 1: VPS Backup" | tee -a "$BACKUP_LOG"
if ping -c 1 murakami &> /dev/null; then
    rsync -avz --delete \
        --exclude='.git/' \
        --exclude='node_modules/' \
        --exclude='target/' \
        --exclude='build/' \
        --exclude='dist/' \
        ~/Kódtár/ \
        palpinter@murakami:~/.local/backups/tier1-continuous/clients/$HOSTNAME/Kódtár/ \
        2>&1 | tee -a "$BACKUP_LOG"

    # Note: XDG directories (Dokumentumok, Képek, Videók, Zenék) are now synced via Syncthing (real-time)
    echo "📁 XDG directories synced via Syncthing (real-time)" | tee -a "$BACKUP_LOG"

    echo "✅ VPS backup completed" | tee -a "$BACKUP_LOG"
else
    echo "❌ VPS not reachable" | tee -a "$BACKUP_LOG"
fi

# Tier 2: NAS Backup (if available)
echo "" | tee -a "$BACKUP_LOG"
echo "🏠 Tier 2: NAS Backup" | tee -a "$BACKUP_LOG"
if [ "$HOSTNAME" = "siddhartha" ]; then
    # Local NAS access
    mkdir -p /mnt/nas/backups/clients/$HOSTNAME
    rsync -avz --delete \
        ~/Kódtár/ \
        /mnt/nas/backups/clients/$HOSTNAME/Kódtár/ \
        2>&1 | tee -a "$BACKUP_LOG"
    echo "✅ Local NAS backup completed" | tee -a "$BACKUP_LOG"
elif ping -c 1 siddhartha.local &> /dev/null; then
    # Remote NAS access
    rsync -avz --delete \
        ~/Kódtár/ \
        palpinter@siddhartha.local:~/.local/backups/tier2-nas/clients/$HOSTNAME/Kódtár/ \
        2>&1 | tee -a "$BACKUP_LOG"
    echo "✅ Remote NAS backup completed" | tee -a "$BACKUP_LOG"
else
    echo "⚠️  NAS not available" | tee -a "$BACKUP_LOG"
fi

echo "" | tee -a "$BACKUP_LOG"
echo "✅ Backup process completed" | tee -a "$BACKUP_LOG"
