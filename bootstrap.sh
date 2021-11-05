#!/usr/bin/env bash
set -e

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
export DOTFILES_DIR="${HOME}/dotfiles"

################################################################################
# Make sure we're on a Mac before continuing
################################################################################

if [ "$osname" != "Darwin" ]; then
  fancy_echo "Oops, it looks like you're using a non-UNIX system. This script
only supports Mac. Exiting..."
  exit 1
fi

################################################################################
# Get elavated
################################################################################

fancy_echo "Get elevated..."
sudo -v

# Keep-alive: update existing `sudo` time stamp until `bootstrap.sh` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Prevent sleeping during script execution, as long as the machine is on AC power
caffeinate -s -w $$ &

################################################################################
# Install Rosetta 2 if we're on Apple Silicon
################################################################################

if [[ $(/usr/sbin/sysctl -n machdep.cpu.brand_string) = *"Apple"* ]]; then
  fancy_echo "Apple Silicon detected, installing Rosetta 2..."

  /usr/sbin/softwareupdate --install-rosetta --agree-to-license
fi

################################################################################
# Install updates
################################################################################

fancy_echo "Checking for software updates..."

UPDATE_STATUS=$(softwareupdate --list 2>&1)
if echo "${UPDATE_STATUS}" | grep $Q "No new software available."; then
  fancy_echo "No software updates available."
else
  if echo "${UPDATE_STATUS}" | grep $Q "Action: restart"; then
    fancy_echo "Installing software updates (will automatically restart)..."
    sudo softwareupdate --install --all --restart
    # TODO: If Xcode installed, accept license

    # TODO: Handle graceful closing of terminal (blocked by 'tee' process)

    exit 0
  else
    fancy_echo "Installing software updates..."
    sudo softwareupdate --install --all
    # TODO: If Xcode installed, accept license
  fi
fi

################################################################################
# Install Homebrew
################################################################################

if test ! $(which brew); then
  fancy_echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ ! -f "${HOME}/.zprofile" ]] || ! grep -qF 'eval "$(/opt/homebrew/bin/brew shellenv)"' "${HOME}/.zprofile" ; then
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zprofile"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

fancy_echo "Updating Homebrew..."
brew update

fancy_echo "Installing a bunch of stuff (this'll take a while so probably want to go detail the lambo or something)..."
brew bundle --quiet --file=- <<EOF
#tap "adoptopenjdk/openjdk"
#tap "armmbed/formulae"
tap "homebrew/cask"
tap "homebrew/cask-versions"
tap "homebrew/cask-fonts"
tap "homebrew/core"
tap "homebrew/bundle"
#tap "kryptco/tap"
#brew "apktool"
#brew "armmbed/formulae/arm-none-eabi-gcc"
brew "autoconf"
brew "automake"
brew "azure-cli"
brew "cmake"
#brew "dfu-util"
brew "git"
brew "go"
#brew "kryptco/tap/kr"
brew "libtool"
brew "mackup"
brew "mas"
brew "ninja"
brew "node"
brew "openssl@1.1"
brew "openssl"
brew "pkg-config"
#brew "python"
brew "rust"
brew "shellcheck"
brew "vim"
cask "font-fira-code"
cask "010-editor"
#cask "adobe-acrobat-reader"
#cask "adoptopenjdk15"
cask "airparrot"
#cask "arduino"
cask "autodesk-fusion360"
cask "blender"
cask "docker"
#cask "dotnet-sdk"
cask "gitkraken"
cask "google-chrome"
cask "gpg-suite"
cask "iterm2"
cask "lastpass"
cask "lunar"
cask "magicavoxel"
#cask "microsoft-edge"
cask "midi-monitor"
#cask "mono-mdk-for-visual-studio"
cask "obs"
cask "parallels"
#cask "powershell"
cask "raspberry-pi-imager"
cask "reflector"
cask "spotify"
cask "tg-pro"
cask "tor-browser"
cask "ultimaker-cura"
#cask "visual-studio"
cask "visual-studio-code"
#cask "vivaldi"
cask "wireshark"
mas "Cinebench", id: 1438772273
mas "Compressor", id: 424390742
mas "Dark Reader for Safari", id: 1438243180
mas "Disk Speed Test", id: 425264550
mas "Final Cut Pro", id: 424389933
mas "GarageBand", id: 682658836
mas "Geekbench 5", id: 1478447657
mas "GoodNotes", id: 1444383602
mas "Hex Fiend", id: 1342896380
mas "iMovie", id: 408981434
mas "Logic Pro", id: 634148309
mas "Magnet", id: 441258766
mas "MainStage", id: 634159523
mas "Microsoft Remote Desktop", id: 1295203466
mas "Moom", id: 419330170
mas "Motion", id: 434290957
mas "Playgrounds", id: 1496833156
mas "Pocket MIDI", id: 1260936756
mas "Synalyze It! Pro", id: 475193367
mas "Tonebridge Guitar Effects", id: 1263858588
mas "Voxel Max", id: 1442352186
mas "Xcode", id: 497799835
EOF

