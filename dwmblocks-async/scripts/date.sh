#!/bin/sh

STATE_FILE="/tmp/date_block_view"
[ ! -f "$STATE_FILE" ] && echo 0 > "$STATE_FILE"
view="$(cat "$STATE_FILE")"

case $BLOCK_BUTTON in
    1) dunstify --urgency=low "Calendar" "$(cal)" ;;
    2) dunstify --urgency=low "Date Info" \
		"\nLMB: Show the month calendar.\n\nRMB: Show the year calendar.\n\nMMB: Show this help.\n\nScroll: Cycle through the different formats\n";;
    3) dunstify --urgency=normal "Calendar" "$(cal -y)" ;;

    # Scroll up
    4)
        view=$(( (view + 1) % 3 ))
        echo "$view" > "$STATE_FILE"
        ;;

    # Scroll down
    5)
        view=$(( (view + 2) % 3 ))
        echo "$view" > "$STATE_FILE"
        ;;
esac

# -------- Views --------

case "$view" in
    0)
        printf "%s\n" "$(date '+%b %d')"
        ;;
    1)
        printf "%s\n" "$(date '+%a, %d %b')"
        ;;
    2)
        printf "%s\n" "$(date '+%Y-%m-%d')"
        ;;
esac
