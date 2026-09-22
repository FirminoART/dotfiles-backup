#!/usr/bin/env bash
# dotfiles-backup — CachyOS / Arch restore script
# Repo: https://github.com/FirminoART/dotfiles-backup
# Usage:
#   git clone https://github.com/FirminoART/dotfiles-backup ~/dotfiles-backup
#   cd ~/dotfiles-backup
#   chmod +x install.sh
#   ./install.sh            # full restore (packages + flatpaks + dotfiles)
#   ./install.sh --dotfiles-only
#   ./install.sh --packages-only
#
# Safe to re-run: dotfiles restore backs up existing files to *.bak-<timestamp>.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$REPO_DIR/dotfiles"
WALLPAPERS_DIR="$REPO_DIR/Wallpapers"
PACKAGES_DIR="$REPO_DIR/packages"
BACKUP_SUFFIX=".bak-$(date +%Y%m%d-%H%M%S)"

DOTFILES_ONLY=false
PACKAGES_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --dotfiles-only) DOTFILES_ONLY=true ;;
    --packages-only) PACKAGES_ONLY=true ;;
    -h|--help)
      echo "Usage: $0 [--dotfiles-only] [--packages-only]"
      exit 0
      ;;
  esac
done

log()  { echo -e "\033[1;32m[dotfiles]\033[0m $*"; }
warn() { echo -e "\033[1;33m[warn]\033[0m $*" >&2; }
die()  { echo -e "\033[1;31m[error]\033[0m $*" >&2; exit 1; }

if [[ "$EUID" -eq 0 ]]; then
  die "Do NOT run as root. Run as your normal user (sudo is used internally)."
fi

command -v pacman >/dev/null 2>&1 || die "pacman not found. This script is for Arch/CachyOS only."

# ---------------------------------------------------------------------------
# 1. System update + base tooling (git, base-devel, paru, flatpak)
# ---------------------------------------------------------------------------
install_base() {
  log "Updating system (pacman -Syu)..."
  sudo pacman -Syu --noconfirm

  log "Installing base tooling: git base-devel github-cli flatpak..."
  sudo pacman -S --noconfirm --needed git base-devel github-cli flatpak \
    intel-ucode sof-firmware linux-firmware networkmanager wpa_supplicant iwd \
    bluez bluez-utils blueman pipewire pipewire-alsa pipewire-pulse wireplumber \
    pavucontrol helvum qpwgraph playerctl brightnessctl cpupower upower power-profiles-daemon \
    polkit-gnome uwsm xdg-user-dirs xdg-utils

  if ! command -v paru >/dev/null 2>&1; then
    log "Installing paru (AUR helper)..."
    tmp="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru.git "$tmp/paru"
    (cd "$tmp/paru" && makepkg -si --noconfirm)
    rm -rf "$tmp"
  else
    log "paru already installed."
  fi

  log "Enabling essential services..."
  sudo systemctl enable --now NetworkManager.service 2>/dev/null || true
  sudo systemctl enable --now bluetooth.service 2>/dev/null || true
  sudo systemctl enable --now cups.service 2>/dev/null || true
  sudo systemctl enable --now power-profiles-daemon.service 2>/dev/null || true
  sudo systemctl enable --now ufw.service 2>/dev/null || warn "ufw service not found, skipping"
}

