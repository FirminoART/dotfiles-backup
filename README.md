# dotfiles-backup — CachyOS Hyprland restore kit

> **Purpose:** full-fidelity restore of user `f1rmino`'s CachyOS Hyprland desktop
> after a reinstall, with **zero re-configuration pain**.
> This README is written for **an AI agent performing the setup** on a fresh
> CachyOS install. Follow it literally, in order.

- **Repo:** https://github.com/FirminoART/dotfiles-backup
- **Source machine:** CachyOS (Arch-based), kernel `linux-cachyos`, Hyprland 0.56,
  default shell **fish** (`/bin/fish`), display manager **SDDM**, bootloader
  `systemd-boot-manager`, filesystem tools for btrfs/xfs/ext4.
- **Hardware captured:** Intel-only iGPU (`Intel Whiskey Lake-U UHD 610`,
  `/dev/dri/card1`, no NVIDIA GPU present at backup time — `nvidia-smi` was
  **not** installed). Single-monitor laptop panel `eDP-1 1366x768@60.02`
  (see `monitors.conf`). No second monitor. Keyboard layout **br** (ABNT2).
- **Backup date:** 2026-09-22. Target restore: latest CachyOS with Hyprland.

---

## 1. What I (the backup agent) did

1. **Inventoried the live system:**
   - `pacman -Qe` (244 explicit packages) → `packages/pacman-explicit.txt`
     + `packages/pacman-explicit-names-only.txt`
   - `pacman -Qm` (29 AUR packages) → `packages/aur.txt`
   - `flatpak list` (4 user apps + runtimes) → `packages/flatpak.txt`,
     `packages/flatpak-full.txt`
   - Verified shell (`fish`), `gh auth status` (logged in as `FirminoART`),
     and that `~/dots` is actually **someone else's repo**
     (`origin https://github.com/felipefma/dots`) — so I did **not** trust it
     blindly; I copied the **live `~/.config` files** instead.
2. **Copied live configs** (whitelist only, no secrets/caches) into `dotfiles/`:
   - `.config/hypr/` — all 18 files: `hyprland.conf`, `hyprland.lua`,
     `monitors.conf/.lua`, `workspaces.conf/.lua`, `hyprlock.conf`,
     `hypridle.conf`, `hyprpaper.conf`, `hyprlauncher.conf`,
     `hyprtoolkit.conf`, `ac.sh`, `battery.sh`, `clipboard.sh`,
     `cliphist-rofi`, `powermenu.sh`, `powerplan.sh`, `print.sh`
     (excluded `*.save*` editor backups).
   - `.config/waybar/` — `config.jsonc`, `style.css`
   - `.config/foot/foot.ini`, `.config/helix/config.toml`,
     `.config/mako/` (`config` + `brightness.sh` + `volume.sh`),
     `.config/btop/btop.conf`, `.config/cava/config`,
     `.config/fish/` (`config.fish` + `fish_variables`),
     `.config/MangoHud/MangoHud.conf`
   - `.config/*.conf` root files: `electron-flags.conf`, `code-flags.conf`,
     `antigravity-flags.conf`, plus `mimeapps.list`, `user-dirs.dirs`,
     `user-dirs.locale`, `pavucontrol.ini`, `QtProject.conf`
   - Home: `.bashrc`, `.bash_profile`, `.zshrc`,
     `.gitconfig.example` (copy of live `.gitconfig`)
   - `Wallpapers/angel.png` (live, 70 KB, referenced by hyprpaper+hyprlock)
     + `Wallpapers/wallpaper.jpeg` (legacy from old `dots/`, 5.9 MB)
3. **Deliberately excluded** (do NOT restore these; they are secrets/caches
   or machine-specific bulk data):
   - `~/.config/gh/hosts.yml` (GitHub token), `~/.config/opencode/service.json`
     (password), `~/.gnupg/`, `~/.ssh/`, `~/.pki/`, `~/.cache/`,
     `~/.local/share/`, browser profiles (`BraveSoftware/`, `google-chrome/`,
     `mozilla/`), `~/.steam/`, `~/.minecraft/`, `~/.var/` (flatpak data),
     editor backups (`hyprland.conf.save*`, `config.jsonc.save`, `.codex`),
     `kitty/` (empty dir), `gtk-3.0/`, `gtk-4.0/` (empty), `autostart/` (empty).
