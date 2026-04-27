#!/bin/sh

# -------- Config --------

CONFIG_FILE="$HOME/.local/share/dgbwm/.config/dgbwm/dgbwmrc"

# Default fallback
WEATHER_MODE="ip"

# Load config if exists
[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"

# Decide URL
case "$WEATHER_MODE" in
    ip)
        URL="https://wttr.in"
        ;;
    location:*)
        loc="${WEATHER_MODE#location:}"
        URL="https://wttr.in/$loc"
        ;;
    *)
        URL="https://wttr.in"
        ;;
esac

# -------- State --------

STATE_FILE="/tmp/weather_block_view"
[ ! -f "$STATE_FILE" ] && echo 0 > "$STATE_FILE"
view="$(cat "$STATE_FILE")"

CACHE_FILE="/tmp/weather_cache"
CACHE_TIME=300

now=$(date +%s)

if [ -f "$CACHE_FILE" ]; then
    last=$(stat -c %Y "$CACHE_FILE" 2>/dev/null)
else
    last=0
fi

# -------- Fetch + Cache --------

if [ $((now - last)) -ge "$CACHE_TIME" ]; then
    tmp="$(mktemp)"
    if curl -s --max-time 3 "$URL?format=%c|%t|%f|%h|%w|%C" > "$tmp"; then
        mv "$tmp" "$CACHE_FILE"
    else
        rm -f "$tmp"
    fi
fi

# -------- Click Actions --------

case $BLOCK_BUTTON in
    1)
        dunstify --urgency=low "Weather" \
        "$(curl -s --max-time 5 "$URL?0&Q" | dwm_conv_ansi_to_pango.sh)"
        ;;
    2)
        dunstify --urgency=low "Weather Info" \
"\nLMB: Show current weather.\n\nRMB: Show forecast.\n\nMMB: Show this help.\n\nScroll: Cycle views.\n"
        ;;
    3)
        dunstify --urgency=normal "Weather" \
        "$(curl -s --max-time 5 "$URL?Q&F" | dwm_conv_ansi_to_pango.sh)"
        ;;
    4)
        view=$(( (view + 1) % 3 ))
        echo "$view" > "$STATE_FILE"
        ;;
    5)
        view=$(( (view + 2) % 3 ))
        echo "$view" > "$STATE_FILE"
        ;;
esac

# -------- Parse Cached Data --------

weather="$(cat "$CACHE_FILE" 2>/dev/null)"

icon="$(printf "%s" "$weather" | cut -d'|' -f1)"
temp="$(printf "%s" "$weather" | cut -d'|' -f2)"
feels="$(printf "%s" "$weather" | cut -d'|' -f3)"
humidity="$(printf "%s" "$weather" | cut -d'|' -f4)"
wind="$(printf "%s" "$weather" | cut -d'|' -f5)"
cond="$(printf "%s" "$weather" | cut -d'|' -f6)"

# -------- Output Views --------

case "$view" in
    0)
        printf "%s%s\n" "$icon" "$temp"
        ;;
    1)
        printf "feels %s 💧%s\n" "$feels" "$humidity"
        ;;
    2)
        printf "%s 🌬 %s\n" "$cond" "$wind"
        ;;
esac
