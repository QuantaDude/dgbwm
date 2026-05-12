#!/bin/sh
set -e
# =========================
# Gruvbox Colors
# =========================

RESET="\033[0m"

BG="#282828"

RED="\033[38;2;204;36;29m"
GREEN="\033[38;2;152;151;26m"
YELLOW="\033[38;2;215;153;33m"
BLUE="\033[38;2;69;133;136m"
PURPLE="\033[38;2;177;98;134m"
AQUA="\033[38;2;104;157;106m"
ORANGE="\033[38;2;214;93;14m"
GRAY="\033[38;2;168;153;132m"

BOLD="\033[1m"

section() {
    printf "\n${ORANGE}${BOLD}==> %s${RESET}\n" "$1"
}

info() {
    printf "${BLUE}[*] %s${RESET}\n" "$1"
}

success() {
    printf "${GREEN}[✓] %s${RESET}\n" "$1"
}

warn() {
    printf "${YELLOW}[!] %s${RESET}\n" "$1"
}

error() {
    printf "${RED}[✗] %s${RESET}\n" "$1"
}

question() {
    printf "${PURPLE}[?] %s${RESET}" "$1"
}

clear

printf "${ORANGE}${BOLD}"
cat << "EOF"

   ▄████  █     █░ ███▄ ▄███▓
  ██▒ ▀█▒▓█░ █ ░█░▓██▒▀█▀ ██▒
 ▒██░▄▄▄░▒█░ █ ░█ ▓██    ▓██░
 ░▓█  ██▓░█░ █ ░█ ▒██    ▒██
 ░▒▓███▀▒░░██▒██▓ ▒██▒   ░██▒
  ░▒   ▒ ░ ▓░▒ ▒  ░ ▒░   ░  ░
   ░   ░   ▒ ░ ░  ░  ░      ░
 ░ ░   ░   ░   ░  ░      ░
       ░     ░           ░

    Gruvbox Window Manager
         (Installer)

EOF
printf "${RESET}\n"

# --- XDG fallbacks ---
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"


info "Using:"
info "    CONFIG: $XDG_CONFIG_HOME"
info "    DATA:   $XDG_DATA_HOME"

# --- Create dirs if missing ---
mkdir -p "$XDG_CONFIG_HOME"
mkdir -p "$XDG_DATA_HOME/dgwm"

DATA_CONFIG_DIR="$XDG_DATA_HOME/dgwm/.config"

mkdir -p "$DATA_CONFIG_DIR/dgwm"


BASHRC="$HOME/.bashrc"

DEST="$XDG_DATA_HOME/dgwm"
CONFIG_FILE="$DEST/.config/dgwm/dgwmrc"

[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"

HAS_CONFIG=0
[ -f "$CONFIG_FILE" ] && HAS_CONFIG=1

# --- Copy DGWM to .local/share ---

info "Copying entire project to data dir..."

SRC="$(realpath .)"
DEST_REAL="$(realpath "$DEST" 2>/dev/null || echo "$DEST")"

if [ "$SRC" = "$DEST_REAL" ]; then
    warn "Already inside $DEST, skipping copy"
else
    mkdir -p "$DEST"

    # --- Backup if modified ---
    timestamp="$(date +%Y%m%d_%H%M%S)"

    backup_tree_if_different() {
        name="$1"
        src_dir="./$name"
        dst_dir="$DEST/$name"

        [ ! -d "$src_dir" ] && return 0
        [ ! -d "$dst_dir" ] && return 0

        # ignore binaries/build junk
        if diff -qr \
            --exclude="*.o" \
            --exclude="*.out" \
            --exclude="*.log" \
            --exclude="*.tar*" \
            "$src_dir" "$dst_dir" >/dev/null 2>&1
        then
            return 0
        fi

        backup_dir="$DEST/${name}.bak.$timestamp"

        warn "Changes detected in $name → backing up to $backup_dir"

        mkdir -p "$backup_dir"

        # safe copy (handles hidden files too)
        cp -r "$dst_dir"/. "$backup_dir/"
    }

    backup_tree_if_different "dwm"
    backup_tree_if_different "dwmblocks-async"
    backup_tree_if_different "st"

    # --- Copy files (non-destructive update) ---
    for f in .* *; do
        case "$f" in
            .|..) continue ;;
            .git|build) continue ;;
        esac

        # preserve user config if exists
        if [ -f "$CONFIG_FILE" ] && [ "$f" = ".config" ]; then
            warn "Preserving existing .config"
            continue
        fi

        find "$DEST" -type f \( \
            -name "*.o" -o \
            -name "dwm" -o \
            -name "st" -o \
            -name "dwmblocks" \
            \) \
            ! -path "$DEST/*.bak.*/*" \
            ! -path "$DEST/.config/*" \
            -delete 2>/dev/null
        
        cp -r "$f" "$DEST/"
    done
