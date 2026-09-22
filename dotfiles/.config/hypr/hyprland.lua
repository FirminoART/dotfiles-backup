-- Ported from hyprland.conf (hyprlang) to Lua.
-- Hyprland 0.55+ deprecates hyprlang in favor of Lua (hyprland.lua).
-- Verified 2026-09-22: Hyprland 0.55/0.56 uses Lua, old .conf works for 1-2 releases then dropped.
-- Other hypr* tools (hyprlock, hypridle, hyprpaper, hyprlauncher) still use hyprlang .conf.
-- Source: ~/.config/hypr/hyprland.conf (live, 205 lines). Old .conf kept as fallback.

------------------
---- MONITORS ----
------------------
-- nwg-displays writes monitors.conf (hyprlang) and monitors.lua.
-- Load the Lua modules so monitor/workspace layout stays in sync.
require("monitors")
require("workspaces")

---------------------
---- MY PROGRAMS ----
---------------------
local browser     = "brave-origin-beta"
local terminal    = "footclient"
local fileManager = "nautilus"
local launcher    = "hyprlauncher"
local powermenu   = os.getenv("HOME") .. "/.config/hypr/powermenu.sh"
local emoji       = "rofimoji --selector hyprlauncher --action copy"
local mainMod     = "SUPER"

-------------------
---- AUTOSTART ----
-------------------
-- exec-once = ... becomes hl.exec_cmd inside hyprland.start
hl.on("hyprland.start", function()
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd("hyprlauncher -d")
  hl.exec_cmd("waybar")
  hl.exec_cmd("mako")
  hl.exec_cmd("foot -s")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("rm ~/.cache/cliphist/db")
  hl.exec_cmd("arrpc")
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("systemd-run --user --service-type=oneshot --property=Wants=graphical-session.target true")
  hl.exec_cmd("kdeconnect-indicator")

  -- performance tweaks
  hl.exec_cmd("sudo intel_gpu_frequency -m")
  hl.exec_cmd("sudo cpupower frequency-set -g performance")
  hl.exec_cmd("sudo nvidia-smi -pm 1")

  -- cursor theme
  hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice")
  hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 12")
  hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 12")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "23")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("EDITOR", "helix")
-- Nvidia/electron stuff
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("AQ_DRM_DEVICES", "/dev/dri/card2:/dev/dri/card1")
-- QT theme (also applies to qt5ct)
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-----------------------
---- LOOK AND FEEL ----
-------------------------------
hl.config({
  xwayland = {
    force_zero_scaling = true,
  },
})

hl.config({
  input = {
    kb_layout   = "br",
    kb_variant  = "",
    kb_model    = "",
    kb_options  = "",
    kb_rules    = "",

    follow_mouse  = 1,
    accel_profile = "flat",

    touchpad = {
      natural_scroll       = true,
      disable_while_typing = false,
      scroll_factor        = 0.2,
    },

    sensitivity = 0, -- -1.0 to 1.0; 0 is default
  },
})

hl.device({
  name       = "at-translated-set-2-keyboard",
  kb_layout  = "br",
  kb_variant = "",
})

hl.config({
  general = {
    gaps_in           = 4,
    gaps_out          = 10,
    border_size       = 1,
    col = {
      active_border   = "rgb(ffffff)",
      inactive_border = "rgb(1b1b1b)",
    },
    layout = "dwindle",
    -- https://wiki.hypr.land/configuring/extra/tearing/
    allow_tearing = true,
  },
})

hl.config({
  decoration = {
    rounding = 0,
    blur = {
      enabled = false,
      size    = 8,
      passes  = 3,
    },
    shadow = {
      enabled = true,
      range   = 7,
    },
  },
})

-- Animations (old: bezier = myBezier, ... + animation = ... lines)
hl.config({
  animations = {
    enabled = true,
  },
})
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.animation({ leaf = "windows",     enabled = true, speed = 2, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 2, bezier = "default" })

hl.config({
  misc = {
    force_default_wallpaper = 1,
    disable_hyprland_logo   = true,
    vrr                     = 0,
  },
})

---------------------
---- KEYBINDINGS ----
---------------------
-- Main binds
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + Space",  hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + W",      hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + P",      hl.dsp.exec_cmd(powermenu))
hl.bind(mainMod .. " + V",      hl.dsp.exec_cmd("cliphist list | hyprlauncher --dmenu | cliphist decode | wl-copy"))
hl.bind(mainMod .. " + M",      hl.dsp.exec_cmd(emoji))
hl.bind(mainMod .. " + K",      hl.dsp.window.kill()) -- was: exec hyprctl kill
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))
hl.bind("XF86Presentation",     hl.dsp.exec_cmd(os.getenv("HOME") .. "/Documents/Github/nekro-sense/tools/nekroctl_gui.py"))

-- Switch focused window
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Workspaces: focus with MOD + [0-9], move window with MOD + SHIFT + [0-9]
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Drag/resize with mouse (was bindm)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Audio keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5% && ~/.config/mako/volume.sh"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5% && ~/.config/mako/volume.sh"))
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle && ~/.config/dunst/volume.sh"))
hl.bind("Pause",                hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))

-- Brightness keys
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+ && ~/.config/mako/brightness.sh"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%- && ~/.config/mako/brightness.sh"))

-- Browser key
hl.bind("XF86Search", hl.dsp.exec_cmd(browser))

-- Player keys
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

-- Print keys
hl.bind("Print",           hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/print.sh"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/print.sh"))
