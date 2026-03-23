#!/usr/bin/env bash
set -euo pipefail

# ─── Colors & helpers ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

info()    { printf "${CYAN}▸${RESET} %s\n" "$*"; }
success() { printf "${GREEN}✓${RESET} %s\n" "$*"; }
warn()    { printf "${YELLOW}!${RESET} %s\n" "$*"; }
error()   { printf "${RED}✗${RESET} %s\n" "$*"; }

backup_and_link() {
    local src="$1" dest="$2"
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
            printf "  ${DIM}already linked${RESET} %s\n" "$dest"
            return
        fi
        local backup="${dest}.bak.$(date +%s)"
        warn "Backing up existing $dest → $backup"
        mv "$dest" "$backup"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    success "Linked $dest → $src"
}

copy_file() {
    local src="$1" dest="$2"
    if [ -e "$dest" ]; then
        if diff -q "$src" "$dest" &>/dev/null; then
            printf "  ${DIM}already up to date${RESET} %s\n" "$dest"
            return
        fi
        local backup="${dest}.bak.$(date +%s)"
        warn "Backing up existing $dest → $backup"
        mv "$dest" "$backup"
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    success "Copied $src → $dest"
}

# ─── Header ──────────────────────────────────────────────────────────────────
clear
printf "\n"
printf "${BOLD}  ┌─────────────────────────────────┐${RESET}\n"
printf "${BOLD}  │       Dotfiles Installer         │${RESET}\n"
printf "${BOLD}  └─────────────────────────────────┘${RESET}\n"
printf "\n"
printf "  ${DIM}Source: %s${RESET}\n\n" "$DOTFILES_DIR"

# ─── Module selection ────────────────────────────────────────────────────────
printf "${BOLD}  Select what to install:${RESET}\n\n"
printf "  ${CYAN}1)${RESET} Terminal configs  ${DIM}(tmux, starship)${RESET}\n"
printf "  ${CYAN}2)${RESET} Claude Code       ${DIM}(settings, hooks, skills, plugins)${RESET}\n"
printf "  ${CYAN}3)${RESET} Everything\n"
printf "  ${CYAN}q)${RESET} Quit\n"
printf "\n"

read -rp "  Choice [1/2/3/q]: " choice
printf "\n"

install_terminal=false
install_claude=false

case "$choice" in
    1) install_terminal=true ;;
    2) install_claude=true ;;
    3) install_terminal=true; install_claude=true ;;
    q|Q) printf "  Bye!\n"; exit 0 ;;
    *) error "Invalid choice"; exit 1 ;;
esac

# ─── Terminal configs ────────────────────────────────────────────────────────
if $install_terminal; then
    printf "${BOLD}  ── Terminal ──${RESET}\n\n"

    # Install tmux if missing
    if ! command -v tmux &>/dev/null; then
        read -rp "  tmux not found. Install it? [Y/n]: " install_tmux
        if [[ ! "$install_tmux" =~ ^[Nn]$ ]]; then
            if command -v apt-get &>/dev/null; then
                sudo apt-get update -qq && sudo apt-get install -y -qq tmux \
                    && success "Installed tmux" \
                    || error "Failed to install tmux"
            elif command -v brew &>/dev/null; then
                brew install tmux \
                    && success "Installed tmux" \
                    || error "Failed to install tmux"
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y tmux \
                    && success "Installed tmux" \
                    || error "Failed to install tmux"
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm tmux \
                    && success "Installed tmux" \
                    || error "Failed to install tmux"
            else
                warn "No supported package manager found. Install tmux manually."
            fi
        fi
    else
        printf "  ${DIM}tmux already installed${RESET}\n"
    fi

    # Install ble.sh if missing
    if [ ! -d "$HOME/.local/share/blesh" ]; then
        read -rp "  ble.sh not found. Install it? [Y/n]: " install_blesh
        if [[ ! "$install_blesh" =~ ^[Nn]$ ]]; then
            info "Installing ble.sh..."
            git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh \
                && make -C /tmp/ble.sh install PREFIX="$HOME/.local" \
                && success "Installed ble.sh" \
                || error "Failed to install ble.sh (requires make and gawk)"
            rm -rf /tmp/ble.sh
        fi
    else
        printf "  ${DIM}ble.sh already installed${RESET}\n"
    fi

    # Install starship if missing
    if ! command -v starship &>/dev/null; then
        read -rp "  starship not found. Install it? [Y/n]: " install_starship
        if [[ ! "$install_starship" =~ ^[Nn]$ ]]; then
            curl -sS https://starship.rs/install.sh | sh -s -- -y \
                && success "Installed starship" \
                || error "Failed to install starship"
        fi
    else
        printf "  ${DIM}starship already installed${RESET}\n"
    fi

    # tmux config
    backup_and_link "$DOTFILES_DIR/terminal/.tmux.conf" "$HOME/.tmux.conf"
    if command -v tmux &>/dev/null && [ -n "${TMUX:-}" ]; then
        tmux source-file ~/.tmux.conf 2>/dev/null && success "Reloaded tmux config" || true
    fi

    # starship config
    mkdir -p "$HOME/.config"
    backup_and_link "$DOTFILES_DIR/terminal/starship.toml" "$HOME/.config/starship.toml"

    # ble.sh config
    backup_and_link "$DOTFILES_DIR/terminal/.blerc" "$HOME/.blerc"

    # Check if ble.sh is sourced in shell rc
    if ! grep -q 'blesh/ble.sh' "$HOME/.bashrc" 2>/dev/null; then
        read -rp "  Add ble.sh source to .bashrc? [y/N]: " add_blesh
        if [[ "$add_blesh" =~ ^[Yy]$ ]]; then
            printf '\n# ble.sh syntax highlighting\n[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh\n' >> "$HOME/.bashrc"
            success "Added ble.sh source to .bashrc"
        fi
    else
        printf "  ${DIM}ble.sh already sourced in .bashrc${RESET}\n"
    fi

    # Check if starship init is in shell rc
    if ! grep -q 'starship init' "$HOME/.bashrc" 2>/dev/null; then
        read -rp "  Add starship init to .bashrc? [y/N]: " add_starship
        if [[ "$add_starship" =~ ^[Yy]$ ]]; then
            printf '\n# Starship prompt\neval "$(starship init bash)"\n' >> "$HOME/.bashrc"
            success "Added starship init to .bashrc"
        fi
    else
        printf "  ${DIM}starship init already in .bashrc${RESET}\n"
    fi

    printf "\n"
