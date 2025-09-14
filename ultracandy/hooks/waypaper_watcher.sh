#!/bin/bash
WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"
INTEGRATION_SCRIPT="$HOME/.config/hyprcandy/hooks/waypaper_integration.sh"

wait_for_config() {
    while [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; do
        echo "Waiting for Hyprland to start..."
        sleep 1
    done
    echo "Hyprland started"
    echo "🔍 Waiting for Waypaper config to appear..."
    while [ ! -f "$WAYPAPER_CONFIG" ]; do
        echo "⏳ Waiting for Waypaper config to appear..."
        sleep 1
    done
    echo "✅ Waypaper config found"
}

monitor_waypaper() {
    echo "🔍 Starting Waypaper config monitoring..."
    wait_for_config
    inotifywait -m -e modify "$WAYPAPER_CONFIG" | while read -r path action file; do
        echo "🎯 Waypaper config changed, triggering integration..."
        sleep 0.5
        "$INTEGRATION_SCRIPT"
    done
}

initial_setup() {
    echo "🚀 Initial Waypaper integration setup..."
    wait_for_config
    "$INTEGRATION_SCRIPT"
    monitor_waypaper
}

echo "🎨 Starting Waypaper integration watcher..."
initial_setup