fi

success "Copy complete"
cd "$DEST" || {
    echo "Failed to enter $DEST"
    exit 1
}


DGWM_LIB="$XDG_DATA_HOME/dgwm/dgwm-utils.sh"

[ -f "$DGWM_LIB" ] && . "$DGWM_LIB"

# --- I have x11-ssh-askpass as a dependency because my openssh does not prompt me for a password, I need this
DEPS="feh xorg-server openssh xorg-xauth x11-ssh-askpass libx11 pango dbus libxrandr libxinerama libxss xdg-utils pod2man fontconfig xorg-mkfontdir xorg-mkfontscale curl ttf-jetbrains-mono-nerd ttf-fira-code"

FONTS="
JetBrainsMono Nerd Font
Fira Code
Noto Emoji
"

OPTIONAL_PKGS="flameshot vifm nvim emacs qutebrowser btop mpv kew wezterm alacritty"

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
    else
        DISTRO="unknown"
    fi
}

install_yay() {
    if command -v yay >/dev/null 2>&1; then
        success "yay already installed."
        return
    fi

    section "Installing yay"

    if ! command -v git >/dev/null 2>&1; then
        error "git is required to install yay."
        exit 1
    fi

    if ! command -v makepkg >/dev/null 2>&1; then
        error "base-devel / makepkg is required."
        exit 1
    fi

    TMP_DIR="/tmp/yay-install.$$"

    rm -rf "$TMP_DIR"

    git clone https://aur.archlinux.org/yay.git "$TMP_DIR"

    cd "$TMP_DIR" || exit 1

    makepkg -si --noconfirm

    cd "$DEST" || exit 1

    rm -rf "$TMP_DIR"

    success "yay installed successfully."
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

    font_cache="$(fc-list : family)"

    while IFS= read -r font; do
        [ -z "$font" ] && continue

        if ! printf '%s\n' "$font_cache" | grep -iq "\\b$font\\b"; then
            missing_fonts="$missing_fonts [$font]"
        fi
    done <<EOF
$FONTS
EOF

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
install_mini_neovim_ide() {
    MINI_NVIM_DIR="$HOME/.local/share/MiniNeovimIDE"

    echo ""
    section "MiniNeovimIDE Setup"

    if [ -d "$MINI_NVIM_DIR/.git" ]; then
        warn "MiniNeovimIDE already exists at:"
        info "$MINI_NVIM_DIR"

        question "Reinstall/update it? (y/n): "
        read ans

        case "$ans" in
            y|Y)
                info "Removing old MiniNeovimIDE..."
                rm -rf "$MINI_NVIM_DIR"
                ;;
            *)
                info "Skipping MiniNeovimIDE installation."
                return
                ;;
        esac
    fi

    info "Cloning MiniNeovimIDE..."

    git clone \
        https://github.com/QuantaDude/MiniNeovimIDE \
        "$MINI_NVIM_DIR"

    success "Repository cloned."

    if [ -f "$MINI_NVIM_DIR/install.sh" ]; then
        info "Running install.sh..."

        cd "$MINI_NVIM_DIR"
        chmod +x install.sh
        sh ./install.sh

        success "MiniNeovimIDE installed."
        cd "$DEST"
    else
        error "install.sh not found."
    fi
}

