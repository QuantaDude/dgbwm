#!/bin/sh

toggle_mic() {
    pactl set-source-mute @DEFAULT_SOURCE@ toggle
}

get_mic() {
    pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}'
}

get_info() {
    pactl list sources | grep -E "Name:|Description:|Active Port:|Volume:|Mute:"
}

# ---- LISTENER MODE ----
if [ "$1" = "--listen" ]; then

    get_default_source() {
        pactl info | awk -F': ' '/Default Source/ {print $2}'
    }

    get_source_desc() {
        pactl list sources | awk -v src="$1" '
            $0 ~ "Name: "src {found=1}
            found && /Description:/ {sub("Description: ", ""); print; exit}
        '
    }

    get_active_port() {
        pactl list sources | awk -v src="$1" '
            $0 ~ "Name: "src {found=1}
            found && /Active Port:/ {print $3; exit}
        '
    }

    prev_source="$(get_default_source)"
    prev_port="$(get_active_port "$prev_source")"

    pactl subscribe | while read -r line; do
        case "$line" in
            *"on source"*|*"on server"*|*"on card"*)

                curr_source="$(get_default_source)"
                curr_port="$(get_active_port "$curr_source")"

                if [ "$curr_source" != "$prev_source" ] || [ "$curr_port" != "$prev_port" ]; then

                    desc="$(get_source_desc "$curr_source")"

                    # ---- TRUTH ENGINE ----
                    if echo "$curr_source" | grep -qi usb; then
                        msg="USB mic active 🎤"

                    else
                        case "$curr_port" in
                            *internal*)
                                msg="Internal mic active 🎙"
                                ;;
                            *mic)
                                msg="Headset mic active 🎧"
                                ;;
                            *)
                                msg="$desc"
                                ;;
                        esac
                    fi

                    dunstify -u normal "Microphone" "$msg"

                    prev_source="$curr_source"
                    prev_port="$curr_port"

                    pkill -RTMIN+4 dwmblocks 2>/dev/null
                fi
                ;;
        esac
    done

    exit 0
fi

# ---- CLICK HANDLING ----
case $BLOCK_BUTTON in
    1) toggle_mic ;;  # left click
    2) dunstify --urgency=low "Mic Info" \
"\nLMB: Toggle microphone on/off.\n\nRMB: Show info about audio sources.\n\nMMB: Show this help.\n\nScroll: Increase/Decrease mic volume.\n" ;;
    3) dunstify --urgency=low "Microphone" "$(get_info)" ;;  # right click
    4) pactl set-source-volume @DEFAULT_SOURCE@ +5% ;; # scroll up
    5) pactl set-source-volume @DEFAULT_SOURCE@ -5% ;; # scroll down
esac

# ---- STATUS BAR ICON ----
STATUS="$(get_mic)"

if [ "$STATUS" = "yes" ]; then
    ICON="🎙❌"
else
    ICON="🎙"
fi

printf "%s\n" "$ICON"