# ---------------------------------------------------------------------------
# 2. Curated essential packages (what the user actually uses)
#    Full explicit list is in packages/pacman-explicit.txt for reference.
# ---------------------------------------------------------------------------
install_official_packages() {
  log "Installing curated official-repo packages..."

  # Hyprland desktop core
  local HYPR=(
    hyprland hyprpaper hyprlock hypridle hyprlauncher
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    waybar mako foot footclient foot-terminfo
    grim slurp swappy wl-clipboard cliphist
    qt6-wayland polkit-kde-agent
    nwg-displays wofi rofi
    intel-media-driver intel-media-sdk vulkan-intel lib32-vulkan-intel
    mesa mesa-utils lib32-mesa opencl-mesa lib32-opencl-mesa
  )

  # Terminal / shell / editors / CLI
  local TERM_EDIT=(
    fish cachyos-fish-config cachyos-zsh-config
    alacritty kitty
    helix micro vim nano nano-syntax-highlighting
    fastfetch neofetch btop cava
    git github-cli ripgrep fd eza bat fzf unzip unrar wget curl rsync
    man-db man-pages bash-completion pkgfile pacman-contrib reflector plocate
    ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-meslo-nerd
    noto-fonts noto-fonts-cjk noto-fonts-emoji
    cantarell-fonts ttf-bitstream-vera ttf-dejavu ttf-liberation ttf-opensans
    awesome-terminal-fonts woff2-font-awesome
    apple-fonts bibata-cursor-theme
  )

  # Browsers / apps / media / gaming (official repos only)
  local APPS=(
    firefox nautilus dolphin kdeconnect
    pipewire-alsa pipewire-pulse wireplumber pavucontrol
    obs-studio audacity vlc vlc-plugins-all
    qbittorrent kolourpaint ktorrent
    steam heroic-games-launcher prismlauncher
    mangohud gamemode lib32-gamemode
    vesktop
    yt-dlp mpv imv
    gnome-disk-utility gparted gphoto2
    scrcpy fastfetch glances duf
    sddm
    cups system-config-printer
    opencode nodejs npm python python-pip
  )

  sudo pacman -S --noconfirm --needed "${HYPR[@]}" "${TERM_EDIT[@]}" "${APPS[@]}" || {
    warn "Some curated packages failed (name drift on CachyOS is normal)."
    warn "Falling back: installing package-by-package, skipping missing ones."
    for pkg in "${HYPR[@]}" "${TERM_EDIT[@]}" "${APPS[@]}"; do
      sudo pacman -S --noconfirm --needed "$pkg" 2>/dev/null || warn "skip: $pkg"
    done
  }
}

install_aur_packages() {
  log "Installing AUR packages (paru)..."
  # These were installed from AUR on the source machine (packages/aur.txt).
  # Only the ones the user actually uses are curated here; full list in aur.txt.
  local AUR_PKGS=(
    brave-origin-beta-bin
    google-chrome
    hydra-launcher-bin
    losslesscut-bin
    ytmdesktop
    rofimoji-git
    minecraft-legacy-launcher
    sklauncher-bin
    osu-lazer
    parsec-bin
    audiorelay
    balena-etcher
    logmein-hamachi
    playit
    vesktop
  )
  if command -v paru >/dev/null 2>&1; then
    for pkg in "${AUR_PKGS[@]}"; do
      paru -S --noconfirm --needed "$pkg" 2>/dev/null || warn "AUR skip/fail: $pkg"
    done
  else
    warn "paru missing, skipping AUR packages."
  fi
}

install_flatpaks() {
  log "Setting up Flatpak + Flathub + user apps..."
  sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak update -y 2>/dev/null || true
  # Apps actually used (from packages/flatpak.txt):
  flatpak install -y flathub com.usebottles.bottles || warn "flatpak fail: Bottles"
  flatpak install -y flathub io.mrarm.mcpelauncher || warn "flatpak fail: Minecraft Bedrock Launcher"
  flatpak install -y flathub org.telegram.desktop || warn "flatpak fail: Telegram"
  flatpak install -y flathub org.vinegarhq.Sober || warn "flatpak fail: Sober (Roblox)"
}

# ---------------------------------------------------------------------------
# 3. Dotfiles restore (with backup)
# ---------------------------------------------------------------------------
restore_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    if cmp -s "$src" "$dest"; then
      log "unchanged: $dest"
      return 0
    fi
    cp -a "$dest" "${dest}${BACKUP_SUFFIX}"
    log "backed up $dest -> ${dest}${BACKUP_SUFFIX}"
  fi
  cp -p "$src" "$dest"
  log "restored: $dest"
}

