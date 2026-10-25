#!/bin/bash
# Verify that the right identity and SSH key apply in every account directory
FAIL=0
check() {  # check <dir> <expected-email> <expected-key>
    local d="$HOME/Kódtár/aktiv/$1/.dev-env-test-$$"
    mkdir -p "$d" && git -C "$d" init -q
    local email key
    email=$(git -C "$d" config user.email)
    key=$(git -C "$d" config core.sshCommand)
    rm -rf "$d"
    if [ "$email" = "$2" ] && [[ "$key" == *"id_ed25519_$3 "* ]] && [ -f ~/.ssh/id_ed25519_$3 ]; then
        echo "✅ $1: $email / $3"
    else
        echo "❌ $1: email=$email sshCommand=$key"; FAIL=1
    fi
}
echo "🧪 Testing Git Multi-Account Setup"
check github-pal-pinter          pal@palpinter.com      github_personal
check github-pinter-pal-orgware  pinter.pal@orgware.hu  github_work
check gitlab-pal-pinter          pal@palpinter.com      gitlab_personal
check gitlab-pinter-pal          pinter.pal@gitlab.com  gitlab_work
exit $FAIL
