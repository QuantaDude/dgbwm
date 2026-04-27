#!/bin/sh
set -e

# --- XDG fallbacks ---
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

echo "[*] Using:"
echo "    CONFIG: $XDG_CONFIG_HOME"
echo "    DATA:   $XDG_DATA_HOME"

# --- Create dirs if missing ---
mkdir -p "$XDG_CONFIG_HOME"
mkdir -p "$XDG_DATA_HOME/dgbwm"

# --- Copy assets (wallpapers, scripts, etc.) ---
echo "[*] Copying assets..."
cp -r wp1.png wp2.png startdwm.sh "$XDG_DATA_HOME/dgbwm/"

# --- Build & install suckless tools ---
echo "[*] Installing dwm..."
cd dwm && sudo make clean install

echo "[*] Installing dwmblocks..."
cd ../dwmblocks-async && sudo make clean install

echo "[*] Installing st..."
cd ../st && sudo make clean install

echo "[*] Installing dunst..."
cd ../dunst && sudo make clean install

cd ..
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

    target="$XDG_CONFIG_HOME/$name"

    # remove existing config if it's not a symlink
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "    Removing existing $target"
        rm -rf "$target"
    fi

    echo "    Linking $name"
    ln -sf "$(pwd)/.config/$name" "$target"
done

echo "[✓] Done. Restart X session."
