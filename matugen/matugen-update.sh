#!/usr/bin/env bash
set -euo pipefail

# Helper function to apply template
apply_template() {
    local input="$1"
    local output="$2"
    local post_hook="${3:-}"

    # Ensure output directory exists
    mkdir -p "$(dirname "$output")"

    # Copy template to output
    cp -f "$input" "$output"

    # Run post hook if provided
    if [[ -n "$post_hook" ]]; then
        echo "Running post hook: $post_hook"
        eval "$post_hook"
    fi
}

# Paths to templates and outputs
declare -A templates

templates["~/.config/matugen/templates/waybar.css.template"]="~/.config/mango/waybar/colors.css|pkill -SIGUSR2 waybar"
templates["~/.config/matugen/templates/alacritty.toml.template"]="~/.config/alacritty/colors.toml"
templates["~/.config/matugen/templates/gtk-colors.css.template"]="~/.config/gtk-3.0/colors.css"
templates["~/.config/matugen/templates/gtk-colors.css.template"]="~/.config/gtk-4.0/colors.css"
templates["~/.config/matugen/templates/rofi.rasi.template"]="~/.config/rofi/shared/colors.rasi|pkill -f rofi"
templates["~/.config/matugen/templates/neovim.lua.template"]="~/.config/nvim/lua/plugins/matugen-colors.lua"
templates["~/.config/matugen/templates/dunstrc.template"]="~/.config/dunst/dunstrc.d/colors.conf|dunstctl reload"

# Apply all templates
for input in "${!templates[@]}"; do
    IFS='|' read -r output post_hook <<< "${templates[$input]}"
    # Expand ~
    input="${input/#\~/$HOME}"
    output="${output/#\~/$HOME}"
    apply_template "$input" "$output" "$post_hook"
done

~/.config/matugen/update_gtkcolors.sh
