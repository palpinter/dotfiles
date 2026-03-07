#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Machine-specific profile overrides
if [ -f "$HOME/.config/bash/profile.sh" ]; then
    source "$HOME/.config/bash/profile.sh"
fi