4. **Wrote `install.sh`** — idempotent restore script (packages + flatpaks +
   dotfiles, with `*.bak-<timestamp>` backups of anything it overwrites).
5. **Wrote this README** with every quirk found so the restore is exact.

---

## 2. Repo layout

```
.
├── README.md                  # this file (AI setup manual)
├── install.sh                 # main restore script
├── Wallpapers/
│   ├── angel.png              # LIVE wallpaper (hyprpaper + hyprlock use this)
│   └── wallpaper.jpeg         # legacy wallpaper from old dots/
├── dotfiles/                  # mirrors $HOME (dotfiles/.config/x -> ~/.config/x)
│   ├── .bashrc .bash_profile .zshrc .gitconfig.example
│   └── .config/
│       ├── hypr/              # Hyprland + helpers (see §5)
│       ├── waybar/            # config.jsonc + style.css
│       ├── foot/foot.ini
│       ├── helix/config.toml
│       ├── mako/{config,brightness.sh,volume.sh}
│       ├── btop/btop.conf
│       ├── cava/config
│       ├── fish/{config.fish,fish_variables}
│       ├── MangoHud/MangoHud.conf
│       └── electron-flags.conf code-flags.conf antigravity-flags.conf
│           mimeapps.list user-dirs.dirs user-dirs.locale ...
└── packages/
    ├── pacman-explicit.txt             # full `pacman -Qe` with versions
    ├── pacman-explicit-names-only.txt  # same, names only
    ├── aur.txt                         # `pacman -Qm` (29 pkgs)
    ├── flatpak.txt                     # 4 user apps
    └── flatpak-full.txt                # apps + runtimes
```

---

## 3. Fresh-machine setup — do exactly this (AI instructions)

### 3.1. Prerequisites

1. Install **CachyOS** normally (choose **Hyprland** desktop if the installer
   offers it, `linux-cachyos` kernel, `systemd-boot`, SDDM).
2. Create the user with the **same username** if possible (`f1rmino`).
   If the username differs, every `~`/`$HOME` reference still works, but fix
   the two hard-coded paths listed in §7.
3. Boot into the fresh system, open a terminal, ensure internet works:
   `ping -c2 archlinux.org`.

### 3.2. Clone and run

```bash
git clone https://github.com/FirminoART/dotfiles-backup ~/dotfiles-backup
cd ~/dotfiles-backup
chmod +x install.sh

# Full restore (recommended): system update + packages + AUR + flatpaks + dotfiles
./install.sh
```

Variants:

```bash
./install.sh --packages-only   # only system update + pacman/AUR/flatpak
./install.sh --dotfiles-only   # only copy configs (fast, safe to re-run)
```

What `install.sh` does, in order:

1. `pacman -Syu`, installs `git base-devel github-cli flatpak` + firmware,
   NetworkManager, PipeWire, Bluetooth, power tooling; installs **paru**
   (AUR helper) if missing; enables `NetworkManager`, `bluetooth`, `cups`,
   `power-profiles-daemon`, `ufw`.
2. Installs the **curated official-repo set** (Hyprland stack, fish, foot,
   kitty, alacritty, helix, browsers, gaming, media — see §4). If a name
   fails (CachyOS renames happen), it retries package-by-package and skips
   missing ones instead of aborting.
3. Installs the **curated AUR set** via `paru` (Brave Beta, Chrome, Hydra,
   LosslessCut, YTMDesktop, rofimoji-git, Minecraft/SK launchers, osu-lazer,
   parsec, audiorelay, etcher, hamachi, playit, vesktop).
4. Adds Flathub and installs the 4 flatpaks: **Bottles, Minecraft Bedrock
   Launcher (`io.mrarm.mcpelauncher`), Telegram, Sober**.
5. Restores `dotfiles/` → `$HOME` (backing up collisions to
   `*.bak-YYYYMMDD-HHMMSS`), restores wallpaper to
   `~/Pictures/Wallpapers/angel.png`, creates `~/Pictures/screenshots`,
   refreshes font cache + `xdg-user-dirs-update`, `chmod +x` on helper scripts.
6. Prints post-reboot manual steps (also listed in §3.4).

> **Never run `./install.sh` as root.** Run as the normal user; it calls
> `sudo` internally.

### 3.2.1. If you are the OpenCode agent (Muse Spark) doing this setup

