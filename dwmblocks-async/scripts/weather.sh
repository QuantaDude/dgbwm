#!/bin/sh

STATE_FILE="/tmp/weather_block_view"
[ ! -f "$STATE_FILE" ] && echo 0 > "$STATE_FILE"
view="$(cat "$STATE_FILE")"

CACHE_FILE="/tmp/weather_cache"
CACHE_TIME=300   # seconds (match your dwmblocks interval)

now=$(date +%s)

if [ -f "$CACHE_FILE" ]; then
    last=$(stat -c %Y "$CACHE_FILE" 2>/dev/null)
else
    last=0
fi

# Refresh only if expired
if [ $((now - last)) -ge "$CACHE_TIME" ]; then
    	tmp="$(mktemp)"
	if curl -s 'https://wttr.in/Noida?format=%c|%t|%f|%h|%w|%C' > "$tmp"; then
    		mv "$tmp" "$CACHE_FILE"
	else
    		rm -f "$tmp"
	fi
fi


case $BLOCK_BUTTON in
    1) dunstify --urgency=low "Weather" "$(curl -s 'https://wttr.in/Noida?0&Q' | dwm_conv_ansi_to_pango.sh)" ;;
    2) dunstify --urgency=low "Weather Info" \
		"\nLMB: Show current weather.\n\nRMB: Show day wise forecast.\n\nMMB: Show this help.\n\nScroll: Cycle through the following views:\n→ Temperature.\n→ Feels like temperature and humidity.\n→ Condition and wind speed\n";;
    3) dunstify --urgency=normal "Weather" "$(curl -s 'https://wttr.in/Noida?Q&F' | dwm_conv_ansi_to_pango.sh)" ;;

    # Scroll up
    4)
        view=$(( (view + 1) % 3 ))
        echo "$view" > "$STATE_FILE"
#        pkill -RTMIN+5 dwmblocks
        ;;

    # Scroll down
    5)
        view=$(( (view + 2) % 3 ))
        echo "$view" > "$STATE_FILE"
 #       pkill -RTMIN+5 dwmblocks
        ;;
esac

#weather="$(curl -s 'https://wttr.in/Noida?format=%c|%t|%f|%h|%w|%C')"
weather="$(cat "$CACHE_FILE")"

icon="$(printf "%s" "$weather" | cut -d'|' -f1)"
temp="$(printf "%s" "$weather" | cut -d'|' -f2)"
feels="$(printf "%s" "$weather" | cut -d'|' -f3)"
humidity="$(printf "%s" "$weather" | cut -d'|' -f4)"
wind="$(printf "%s" "$weather" | cut -d'|' -f5)"
cond="$(printf "%s" "$weather" | cut -d'|' -f6)"

# -------- Views --------

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
