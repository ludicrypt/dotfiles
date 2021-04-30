#!/usr/bin/env bash
set -e

# TODO:
# - programatically install Xcode command line tools and accept license
# - Only install Mac apps with mas if they aren't already installed

################################################################################
# bootstrap.sh
#
# This script sets up a new Mac the way I dig it. YMMV.
#
# Credits for inspiration and/or stolen code:
# - https://github.com/joshukraine/mac-bootstrap/blob/master/bootstrap
# - https://github.com/thoughtbot/laptop/blob/master/mac
################################################################################

fancy_echo() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
  printf "\n\033[32m[BOOTSTRAP]\033[0m $fmt\n" "$@"
}

################################################################################
# Vars
################################################################################

osname=$(uname)

COMMANDLINE_TOOLS="/Library/Developer/CommandLineTools"
DOTFILES_REPO_URL="https://github.com/ludicrypt/dotfiles.git"
DOTFILES_BRANCH="working"
DOTFILES_DIR="${HOME}/dotfiles"

################################################################################
# Make sure we're on a Mac before continuing
################################################################################

if [ "$osname" != "Darwin" ]; then
  fancy_echo "Oops, it looks like you're using a non-UNIX system. This script
only supports Mac. Exiting..."
  exit 1
fi

################################################################################
# Check for presence of command line tools if macOS
# Modified from https://github.com/joshukraine/mac-bootstrap/blob/master/bootstrap
################################################################################

if [ ! -d "$COMMANDLINE_TOOLS" ]; then
  fancy_echo "Apple's command line developer tools must be installed before
running this script. To install them, just run 'xcode-select --install' from
the terminal and then follow the prompts. Once the command line tools have been
installed, you can try running this script again."
  exit 1
fi

################################################################################
# Get elavated
################################################################################

fancy_echo "Get elevated..."
sudo -v

# Keep-alive: update existing `sudo` time stamp until `bootstrap.sh` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

################################################################################
# Install Homebrew
################################################################################

if test ! $(which brew); then
  fancy_echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

fancy_echo "Updating Homebrew..."
brew update

fancy_echo "Installing a bunch of stuff (this'll take a while so probably want to go detail the lambo or something)..."
brew bundle --file=- <<EOF
#tap "adoptopenjdk/openjdk"
#tap "armmbed/formulae"
tap "homebrew/bundle"
tap "homebrew/cask"
tap "homebrew/cask-versions"
tap "homebrew/core"
tap "kryptco/tap"
#brew "apktool"
brew "autoconf"
brew "automake"
brew "openssl@1.1"
brew "azure-cli"
brew "cmake"
#brew "dfu-util"
brew "git"
brew "go"
brew "libtool"
brew "mas"
brew "ninja"
brew "node"
brew "pkg-config"
brew "shellcheck"
brew "vim"
#brew "armmbed/formulae/arm-none-eabi-gcc"
brew "kryptco/tap/kr"
cask "010-editor"
#cask "adobe-acrobat-reader"
#cask "adoptopenjdk15"
#cask "arduino"
cask "autodesk-fusion360"
cask "blender"
cask "docker"
cask "dotnet-sdk"
cask "gitkraken"
cask "google-chrome"
cask "gpg-suite"
cask "iterm2"
cask "lunar"
cask "macs-fan-control"
cask "magicavoxel"
cask "midi-monitor"
#cask "mono-mdk-for-visual-studio"
cask "obs"
cask "parallels"
cask "powershell"
cask "raspberry-pi-imager"
cask "spotify"
cask "tor-browser"
cask "ultimaker-cura"
cask "visual-studio"
cask "visual-studio-code"
cask "vivaldi"
cask "wireshark"
mas "Compressor", id: 424390742
mas "Final Cut Pro", id: 424389933
mas "GoodNotes", id: 1444383602
mas "Hex Fiend", id: 1342896380
mas "iMovie", id: 408981434
mas "Logic Pro", id: 634148309
#mas "Magnet", id: 441258766
mas "MainStage", id: 634159523
#mas "Microsoft Remote Desktop", id: 1295203466
#mas "Monit", id: 1014850245
mas "Moom", id: 419330170
mas "Motion", id: 434290957
mas "Pocket MIDI", id: 1260936756
mas "Synalyze It! Pro", id: 475193367
mas "Voxel Max", id: 1442352186
mas "Xcode", id: 497799835
EOF

fancy_echo "Accepting Xcode license..."
sudo xcodebuild -license accept

fancy_echo "Cleaning up..."
brew cleanup

################################################################################
# Install oh-my-zsh
################################################################################

fancy_echo "Installing oh-my-zsh..."

if [ -d "${HOME}/.oh-my-zsh" ]; then
  rm -rf "${HOME}/.oh-my-zsh"
fi

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

if [ -d /usr/local/share/zsh ]; then
  fancy_echo "Setting permissions for /usr/local/share/zsh..."
  sudo chmod -R 755 /usr/local/share/zsh
fi

if [ -d /usr/local/share/zsh/site-functions ]; then
  fancy_echo "Setting permissions for /usr/local/share/zsh/site-functions..."
  sudo chmod -R 755 /usr/local/share/zsh/site-functions
fi

#source ~/.zshrc

ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# TODO: Add plugins to ~/.zshrc, for example:
#
# plugins=(
#   git
#   zsh-autosuggestions
#   zsh-syntax-highlighting
# )
#
# Added by Krypton
# export GPG_TTY=$(tty)
#
# Override LibreSSL
# export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"

################################################################################
# Clone https://github.com/ludicrypt/dotfiles.git
################################################################################

fancy_echo "Cloning dotfiles repo..."
git clone "$DOTFILES_REPO_URL" -b "$DOTFILES_BRANCH" "$DOTFILES_DIR"

################################################################################
# Set macOS preferences
################################################################################

fancy_echo "Setting macOS preferences..."

# shellcheck source=/dev/null
source "${DOTFILES_DIR}/macos-defaults.sh"

################################################################################
# Peace out
################################################################################

fancy_echo "Done! Now's a good time to restart your computer."
