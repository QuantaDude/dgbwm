#!/bin/sh
set -e

DEPS="feh xorg-server libx11 pango dbus libxrandr libxinerama libxss pod2man ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols ttf-hack-nerd"
FONTS="JetBrainsMono Nerd Font Symbols Nerd Font Hack Nerd Font"
OPTIONAL_PKGS="flameshot vifm emacs qutebrowser btop"

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
    else
        DISTRO="unknown"
    fi
}
check_deps() {
    missing=""

    for pkg in $DEPS; do
        if command -v pacman >/dev/null 2>&1; then
            pacman -Q "$pkg" >/dev/null 2>&1 || missing="$missing $pkg"
        elif command -v dpkg >/dev/null 2>&1; then
            dpkg -s "$pkg" >/dev/null 2>&1 || missing="$missing $pkg"
        elif command -v rpm >/dev/null 2>&1; then
            rpm -q "$pkg" >/dev/null 2>&1 || missing="$missing $pkg"
        else
            command -v "$pkg" >/dev/null 2>&1 || missing="$missing $pkg"
        fi
    done

    echo "$missing"
}

check_fonts() {
    missing_fonts=""

    for font in $FONTS; do
        if ! fc-list | grep -iq "$font"; then
            missing_fonts="$missing_fonts [$font]"
        fi
    done

    echo "$missing_fonts"
}

check_optional_missing() {
    missing=""

    for pkg in $OPTIONAL_PKGS; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            missing="$missing $pkg"
        fi
    done

    echo "$missing"
}

choose_optional_install() {
    missing="$1"

    [ -z "$missing" ] && return

    echo ""
    echo "[*] Optional tools not found:"
    
    i=1
    for pkg in $missing; do
        echo "  $i) $pkg"
        eval "opt_$i=\"$pkg\""
        i=$((i+1))
    done

    echo ""
    echo "Select which ones to install (space-separated numbers)"
    echo "Press Enter to skip all"

    printf "Choice: "
    read choices

    [ -z "$choices" ] && {
        echo "[*] Skipping optional tools."
        return
    }

    selected=""

    for c in $choices; do
        eval "selected=\"$selected \$opt_$c\""
    done

    echo "[*] Selected:$selected"

    if [ "$ARCH_BASED" -eq 1 ]; then
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed $selected
        else
            sudo pacman -S --needed $selected
        fi
    else
        echo ""
        echo "[!] Install manually:"
        
        if command -v apt >/dev/null 2>&1; then
            echo "    sudo apt install $selected"
        elif command -v dnf >/dev/null 2>&1; then
            echo "    sudo dnf install $selected"
        elif command -v zypper >/dev/null 2>&1; then
            echo "    sudo zypper install $selected"
        else
            echo "    (unknown package manager)"
        fi
    fi
}

BROWSERS="firefox chromium brave qutebrowser librewolf"
RES_MONITORS="btop htop top"
TERMINALS="st kitty ghostty alacritty konsole"
EDITORS="vim nvim emacs"
FILE_MANAGERS="vifm thunar pcmanfm ranger nnn lf dolphin"
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

validate_exec() {
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        echo "[!] '$1' not found in PATH" >&2
        return 1
    fi
}

choose_program() {
    category="$1"
    default="$2"
    shift 2

    options="$@"

    # Add previous choice if not in list
    found_prev=0
    for p in $options; do
        [ "$p" = "$default" ] && found_prev=1
    done

    if [ -n "$default" ] && [ "$found_prev" -eq 0 ]; then
        options="$default $options"
    fi

    echo "" >&2
    echo "[*] Select $category:" >&2

    i=1
    default_index=1

    for prog in $options; do
        echo "  $i) $prog" >&2
        eval "opt_$i=\"$prog\""

        [ "$prog" = "$default" ] && default_index=$i

        i=$((i+1))
    done

    # Add <other>
    echo "  $i) <other>" >&2
    other_index=$i

    printf "Choice [default %d]: " "$default_index" >&2
    read choice

    # default on empty
    [ -z "$choice" ] && choice=$default_index

    if [ "$choice" -eq "$other_index" ]; then
        while :; do
            printf "Enter executable name: " >&2
            read manual

            if validate_exec "$manual"; then
                echo "$manual"
                return
            fi
        done
    fi

    eval "echo \"\$opt_$choice\""
}

# -- Detect Distro ---

detect_distro

echo "[*] Detected $DISTRO distro."
echo ""

case "$DISTRO" in
    arch|artix|endeavouros|manjaro|cachyos|garuda|arcolinux)
        ARCH_BASED=1
        ;;
    *)
        # fallback: if pacman exists, it's *probably* arch-based
        if command -v pacman >/dev/null 2>&1; then
            ARCH_BASED=1
        else
            ARCH_BASED=0
        fi
        ;;
