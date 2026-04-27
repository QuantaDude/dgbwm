# The Dynamic GruvBox Window Manager

![Screenshot1](./screenshot1.png)

![Screenshot2](./screenshot2.png)

![Screenshot3](./screenshot3.png)

This is my dwm configuration files. Here you'll find:
- dwm
- dwmblocks
- dunst
- st

## Dependencies

- Xlibre or X11 (duh)
- feh

### Fonts required

- ttf-jetbrains-mono-nerd
- ttf-nerd-fonts-symbols 

## Installation
```bash
git clone https://github.com/QuantaDude/dgbwm
cd dgbwm
cd dwm
make && sudo make install
cd ../dwmblocks
# Change your location in blocks.h for the weather widget
make && sudo make install
cd ..
# This will overwrite your previous configuration
cp -r .config/ ~/
cp startdwm.sh /usr/local/bin/
```

If you use a display manager
```bash
sudo cp dwm.desktop /usr/local/share/xsessions/
```
If you don't
```bash
echo "exec /usr/local/bin/startdwm.sh" >> ~/.xinitrc
```

## Other wonderful software to use along

- vifm
- qutebrowser
- ly (login screen/ manager)
- emacs
- 