choose_optional_install() {
    missing="$1"

    [ -z "$missing" ] && return

    echo ""
    info "Optional tools not found:"
    
    i=1
    for pkg in $missing; do
        echo "  $i) $pkg"
        eval "opt_$i=\"$pkg\""
        i=$((i+1))
    done

    echo ""
    question "Select which ones to install (space-separated numbers)"
    question "Press Enter to skip all"

    info "Choice: "
    read choices

    [ -z "$choices" ] && {
        info "Skipping optional tools."
        return
    }

    selected=""

for c in $choices; do
    eval "pkg=\$opt_$c"

    selected="$selected $pkg"

    # Extra packages for vifm
    if [ "$pkg" = "vifm" ]; then
        selected="$selected \
        zathura \
        zathura-pdf-mupdf \
        zathura-djvu \
        poppler \
        atool \
        unzip \
        p7zip \
        unrar \
        tar \
        bat \
        eza \
        tree \
        ffmpegthumbnailer"
    fi
done

    info "Selected:$selected"

    if [ "$ARCH_BASED" -eq 1 ]; then
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed $selected
        else
            sudo pacman -S --needed $selected
        fi
    else
        echo ""
        error "Install manually:"
        
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
TERMINALS="st kitty ghostty alacritty wezterm konsole"
FILE_MANAGERS="vifm thunar pcmanfm ranger nnn lf dolphin"
TUI_FM="vifm ranger nnn lf"

EDITORS="vim nvim emacs helix micro ed kate"
AUDIO="kew mpv vlc"
VIDEO="mpv vlc"


IS_LAPTOP=0

if find /sys/class/power_supply -maxdepth 1 -name 'BAT*' | grep -q .; then
    IS_LAPTOP=1
    info "Laptop detected"
fi
# -- Detect Distro ---

detect_distro

info "Detected $DISTRO distro."
echo ""

case "$DISTRO" in
    arch|artix|endeavouros|manjaro|cachyos|garuda|arcolinux)
        ARCH_BASED=1
        ;;
    *)
        #if pacman exists, it's probably arch-based
        if command -v pacman >/dev/null 2>&1; then
            ARCH_BASED=1
        else
            ARCH_BASED=0
        fi
        ;;
esac

if [ "$ARCH_BASED" -eq 1 ]; then
    success "Arch-based system detected. Auto-install enabled."

      install_yay
else
    warn "Non-Arch distro detected."
    warn "You must manually install missing dependencies."
fi

echo ""



# --- Check for missing dependencies ---

info "[*] Checking dependencies..."
missing_pkgs="$(check_deps)"

info "[*] Checking fonts..."
missing_fonts="$(check_fonts)"

# --- Handle missing deps ---
if [ -n "$missing_pkgs" ]; then
    warn "Missing packages:$missing_pkgs"
fi

if [ -n "$missing_fonts" ]; then
    warn "Missing fonts:$missing_fonts"
fi

if [ -n "$missing_pkgs$missing_fonts" ]; then
    echo ""

    case $ARCH_BASED in
        1)
            question "Install missing components? (y/n): "
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
            if echo "$missing_fonts" | grep -iq "Noto Emoji"; then
                info "Installing Noto Emoji Monochrome font..."

                sh "$DEST/fonts/install-ttf-noto-emoji-mono.sh"
            fi

            else
                error "Aborting."
                exit 1
            fi
            ;;
        0)
            error "Install missing items manually."
            exit 1
            ;;
    esac
fi





# on first install, prompt the user to install the optional dependencies and assign the default multimedia applications
if [ "$HAS_CONFIG" -eq 0 ]; then
    missing_optional="$(check_optional_missing)"
    choose_optional_install "$missing_optional"

   
fi


timestamp="$(date +%Y%m%d_%H%M%S)"

backup_tree_if_different() {
    name="$1"              # dwm / st / dwmblocks-async
    src_dir="./$name"
    dst_dir="$DEST/$name"

    [ ! -d "$src_dir" ] && return
    [ ! -d "$dst_dir" ] && return

    # detect any difference
if diff -qr \
    --exclude="*.o" \
    --exclude="*.a" \
    --exclude="*.so" \
    --exclude="*.out" \
    --exclude="*.tar*" \
    --exclude="build" \
    --exclude="dwm" \
    --exclude="st" \
    --exclude="dwmblocks" \
    "$src_dir" "$dst_dir" >/dev/null 2>&1
then
    return 0
fi

    backup_dir="$DEST/${name}.bak.$timestamp"

    warn "[*] Changes detected in $name → backing up to $backup_dir"

    mkdir -p "$backup_dir"
    # copy entire existing tree (user-modified version)
    cp -r "$dst_dir"/. "$backup_dir/"
}



choose_wallpaper() {
    DIR="$HOME/.local/share/dgwm/wallpapers/"

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
        error "No wallpapers found in $DIR" >&2
        echo "$WALLPAPER"
        return
    fi

    echo "" >&2
    question "Select wallpaper (current: ${WALLPAPER:-none})" >&2
    echo "" >&2
    i=1
    for f in $files; do
        name=$(basename "$f")
        info "  $i) $name" >&2
        eval "wp_$i=\"$f\""
        i=$((i+1))
    done

    question "Choice [Enter to keep current]: " >&2
    read choice

    if [ -z "$choice" ]; then
        echo "$WALLPAPER"
        return
    fi

    eval "echo \$wp_$choice"
}

