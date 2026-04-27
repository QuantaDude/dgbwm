#!/bin/sh

# XDG fallbacks (if not set, assume sensible defaults)
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

feh --bg-scale "$XDG_DATA_HOME/dgbwm/wp1.png"

dwmblocks &
dunst --config "$XDG_CONFIG_HOME/dunst/dunstrc" &

while true; do
        dwm 2>"$HOME/.dwm.log"
done
