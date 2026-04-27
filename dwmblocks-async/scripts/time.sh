#!/bin/sh

STATE_FILE="/tmp/time_block_format"
[ ! -f "$STATE_FILE" ] && echo 0 > "$STATE_FILE"
fmt="$(cat "$STATE_FILE")"

case $BLOCK_BUTTON in
    1)
        if [ "$fmt" -eq 0 ]; then
            dunstify --urgency=low "Time" "$(date '+%H:%M:%S')"
        else
            dunstify --urgency=low "Time" "$(date '+%I:%M:%S %p')"
        fi
        ;;

    2) dunstify --urgency=low "Time Controls" \
		"\nLMB: Show time with seconds.\n\nRMB: Sync system clock using chrony.\n\nMMB: Show this help.\n\nScroll: 12/24 hour format.\n";;
    # Right click → sync time via chrony
    3)
        dunstify "Time Sync" "Starting sync..."

        (
            if sudo chronyc -a makestep >/dev/null 2>&1; then
                dunstify "Time Sync" "✔ Sync successful"
            else
                dunstify "Time Sync" "❌ Sync failed"
            fi
        ) &
        ;;

    # Scroll up
    4)
        fmt=$(( (fmt + 1) % 2 ))
        echo "$fmt" > "$STATE_FILE"
        ;;

    # Scroll down
    5)
        fmt=$(( (fmt + 1) % 2 ))
        echo "$fmt" > "$STATE_FILE"
        ;;
esac

# -------- Output --------

if [ "$fmt" -eq 0 ]; then
    printf "%s\n" "$(date '+%H:%M')"
else
    printf "%s\n" "$(date '+%I:%M %p')"
fi
