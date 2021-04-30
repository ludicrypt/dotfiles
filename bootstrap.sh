#!/usr/bin/env bash

set -e

# https://github.com/joshukraine/mac-bootstrap/blob/master/bootstrap
bootstrap_echo() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
  printf "\\n[BOOTSTRAP] $fmt\\n" "$@"
}

# Ask for the administrator password upfront
#sudo -v

# Keep-alive: update existing `sudo` time stamp until `bootstrap.sh` has finished
#while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Install Homebrew
if test ! $(which brew); then
  bootstrap_echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

bootstrap_echo "Updating Homebrew..."
brew update

bootstrap_echo "Installing a bunch of stuff..."
brew bundle --file=- <<EOF
tap "homebrew/bundle"
tap "homebrew/cask"
tap "homebrew/cask-versions"
tap "homebrew/core"

brew "openssl@1.1"
brew "git"
brew "mas"

cask "iterm2"
cask "macs-fan-control"
cask "visual-studio-code"
EOF

brew cleanup

bootstrap_echo "Done!"
