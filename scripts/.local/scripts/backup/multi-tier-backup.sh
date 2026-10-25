#!/bin/bash
# Multi-tier backup system
set -uo pipefail

HOSTNAME=$(hostname)
BACKUP_LOG="$HOME/.local/backups/logs/backup-$(date +%Y%m%d_%H%M%S).log"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=10)
RC=0

log() { echo "$*" | tee -a "$BACKUP_LOG"; }

log "🔄 Multi-Tier Backup System"
log "============================"
log "Machine: $HOSTNAME"
log "Date: $(date)"
log ""

# Tier 1: VPS
log "📡 Tier 1: VPS Backup"
if ssh "${SSH_OPTS[@]}" murakami true 2>/dev/null; then
    if rsync -az --delete --mkpath \
        --exclude='.git/' --exclude='node_modules/' --exclude='target/' \
        --exclude='build/' --exclude='dist/' --exclude='.venv/' \
        ~/Kódtár/ \
        "murakami:.local/backups/tier1-continuous/clients/$HOSTNAME/Kódtár/" >> "$BACKUP_LOG" 2>&1; then
        log "✅ VPS backup completed"
    else
        log "❌ VPS backup failed (see log)"; RC=1
    fi
    log "📁 XDG directories are synced via Syncthing (real-time)"
else
    log "❌ VPS not reachable"; RC=1
fi

# Tier 2: NAS
log ""
log "🏠 Tier 2: NAS Backup"
NAS_TARGET="/mnt/nas/backups/clients/$HOSTNAME/Kódtár/"
if [ "$HOSTNAME" = "siddhartha" ]; then
    if mountpoint -q /mnt/nas; then
        rsync -az --delete --mkpath ~/Kódtár/ "$NAS_TARGET" >> "$BACKUP_LOG" 2>&1 \
            && log "✅ Local NAS backup completed" || { log "❌ Local NAS backup failed"; RC=1; }
    else
        log "⚠️  /mnt/nas is not mounted – skipped"
    fi
elif ssh "${SSH_OPTS[@]}" siddhartha "mountpoint -q /mnt/nas" 2>/dev/null; then
    rsync -az --delete --mkpath ~/Kódtár/ "siddhartha:$NAS_TARGET" >> "$BACKUP_LOG" 2>&1 \
        && log "✅ Remote NAS backup completed" || { log "❌ Remote NAS backup failed"; RC=1; }
else
    log "⚠️  NAS not available"
fi

log ""
log "Backup process finished (exit code $RC)"
exit $RC
