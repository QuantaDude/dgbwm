#!/bin/sh

set -e

pkgname="ttf-noto-emoji-monochrome"

FONT_DIR="/usr/share/fonts/TTF"
LICENSE_DIR="/usr/share/licenses/$pkgname"

echo "[*] Removing Noto Emoji Monochrome fonts..."

remove_font() {
    file="$FONT_DIR/$1"

    if [ -f "$file" ]; then
        echo "    Removing $file"
        sudo rm -f "$file"
    else
        echo "    Skipping $file (not found)"
    fi
}

remove_font "NotoEmoji-Medium.ttf"
remove_font "NotoEmoji-Bold.ttf"
remove_font "NotoEmoji-SemiBold.ttf"
remove_font "NotoEmoji-Light.ttf"
remove_font "NotoEmoji-Regular.ttf"
remove_font "NotoEmoji-VariableFont_wght.ttf"

echo "[*] Removing license..."
if [ -d "$LICENSE_DIR" ]; then
    sudo rm -rf "$LICENSE_DIR"
else
    echo "    License directory not found"
fi

echo "[*] Updating font cache..."
sudo fc-cache -f >/dev/null
sudo mkfontscale "$FONT_DIR"
sudo mkfontdir "$FONT_DIR"

echo "[✔] Uninstalled ttf-noto-emoji-monochrome."