fi

# ─── Claude Code ─────────────────────────────────────────────────────────────
if $install_claude; then
    printf "${BOLD}  ── Claude Code ──${RESET}\n\n"

    CLAUDE_DIR="$HOME/.claude"
    mkdir -p "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/skills"

    # settings.json — merge or install
    SETTINGS_DEST="$CLAUDE_DIR/settings.json"
    if [ -e "$SETTINGS_DEST" ]; then
        printf "  ${YELLOW}Existing settings.json found.${RESET}\n"
        printf "    ${CYAN}a)${RESET} Overwrite  ${DIM}(backup existing first)${RESET}\n"
        printf "    ${CYAN}b)${RESET} Skip\n"
        read -rp "    Choice [a/b]: " settings_choice
        case "$settings_choice" in
            a|A) copy_file "$DOTFILES_DIR/claude/settings.json" "$SETTINGS_DEST" ;;
            *)   printf "  ${DIM}Skipped settings.json${RESET}\n" ;;
        esac
    else
        copy_file "$DOTFILES_DIR/claude/settings.json" "$SETTINGS_DEST"
    fi

    # hooks
    copy_file "$DOTFILES_DIR/claude/hooks/notify.sh" "$CLAUDE_DIR/hooks/notify.sh"
    chmod +x "$CLAUDE_DIR/hooks/notify.sh"

    # skills
    for skill_dir in "$DOTFILES_DIR/claude/skills"/*/; do
        skill_name="$(basename "$skill_dir")"
        dest="$CLAUDE_DIR/skills/$skill_name"

        if [ -d "$dest" ]; then
            printf "  ${DIM}skill already exists:${RESET} %s\n" "$skill_name"
            continue
        fi

        # Symlink the entire skill directory
        ln -sf "$skill_dir" "$dest"
        success "Linked skill: $skill_name"
    done

    # Marketplaces — add anthropics/claude-code if claude CLI is available
    if command -v claude &>/dev/null; then
        printf "\n"
        info "Adding anthropics/claude-code marketplace (for frontend-design plugin)..."
        claude plugin marketplace add anthropics/claude-code 2>/dev/null \
            && success "Added anthropics/claude-code marketplace" \
            || printf "  ${DIM}marketplace may already be added, or claude not authenticated${RESET}\n"
    else
        printf "\n"
        warn "claude CLI not found — after installing Claude Code, run:"
        printf "    ${DIM}claude plugin marketplace add anthropics/claude-code${RESET}\n"
    fi

    # Plugins — remind user
    printf "\n  ${BOLD}Enabled plugins${RESET} ${DIM}(auto-installed by Claude Code):${RESET}\n"
    if command -v jq &>/dev/null && [ -e "$SETTINGS_DEST" ]; then
        jq -r '.enabledPlugins // {} | keys[]' "$SETTINGS_DEST" 2>/dev/null | while read -r plugin; do
            printf "    ${DIM}•${RESET} %s\n" "$plugin"
        done
    else
        printf "    ${DIM}(install jq to list plugins, or check settings.json)${RESET}\n"
    fi

    # Check notify.sh dependency: paplay
    printf "\n"
    if ! command -v paplay &>/dev/null; then
        warn "notify.sh uses paplay (pulseaudio-utils) — not found on this system"
        printf "    ${DIM}Install with: sudo apt install pulseaudio-utils${RESET}\n"
    fi
    if ! command -v notify-send &>/dev/null; then
        warn "notify.sh uses notify-send (libnotify-bin) — not found on this system"
        printf "    ${DIM}Install with: sudo apt install libnotify-bin${RESET}\n"
    fi

    printf "\n"
fi

# ─── Done ────────────────────────────────────────────────────────────────────
printf "${BOLD}${GREEN}  Done!${RESET}\n\n"
