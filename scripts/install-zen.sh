#!/bin/sh
# Instala Zen Browser desde Flathub en el usuario actual.
# Se ejecuta después del primer inicio de sesión, sin privilegios de root:
#
#   ./scripts/install-zen.sh

set -eu

if ! command -v flatpak >/dev/null 2>&1; then
    echo "flatpak no está en PATH. ¿Se instaló Guix System correctamente?" >&2
    exit 1
fi

flatpak --user remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak --user install -y flathub app.zen_browser.zen

# Actualizar el escritorio para que aparezca en wofi/waybar.
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

echo "Zen Browser instalado. Se puede abrir con:"
echo "  flatpak run app.zen_browser.zen"