The user will run the fresh CachyOS setup through you (OpenCode), so:

1. You already have shell access — prefer the `shell` tool over asking the
   user to type commands. Clone the repo and run `./install.sh` yourself,
   then report each phase (base → official pkgs → AUR → flatpaks → dotfiles).
2. Do NOT ask for root password interactively more than once — batch the
   `sudo` steps (`install.sh` does this already).
3. Wallpaper is bundled: `Wallpapers/angel.png` in this repo is the live
   wallpaper. `install.sh` copies it to `~/Pictures/Wallpapers/angel.png`
   (the exact path in `hyprpaper.conf` + `hyprlock.conf`) and restarts
   `hyprpaper` if it is running. Manual fallback (only if the script step
   failed): `mkdir -p ~/Pictures/Wallpapers &&
   cp -p Wallpapers/angel.png ~/Pictures/Wallpapers/angel.png`, then
   `pkill hyprpaper; hyprpaper &` inside the Hyprland session.
4. Single monitor only (`eDP-1 1366x768@60.02`). Do NOT add an `HDMI-A-1`
   block to `hyprpaper.conf` / `monitors.conf` / `workspaces.conf` — an
   earlier revision had one and it was removed on purpose.
5. End your run with the §8 verification checklist output plus the list of
   §3.4 manual logins the user must still do in a browser/GUI.

### 3.3. Reboot and first login

1. `reboot`, at SDDM choose **Hyprland** session.
2. If prompted for shell, pick **fish** (source machine default).
   If you land in bash/zsh: `chsh -s /usr/bin/fish`, then log out/in.
3. Verify: `SUPER+Return` opens `footclient`, `SUPER+D` opens `hyprlauncher`,
   `SUPER+W` opens Brave Beta, top bar (waybar) appears with workspaces left,
   music center, audio/net/battery/clock/powermenu right.

### 3.4. Manual steps the script CANNOT do (do all of these)

- [ ] `gh auth login` (restore GitHub CLI; `~/.gitconfig` already has
      `user.name=FirminoART`, `user.email=firminoarthur35@gmail.com`).
- [ ] Log into **Brave Beta + Chrome + Firefox** sync, **Vesktop/Discord**
      (needs `arrpc` for Rich Presence — autostarted in hyprland.conf; install
      from AUR if missing: `paru -S arrpc`), **Steam, Heroic, Hydra,
      PrismLauncher**, **Telegram** (flatpak), **Bottles**, **Sober**,
      **Spotify/YTMD**, `parsec`, `audiorelay`.
- [ ] External monitor (only if you add one later): run **`nwg-displays`** —
      it rewrites `monitors.conf` + `workspaces.conf` (+ `.lua` twins).
      Current files target single-monitor `eDP-1 1366x768@60.02` (§6).
- [ ] Printer: `system-config-printer` (CUPS already enabled by script).
- [ ] VPN/game tunnels if used: `logmein-hamachi`, `playit` need login.
- [ ] `kdeconnect-indicator` autostarts — pair phone if desired.
- [ ] Check `~/.bak-*` files after restore; delete once satisfied.

---

## 4. Package inventory (what the user actually had)

**Official repos (curated in `install.sh`; full list in
`packages/pacman-explicit.txt`, 244 pkgs):**

| Group | Packages |
|---|---|
| Hyprland core | hyprland, hyprpaper, hyprlock, hypridle, hyprlauncher, xdg-desktop-portal-hyprland, xdg-desktop-portal-gtk, waybar, mako, foot, grim, slurp, swappy, wl-clipboard, cliphist, nwg-displays, wofi, qt6-wayland, polkit-kde-agent, uwsm |
| Shell/term/CLI | fish, cachyos-fish-config, cachyos-zsh-config, alacritty, kitty, helix, micro, vim, btop, cava, fastfetch, neofetch, ripgrep, fd, eza, bat, fzf, reflector, plocate |
| Fonts/theme | apple-fonts, ttf-jetbrains-mono(-nerd), ttf-meslo-nerd, noto-fonts(+cjk+emoji), bibata-cursor-theme, awesome-terminal-fonts, woff2-font-awesome |
| Browsers | firefox, brave-origin-beta-bin (AUR), google-chrome (AUR) |
| Audio/power/net | pipewire(-alsa/-pulse), wireplumber, pavucontrol, helvum, qpwgraph, playerctl, brightnessctl, cpupower, upower, power-profiles-daemon, NetworkManager, bluez(+utils), blueman |
| Apps/media | nautilus, dolphin, kdeconnect, obs-studio, audacity, vlc, qbittorrent/ktorrent, kolourpaint, yt-dlp, mpv, imv, scrcpy, vesktop |
| Gaming | steam, heroic-games-launcher, prismlauncher, hydra-launcher-bin (AUR), minecraft-legacy-launcher (AUR), sklauncher-bin (AUR), osu-lazer (AUR), mangohud, gamemode |
| Dev/sys | base-devel, git, github-cli, paru, opencode, python, nodejs, cups, sddm, ufw, sof-firmware, intel-ucode, intel-media-driver/sdk, vulkan-intel |

