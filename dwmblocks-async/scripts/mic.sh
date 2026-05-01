#!/bin/sh

toggle_mic() {
    pactl set-source-mute @DEFAULT_SOURCE@ toggle
}

get_mic() {
    pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}'
}

get_info() {
    pactl list sources | grep -E "Name:|Description:|Volume:|Mute:"
}

if [ "$1" = "--listen" ]; then
    get_mic_port() {
        pactl list sources | awk '
            /Active Port:/ {print $3; exit}
        '
    }

    prev_port="$(get_mic_port)"

    pactl subscribe | while read -r line; do
        case "$line" in
            *"on source"*|*"on card"*)
                curr_port="$(get_mic_port)"

                if [ "$curr_port" != "$prev_port" ]; then
                    case "$curr_port" in
                        *headset*|*headphone*)
                            dunstify -u normal "Microphone" "Headset mic active 🎧"
                            ;;
                        *internal*|*analog*)
                            dunstify -u normal "Microphone" "Internal mic active 🎙"
                            ;;
                        *)
                            dunstify -u normal "Microphone" "Mic route changed: $curr_port"
                            ;;
                    esac

                    prev_port="$curr_port"
                    pkill -RTMIN+3 dwmblocks 2>/dev/null
                fi
                ;;
        esac
    done
    exit 0
fi

case $BLOCK_BUTTON in
    1) toggle_mic;;   # left click → toggle
    2) dunstify --urgency=low "Mic Info" \
		"\nLMB: Toggle microphone on/off.\n\nRMB: Show info about audio sources.\n\nMMB: Show this help.\n\nScroll: Increase/Decrease the volume of the mic (audio source).\n";;
    3) dunstify --urgency=low "Microphone" "$(get_info)" ;;  # right click → info

    4) pactl set-source-volume @DEFAULT_SOURCE@ +5% ;; # scroll up

    5) pactl set-source-volume @DEFAULT_SOURCE@ -5% ;; # scroll down
esac

STATUS="$(get_mic)"

if [ "$STATUS" = "yes" ]; then
    ICON="🎙❌"   # muted
else
    ICON="🎙"     # active
fi

printf "%s\n" "$ICON"
