#!/bin/sh

MONITOR="${1:-auto}"
TERM_CMD="${2:-auto}"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

CONFIG_FILE="$XDG_DATA_HOME/dgbwm/.config/dgbwm/dgbwmrc"

# -------- Load terminal from config if needed --------

if [ "$TERM_CMD" = "auto" ]; then
    if [ -f "$CONFIG_FILE" ]; then
        . "$CONFIG_FILE"
        TERM_CMD="${TERMINAL:-st}"
    else
        TERM_CMD="st"
    fi
fi
# -------- Detect monitor --------

if [ "$MONITOR" = "auto" ]; then
    if command -v btop >/dev/null; then
        MONITOR="btop"
    elif command -v htop >/dev/null; then
        MONITOR="htop"
    else
        MONITOR="top"
    fi
fi


STATE_FILE="/tmp/memory_block_view"
[ ! -f "$STATE_FILE" ] && echo 0 > "$STATE_FILE"
view="$(cat "$STATE_FILE")"

case $BLOCK_BUTTON in
    2)
        dunstify --urgency=low "Sys Info" \
"\nLMB: View RAM hogs.\n\nRMB: Open $MONITOR.\n\nMMB: Help.\n\nScroll: Cycle views.\n"
        ;;
    1)
        dunstify --urgency=normal "Memory hogs" \
        "$(ps axch -o cmd:15,%mem --sort=-%mem | head)"
        ;;
    3)
        if ! command -v "$TERM_CMD" >/dev/null 2>&1; then
            dunstify --urgency=critical "Error" "$TERM_CMD not found." 
        elif ! command -v "$MONITOR" >/dev/null 2>&1; then
            dunstify --urgency=critical "Error" "$MONITOR not found." 
        else
            setsid -f "$TERM_CMD" -e "$MONITOR"
        fi
        ;;
    4)
        view=$(( (view + 1) % 4 ))
        echo "$view" > "$STATE_FILE"
        ;;
    5)
        view=$(( (view + 3) % 4 ))
        echo "$view" > "$STATE_FILE"
        ;;
esac

# -------- Views --------

case "$view" in
    0)
        free --mebi | awk 'NR==2 {
            printf "RAM %.2f/%.2fGiB\n", $3/1024, $2/1024
        }'
        ;;
    1)
        free --mebi | awk 'NR==3 {
            printf "Swap %.2f/%.2fGiB\n", $3/1024, $2/1024
        }'
        ;;
    2)
        cpu="$(top -bn1 | awk '/Cpu/ {print 100 - $8}')"
        printf "CPU %.1f%%\n" "$cpu"
        ;;
    3)
        df -h / | awk 'NR==2 {
            printf "Root FS: %.0f%%\n", $5
        }'
        ;;
esac