echo ""
question "Choose the text editor"
echo ""

editor=$(choose_program \
    "editor" \
    "$EDITOR" \
    $(detect_programs "$EDITORS"))

editor_desktop=$(get_desktop_file "$editor")
ED_NEEDS_TERM=0

if [ -n "$editor_desktop" ]; then
    info "Found desktop entry: $editor_desktop"

    term_flag=$(get_terminal_requirement "$editor_desktop")

    if [ -n "$term_flag" ]; then
        ED_NEEDS_TERM=$term_flag
        info "Terminal requirement detected: $ED_NEEDS_TERM"
    else
        warn "Could not determine Terminal= from .desktop"
    fi

    # set default editor for text
    info "Setting editor for all supported text MIME types"
    set_mime_from_desktop "$editor_desktop" "text/"
    xdg-mime default "$editor_desktop" "text/plain"


else
    error "No .desktop file found for $editor"

    # fallback: ask user
    echo ""
    question "Does '%s' require a terminal to run? (y/n): " "$editor"
    read ans

    case "$ans" in
        y|Y) ED_NEEDS_TERM=1 ;;
        *)   ED_NEEDS_TERM=0 ;;
    esac
fi

info "ED_NEEDS_TERM=$ED_NEEDS_TERM"


# remove old entries
sed -i '/^export EDITOR=/d' "$BASHRC"
sed -i '/^export VISUAL=/d' "$BASHRC"

# add new ones
echo "export EDITOR=$editor" >> "$BASHRC"
echo "export VISUAL=$editor" >> "$BASHRC"

echo ""
question "Choose the web browser to quick launch using the keybind (Super + F1)"
echo ""
browser=$(choose_program \
    "browser" \
    "$BROWSER" \
    $(detect_programs "$BROWSERS"))

browser_desktop=$(get_desktop_file "$browser")

if [ -n "$browser_desktop" ]; then
    info "Setting default xdg web browser desktop entry: $browser_desktop"
    xdg-settings set default-web-browser $browser_desktop
    xdg-settings set default-url-scheme-handler https $browser_desktop
else
    warn "Could not find .desktop file for $browser."
fi

echo ""
question "Choose the file manager to quick launch using the keybind (Super + F2)"
echo ""

fm=$(choose_program \
    "file manager" \
    "$FILE_MANAGER" \
    $(detect_programs "$FILE_MANAGERS"))

fm_desktop=$(get_desktop_file "$fm")

FM_NEEDS_TERM=0

if [ -n "$fm_desktop" ]; then
    info "Found desktop entry: $fm_desktop"

    term_flag=$(get_terminal_requirement "$fm_desktop")

    if [ "$term_flag" = "1" ] || [ "$term_flag" = "0" ]; then
        FM_NEEDS_TERM=$term_flag
        info "Terminal requirement detected: $FM_NEEDS_TERM"
    else
        warn "Could not determine Terminal= from .desktop"
    fi

    # set as default file manager
    xdg-mime default "$fm_desktop" "inode/directory"
    xdg-mime default "$fm_desktop" "x-scheme-handler/file"
    xdg-mime default "$fm_desktop" "text/vnd.typst"

else
    warn "No .desktop file found for $fm"

    # fallback: ask user
    echo ""
    question "Does '%s' require a terminal to run? (y/n): " "$fm"
    read ans

    case "$ans" in
        y|Y) FM_NEEDS_TERM=1 ;;
        *)   FM_NEEDS_TERM=0 ;;
    esac
fi

info "FM_NEEDS_TERM=$FM_NEEDS_TERM"

echo ""
question "Choose the resource monitor to quick launch from the status bar"
echo ""
res_monitor=$(choose_program \
    "system monitor" \
    "$MONITOR" \
    $(detect_programs "$RES_MONITORS"))

# --- Build & install suckless tools ---
echo ""
question "Do you want to install st (suckless terminal) y/n ?"
read install_st

if [ "$install_st" = "y" ] || [ "$install_st" = "Y" ]; then
    INSTALL_ST=1
    terminal="st"
else
    INSTALL_ST=0
    echo ""
    question "Choose the terminal to quick using the keybind (Super + t)"
    echo ""
    terminal=$(choose_program \
    "terminal" \
    "$TERMINAL" \
    $(detect_programs "$TERMINALS"))
fi

success "Selected terminal: $terminal"

if [ "$INSTALL_ST" -eq 1 ]; then
    info "Installing st..."
    cd st && sudo make clean install
    sudo make clean
    cd ..
