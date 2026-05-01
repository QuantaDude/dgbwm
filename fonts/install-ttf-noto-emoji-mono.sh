#!/bin/sh

set -e

pkgname="ttf-noto-emoji-monochrome"
pkgver="1.1.0"
_commit="b80db438fe644bd25e0032661ab66fa72f2af0e2"

FONT_DIR="/usr/share/fonts/TTF"
LICENSE_DIR="/usr/share/licenses/$pkgname"

BASE_URL="https://github.com/zjaco13/Noto-Emoji-Monochrome/raw/${_commit}"

echo "[*] Creating directories..."
sudo install -dm 755 "$FONT_DIR"
sudo install -dm 755 "$LICENSE_DIR"

echo "[*] Downloading fonts..."

download_and_install() {
    name="$1"
    url="$BASE_URL/fonts/$name"

    tmpfile="$(mktemp)"
    curl -L "$url" -o "$tmpfile"

    sudo install -m 644 "$tmpfile" "$FONT_DIR/$name"
    rm -f "$tmpfile"
}

download_and_install "NotoEmoji-Medium.ttf"
download_and_install "NotoEmoji-Bold.ttf"
download_and_install "NotoEmoji-SemiBold.ttf"
download_and_install "NotoEmoji-Light.ttf"
download_and_install "NotoEmoji-Regular.ttf"
download_and_install "NotoEmoji-VariableFont_wght.ttf"

echo "[*] Installing license..."
tmpfile="$(mktemp)"
curl -L "$BASE_URL/OFL.txt" -o "$tmpfile"
sudo install -Dm644 "$tmpfile" "$LICENSE_DIR/LICENSE"
rm -f "$tmpfile"

echo "[*] Updating font cache..."
sudo fc-cache -f >/dev/null
sudo mkfontscale "$FONT_DIR"
sudo mkfontdir "$FONT_DIR"

echo "[✔] Done. ttf-noto-emoji-monochrome (Noto Emoji, monochrome) installed."
