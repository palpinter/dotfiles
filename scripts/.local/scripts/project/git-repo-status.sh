#!/bin/bash
# Tier 1 check for every repository under ~/Kódtár/aktiv/<account>/<repo>:
#   - origin on GitHub/GitLab  → backed up by the Forgejo pull mirrors on murakami; report unpushed commits / dirty tree
#   - origin on murakami       → it is already the backup
#   - no usable remote         → push it to Forgejo (org "local", push-create) over the "forgejo" SSH alias
# Exit 1 only when a push to Forgejo fails; unpushed/dirty are warnings (the developer's job).
set -uo pipefail

KODTAR="$HOME/Kódtár/aktiv"
LOG="$HOME/.local/backups/logs/git-status-$(date +%Y%m%d).log"
RC=0; total=0; covered=0; unpushed=0; dirty=0; pushed=0; failed=0
log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

while IFS= read -r repo; do
    name=$(basename "$repo"); account=$(basename "$(dirname "$repo")")
    total=$((total + 1))
    if ! git -C "$repo" rev-parse --verify -q HEAD >/dev/null; then echo "⚠️  $account/$name: no commits"; continue; fi
    d=$(git -C "$repo" status --porcelain | wc -l)
    [ "$d" -gt 0 ] && { dirty=$((dirty + 1)); echo "⚠️  $account/$name: $d uncommitted change(s)"; }
    origin=$(git -C "$repo" remote get-url origin 2>/dev/null || true)
    case "$origin" in
        *github.com*|*gitlab.com*|*@github-*|*@gitlab-*)   # also the SSH host aliases from the shared ssh config (client guide 4.2)
            u=$(git -C "$repo" log --branches --not --remotes=origin --oneline 2>/dev/null | wc -l)
            if [ "$u" -gt 0 ]; then unpushed=$((unpushed + 1)); echo "⚠️  $account/$name: $u commit(s) not pushed to origin (not yet in the Forgejo mirror)"; log "UNPUSHED $account/$name $u"
            else covered=$((covered + 1)); fi ;;
        *murakami*|*195.154.222.53*)
            covered=$((covered + 1)) ;;
        *)
            # local-only repository → Forgejo org "local"
            git -C "$repo" remote get-url forgejo >/dev/null 2>&1 || git -C "$repo" remote add forgejo "forgejo:local/$name.git"
            if out=$(GIT_LFS_SKIP_PUSH=1 git -C "$repo" push forgejo --all 2>&1) && GIT_LFS_SKIP_PUSH=1 git -C "$repo" push forgejo --tags >/dev/null 2>&1; then
                pushed=$((pushed + 1)); echo "✅ $account/$name → forgejo:local/$name (no public remote)"; log "PUSHED $account/$name"
            else
                failed=$((failed + 1)); RC=1; echo "❌ $account/$name: push to Forgejo failed: $(echo "$out" | tail -1)"; log "PUSH_FAILED $account/$name"
            fi ;;
    esac
done < <(find "$KODTAR" -mindepth 3 -maxdepth 3 -name .git -type d 2>/dev/null | sed 's|/.git$||' | sort)

echo "📊 $total repos: $covered covered by Forgejo mirrors, $pushed pushed to forgejo:local, $unpushed with unpushed commits, $dirty dirty, $failed failed"
log "SUMMARY total=$total covered=$covered pushed=$pushed unpushed=$unpushed dirty=$dirty failed=$failed"
exit $RC
