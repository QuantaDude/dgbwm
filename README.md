# The Gruvbox Window Manager

![Screenshot1](./screenshot1.png)

![Screenshot2](./screenshot2.png)

![Screenshot3](./screenshot3.png)

This is my dwm configuration files. Here you'll find:
- dwm
- dwmblocks
- dunst
- st

And optional software with their configuration files:
- kew : terminal music player
- qutebrowser
- btop
- mpv
- vifm
- emacs

## Dependencies
Note: On **non** arch based distros, you'll need to install these by yourself if they aren't already.

- Xlibre or X11 server (duh)
- libx11
- feh
- pod2man
- pango
- libxrandr libxinerama libxss
- flameshot (optional, only for screenshots)

### Fonts required
On arch based systems the installation script will install these if missing.

- ttf-jetbrains-mono-nerd
- ttf-noto-emoji-monochrome
- ttf-hack-nerd

## Installation

```bash
git clone https://github.com/QuantaDude/dgbwm && cd dgbwm && chmod +x install_dgbwm.sh && sudo ./install_dgbwm.sh
```
or
```bash
git clone https://github.com/QuantaDude/dgbwm
cd dgbwm
chmod +x install_dgbwm.sh
sudo ./install_dgbwm.sh
```
## Configuration

If you want to change some settings after installing, let's say the wallpaper, you can do so by running:

```bash
dgbwm-config
```
You'll need to place your wallpapers in $HOME/.local/share/dgbwm/wallpapers/

- If you want to make changes to the keybinds, or make additional changes to the DWM or dwmblocks source code, apply patches to them, you should do so in the ``~/.local/share/dgbwm`` directory instead of the location you cloned this repository in. This is because dgbwm-config reads the ~/.local/ directory to rebuild dwm and dwmblocks incase you change the mode setting.

## Status Bar

Each block in the status bar has 3 to 4 block specific actions, press middle mouse to find out about each.
Each block's output can be cycled through by scrolling over them.

## Keybinds

(details coming soon)

## Other wonderful software to use along

- vifm
- qutebrowser
- ly (login screen/ manager)
- emacs
- btop 