**AUR (`packages/aur.txt`, 29 pkgs — curated subset installed by script):**
`brave-origin-beta-bin`, `google-chrome`, `hydra-launcher-bin`,
`losslesscut-bin`, `ytmdesktop`, `rofimoji-git`, `minecraft-legacy-launcher`,
`sklauncher-bin`, `osu-lazer`, `parsec-bin`, `audiorelay`, `balena-etcher`,
`logmein-hamachi`, `playit`, `vesktop` (+ build deps like `electron37`,
`jack`, `clutter*`, `cogl`, `nodejs-mapscii`, `oneko` restored only on demand).

**Flatpak (`packages/flatpak.txt`):**
`com.usebottles.bottles`, `io.mrarm.mcpelauncher`,
`org.telegram.desktop`, `org.vinegarhq.Sober`.

To restore **literally every** explicit package instead of the curated set:

```bash
sudo pacman -S --needed $(cat packages/pacman-explicit-names-only.txt)
paru -S --needed $(awk '{print $1}' packages/aur.txt)
```

(Careful: this pulls the whole CachyOS meta-set including kernels
`linux-cachyos` + `linux-cachyos-lts` and Plymouth — fine on CachyOS, noisy
elsewhere.)

---

## 5. Config map (what each file does)

- `hypr/hyprland.conf` (205 lines, **live config**) — monitors/workspaces
  includes, autostart (`hyprpaper`, `hyprlauncher -d`, `waybar`, `mako`,
  `foot -s`, polkit agent, `wl-paste … cliphist store`, `arrpc`,
  `kdeconnect-indicator`, perf tweaks), cursor (`Bibata-Modern-Ice`),
  vars (`$browser=brave-origin-beta`, `$terminal=footclient`,
  `$fileManager=nautilus`, `$launcher=hyprlauncher`), env
  (`ELECTRON_OZONE_PLATFORM_HINT`, `AQ_DRM_DEVICES`,
  `QT_QPA_PLATFORMTHEME=qt6ct`), input (`kb_layout=br`, flat accel, natural
  scroll), keybinds (`SUPER+Return/Q/E/Space/D/F/W/P/V/M/K/L`, workspaces
  1-10, audio/brightness/player/print keys).
- `hypr/hyprland.lua` — **Lua port** of the above for Hyprland ≥0.55
  (hyprlang is deprecated). Keep **both** files; Hyprland 0.56 reads either
  for now. `monitors.lua`/`workspaces.lua` are required from it.
- `hypr/monitors.conf` + `monitors.lua` — generated by `nwg-displays`:
  `eDP-1,1366x768@60.02,0x0,1.0`. Regenerate on new hardware.
- `hypr/workspaces.conf` + `workspaces.lua` — single monitor: ws1→eDP-1 default.
- `hypr/hyprlock.conf` — lock screen, wallpaper `angel.png`, clock, greeting
  `Hello, Felipe.` (rename if desired), `SF Pro` font.
- `hypr/hypridle.conf` — idle daemon (all listeners commented out by user;
  screen-lock/suspend disabled — enable if wanted).
- `hypr/hyprpaper.conf` — wallpaper `~/Pictures/Wallpapers/angel.png` on
  `eDP-1` (single monitor), `splash=off, ipc=off`.
- `hypr/hyprlauncher.conf` — `background/base 0xFF1b1b1b`, white accents.
- `hypr/hyprtoolkit.conf` — toolkit theme bits.
- `hypr/*.sh` — `ac.sh`/`battery.sh` (performance/powersave via
  `cpupower`+`intel_gpu_frequency`), `powerplan.sh` (dmenu chooser),
  `powermenu.sh` (suspend/shutdown/reboot via hyprlauncher),
  `print.sh` (region → swappy → `~/Pictures/screenshots/`),
  `clipboard.sh` + `cliphist-rofi` (clipboard history pickers).