esac

if [ "$ARCH_BASED" -eq 1 ]; then
    echo "[*] Arch-based system detected. Auto-install enabled."
else
    echo "[!] Non-Arch distro detected."
    echo "[!] You must manually install missing dependencies."
fi

echo ""

# --- XDG fallbacks ---
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"


echo "[*] Using:"
echo "    CONFIG: $XDG_CONFIG_HOME"
echo "    DATA:   $XDG_DATA_HOME"

# --- Check for missing dependencies ---

echo "[*] Checking dependencies..."
missing_pkgs="$(check_deps)"

echo "[*] Checking fonts..."
missing_fonts="$(check_fonts)"

# --- Handle missing deps ---
if [ -n "$missing_pkgs" ]; then
    echo "[!] Missing packages:$missing_pkgs"
fi

if [ -n "$missing_fonts" ]; then
    echo "[!] Missing fonts:$missing_fonts"
fi

if [ -n "$missing_pkgs$missing_fonts" ]; then
    echo ""

    case "$DISTRO $DISTRO_LIKE" in
        *arch*)
            printf "[?] Install missing components? (y/n): "
            read ans

            if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
                # install packages normally
                if [ -n "$missing_pkgs" ]; then
                    if command -v yay >/dev/null 2>&1; then
                        yay -S --needed $missing_pkgs
                    else
                        sudo pacman -S --needed $missing_pkgs
                    fi
                fi

            else
                echo "[!] Aborting."
                exit 1
            fi
            ;;
        *)
            echo "[!] Install missing items manually."
            exit 1
            ;;
    esac
fi



# --- Create dirs if missing ---
mkdir -p "$XDG_CONFIG_HOME"
mkdir -p "$XDG_DATA_HOME/dgbwm"

DATA_CONFIG_DIR="$XDG_DATA_HOME/dgbwm/.config"

mkdir -p "$DATA_CONFIG_DIR/dgbwm"

CONFIG_FILE="$DATA_CONFIG_DIR/dgbwm/dgbwmrc"

