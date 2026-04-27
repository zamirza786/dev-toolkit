#!/usr/bin/env bash

set -e

# -------------------------------
# 🎨 Colors
# -------------------------------
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
NC="\033[0m"

log() { echo -e "${BLUE}➜ $1${NC}"; }
success() { echo -e "${GREEN}✔ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✖ $1${NC}"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

ensure_brew() {
  if ! command_exists brew; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    success "Homebrew installed"
  else
    success "Homebrew already installed"
  fi
}

ensure_gh() {
  if ! command_exists gh; then
    log "Installing GitHub CLI..."
    brew install gh
    success "GitHub CLI installed"
  else
    success "GitHub CLI already installed"
  fi
}

setup_ssh() {
  echo ""
  log "Setting up SSH key..."

  read -p "📧 Enter your Git email: " EMAIL
  read -p "🔑 Enter key name (default: id_ed25519): " KEY_NAME
  KEY_NAME=${KEY_NAME:-id_ed25519}

  KEY_PATH="$HOME/.ssh/$KEY_NAME"

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  if [ -f "$KEY_PATH" ]; then
    warn "SSH key already exists at $KEY_PATH"
    read -p "Use existing key? (y/n): " USE_EXISTING
    if [[ "$USE_EXISTING" != "y" ]]; then
      mv "$KEY_PATH" "$KEY_PATH.bak.$(date +%s)"
      mv "$KEY_PATH.pub" "$KEY_PATH.pub.bak.$(date +%s)"
      log "Old key backed up"
      ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH"
    fi
  else
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH"
  fi

  log "Starting ssh-agent..."
  eval "$(ssh-agent -s)" >/dev/null

  log "Adding key to agent..."
  ssh-add --apple-use-keychain "$KEY_PATH"

  log "Configuring SSH config..."
  SSH_CONFIG="$HOME/.ssh/config"

  if [ ! -f "$SSH_CONFIG" ]; then
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
  fi

  if ! grep -q "Host github.com" "$SSH_CONFIG"; then
    cat >> "$SSH_CONFIG" <<EOC

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $KEY_PATH
EOC
    success "SSH config updated"
  else
    warn "SSH config already contains github.com"
  fi

  success "SSH setup complete"
}

check_network() {
  log "Checking GitHub API connectivity..."
  if ! curl -s --connect-timeout 5 https://api.github.com >/dev/null; then
    warn "Network issue detected. GitHub API may be slow/unreachable."
  else
    success "GitHub API reachable"
  fi
}

setup_github() {
  echo ""
  log "Setting up GitHub authentication..."

  if gh auth status >/dev/null 2>&1; then
    success "Already authenticated with GitHub"
    return
  fi

  check_network

  ATTEMPTS=0
  MAX_ATTEMPTS=3

  while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    log "Attempt $(($ATTEMPTS+1)) of $MAX_ATTEMPTS"

    if gh auth login; then
      break
    fi

    warn "Authentication failed"
    ATTEMPTS=$(($ATTEMPTS+1))
    sleep 3
  done

  if ! gh auth status >/dev/null 2>&1; then
    error "GitHub authentication failed"
    echo "Run manually: gh auth login"
    exit 1
  fi

  success "GitHub authentication successful"

  PUB_KEY=$(ls ~/.ssh/*.pub | head -n 1)

  if [ -z "$PUB_KEY" ]; then
    error "No public SSH key found"
    exit 1
  fi

  log "Adding SSH key to GitHub..."
  gh ssh-key add "$PUB_KEY" --title "$(hostname)-$(date +%Y-%m-%d)" || warn "Key may already exist"

  success "SSH key added to GitHub"
}

test_connection() {
  echo ""
  log "Testing GitHub SSH connection..."

  if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    success "SSH connection successful 🎉"
  else
    warn "SSH test message:"
    ssh -T git@github.com
  fi
}

main() {
  echo -e "${GREEN}"
  echo "======================================"
  echo "   🚀 Dev Bootstrap: SSH + GitHub"
  echo "======================================"
  echo -e "${NC}"

  ensure_brew
  ensure_gh
  setup_ssh
  setup_github
  test_connection

  echo ""
  success "All done! Your machine is ready 🔥"
}

main "$@"