- `waybar/config.jsonc` + `style.css` — gray `#1b1b1b` blocks, white text,
  `JetBrainsMono Nerd Font`, modules: workspaces+tray | music | pulse/net/
  BAT1/clock/powermenu. Music via `playerctl`, net click opens `nmtui` in foot.
- `foot/foot.ini` — `SF Mono`+JetBrainsMono 8pt, `pad=10x10`,
  `background=1b1b1b` (rest commented = defaults).
- `helix/config.toml` — `adwaita-dark`, bar/block/underline cursors.
- `mako/config` + `brightness.sh` + `volume.sh` — dark `#1b1b1b` notifications,
  synchronous volume/brightness popups wired to media keys.
- `btop/btop.conf`, `cava/config`, `MangoHud/MangoHud.conf` (fps+gpu/cpu/ram
  overlay top-left), `fish/config.fish` (sources
  `/usr/share/cachyos-fish-config/cachyos-config.fish`) + `fish_variables`
  (**pure prompt** theme settings).
- `electron-flags.conf` / `code-flags.conf` / `antigravity-flags.conf` —
  Wayland ozone flags for Electron apps (Chrome/VSCode/etc.).
- `mimeapps.list` (vesktop handles discord links), `user-dirs.dirs`
  (XDG dirs incl. `XDG_PROJECTS_DIR=~/Projects`), `.bashrc`/`.bash_profile`
  (stock CachyOS), `.zshrc` (one line sourcing cachyos config),
  `.gitconfig.example` (FirminoART identity + `gh` credential helper).

---

## 6. Environment specifics the AI must respect

- **No NVIDIA on source hardware.** `hyprland.conf`/`hyprland.lua` contain
  `sudo nvidia-smi -pm 1` and `AQ_DRM_DEVICES=/dev/dri/card2:/dev/dri/card1`
  from the template (old `dots/` targeted NVIDIA). On Intel-only these fail
  harmlessly at startup — **leave them**, or comment out if logs annoy you.
  If the new machine **has** NVIDIA, install `nvidia-open nvidia-settings`
  + `linux-cachyos-nvidia` bits via `chwd`/kernel-manager instead.
- **Hyprland Lua migration:** Hyprland 0.55+ prefers `hyprland.lua`;
  `hyprland.conf` still loads. Keep both in sync; edit the `.conf` (simpler)
  then mirror important changes to `.lua`, or vice versa.
- **Wallpaper path is hard-coded** in `hyprpaper.conf`, `hyprlock.conf`
  (`~/Pictures/Wallpapers/angel.png`). `install.sh` guarantees that path by
  copying the bundled `Wallpapers/angel.png` there and restarting
  `hyprpaper` when possible — no manual download needed.
- **SDDM + fish:** CachyOS default. `install.sh` warns if `$SHELL` isn't fish;
  switch with `chsh -s /usr/bin/fish`.
- **Fonts assumed:** `SF Pro`/`SF Mono` (via `apple-fonts` AUR),
  `JetBrainsMono Nerd Font`. Waybar/foot/hyprlock fall back silently if a
  future CachyOS drops one.
- **`intel_gpu_frequency` / `cpupower` perf tweaks** run passwordless only if
  the user has NOPASSWD sudo rules (CachyOS default for these tools is
  passworded — expect a sudo prompt on first Hyprland login; harmless).

---

## 7. Known quirks / bugs carried over (fix or ignore)

1. `waybar/config.jsonc` → `custom/powermenu.on-click` =
   `/home/felipe/.config/hypr/powermenu.sh` — **wrong username**
   (template leftover from `felipefma/dots`). `$powermenu` in Hyprland is
   correct (`~/.config/hypr/powermenu.sh`), only the Waybar click path is
   stale. Fix: change to `~/.config/hypr/powermenu.sh`.
2. `hyprland.conf` mute bind calls `~/.config/dunst/volume.sh` but the user
   uses **mako** (`~/.config/mako/volume.sh` exists). Fix the path or ignore
   (mute key still toggles; only the popup path is wrong).
3. `hyprlock.conf` greeting says `Hello, Felipe.` (template author). Change
   to your name if you like.