else
    info "Skipping st installation"
fi

# ==========================================
# Shell selection
# ==========================================

echo ""
question "Choose your shell"
echo ""

user_shell=$(choose_program \
    "shell" \
    "$(basename "$SHELL")" \
    $SHELLS)

install_shell_if_missing "$user_shell"

shell_path="$(command -v "$user_shell")"

# prefer path listed in /etc/shells
if [ -f /etc/shells ]; then
    valid_shell="$(grep "/$(basename "$shell_path")$" /etc/shells | head -n1)"

    if [ -n "$valid_shell" ]; then
        shell_path="$valid_shell"
    fi
fi

success "Selected shell: $shell_path"

# remove old SHELL export
sed -i '/^export SHELL=/d' "$BASHRC"

echo "export SHELL=$shell_path" >> "$BASHRC"

export SHELL="$shell_path"

# change login shell
if command -v chsh >/dev/null 2>&1; then
    question "Set $user_shell as login shell using chsh? (y/n): "
    read ans

    case "$ans" in
        y|Y)
            chsh -s "$shell_path"
            success "Login shell changed to $shell_path"
            ;;
    esac
fi

section "Installing DWM"

echo ""

if [ "$HAS_CONFIG" -eq 1 ]; then
    question "Do you tinker often? (current: $MODE) (y/n, Enter to keep): "
else
  question "Do you tinker often? (y/n): "
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
    sudo make clean
else
    sudo make clean \
        TERMINAL="$terminal" \
        BROWSER="$browser" \
        FM="$fm" \
        FM_NEEDS_TERM=$FM_NEEDS_TERM \
        DYNAMIC=0 \
        install
    sudo make clean
fi

success "Installed DWM."

section "Installing dwmblocks-async"
echo ""

info "Weather configuration (current: ${WEATHER_MODE:-none})"

info "  1) Disable"
info "  2) IP-based"
info "  3) Location-based"
question "Choice [Enter to keep current]: "
read wchoice

if [ -z "$wchoice" ]; then
    :
else
    case "$wchoice" in
        1)
            WEATHER_MODE="none"
            ;;
        2)
            WEATHER_MODE="ip"
            ;;
        3)
            question "Enter location (e.g.: Delhi, or West_Delhi or XYZ_CITY_NAME): "
            read loc
            WEATHER_MODE="location:$loc"
            ;;
    esac
fi

[ "$WEATHER_MODE" = "none" ] && WEATHER_BLOCK=0 || WEATHER_BLOCK=1

cd ..
cd dwmblocks-async

if [ "$MODE" = "dynamic" ]; then
    sudo make clean DYNAMIC=1 WEATHER_BLOCK=$WEATHER_BLOCK IS_LAPTOP=$IS_LAPTOP install
    sudo make clean
else
    sudo make clean \
        TERMINAL="$terminal" \
        RES_MONITOR="$res_monitor" \
        WEATHER_BLOCK=$WEATHER_BLOCK \
        IS_LAPTOP=$IS_LAPTOP \
        install
    sudo make clean
fi

success "Installed dwmblocks-async"

section "Installing dunst"
cd ../dunst && sudo make clean install && sudo make clean
cd ..

echo ""
success "Installed dunst."

if [ "$HAS_CONFIG" -eq 1 ]; then
    question "Change wallpaper? (y/n, Enter to keep): "
    read ans
    [ "$ans" = "y" ] && WALLPAPER=$(choose_wallpaper)
else
    question "Select wallpaper? (y/n): "
    read ans
    [ "$ans" = "y" ] && WALLPAPER=$(choose_wallpaper)
fi


info "Saving config..."

cat > "$CONFIG_FILE" <<EOF
MODE=$MODE
SHELL=$shell_path
TERMINAL=$terminal
BROWSER=$browser
FILE_MANAGER=$fm
FM_NEEDS_TERM=$FM_NEEDS_TERM
EDITOR=$editor
ED_NEEDS_TERM=$ED_NEEDS_TERM
MONITOR=$res_monitor
WEATHER_MODE=$WEATHER_MODE
WALLPAPER=$WALLPAPER
IS_LAPTOP=$IS_LAPTOP
EOF

# --- Install start script ---
section "Installing dgwm-init, dgwm-config, and dgwm-run scripts"

sudo install -Dm755 dgwm-init /usr/local/bin/dgwm-init
sudo install -Dm755 dgwm-config /usr/local/bin/dgwm-config
sudo install -Dm755 dgwm-run /usr/local/bin/dgwm-run

