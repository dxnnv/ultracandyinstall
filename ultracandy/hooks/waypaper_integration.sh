#!/bin/bash
set -euo pipefail

CONFIG_BG="$HOME/.config/background"
WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"

APPLIER="$HOME/.config/ultracandy/bin/apply-preset.sh"

get_waypaper_background() {
    if [ -f "$WAYPAPER_CONFIG" ]; then
        current_bg=$(grep "^wallpaper = " "$WAYPAPER_CONFIG" | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$current_bg" ]; then
            current_bg=$(echo "$current_bg" | sed "s|^~|$HOME|")
            echo "$current_bg"
            return 0
        fi
    fi
    return 1
}

update_config_background() {
    local bg_path="$1"
    if [ -f "$bg_path" ]; then
        # keep behavior consistent with the installer: write the path to ~/.config/background
        echo "$bg_path" > "$CONFIG_BG"
        echo "🖼️  Set current background to: $bg_path"
        return 0
    else
        echo "⚠️  Background file not found: $bg_path"
        return 1
    fi
}

trigger_matugen() {
    if [ -f "$MATUGEN_CONFIG" ]; then
        echo "🎨 Triggering Matugen fallback..."
        matugen image "$CONFIG_BG" --type scheme-content --contrast 0.7 || true
        echo "✅ Matugen done"
    else
        echo "⚠️  Matugen config not found at: $MATUGEN_CONFIG"
    fi
}

reload_env() {
    hyprctl reload >/dev/null 2>&1 || true
    systemctl --user restart waybar.service || {
      pkill waybar 2>/dev/null || true
      nohup waybar --config "$HOME/.config/waybar/config.jsonc" --style "$HOME/.config/waybar/style.css" >/dev/null 2>&1 &
    }
    pkill -f swaync 2>/dev/null || true
    nohup swaync >/dev/null 2>&1 &
}

execute_color_generation() {
    echo "🚀 Applying preset (or Matugen fallback) for new background..."
    if [[ -x "$APPLIER" ]]; then
        if "$APPLIER"; then
            echo "✅ Preset applied"
        else
            echo "ℹ️  No preset found, using Matugen fallback"
            trigger_matugen
        fi
    else
        echo "ℹ️  Preset applier missing; using Matugen"
        trigger_matugen
    fi
    reload_env
}

main() {
    echo "🎯 Waypaper integration triggered"
    if current_bg=$(get_waypaper_background); then
        echo "📸 Current Waypaper background: $current_bg"
        if update_config_background "$current_bg"; then
            execute_color_generation
        fi
    else
        echo "⚠️  Could not determine current Waypaper background"
    fi
}

main