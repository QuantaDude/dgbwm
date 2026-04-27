#!/bin/sh

MONITOR="${1:-auto}"

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
    2) dunstify --urgency=low "Sys Info" \
		"\nLMB: View which processes are consuming the most RAM.\n\nRMB: Open $MONITOR (resource monitor).\n\nMMB: Show this help.\n\nScroll: Cycle through the following views:\n→ RAM.\n→ CPU.\n→ Swap.\n→ Root FS storage use%.\n";;
    1) notify-send "Memory hogs" "$(ps axch -o cmd:15,%mem --sort=-%mem | head)" ;;
  
    3) setsid -f st -e sh -c "$MONITOR" ;;

    # Scroll up
    4)
        view=$(( (view + 1) % 4 ))
        echo "$view" > "$STATE_FILE"
        ;;

    # Scroll down
    5)
        view=$(( (view + 3) % 4 ))
        echo "$view" > "$STATE_FILE"
        ;;
esac

# -------- Views --------

case "$view" in
    0)
        # RAM
        free --mebi | awk 'NR==2 {
            printf "RAM %.2f/%.2fGiB\n", $3/1024, $2/1024
        }'
        ;;
    1)
        # Swap
        free --mebi | awk 'NR==3 {
            printf "Swap %.2f/%.2fGiB\n", $3/1024, $2/1024
        }'
        ;;
    2)
        # CPU usage (instant snapshot)
        cpu="$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')"
        printf "CPU %.1f%%\n" "$cpu"
        ;;
    3)
        # Root filesystem
        df -h / | awk 'NR==2 {
            printf "Root FS: %.0f%%\n", $5
        }'
        ;;
esac
