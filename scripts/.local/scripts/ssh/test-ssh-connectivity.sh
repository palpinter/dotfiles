#!/bin/bash
# Test SSH connectivity to all services

echo "🔗 Testing SSH Connectivity"
echo "============================"

echo ""
echo "📡 Testing VPS connection..."
ssh -o ConnectTimeout=5 palpinter@murakami "echo 'VPS connection: ✅ OK'" || echo "VPS connection: ❌ FAILED"

echo ""
echo "🐙 Testing GitHub connections..."
ssh -T git@github.com 2>&1 | grep -q "successfully authenticated" && echo "GitHub: ✅ OK" || echo "GitHub: ❌ Check keys"

echo ""
echo "🦊 Testing GitLab connections..."
ssh -T git@gitlab.com 2>&1 | grep -q "Welcome to GitLab" && echo "GitLab: ✅ OK" || echo "GitLab: ❌ Check keys"

echo ""
echo "🏠 Testing inter-machine connectivity..."
for host in wittgenstein monteverdi siddhartha gadamer kierkegaard puccini; do
    if [ "$host" != "$(hostname)" ]; then
        if ping -c 1 "$host.local" &> /dev/null; then
            ssh -o ConnectTimeout=3 "palpinter@$host.local" "echo '$host: ✅ OK'" 2>/dev/null || echo "$host: ⚠️  SSH failed"
        else
            echo "$host: ⚠️  Not reachable"
        fi
    fi
done