restore_dotfiles() {
  log "Restoring dotfiles from $DOTFILES_DIR -> \$HOME ..."
  [[ -d "$DOTFILES_DIR" ]] || die "dotfiles dir missing: $DOTFILES_DIR"

  # Walk dotfiles/ preserving relative paths (dotfiles/.config/x -> ~/.config/x)
  while IFS= read -r -d '' src; do
    rel="${src#$DOTFILES_DIR/}"
    # .gitconfig.example is a template, handle separately
    if [[ "$rel" == ".gitconfig.example" ]]; then
      continue
    fi
    restore_file "$src" "$HOME/$rel"
  done < <(find "$DOTFILES_DIR" -type f -print0)

  # Executable bits for helper scripts
  chmod +x "$HOME/.config/hypr/"*.sh "$HOME/.config/hypr/cliphist-rofi" 2>/dev/null || true
  chmod +x "$HOME/.config/mako/"*.sh 2>/dev/null || true

  # Git identity (source machine: FirminoART <firminoarthur35@gmail.com>)
  if [[ ! -f "$HOME/.gitconfig" ]]; then
    if [[ -f "$DOTFILES_DIR/.gitconfig.example" ]]; then
      cp -p "$DOTFILES_DIR/.gitconfig.example" "$HOME/.gitconfig"
      log "restored ~/.gitconfig from example (check user.name/email)."
    fi
  else
    log "kept existing ~/.gitconfig (verify user.name=FirminoART)."
  fi

  # Wallpapers -> ~/Pictures/Wallpapers/angel.png (path hard-coded in
  # hyprpaper.conf + hyprlock.conf)
  mkdir -p "$HOME/Pictures/Wallpapers"
  if [[ -f "$WALLPAPERS_DIR/angel.png" ]]; then
    restore_file "$WALLPAPERS_DIR/angel.png" "$HOME/Pictures/Wallpapers/angel.png"
  fi
  if [[ -f "$WALLPAPERS_DIR/wallpaper.jpeg" && ! -f "$HOME/Pictures/Wallpapers/wallpaper.jpeg" ]]; then
    cp -p "$WALLPAPERS_DIR/wallpaper.jpeg" "$HOME/Pictures/Wallpapers/" || true
  fi
  mkdir -p "$HOME/Pictures/screenshots" # used by print.sh

  # Fish is the default shell on source machine (CachyOS default)
  if [[ "$SHELL" != *"fish"* ]] && command -v fish >/dev/null 2>&1; then
    warn "Current shell is $SHELL. Source machine used fish."
    warn "To switch: chsh -s /usr/bin/fish  (then re-login)"
  fi

  # Font cache + xdg dirs
  fc-cache -f >/dev/null 2>&1 || true
  xdg-user-dirs-update 2>/dev/null || true

  log "Dotfiles restore done. Old files (if any) saved as *$BACKUP_SUFFIX"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  log "Repo: $REPO_DIR"
  if [[ "$DOTFILES_ONLY" == true ]]; then
    restore_dotfiles
    log "Done (dotfiles only). Log out/in to Hyprland to apply."
    return 0
  fi
  if [[ "$PACKAGES_ONLY" == true ]]; then
    install_base
    install_official_packages
    install_aur_packages
    install_flatpaks
    log "Done (packages only)."
    return 0
  fi
  install_base
  install_official_packages
  install_aur_packages
  install_flatpaks
  restore_dotfiles
  echo ""
  log "=================================================="
  log "Restore complete."
  log "- Reboot, log into Hyprland (via SDDM), pick fish if prompted."
  log "- Run: gh auth login   (to restore GitHub CLI auth)"
  log "- Manual logins still needed: Brave/Chrome sync, Vesktop/Discord,"
  log "  Steam, Heroic, Telegram (flatpak), Bottles, Sober."
  log "- Multi-monitor: run nwg-displays (rewrites monitors.conf)."
  log "=================================================="
}

main "$@"