success "Succesfully installed scripts."

# --- Install desktop entry ---
section "Installing dgwm.desktop"

sudo install -Dm644 dgwm.desktop /usr/local/share/xsessions/dgwm.desktop

# Also copy to /usr/share as some DMs only check here
if [ -d /usr/share/xsessions ]; then
    sudo install -Dm644 dgwm.desktop /usr/share/xsessions/dgwm.desktop
fi

success "Installed Desktop files."
# --- Configs ---

# ==========================================
# Neovim configuration setup
# ==========================================

if command -v nvim >/dev/null 2>&1; then
    if [ ! -d "$HOME/.local/share/MiniNeovimIDE" ]; then
        section "MiniNeovimIDE"
        echo ""
        question "Neovim detected. Install MiniNeovimIDE config? (y/n): "
        read install_mini

        case "$install_mini" in
            y|Y)
                install_mini_neovim_ide
                ;;
            *)
                info "Skipping MiniNeovimIDE setup."
                ;;
        esac
    else
        info "MiniNeovimIDE already installed."
    fi
fi
section "Linking configs"

for dir in .config/*; do
    name=$(basename "$dir")

    source_dir="$DATA_CONFIG_DIR/$name"
    target="$XDG_CONFIG_HOME/$name"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo ""
        warn "Config '$name' already exists at $target"
        question "Choose an action:"
        info     "1) Backup and overwrite"
        info     "2) Overwrite without backup"
        info     "3) Skip"

        question "Choice (1/2/3): "
        read choice

        case "$choice" in
            1)
		backup="$XDG_CONFIG_HOME/${name}.bak.$(date +%s)"
                
                info "    Backing up to $backup"
                rm -rf "$backup"
                mv "$target" "$backup"
                ;;
            2)
                warn "    Overwriting $target"
                rm -rf "$target"
                ;;
            3)
                info "    Skipping $name"
                continue
                ;;
            *)
                warn "    Invalid choice, skipping"
                continue
                ;;
        esac
    fi

    # Remove broken symlink if exists
    if [ -L "$target" ]; then
        rm -f "$target"
    fi

    info "    Linking $name"
    ln -sf "$source_dir" "$target"
done

success " symlinked configuration files."

section "Installing application .desktop files"

DESKTOP_SRC="./.desktop"
DESKTOP_DEST="/usr/share/applications"


if [ -d "$DESKTOP_SRC" ]; then
    for file in "$DESKTOP_SRC"/*.desktop; do
        [ -e "$file" ] || continue

        name=$(basename "$file")
        cmd="${name%.desktop}"

        if command -v $cmd >/dev/null 2>&1; then
            info "    Installing $name → $DESKTOP_DEST"
            sudo install -Dm644 "$file" "$DESKTOP_DEST/$name"
        fi
    done

    if command -v update-desktop-database >/dev/null 2>&1; then
        sudo update-desktop-database "$DESKTOP_DEST"
    fi
else
    warn "No .desktop directory found, skipping"
fi


if [ "$HAS_CONFIG" -eq 0 ]; then
    echo ""
    info "Setting feh as the default image viewer..."

    set_mime_from_desktop "feh.desktop" "image/"

    echo ""

    info "Setting default audio player..."

    audio_player=""

    if command -v kew >/dev/null 2>&1; then
        audio_player="kew"
    elif command -v mpv >/dev/null 2>&1; then
        audio_player="mpv"
    elif command -v vlc >/dev/null 2>&1; then
        audio_player="vlc"
    fi

    if [ -n "$audio_player" ]; then
        audio_desktop=$(get_desktop_file "$audio_player")

        if [ -n "$audio_desktop" ]; then
            success "Using $audio_player ($audio_desktop) for all audio types"
            set_mime_from_desktop "$audio_desktop" "audio/"
        else
            error "not found"
        fi
    fi

    echo ""
    info "Setting default video player..."

    video_player=""

    if command -v mpv >/dev/null 2>&1; then
        video_player="mpv"
    elif command -v vlc >/dev/null 2>&1; then
        video_player="vlc"
    fi

    if [ -n "$video_player" ]; then
        video_desktop=$(get_desktop_file "$video_player")

    if [ -n "$video_desktop" ]; then
        success "Using $video_player ($video_desktop) for all video types"
        set_mime_from_desktop "$video_desktop" "video/"
    fi
    
    fi

fi


success "[✓] Done. Restart X session."
