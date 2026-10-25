#!/bin/bash
# Multi-tier backup system
set -uo pipefail

HOSTNAME=$(hostname)
BACKUP_LOG="$HOME/.local/backups/logs/backup-$(date +%Y%m%d_%H%M%S).log"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=10)
NAS_MOUNT="/srv/nas"            # QNAP 192.168.50.30:/Backup – mounted (systemd automount) on gadamer only
NAS_ROOT="$NAS_MOUNT/backups"
NAS_KEEP=30                     # daily snapshots to keep per machine
XDG_DIRS=(Dokumentumok Képek Könyvek)   # irreplaceable data only; Videók/Zenék live on the NAS shares, not synced
RC=0

log() { echo "$*" | tee -a "$BACKUP_LOG"; }

log "🔄 Multi-Tier Backup System"
log "============================"
log "Machine: $HOSTNAME"
log "Date: $(date)"
log ""

# Tier 1: murakami – Git mirror of every repository under ~/Kódtár/aktiv (bare repos in /var/git/<account>/).
# The working trees are not rsynced any more: everything committed is in the mirror, documents travel via Syncthing.
log "📡 Tier 1: VPS – Git mirror"
if ssh "${SSH_OPTS[@]}" murakami true 2>/dev/null; then
    if "$HOME/.local/scripts/project/git-backup-to-vps.sh" >> "$BACKUP_LOG" 2>&1; then
        log "✅ Git mirror on murakami up to date ($(grep -c 'BACKUP: .* - success' "$BACKUP_LOG") repos)"
    else
        log "❌ Git mirror reported problems (conflicts or errors – see log)"; RC=1
    fi
    log "📁 Documents are synced to murakami by Syncthing (real-time, versioned there)"
else
    log "❌ VPS not reachable"; RC=1
fi

# Tier 2: NAS – only on the machine that mounts the QNAP. The XDG folders there are the
# Syncthing copies of every machine, so one NAS node covers the whole fleet's documents.
log ""
log "🏠 Tier 2: NAS Backup"
if mountpoint -q "$NAS_MOUNT"; then
    TODAY=$(date +%Y-%m-%d)
    SNAP_BASE="$NAS_ROOT/snapshots/$HOSTNAME"
    SNAP="$SNAP_BASE/$TODAY"
    LATEST="$SNAP_BASE/latest"
    mkdir -p "$SNAP"
    LINK=()
    if [ -d "$LATEST" ] && [ "$(readlink -f "$LATEST")" != "$(readlink -f "$SNAP")" ]; then
        LINK=(--link-dest="$(readlink -f "$LATEST")/")     # unchanged files become hard links → daily history, little space
    fi
    # The share squashes every writer to one uid: do not try to preserve owner/group (no -o/-g, no -a)
    nas_sync() {  # nas_sync <dir under $HOME> [rsync excludes...]
        local src="$1"; shift
        [ -d "$HOME/$src" ] || { log "  ⏭  ~/$src not present"; return 0; }
        if rsync -rltD --delete --delete-excluded "${LINK[@]}" "$@" \
            "$HOME/$src/" "$SNAP/$src/" >> "$BACKUP_LOG" 2>&1; then
            log "  ✅ $src"
        else
            log "  ❌ $src failed (see log)"; RC=1
        fi
    }
    nas_sync Kódtár --exclude='node_modules/' --exclude='target/' --exclude='build/' --exclude='dist/' --exclude='.venv/'
    for d in "${XDG_DIRS[@]}"; do
        nas_sync "$d" --exclude='.stfolder/' --exclude='.stversions/' --exclude='.syncthing*'
    done
    ln -sfn "$TODAY" "$LATEST"
    # retention: keep the newest $NAS_KEEP daily snapshots
    find "$SNAP_BASE" -mindepth 1 -maxdepth 1 -type d -name '20??-??-??' | sort | head -n -"$NAS_KEEP" | while read -r old; do
        rm -rf "$old" && log "  🗑  pruned snapshot $(basename "$old")"
    done
    log "✅ NAS snapshot: $SNAP"
else
    log "ℹ️  No NAS mounted on this machine – gadamer snapshots its Syncthing copies of the XDG folders for everyone"
fi

log ""
log "Backup process finished (exit code $RC)"
exit $RC