4. `hyprland.conf` exec `rm ~/.cache/cliphist/db` wipes clipboard history
   every login — intentional upstream, keep unless clipboard persistence is
   wanted.
5. Waybar `battery#bat1` uses `bat=BAT1`; some laptops expose `BAT0` — if the
   module shows empty, change to `BAT0`.
6. `~/dots` (old `felipefma/dots` clone with `packages.sh`, `git.sh`) was
   **not** migrated: `git.sh` hard-codes the wrong identity
   (`felipefmavelar@gmail.com`/`FelipeFMA`) and `README` lists packages the
   user no longer has (e.g. `helium-browser-bin`, `microsoft-edge-stable-bin`,
   `visual-studio-code-bin`). Correct identity is in `.gitconfig.example`.
   VS Code is **not** installed on the source machine — install
   `visual-studio-code-bin` (AUR) only if wanted.
7. `kitty/`, `gtk-3.0/`, `gtk-4.0/`, `autostart/` were empty on source —
   intentionally absent here.

---

## 8. Verification checklist (AI: run after restore)

```bash
# configs landed
ls ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.lua \
   ~/.config/waybar/config.jsonc ~/.config/foot/foot.ini \
   ~/Pictures/Wallpapers/angel.png
# Hyprland parses (inside Hyprland session)
hyprctl monitors && hyprctl workspaces
waybar --version; mako --version; foot --version
# audio/net/power
pactl info | head -5; nmcli general status; bluetoothctl show | head -5
brightnessctl info | head -5; cpupower frequency-info | head -8
# shell/fonts
echo $SHELL; fc-list | grep -i -E "JetBrains|SF Pro|apple" | head -5
# apps
which brave-origin-beta google-chrome firefox steam heroic vesktop code hx fish paru flatpak
flatpak list --app
```

Expected: all config paths exist, `hyprctl monitors` shows `eDP-1`
(or new hardware), waybar/mako/foot start without errors, audio sink present,
`BAT1` (or `BAT0`) visible, fonts listed.

---

## 9. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Black screen, no wallpaper | `hyprpaper` path wrong or `angel.png` missing → re-run `./install.sh --dotfiles-only`, check `~/Pictures/Wallpapers/angel.png` |
| No bar / no notifications | `waybar`/`mako` not in PATH or crashed on bad JSONC → run them in terminal, fix `config.jsonc` (JSONC comments allowed, trailing commas not) |
| `SUPER+W` does nothing | `brave-origin-beta` not installed (AUR step failed) → `paru -S brave-origin-beta-bin` or rebind `$browser` |
| Clipboard picker empty | `cliphist` store services not running → `wl-paste --type text --watch cliphist store &` (+ image) |
| Screenshots fail | `grim`/`slurp`/`swappy` missing → `sudo pacman -S grim slurp swappy` |
| Mute key no popup | Known `dunst` path bug (§7.2) → edit bind to `~/.config/mako/volume.sh` |
| Powermenu from bar dead | Known `/home/felipe` path bug (§7.1) → fix Waybar `on-click` |
| Battery widget empty | `BAT1` vs `BAT0` (§7.5) → edit Waybar `bat` field |
| `nvidia-smi` errors at login | Intel-only machine (§6) → harmless, or comment out those `exec-once` lines |
| `paru` build fails | Update mirrors: `sudo pacman -Syu`, `cachyos-rate-mirrors`, retry |
| Flatpak app missing icon/theme | Install `org.kde.Platform//6.10`, Adwaita theme (in `flatpak-full.txt`) |
| Second monitor wrong | Run `nwg-displays`, regenerate `monitors.conf` |

---

## 10. Maintenance (keeping this backup fresh)

```bash
# Refresh package snapshots after installing/removing software:
pacman -Qe | sort > packages/pacman-explicit.txt
pacman -Qm | sort > packages/aur.txt
flatpak list --app --columns=application,origin,version > packages/flatpak.txt
# Re-copy any config you changed:
cp -p ~/.config/hypr/hyprland.conf dotfiles/.config/hypr/
# Commit + push:
git add -A && git commit -m "sync $(date +%F)" && git push
```

Do **not** commit `~/.config/gh/`, `~/.config/opencode/`, `~/.ssh/`,
browser profiles, or anything under `~/.cache/` / `~/.local/share/`.
