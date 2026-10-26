#!/bin/bash
# Multi-tier backup system
set -uo pipefail

HOSTNAME=$(hostname)
BACKUP_LOG="$HOME/.local/backups/logs/backup-$(date +%Y%m%d_%H%M%S).log"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=10)
NAS_MOUNT="/srv/nas"            # QNAP 192.168.50.30:/Backup – mounted (systemd automount) on gadamer only
NAS_ROOT="$NAS_MOUNT/backups"
BORG_PATTERNS="$HOME/.config/borg/patterns.lst"   # what tier 2 backs up (roots + excludes), see the client guide 8.2
BORG_PASSFILE="$HOME/.config/borg/passphrase"     # also in the vault: backup/borg-gadamer-nas.txt
RC=0

log() { echo "$*" | tee -a "$BACKUP_LOG"; }

log "🔄 Multi-Tier Backup System"
log "============================"
log "Machine: $HOSTNAME"
log "Date: $(date)"
log ""

# Tier 1: Git. Everything pushed to GitHub/GitLab is mirrored into Forgejo on murakami (pull mirrors, 8 h);
# repos without a public remote are pushed to Forgejo (org "local"). This step only checks and pushes those.
log "📡 Tier 1: Git (Forgejo mirrors on murakami)"
if ssh "${SSH_OPTS[@]}" murakami true 2>/dev/null; then
    if "$HOME/.local/scripts/project/git-repo-status.sh" 2>&1 | tee -a "$BACKUP_LOG" | grep -E '^(⚠️|❌|📊)' ; then :; fi
    if [ "${PIPESTATUS[0]}" -eq 0 ]; then log "✅ Git tier OK"; else log "❌ Git tier: a push to Forgejo failed (see log)"; RC=1; fi
    log "📁 Documents are synced to murakami by Syncthing (real-time, versioned there)"
else
    log "❌ VPS not reachable"; RC=1
fi

# Tier 2: NAS – a borg repository, only on the machine that mounts the QNAP (gadamer). The XDG folders there are
# the Syncthing copies of every machine, so one NAS node covers the whole fleet's documents. Kódtár is not included:
# every repo lives on GitHub/GitLab and in the Forgejo mirrors (tier 1).
log ""
log "🏠 Tier 2: NAS (borg → $NAS_ROOT)"
if mountpoint -q "$NAS_MOUNT"; then
    export BORG_REPO="$NAS_ROOT" BORG_PASSCOMMAND="cat $BORG_PASSFILE"
    if borg create --stats --compression zstd,3 --exclude-caches --one-file-system \
         --patterns-from "$BORG_PATTERNS" "::{hostname}-{now:%Y-%m-%d_%H%M}" >> "$BACKUP_LOG" 2>&1; then
        log "  ✅ borg create: $(grep -E '^This archive:' "$BACKUP_LOG" | tail -1 | sed 's/  */ /g')"
    else
        log "  ❌ borg create failed (see log)"; RC=1
    fi
    if borg prune --glob-archives "$HOSTNAME-*" --keep-daily 7 --keep-weekly 4 --keep-monthly 6 >> "$BACKUP_LOG" 2>&1 \
       && borg compact >> "$BACKUP_LOG" 2>&1; then
        log "  ✅ prune 7d/4w/6m + compact"
    else
        log "  ❌ prune/compact failed (see log)"; RC=1
    fi
    if [ "$(date +%d)" = "01" ]; then   # monthly integrity check of the whole repository
        if borg check >> "$BACKUP_LOG" 2>&1; then log "  ✅ monthly borg check"; else log "  ❌ borg check FAILED"; RC=1; fi
    fi
    log "✅ NAS archives: $(borg list --short --last 3 2>/dev/null | tr '\n' ' ')"
else
    log "ℹ️  No NAS mounted on this machine – gadamer backs up its Syncthing copies of the XDG folders for everyone"
fi

log ""
log "Backup process finished (exit code $RC)"
exit $RC
