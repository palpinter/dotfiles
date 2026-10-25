# Dotfiles

Personal dotfiles for a productive Linux development environment with GTD workflow integration.

## Features

- **Shell Configuration**: Modern Zsh setup with Starship prompt, syntax highlighting, and autosuggestions
- **Terminal Multiplexing**: Advanced tmux configuration with vim-style navigation and SSH clipboard support
- **Multi-Profile Git**: Automatic git identity switching based on project directory
- **GTD Integration**: Built-in Getting Things Done workflow with daily dashboards and task tracking
- **Terminal Emulators**: Configurations for Alacritty, WezTerm, and Zellij
- **Modern CLI Tools**: Pre-configured for zoxide, volta, pnpm, and more

## Structure

```
.
├── alacritty/          # Alacritty terminal emulator config
├── backgrounds/        # Wallpapers and backgrounds
├── bash/              # Bash shell configuration (alternative)
├── bin/               # Symlinks to CLI tools
├── fonts/             # Custom fonts
├── gitconfig/         # Git configuration with multi-profile support
├── maven/             # Maven build tool settings
├── scripts/           # Custom scripts organized by category
│   ├── backup/        # Backup automation
│   ├── books/         # Book management
│   ├── gtd/           # GTD workflow scripts
│   ├── migration/     # System migration helpers
│   ├── monitoring/    # System monitoring
│   ├── project/       # Project management
│   ├── security/      # Security tools
│   └── ssh/           # SSH utilities
├── starship/          # Starship prompt configuration
├── tmux/              # Tmux terminal multiplexer
├── wezterm/           # WezTerm terminal emulator
├── zellij/            # Zellij terminal workspace
└── zsh/               # Zsh shell configuration (primary)
```

## Installation

### Prerequisites

Install required dependencies:

```bash
# Arch Linux
sudo pacman -S zsh tmux git starship zoxide

# Zsh plugins (clone manually)
mkdir -p ~/.zsh/plugins
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-history-substring-search ~/.zsh/plugins/zsh-history-substring-search

# Tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### Deploy Dotfiles

Using GNU Stow:

```bash
cd ~/Kódtár/aktiv/github-pal-pinter/dotfiles

# Remove existing files/symlinks first
rm -f ~/.zshrc ~/.zshenv ~/.zprofile
rm -f ~/.tmux.conf
rm -f ~/.gitconfig
# ... etc

# Install with stow (specify -t ~ as target)
stow -t ~ zsh
stow -t ~ tmux
stow -t ~ gitconfig
stow -t ~ starship
stow -t ~ bash
stow -t ~ alacritty
stow -t ~ wezterm
stow -t ~ zellij
```

After deployment:

```bash
# Change shell to zsh
chsh -s $(which zsh)

# Install tmux plugins
tmux source ~/.tmux.conf
# Press prefix + I (Ctrl+Space + Shift+I) to install plugins

# Restart terminal
```

## Configuration Highlights

### Zsh

- **Plugins**: Syntax highlighting, autosuggestions, history substring search
- **Prompt**: Starship with git status and language detection
- **Tools**: Zoxide (smart cd), Volta (Node.js manager), pnpm
- **Aliases**: Productivity shortcuts (see `zsh/.zshrc:16-25`)

### Tmux

- **Prefix**: `Ctrl+Space` (instead of Ctrl+B)
- **Navigation**: Vim-style hjkl pane selection
- **Clipboard**: OSC 52 support for SSH + local clipboard integration
- **Plugins**: TPM, tmux-resurrect, Nord theme
- **Splits**: `|` for horizontal, `-` for vertical

### Git

Multi-profile configuration automatically switches identity based on directory:

- `~/Kódtár/aktiv/github-pal-pinter/` → github-pal-pinter profile
- `~/Kódtár/aktiv/github-pinter-pal-orgware/` → github-pinter-pal-orgware profile
- `~/Kódtár/aktiv/gitlab-pal-pinter/` → gitlab-pal-pinter profile

Configure individual profiles in `~/.config/git/`.

### GTD Workflow

Custom shell functions for productivity:

```bash
sod     # "Start of Day" - Shows inbox count and top tasks
dash    # System status dashboard with GTD metrics
```

## Key Bindings

### Tmux

| Key | Action |
|-----|--------|
| `Ctrl+Space` | Prefix |
| `Prefix + r` | Reload config |
| `Prefix + h/j/k/l` | Navigate panes (vim-style) |
| `Prefix + \|` | Split horizontal |
| `Prefix + -` | Split vertical |
| `Prefix + m` | Copy mode |
| `Shift + ←/→` | Switch windows |
| `Alt + ←/→/↑/↓` | Navigate panes (no prefix) |

### Zsh

| Key | Action |
|-----|--------|
| `↑/↓` | History substring search |
| `Tab` | Menu-style completion |

## Environment

- **OS**: Arch Linux
- **Shell**: Zsh
- **Terminal**: Alacritty / WezTerm
- **Multiplexer**: Tmux
- **Editor**: Neovim (configured via `$EDITOR`)

## Customization

1. **Add personal scripts**: Place in `scripts/.local/scripts/<category>/`
2. **Extend zsh**: Add custom aliases/functions in `zsh/.zshrc`
3. **Git profiles**: Create new profiles in `~/.config/git/` and reference in `.gitconfig`
4. **Tmux plugins**: Add to `tmux/.tmux.conf` and install with `Prefix + I`

## License

Personal configuration - use at your own risk. Feel free to fork and adapt.

## Author

Pál Pintér - [pal@palpinter.com](mailto:pal@palpinter.com)
