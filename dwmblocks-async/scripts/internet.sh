#!/bin/sh

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

CONFIG_FILE="$XDG_DATA_HOME/dgbwm/.config/dgbwm/dgbwmrc"
BACKEND="${1:-auto}"
TERM_CMD="${2:-auto}"

# -------- Load terminal from config if needed --------

if [ "$TERM_CMD" = "auto" ]; then
    if [ -f "$CONFIG_FILE" ]; then
        . "$CONFIG_FILE"
        TERM_CMD="${TERMINAL:-st}"
    else
        TERM_CMD="st"
    fi
fi

detect_backend() {
    case "$BACKEND" in
        connman) echo "connman" ;;
        nm|networkmanager) echo "nm" ;;
        iw) echo "iw" ;;
        auto)
            command -v connmanctl >/dev/null && echo "connman" && return
            command -v nmcli >/dev/null && echo "nm" && return
            command -v iw >/dev/null && echo "iw" && return
            echo "none"
            ;;
        *) echo "none" ;;
    esac
}

NET_BACKEND="$(detect_backend)"

STATE_FILE="/tmp/internet_block_view"
CACHE_FILE="/tmp/internet_block_cache"

[ ! -f "$STATE_FILE" ] && echo 0 > "$STATE_FILE"
view="$(cat "$STATE_FILE")"

case $BLOCK_BUTTON in
    1)
    if ! command -v "$TERM_CMD" >/dev/null 2>&1; then
        dunstify --urgency=critical "Error" "$TERM_CMD not found."
    else
        case "$NET_BACKEND" in
            connman) "$TERM_CMD" -e connmanctl ;;
            nm) "$TERM_CMD" -e nmtui ;;
            iw) "$TERM_CMD" -e iwctl ;;
            *) dunstify "Network" "No backend found" ;;
        esac
    fi
    ;;

    2) dunstify --urgency=low "Network Info" \
		"\nLMB: Launch $NET_BACKEND ctl.\n\nRMB: Show more info about network and interface device.\n\nMMB: Show this help.\n\nScroll: Cycle through the following views:\n→ Connection indicator and wifi signal strength.\n→ Incoming and Outgoing data transfer.\n→ Local IP.\n";;

    3)
	case "$NET_BACKEND" in

	    connman)	
        info="$(connmanctl services 2>/dev/null)"
	connected="$(printf "%s\n" "$info" | grep -E '^\*.*[OR]')"

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
	    # Check if WiFi exists and is powered
	    wifi_powered="$(connmanctl technologies 2>/dev/null \
        | awk '/Type = wifi/{f=1} f && /Powered =/{print $3; exit}')"

	    if [ "$wifi_powered" = "True" ]; then
		dunstify --urgency=normal "Network" "Scanning WiFi networks..."

		scan="$(connmanctl scan wifi >/dev/null 2>&1; connmanctl services)"

		networks="$(printf "%s\n" "$scan" \
            	| grep wifi \
            	| sed 's/^\s*//g' \
            	| sed 's/ wifi_.*$//' \
            	| head -n 10)"

		[ -z "$networks" ] && networks="No networks found"

		dunstify -i network-wireless-disconnected \
			 "📡 Available Networks" \
			 "$networks"
	    else
		dunstify "Network" "WiFi not available or disabled"
	    fi
	fi
        ;;

	    nm)

		eth_iface="$(nmcli -t -f DEVICE,TYPE,STATE dev \
        	| awk -F: '$2=="ethernet" && $3=="connected"{print $1}')"

		if [ -n "$eth_iface" ]; then
		    dunstify -r 9991 "Connected" \
			     "🖧 Ethernet\nDevice: $eth_iface"
		else
		    ssid="$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)"
		    device="$(nmcli -t -f DEVICE,STATE dev | grep ':connected' | cut -d: -f1)"

		    if [ -n "$ssid" ]; then
			dunstify -r 9991 "Connected" \
			     " WiFi\nSSID: $ssid\nDevice: $device"
		    else
	
	            wifi_state="$(nmcli -t -f TYPE,STATE dev | grep '^wifi:' | cut -d: -f2)"

		    if [ "$wifi_state" = "enabled" ] || [ "$wifi_state" = "disconnected" ]; then
			dunstify "Network" "Scanning WiFi networks..."

			networks="$(nmcli -t -f SSID,SIGNAL dev wifi list \
                	| sed '/^--/d' \
                	| head -n 10)"

			[ -z "$networks" ] && networks="No networks found"

			dunstify "📡 Available Networks" "$networks"
		    else
			dunstify "Network" "WiFi disabled or unavailable"
		    fi
		fi
		fi
		;;

	    iw)
		eth_iface="$(for i in /sys/class/net/*; do
        	    iface="$(basename "$i")"
       		     [ "$iface" = "lo" ] && continue
        	     [ -d "$i/wireless" ] && continue

        	     state="$(cat "$i/operstate" 2>/dev/null)"

        	     if [ "$state" = "up" ]; then
            	     	echo "$iface"
            	     	break
        	     elif [ "$state" = "unknown" ]; then
            	     	  ping -I "$iface" -c 1 -W 1 8.8.8.8 >/dev/null 2>&1 && {
                	  echo "$iface"
                	  break
            		  }
        		  fi
    			  done)"
		        if [ -n "$eth_iface" ]; then
			    dunstify -r 9991 "Connected" \
				     "🖧 Ethernet\nDevice: $eth_iface"
			else
	     wifi_iface="$(iw dev | awk '$1=="Interface"{print $2; exit}')"

	     if [ -z "$wifi_iface" ]; then
		 dunstify "Network" "No WiFi interface found"
	     else
		 ssid="$(iw dev "$wifi_iface" link | grep SSID | awk '{print $2}')"

		 if [ -n "$ssid" ]; then
		     dunstify -r 9991 "Connected" \
			      " WiFi\nSSID: $ssid\nDevice: $wifi_iface"
		 else
		     wifi_up="$(ip link show "$wifi_iface" | grep -q 'UP' && echo yes)"

		     if [ "$wifi_up" = "yes" ]; then
			 dunstify "Network" "Scanning WiFi networks..."

			 networks="$(iw dev "$wifi_iface" scan 2>/dev/null \
                    	 | grep 'SSID:' \
                    | sed 's/SSID: //' \
                    | head -n 10)"

			 [ -z "$networks" ] && networks="No networks found"

			 dunstify "📡 Available Networks" "$networks"
		     else
			 dunstify "Network" "WiFi interface down"
		     fi
		 fi
	     fi
	     fi
	     ;;

	    *)
		dunstify "Network" "No backend available"
		;;
	esac
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
        printf "%s%s\n" "$neticon"
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

