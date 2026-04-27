#!/bin/sh

get_vol() {
    pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}'
}

is_muted() {
    pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}'
}

case $BLOCK_BUTTON in
 2) dunstify --urgency=low "Audio Controls" \
		"\nLMB: Mute toggle.\n\nRMB: Show information about audio output devices.\n\nMMB: Show this help.\n\nScroll: Increase/Decrease the volume.\n";;
    3) dunstify --urgency=low "Audio Output" \
		"$(pactl list sinks | grep -E 'Name:|Description:|Volume:|Mute:')" ;;

    1) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;

    4) pactl set-sink-volume @DEFAULT_SINK@ +3% ;;  # scroll up

    5) pactl set-sink-volume @DEFAULT_SINK@ -3% ;;  # scroll down
esac

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
