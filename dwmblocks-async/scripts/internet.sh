#!/bin/sh

STATE_FILE="/tmp/internet_block_view"
CACHE_FILE="/tmp/internet_block_cache"

[ ! -f "$STATE_FILE" ] && echo 0 > "$STATE_FILE"
view="$(cat "$STATE_FILE")"

case $BLOCK_BUTTON in
    1) "st" -e connmanctl;;
    2) dunstify --urgency=low "Network Info" \
		"\nLMB: Launch your network configuration UI.\n\nRMB: Show more info about network and interface device.\n\nMMB: Show this help.\n\nScroll: Cycle through the following views:\n→ Connection indicator and wifi signal strength.\n→ Incoming and Outgoing data transfer.\n→ Local IP.\n";;
    3)
        info="$(connmanctl services 2>/dev/null)"
        connected="$(printf "%s\n" "$info" | grep -E '^\*A')"

        if [ -n "$connected" ]; then
            ssid="$(printf "%s\n" "$connected" | awk '{print $2}')"
            service_id="$(printf "%s\n" "$connected" | awk '{print $NF}')"

            details="$(connmanctl services "$service_id" 2>/dev/null)"
            device="$(printf "%s\n" "$details" | sed -n 's/.*Interface=\([^,]*\).*/\1/p')"
            [ -z "$device" ] && device="unknown"

            case "$service_id" in
                wifi_*) type="  WiFi" ;;
                ethernet_*) type="🖧  Ethernet" ;;
                *) type="🌐 Network" ;;
            esac

            dunstify -r 9991 -i network-wireless \
                "Connected" \
                "$type\nSSID: $ssid\nDevice: $device"
        else
            scan="$(connmanctl scan wifi >/dev/null 2>&1; connmanctl services)"
            networks="$(printf "%s\n" "$scan" \
                | grep wifi \
                | sed 's/^\s*//g' \
                | sed 's/ wifi_.*$//' \
                | head -n 10)"

            dunstify -i network-wireless-disconnected \
                "📡 Available Networks" \
                "$networks"
        fi
        ;;
    4) view=$(( (view + 1) % 3 )); echo "$view" > "$STATE_FILE" ;;
    5) view=$(( (view + 2) % 3 )); echo "$view" > "$STATE_FILE" ;;
esac

# -------- Detect interfaces --------

eth_iface=""
for i in /sys/class/net/*; do
    iface="$(basename "$i")"
    [ "$iface" = "lo" ] && continue
    [ -d "$i/wireless" ] && continue

    state="$(cat "$i/operstate" 2>/dev/null)"

    if [ "$state" = "up" ]; then
        eth_iface="$iface"
    elif [ "$state" = "unknown" ]; then
        if ping -I "$iface" -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
            eth_iface="$iface"
        fi
    fi
done
wifi_iface="$(for i in /sys/class/net/*; do
    [ -d "$i/wireless" ] && basename "$i"
done)"

if [ -n "$eth_iface" ]; then
    active_iface="$eth_iface"
    neticon="eth: $eth_iface "
else
    active_iface="$wifi_iface"

    if [ -n "$wifi_iface" ] && grep -xq 'up' "/sys/class/net/$wifi_iface/operstate"; then
        neticon="$(awk -v iface="$wifi_iface" '$1 ~ iface { printf " %d%% ", int($3 * 100 / 70) }' /proc/net/wireless)"

        # fallback if awk fails
        [ -z "$neticon" ] && neticon=" "
    elif [ -n "$wifi_iface" ]; then
        grep -xq '0x1003' "/sys/class/net/$wifi_iface/flags" && neticon="❌ " || neticon="📡 "
    else
        neticon="⨂"
    fi
fi


# -------- IP --------

get_ip() {
    ip -4 addr show "$active_iface" 2>/dev/null \
    | grep -oE 'inet [0-9.]+' \
    | awk '{print $2}' \
    | head -n1
}

# -------- Non-blocking speed --------

get_speed() {
    [ -z "$active_iface" ] && return

    rx=$(cat /sys/class/net/"$active_iface"/statistics/rx_bytes 2>/dev/null)
    tx=$(cat /sys/class/net/"$active_iface"/statistics/tx_bytes 2>/dev/null)
    now=$(date +%s)

    if [ -f "$CACHE_FILE" ]; then
        read old_rx old_tx old_time < "$CACHE_FILE"

        dt=$((now - old_time))
        [ "$dt" -le 0 ] && dt=1

        rx_rate=$(( (rx - old_rx) / dt / 1024 ))
        tx_rate=$(( (tx - old_tx) / dt / 1024 ))
    else
        rx_rate=0
        tx_rate=0
    fi

    echo "$rx $tx $now" > "$CACHE_FILE"

    printf "↓ %dKB ↑ %dKB" "$rx_rate" "$tx_rate"
}

# -------- Output --------

case "$view" in
    0)
        printf "%s%s\n" "$neticon" "$vpnicon"
        ;;
    1)
        ip="$(get_ip)"
        [ -z "$ip" ] && ip="no ip"
        printf "ip: %s\n" "$ip"
        ;;
    2)
        speed="$(get_speed)"
        [ -z "$speed" ] && speed="no data"
        printf "%s\n" "$speed"
        ;;
esac

