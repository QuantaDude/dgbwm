#!/bin/sh
set -e

BROWSERS="firefox chromium brave qutebrowser librewolf"
FILE_MANAGERS="vifm thunar pcmanfm ranger nnn lf dolphin"
RES_MONITORS="btop htop top"
TERMINALS="st kitty ghostty alacritty konsole"


TUI_FM="vifm ranger nnn lf"

detect_programs() {
    found=""
    for prog in $1; do
        if command -v "$prog" >/dev/null 2>&1; then
            found="$found $prog"
        fi
    done
    echo "$found"
}

choose_program() {
    category="$1"
    programs="$2"

    echo ""
    echo "[*] Select $category:"

    i=1
    for prog in $programs; do
        echo "  $i) $prog"
        eval "opt_$i=$prog"
        i=$((i+1))
    done

    if [ "$i" -eq 1 ]; then
        echo "  No known programs found."
        printf "Enter executable name: "
        read manual
        echo "$manual"
        return
    fi

    printf "Choice (1-$((i-1))): "
    read choice

    eval "echo \$opt_$choice"
}

# --- XDG fallbacks ---
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"


echo "[*] Using:"
echo "    CONFIG: $XDG_CONFIG_HOME"
echo "    DATA:   $XDG_DATA_HOME"

# --- Create dirs if missing ---
mkdir -p "$XDG_CONFIG_HOME"
mkdir -p "$XDG_DATA_HOME/dgbwm"

DATA_CONFIG_DIR="$XDG_DATA_HOME/dgbwm/.config"

mkdir -p "$DATA_CONFIG_DIR/dgbwm"

CONFIG_FILE="$DATA_CONFIG_DIR/dgbwm/dgbwmrc"

# --- Copy assets (.config files, wallpapers, scripts, etc.) ---
echo "[*] Copying assets..."
cp -r wp1.png wp2.png startdwm.sh "$XDG_DATA_HOME/dgbwm/"
echo "[*] Succesfully copied assets to $XDG_DATA_HOME/dgbwm/"

echo "[*] Copying configs into data dir..."
cp -r .config/* "$DATA_CONFIG_DIR/"

echo ""
echo "[*] Choose the web browser to quick launch using the keybind (Super + F1)"
echo ""
browser=$(choose_program "browser" "$(detect_programs "$BROWSERS")")

echo ""
echo "[*] Choose the file manager to quick launch using the keybind (Super + F2)"
echo ""
fm=$(choose_program "file manager" "$(detect_programs "$FILE_MANAGERS")")

FM_NEEDS_TERM=0
KNOWN=0

for t in $TUI_FM; do
    if [ "$fm" = "$t" ]; then
        FM_NEEDS_TERM=1
        KNOWN=1
        break
    fi
done

# If unknown → ask user
if [ "$KNOWN" -eq 0 ]; then
    echo ""
    printf "[?] Does '%s' require a terminal to run? (y/n): " "$fm"
    read ans

    case "$ans" in
        y|Y) FM_NEEDS_TERM=1 ;;
        *)   FM_NEEDS_TERM=0 ;;
    esac
fi

echo "[*] FM_NEEDS_TERM=$FM_NEEDS_TERM"

echo ""
echo "[*] Choose the resource monitor to quick launch using the keybind (Super + F3) and from the status bar"
echo ""
res_monitor=$(choose_program "system monitor" "$(detect_programs "$RES_MONITORS")")

# --- Build & install suckless tools ---
echo ""
echo "[*] Do you want to install st (suckless terminal)?"
read install_st

if [ "$install_st" = "y" ] || [ "$install_st" = "Y" ]; then
    INSTALL_ST=1
    terminal="st"
else
    INSTALL_ST=0
    echo ""
    echo "[*] Choose the terminal to quick using the keybind (Super + t)"
    echo ""
    terminal=$(choose_program "terminal" "$(detect_programs "$TERMINALS")")
fi

echo "[*] Selected terminal: $terminal"

if [ "$INSTALL_ST" -eq 1 ]; then
    echo "[*] Installing st..."
    cd ../st && sudo make clean install
    cd ..
else
    echo "[*] Skipping st installation"
fi

echo "[*] Installing dwm..."
cd dwm && sudo make clean TERMINAL="$terminal" BROWSER="$browser" FM="$fm" RES_MONITOR="$res_monitor" FM_NEEDS_TERM="$FM_NEEDS_TERM" install

echo "[*] Installing dwmblocks..."
echo ""
printf "Enable weather block? (y/n): "
read weather_enable

WEATHER_MODE="none"

if [ "$weather_enable" = "y" ]; then
    echo "1) IP-based"
    echo "2) Location-based"
    printf "Choice: "
    read wchoice

    if [ "$wchoice" = "1" ]; then
        WEATHER_MODE="ip"
    else
        printf "Enter location (e.g. Delhi): "
        read loc
        WEATHER_MODE="location:$loc"
    fi
fi

if [ "$weather_enable" = "y" ]; then
    WEATHER_BLOCK=1
else
    WEATHER_BLOCK=0
fi
cd ../dwmblocks-async && sudo make clean TERMINAL="$terminal" RES_MONITOR="$res_monitor" WEATHER_BLOCK="$WEATHER_BLOCK" install

echo "[*] Installing dunst..."
cd ../dunst && sudo make clean install

cd ..

echo "[*] Saving config..."

cat > "$CONFIG_FILE" <<EOF
TERMINAL=$terminal
FM_NEEDS_TERM=$FM_NEEDS_TERM
BROWSER=$browser
FILE_MANAGER=$fm
MONITOR=$res_monitor
WEATHER_MODE=$WEATHER_MODE
EOF

# --- Install start script ---
echo "[*] Installing startdwm.sh..."

sudo install -Dm755 startdwm.sh /usr/local/bin/startdwm

# --- Install desktop entry ---
echo "[*] Installing dwm.desktop..."

sudo install -Dm644 dwm.desktop /usr/local/share/xsessions/dwm.desktop

# Also copy to /usr/share as some DMs only check here
if [ -d /usr/share/xsessions ]; then
    sudo install -Dm644 dwm.desktop /usr/share/xsessions/dwm.desktop
fi

# --- Configs ---

echo "[*] Linking configs..."

for dir in .config/*; do
    name=$(basename "$dir")

    source_dir="$DATA_CONFIG_DIR/$name"
    target="$XDG_CONFIG_HOME/$name"

    # If target exists and is NOT a symlink → ask user
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo ""
        echo "[!] Config '$name' already exists at $target"
        echo "Choose an action:"
        echo "  1) Backup and overwrite"
        echo "  2) Overwrite without backup"
        echo "  3) Skip"

        printf "Choice (1/2/3): "
        read choice

        case "$choice" in
            1)
		backup="$XDG_CONFIG_HOME/${name}.bak.$(date +%s)"
                
                echo "    Backing up to $backup"
                rm -rf "$backup"
                mv "$target" "$backup"
                ;;
            2)
                echo "    Overwriting $target"
                rm -rf "$target"
                ;;
            3)
                echo "    Skipping $name"
                continue
                ;;
            *)
                echo "    Invalid choice, skipping"
                continue
                ;;
        esac
    fi

    # Remove broken symlink if exists
    if [ -L "$target" ]; then
        rm -f "$target"
    fi

    echo "    Linking $name"
    ln -sf "$source_dir" "$target"
done

echo "[✓] Done. Restart X session."
