#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Aliases
alias x="exit"
alias ..="cd .."
alias env="env | sort"
alias ls='ls --color=auto'
alias diff='diff --color=auto'
alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias cls='clear'

# History
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# Prompt
PS1='[\u@\h \W]\$ '

# Source GTD aliases if available
if [ -f "$HOME/.local/scripts/configs/shell/gtd-aliases.sh" ]; then
    source "$HOME/.local/scripts/configs/shell/gtd-aliases.sh"
fi

# Machine-specific overrides
if [ -f "$HOME/.config/bash/local.sh" ]; then
    source "$HOME/.config/bash/local.sh"
fi
