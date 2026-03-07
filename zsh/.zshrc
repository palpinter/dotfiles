autoload -Uz compinit promptinit
compinit
promptinit

# Completions
zstyle ':completion:*' menu select
zstyle ':completion::complete:*' gain-privileges 1

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

# Aliases
alias x="exit"
alias ..="cd .."
alias env="env | sort"
alias ls='ls --color=auto'
alias diff='diff --color=auto'
alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias tmx='tmuxinator'
alias cls='clear'

export MANPAGER="less -R --use-color -Dd+r -Du+b"

# Plugins
source $HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOME/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

typeset -g -A key

key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Backspace]="${terminfo[kbs]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[PageUp]="${terminfo[kpp]}"
key[PageDown]="${terminfo[knp]}"
key[Shift-Tab]="${terminfo[kcbt]}"

[[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"       beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"        end-of-line
[[ -n "${key[Insert]}"    ]] && bindkey -- "${key[Insert]}"     overwrite-mode
[[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}"  backward-delete-char
[[ -n "${key[Delete]}"    ]] && bindkey -- "${key[Delete]}"     delete-char
[[ -n "${key[Up]}"        ]] && bindkey -- "${key[Up]}"         history-substring-search-up
[[ -n "${key[Down]}"      ]] && bindkey -- "${key[Down]}"       history-substring-search-down
[[ -n "${key[Left]}"      ]] && bindkey -- "${key[Left]}"       backward-char
[[ -n "${key[Right]}"     ]] && bindkey -- "${key[Right]}"      forward-char
[[ -n "${key[PageUp]}"    ]] && bindkey -- "${key[PageUp]}"     beginning-of-buffer-or-history
[[ -n "${key[PageDown]}"  ]] && bindkey -- "${key[PageDown]}"   end-of-buffer-or-history
[[ -n "${key[Shift-Tab]}" ]] && bindkey -- "${key[Shift-Tab]}"  reverse-menu-complete

if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
	autoload -Uz add-zle-hook-widget
	function zle_application_mode_start { echoti smkx }
	function zle_application_mode_stop { echoti rmkx }
	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

export EDITOR="nvim"

if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
        source /etc/profile.d/vte.sh
fi

# Source Starship prompt
eval "$(starship init zsh)"

export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"

eval "$(zoxide init zsh)"


# pnpm
export PNPM_HOME="/home/palpinter/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Development Environment Manager
# ===============================

# Add scripts to PATH
export PATH="$HOME/.local/scripts:$PATH"

# Load GTD aliases
if [ -f "$HOME/.local/scripts/configs/shell/gtd-aliases.sh" ]; then
    source "$HOME/.local/scripts/configs/shell/gtd-aliases.sh"
fi

# Quick functions
sod() {
    echo "🌅 Nap Kezdete"
    echo "==============="
    echo "📧 Beérkező: $([ -f "$HOME/Dokumentumok/1_Munkaterület/Területek/GTD/beerkezo.md" ] && grep -c "^- \[ \]" "$HOME/Dokumentumok/1_Munkaterület/Területek/GTD/beerkezo.md" 2>/dev/null || echo "0") elem"
    echo "💻 Számítógépes feladatok:"
    lc | head -5
    echo ""
    echo "🎯 Mai fókusz:"
    echo "1. Beérkező feldolgozása ha > 5 elem"
    echo "2. Prioritásos feladatok áttekintése"
    echo "3. Legfontosabb projekttel kezdés"
}

# Status dashboard
dash() {
    echo "📊 Fejlesztői Környezet Állapota"
    echo "================================="
    echo "🖥️  Gép: $(hostname)"
    echo "📅 Dátum: $(date '+%Y-%m-%d %H:%M')"
    echo "📧 GTD Beérkező: $([ -f "$HOME/Dokumentumok/1_Munkaterület/Területek/GTD/beerkezo.md" ] && grep -c "^- \[ \]" "$HOME/Dokumentumok/1_Munkaterület/Területek/GTD/beerkezo.md" 2>/dev/null || echo "0") elem"
    echo "📡 Syncthing: $(systemctl --user is-active syncthing)"
    echo "🔄 Utolsó mentés: $(ls -t ~/.local/backups/logs/backup-*.log 2>/dev/null | head -1 | xargs stat -c %y 2>/dev/null | cut -d' ' -f1 || echo "Soha")"
}
