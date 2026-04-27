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
