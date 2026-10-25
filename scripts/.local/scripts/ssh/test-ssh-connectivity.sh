#!/bin/bash
# Test SSH connectivity to VPS, Git platforms and the other machines
O=(-o BatchMode=yes -o ConnectTimeout=8)

echo "🔗 Testing SSH Connectivity"
echo "============================"

echo ""
echo "📡 VPS:"
ssh "${O[@]}" murakami true 2>/dev/null && echo "  murakami: ✅ OK" || echo "  murakami: ❌ FAILED"

echo ""
echo "🐙🦊 Git platforms:"
for h in github-pal-pinter github-pinter-pal-orgware gitlab-pal-pinter gitlab-pinter-pal; do
    out=$(ssh "${O[@]}" -T "$h" 2>&1)
    if echo "$out" | grep -qE "successfully authenticated|Welcome to GitLab"; then
        echo "  $h: ✅ $(echo "$out" | grep -oE 'Hi [^!]+|@[^!]+' | head -1)"
    else
        echo "  $h: ❌ $(echo "$out" | tail -1)"
    fi
done

echo ""
echo "🏠 Inter-machine (Tailscale):"
for host in wittgenstein monteverdi siddhartha gadamer russel claude-pc dev-server; do
    [ "$host" = "$(hostname)" ] && continue
    if ! getent hosts "$host" &>/dev/null; then
        echo "  $host: ⚠️  not in tailnet"
    elif ssh "${O[@]}" "$host" true 2>/dev/null; then
        echo "  $host: ✅ OK"
    else
        echo "  $host: ⚠️  SSH failed (key not authorised or sshd down)"
    fi
done
