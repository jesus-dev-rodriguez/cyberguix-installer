#!/bin/sh
# Instala la CyberArch-Shell (Night City RICE de Hyprland) sobre Guix System.
#
# Adaptación del installer original de ARCANGEL0/CyberArch-Shell (target
# Arch Linux/AUR) al ecosistema Guix:
#
#   - No usa pacman ni AUR. Los componentes de Hyprland ya se declaran en el
#     manifiesto (install.scm, %desktop-packages).
#   - Clona el repositorio de la shell en ~/.local/share/cyberarch-shell.
#   - Crea el enlace simbólico ~/.config/hypr/themes/cyberpunk -> clon.
#   - Genera ~/.config/hypr/hyprland.lua para cargar el tema
#     (Hyprland >= 0.56 con soporte de configuracion via Lua).
#   - Instala las fuentes del tema en ~/.local/share/fonts/cyberarch.
#   - Instala cool-retro-term (AppImage) y el perfil de terminal "netrunner".
#
# Requisitos previos que debe satisfacer el manifiesto:
#   hyprland kitty wofi waybar swaybg swaylock wl-clipboard
#
# Uso:
#   ./scripts/install-cyberarch.sh
#   (ejecutar como red-mat; la mayor parte es por usuario)

set -eu

THEME_NAME="cyberpunk"
CLONE="$HOME/.local/share/cyberarch-shell"
THEME_DIR="$HOME/.config/hypr/themes/$THEME_NAME"
FONTS_SRC="$CLONE/assets/fonts"
FONTS_DIR="$HOME/.local/share/fonts/cyberarch"
CRT_BIN="$HOME/.local/bin/cool-retro-term"
CRT_URL="https://github.com/Swordfish90/cool-retro-term/releases/download/2.0.0-beta2/cool-retro-term-2.0.0-beta2.AppImage"
CRT_DESKTOP="$HOME/.local/share/applications/cool-retro-term.desktop"
NETRUNNER="$CLONE/scripts/netrunner-terminal"

if [ ! -d "$CLONE/.git" ]; then
    git clone --depth 1 https://github.com/ARCANGEL0/CyberArch-Shell.git "$CLONE"
fi

mkdir -p "$(dirname "$THEME_DIR")"
ln -sfn "$CLONE" "$THEME_DIR"

mkdir -p "$HOME/.config/hypr"
cat > "$HOME/.config/hypr/hyprland.lua" <<EOF
package.path = os.getenv("HOME") .. "/.config/hypr/themes/$THEME_NAME/?.lua;" .. (package.path or "")
require("theme")
require("user")
EOF
chmod 644 "$HOME/.config/hypr/hyprland.lua"

if [ -d "$FONTS_SRC" ]; then
    mkdir -p "$FONTS_DIR"
    cp -f "$FONTS_SRC"/* "$FONTS_DIR"/ 2>/dev/null || true
    fc-cache -f >/dev/null 2>&1 || true
fi

if [ ! -x "$CRT_BIN" ]; then
    mkdir -p "$HOME/.local/bin"
    wget -q -O "$CRT_BIN" "$CRT_URL"
    chmod +x "$CRT_BIN"
fi

mkdir -p "$(dirname "$CRT_DESKTOP")"
cat > "$CRT_DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=cool-retro-term
GenericName=Terminal Emulator
Exec=$CRT_BIN
Icon=utilities-terminal
Categories=System;TerminalEmulator;
Terminal=false
EOF

if [ -x "$CRT_BIN" ]; then
    if [ ! -d "$HOME/.local/share/cool-retro-term" ]; then
        "$CRT_BIN" >/dev/null 2>&1 || true
    fi
    sh "$NETRUNNER" >/dev/null 2>&1 || true
fi

echo "CyberArch-Shell instalado."
echo "  Tema:        $THEME_DIR -> $CLONE"
echo "  Hyprland lua: $HOME/.config/hypr/hyprland.lua"
echo "  Fuentes:     $FONTS_DIR"
echo "  cool-retro-term: $CRT_BIN"
echo ""
echo "Reinicia la sesion Hyprland (greeter/tuigreet -> hyprland-session) para que cargue el tema."
