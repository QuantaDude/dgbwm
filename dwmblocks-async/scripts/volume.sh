#!/bin/sh

update_bar() {
    pkill -RTMIN+3 dwmblocks 2>/dev/null
}

get_vol() {
    pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}'
}

is_muted() {
    pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}'
}

# ---- LISTENER MODE ----
if [ "$1" = "--listen" ]; then

    get_default_sink() {
        pactl info | awk -F': ' '/Default Sink/ {print $2}'
    }

    get_sink_desc() {
        pactl list sinks | awk -v sink="$1" '
            $0 ~ "Name: "sink {found=1}
            found && /Description:/ {sub("Description: ", ""); print; exit}
        '
    }

    get_active_port() {
        pactl list sinks | awk -v sink="$1" '
            $0 ~ "Name: "sink {found=1}
            found && /Active Port:/ {print $3; exit}
        '
    }

    prev_sink="$(get_default_sink)"
    prev_port="$(get_active_port "$prev_sink")"

    pactl subscribe | while read -r line; do
        case "$line" in
            *"on sink"*|*"on server"*|*"on card"*)

                curr_sink="$(get_default_sink)"
                curr_port="$(get_active_port "$curr_sink")"

                if [ "$curr_sink" != "$prev_sink" ] || [ "$curr_port" != "$prev_port" ]; then

                    desc="$(get_sink_desc "$curr_sink")"

                    # ---- TRUTH ENGINE ----
                    if echo "$curr_sink" | grep -qi usb; then
                        msg="USB audio device active 🎧🔌"

                    else
                        case "$curr_port" in
                            *headphones*)
                                msg="Headphones connected 🎧"
                                ;;
                            *speaker*)
                                msg="Switched to speakers 🔊"
                                ;;
                            *)
                                msg="$desc"
                                ;;
                        esac
                    fi

                    dunstify -u normal "Audio" "$msg"

                    prev_sink="$curr_sink"
                    prev_port="$curr_port"

                    update_bar
                fi
                ;;
        esac
    done

    exit 0
fi

# ---- CLICK HANDLING ----
case $BLOCK_BUTTON in
    1) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;  # LMB
    2) dunstify --urgency=low "Audio Controls" \
"\nLMB: Mute toggle.\n\nRMB: Show info about audio outputs.\n\nMMB: Show this help.\n\nScroll: Adjust volume.\n" ;;
    3) dunstify --urgency=low "Audio Output" \
"$(pactl list sinks | grep -E 'Name:|Description:|Volume:|Mute:')" ;;
    4) pactl set-sink-volume @DEFAULT_SINK@ +3% ;;
    5) pactl set-sink-volume @DEFAULT_SINK@ -3% ;;
esac

# ---- STATUS BAR ----
VOL="$(get_vol)"
MUTE="$(is_muted)"

if [ "$MUTE" = "yes" ]; then
    ICON="🔇"
else
    VOL_NUM=$(echo "$VOL" | tr -d '%')
    if [ "$VOL_NUM" -lt 30 ]; then
        ICON="🔈"
    elif [ "$VOL_NUM" -lt 70 ]; then
        ICON="🔉"
    else
        ICON="🔊"
    fi
fi

printf "%s %s\n" "$ICON" "$VOL"
