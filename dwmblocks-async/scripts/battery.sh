#!/bin/sh

if [ "$1" = "--listen" ]; then
    update_battery > /dev/null  # initialize cache

    udevadm monitor --udev --subsystem-match=power_supply | while read -r line; do
        case "$line" in
            *"power_supply"*)
                sleep 0.3  # debounce burst

                update_battery > /dev/null
                pkill -RTMIN+1 dwmblocks 2>/dev/null
                ;;
        esac
    done
    exit 0
fi

BAT_LIST=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' | sort)
[ -z "$BAT_LIST" ] && exit 0

BAT_COUNT=$(printf "%s\n" "$BAT_LIST" | wc -l)

STATE_FILE="/tmp/battery_block_idx"
[ ! -f "$STATE_FILE" ] && echo 0 > "$STATE_FILE"
idx="$(cat "$STATE_FILE")"
[ "$idx" -ge "$BAT_COUNT" ] && idx=0

BAT_DIR=$(printf "%s\n" "$BAT_LIST" | sed -n "$((idx+1))p")

CAPACITY="$(cat "$BAT_DIR/capacity" 2>/dev/null)"
STATUS="$(cat "$BAT_DIR/status" 2>/dev/null)"

get_icon() {
    if [ "$STATUS" = "Charging" ]; then
        echo ""
        return
    fi

    if [ "$CAPACITY" -ge 80 ]; then
        echo ""
    elif [ "$CAPACITY" -ge 60 ]; then
        echo ""
    elif [ "$CAPACITY" -ge 40 ]; then
        echo ""
    elif [ "$CAPACITY" -ge 20 ]; then
        echo ""
    else
        echo ""
    fi
}
set_brightness_if_needed() {
    max=50

    if command -v brightnessctl >/dev/null 2>&1; then
        current=$(brightnessctl get)
        max_val=$(brightnessctl max)
        percent=$(( current * 100 / max_val ))

        if [ "$percent" -gt "$max" ]; then
            brightnessctl set "${max}%"
            dunstify -u low "Brightness" "🔅 Reduced to ${max}%"
        fi
    fi
}

update_battery() {
    BAT_LIST=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' | sort)
    [ -z "$BAT_LIST" ] && return

    BAT_COUNT=$(printf "%s\n" "$BAT_LIST" | wc -l)

    STATE_FILE="/tmp/battery_block_idx"
    [ ! -f "$STATE_FILE" ] && echo 0 > "$STATE_FILE"
    idx="$(cat "$STATE_FILE")"
    [ "$idx" -ge "$BAT_COUNT" ] && idx=0

    BAT_DIR=$(printf "%s\n" "$BAT_LIST" | sed -n "$((idx+1))p")

    CAPACITY="$(cat "$BAT_DIR/capacity" 2>/dev/null)"
    STATUS="$(cat "$BAT_DIR/status" 2>/dev/null)"

    STATE_CACHE="/tmp/battery_status_cache"
    LOW_CACHE="/tmp/battery_low_cache"

    curr_key="$(basename "$BAT_DIR"):$STATUS"
    prev_key=""
    [ -f "$STATE_CACHE" ] && prev_key="$(cat "$STATE_CACHE")"

    if [ "$curr_key" != "$prev_key" ]; then
        case "$STATUS" in
            Charging)
                dunstify -u low "Battery" "⚡ Charging ($CAPACITY%)"
                ;;
            Discharging)
                dunstify -u low "Battery" "🔋 Discharging ($CAPACITY%)"
                set_brightness_if_needed
                ;;
            Full)
                dunstify -u low "Battery" "🔌 Fully charged"
                ;;
        esac

        echo "$curr_key" > "$STATE_CACHE"
    fi

    LOW_THRESHOLD=15
    if [ "$STATUS" = "Discharging" ] && [ "$CAPACITY" -le "$LOW_THRESHOLD" ]; then
        if [ ! -f "$LOW_CACHE" ]; then
            dunstify -u critical "Battery Low" " $CAPACITY% remaining!"
            touch "$LOW_CACHE"
        fi
    else
        rm -f "$LOW_CACHE"
    fi

    icon="$(get_icon)"

    if [ "$BAT_COUNT" -gt 1 ]; then
        prefix="BAT $((idx+1)): "
    else
        prefix=""
    fi

    printf "%s%s %s%%\n" "$prefix" "$icon" "$CAPACITY"
}

case $BLOCK_BUTTON in
    1)
        msg=""
        i=1
        for b in $BAT_LIST; do
            cap="$(cat "$b/capacity" 2>/dev/null)"
            stat="$(cat "$b/status" 2>/dev/null)"
            if [ "$stat" = "Charging" ]; then
                ic=""
            elif [ "$cap" -ge 80 ]; then
                ic=""
            elif [ "$cap" -ge 60 ]; then
                ic=""
            elif [ "$cap" -ge 40 ]; then
                ic=""
            elif [ "$cap" -ge 20 ]; then
                ic=""
            else
                ic=""
            fi
            msg="$msg\n$ic BAT $i: $stat ($cap%)"
            i=$((i+1))
        done
        dunstify "Battery Info" "$msg"
        ;;
    2)
        dunstify -u low "Battery" "\nLMB: Details\nScroll: Cycle battery\n"
        ;;
    4)
        idx=$(( (idx + 1) % BAT_COUNT ))
        echo "$idx" > "$STATE_FILE"
        ;;
    5)
        idx=$(( (idx + BAT_COUNT - 1) % BAT_COUNT ))
        echo "$idx" > "$STATE_FILE"
        ;;
esac

update_battery 