[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"

HAS_CONFIG=0
[ -f "$CONFIG_FILE" ] && HAS_CONFIG=1

if [ "$HAS_CONFIG" -eq 0 ]; then
    missing_optional="$(check_optional_missing)"
    choose_optional_install "$missing_optional"
fi

# --- Copy assets (.config files, wallpapers, scripts, etc.) ---
echo "[*] Copying assets..."
cp -r wp1.png wp2.png dgbwm-init dgbwm-run "$XDG_DATA_HOME/dgbwm/"
echo "[*] Succesfully copied assets to $XDG_DATA_HOME/dgbwm/"

echo "[*] Copying configs into data dir..."
cp -r .config/* "$DATA_CONFIG_DIR/"

choose_wallpaper() {
    DIR="$HOME/.local/share/dgbwm"

    files=$(find "$DIR" -type f \( \
        -iname "*.png" -o \
        -iname "*.jpg" -o \
        -iname "*.jpeg" -o \
        -iname "*.bmp" -o \
        -iname "*.gif" -o \
        -iname "*.webp" -o \
        -iname "*.tiff" \
    \))

    if [ -z "$files" ]; then
        echo "[!] No wallpapers found in $DIR" >&2
        echo "$WALLPAPER"
        return
    fi

    echo "" >&2
    echo "[*] Select wallpaper (current: ${WALLPAPER:-none})" >&2

    i=1
    for f in $files; do
        name=$(basename "$f")
        echo "  $i) $name" >&2
        eval "wp_$i=\"$f\""
        i=$((i+1))
    done

    printf "Choice [Enter to keep current]: " >&2
    read choice

    if [ -z "$choice" ]; then
        echo "$WALLPAPER"
        return
    fi

    eval "echo \$wp_$choice"
}

echo ""
echo "[*] Choose the web browser to quick launch using the keybind (Super + F1)"
echo ""
browser=$(choose_program \
    "browser" \
    "$BROWSER" \
    $(detect_programs "$BROWSERS"))

echo ""
echo "[*] Choose the file manager to quick launch using the keybind (Super + F2)"
echo ""
fm=$(choose_program \
    "file manager" \
    "$FILE_MANAGER" \
    $(detect_programs "$FILE_MANAGERS"))

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
echo "[*] Choose the resource monitor to quick launch from the status bar"
echo ""
res_monitor=$(choose_program \
    "system monitor" \
    "$MONITOR" \
    $(detect_programs "$RES_MONITORS"))

# --- Build & install suckless tools ---
echo ""
echo "[*] Do you want to install st (suckless terminal) y/n ?"
read install_st

if [ "$install_st" = "y" ] || [ "$install_st" = "Y" ]; then
    INSTALL_ST=1
    terminal="st"
else
    INSTALL_ST=0
    echo ""
    echo "[*] Choose the terminal to quick using the keybind (Super + t)"
    echo ""
    terminal=$(choose_program \
    "terminal" \
    "$TERMINAL" \
    $(detect_programs "$TERMINALS"))
fi

echo "[*] Selected terminal: $terminal"

if [ "$INSTALL_ST" -eq 1 ]; then
    echo "[*] Installing st..."
    cd st && sudo make clean install
    cd ..
else
    echo "[*] Skipping st installation"
fi

echo "[*] Installing dwm..."
# -------- Mode --------

echo ""

if [ "$HAS_CONFIG" -eq 1 ]; then
    printf "[*] Do you tinker often? (current: %s) (y/n, Enter to keep): " "$MODE"
else
    printf "[*] Do you tinker often? (y/n): "
fi

read dynamic

if [ -z "$dynamic" ] && [ "$HAS_CONFIG" -eq 1 ]; then
    MODE="${MODE:-static}"
elif [ "$dynamic" = "y" ]; then
    MODE="dynamic"
else
    MODE="static"
fi

cd dwm

if [ "$MODE" = "dynamic" ]; then
    sudo make clean DYNAMIC=1 install
else
    sudo make clean \
        TERMINAL="$terminal" \
        BROWSER="$browser" \
        FM="$fm" \
        FM_NEEDS_TERM="$FM_NEEDS_TERM" \
        install
fi


echo "[*] Installing dwmblocks..."
echo ""

if [ "$HAS_CONFIG" -eq 1 ]; then
    echo "[*] Weather configuration (current: $WEATHER_MODE)"
    printf "Change it? (y/n, Enter to keep): "
    read ans

    if [ -z "$ans" ]; then
        :
    elif [ "$ans" = "y" ]; then
        change_weather=1
    else
        change_weather=0
    fi
else
    printf "[*] Enable weather block? (y/n): "
    read ans
    [ "$ans" = "y" ] && change_weather=1 || change_weather=0
fi

if [ "$change_weather" = "1" ]; then
    echo "  1) IP-based"
    echo "  2) Location-based"
    printf "Choice: "
    read wchoice

    if [ "$wchoice" = "1" ]; then
        WEATHER_MODE="ip"
    else
        printf "Enter location: "
        read loc
        WEATHER_MODE="location:$loc"
    fi
fi

[ "$WEATHER_MODE" = "none" ] && WEATHER_BLOCK=0 || WEATHER_BLOCK=1

cd ..
cd dwmblocks-async

if [ "$MODE" = "dynamic" ]; then
    sudo make clean DYNAMIC=1 install
else
    sudo make clean \
        TERMINAL="$terminal" \
        RES_MONITOR="$monitor" \
        install
fi

# cd ../dwmblocks-async && sudo make clean TERMINAL="$terminal" RES_MONITOR="$res_monitor" WEATHER_BLOCK="$WEATHER_BLOCK" install

echo "[*] Installing dunst..."
cd ../dunst && sudo make clean install

cd ..

echo ""

if [ "$HAS_CONFIG" -eq 1 ]; then
    printf "[*] Change wallpaper? (y/n, Enter to keep): "
    read ans
    [ "$ans" = "y" ] && WALLPAPER=$(choose_wallpaper)
else
    printf "[*] Select wallpaper? (y/n): "
    read ans
    [ "$ans" = "y" ] && WALLPAPER=$(choose_wallpaper)
fi


echo "[*] Saving config..."

cat > "$CONFIG_FILE" <<EOF
MODE=$MODE
TERMINAL=$terminal
FM_NEEDS_TERM=$FM_NEEDS_TERM
BROWSER=$browser
FILE_MANAGER=$fm
MONITOR=$res_monitor
WEATHER_MODE=$WEATHER_MODE
WALLPAPER=$WALLPAPER
EOF

# --- Install start script ---
echo "[*] Installing dgbwm-init, dgbwm-config, and dgbwm-run scripts"

sudo install -Dm755 dgbwm-init /usr/local/bin/dgbwm-init
sudo install -Dm755 dgbwm-config /usr/local/bin/dgbwm-config
sudo install -Dm755 dgbwm-run /usr/local/bin/dgbwm-run

# --- Install desktop entry ---
echo "[*] Installing dgbwm.desktop..."

sudo install -Dm644 dgbwm.desktop /usr/local/share/xsessions/dgbwm.desktop

# Also copy to /usr/share as some DMs only check here
if [ -d /usr/share/xsessions ]; then
    sudo install -Dm644 dgbwm.desktop /usr/share/xsessions/dgbwm.desktop
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