#fancy_echo "Accepting Xcode license..."
#sudo xcodebuild -license accept

# Fix ownership set by Parallels
sudo chown -R $(id -un) /usr/local/share/man/man8

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

sed -i '' 's#ZSH_THEME="robbyrussell"#ZSH_THEME="powerlevel10k/powerlevel10k"#g' ~/.zshrc

sed -i '' $'s#plugins=(git)#plugins=(\\\n  git\\\n  zsh-autosuggestions\\\n  zsh-syntax-highlighting\\\n)#g' ~/.zshrc

echo $'\nexport PATH="/usr/local/opt/openssl@1.1/bin:$PATH"' >> ~/.zshrc

################################################################################
# Clone https://github.com/ludicrypt/dotfiles.git
################################################################################

fancy_echo "Cloning dotfiles repo..."

if [ ! -d "${DOTFILES_DIR}" ]; then
  git clone "$DOTFILES_REPO_URL" -b "$DOTFILES_BRANCH" "$DOTFILES_DIR"
fi

################################################################################
# Download and install fonts for Powerlevel10k
################################################################################

fancy_echo "Installing fonts..."

curl -fsSL https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Regular.ttf -o MesloLGS\ NF\ Regular.ttf
curl -fsSL https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold.ttf -o MesloLGS\ NF\ Bold.ttf
curl -fsSL https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Italic.ttf -o MesloLGS\ NF\ Italic.ttf
curl -fsSL https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold%20Italic.ttf -o MesloLGS\ NF\ Bold\ Italic.ttf

mv MesloLGS\ NF\ Regular.ttf ~/Library/Fonts
mv MesloLGS\ NF\ Bold.ttf ~/Library/Fonts
mv MesloLGS\ NF\ Italic.ttf ~/Library/Fonts
mv MesloLGS\ NF\ Bold\ Italic.ttf ~/Library/Fonts

################################################################################
# Mackup restore
################################################################################

#fancy_echo "Running mackup restore..."

#if [ -e "${HOME}/.mackup.cfg" ]; then
#  if [ -L "${HOME}/.mackup.cfg" ]; then
#    unlink "${HOME}/.mackup.cfg"
#  else
#    rm -rf "${HOME}/.mackup.cfg"
#  fi
#fi

#ln -s "${DOTFILES_DIR}/mackup/.mackup.cfg" "${HOME}/.mackup.cfg"

#mackup -f restore

################################################################################
# Set macOS preferences
################################################################################

#fancy_echo "Setting macOS preferences..."

# shellcheck source=/dev/null
#source "${DOTFILES_DIR}/macos/macos-defaults.sh"

################################################################################
# Peace out
################################################################################

fancy_echo "Done! Now would be a good time to restart your computer."
