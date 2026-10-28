# Dotfiles y configuración de Guix System — MS-7721

Repositorio con la configuración completa del sistema Guix, los archivos de
usuario y los scripts necesarios para reinstalar o mantener el equipo.

El objetivo es un multiboot **Windows + Ubuntu + Guix System** en el mismo
disco, usando solo la partición de Guix para el sistema nuevo. Windows y
Ubuntu no se modifican.

## Hardware

- CPU: AMD A10-7860K (Kaveri, sin AVX2)
- GPU: AMD Radeon RX 460 (Baffin, `amdgpu`)
- RAM: 23 GiB
- Ethernet: Realtek RTL8111
- Audio: AMD FCH Azalia
- Sin WiFi ni Bluetooth

## Particiones

| Partición | Tamaño | Uso | UUID |
|---|---|---|---|
| `/dev/sda1` | 100 MiB | ESP compartida (Windows/Ubuntu/Guix) | `9D28-B435` |
| `/dev/sda2` | 16 MiB | Reservada de Microsoft | — |
| `/dev/sda3` | 487.6 GiB | Windows (NTFS) | — |
| `/dev/sda4` | 535 MiB | Recuperación de Windows | — |
| `/dev/sda5` | 300.4 GiB | Datos compartidos (ext4), montada en `/mnt/datos` | `5e0e4652-59c0-4236-a933-b3be3434a28d` |
| `/dev/sda6` | 3.8 GiB | Swap | `ea0f0ef1-ef90-4c2c-ab4c-5d31ae95e932` |
| `/dev/sda7` | 93.1 GiB | Ubuntu 26.04 | `82514266-6533-44eb-816a-ace4be045cd8` |
| `/dev/sda8` | 45.9 GiB | Guix System (ext4), raíz | `cb76479d-aad8-4c5e-9a9c-34380af289e4` |

La ESP es compartida. GRUB de Guix añade entradas para Ubuntu
(`/EFI/ubuntu/shimx64.efi`) y Windows
(`/EFI/Microsoft/Boot/bootmgfw.efi`) sin borrar los cargadores existentes.

## Sistema

- Guix System con canal **Nonguix** (kernel LTS, firmware no libre y
  microcódigo de CPU).
- Kernel `linux-lts` (6.18.x), `amdgpu-firmware`, `radeon-firmware`,
  `realtek-firmware` y `microcode-initrd`.
- Hyprland, Waybar, Wofi, Kitty, Mako, Thunar, Swaybg, Swaylock.
- `greetd` + `tuigreet` como gestor de inicio (VT7).
- PipeWire + WirePlumber + pavucontrol para audio y micrófono.
- NetworkManager, UPower, UDisks, Polkit y `hyprpolkitagent`.
- Flatpak para Zen Browser.
- OpenCode CLI 2.1.4 empaquetado desde el binario `baseline` (sin AVX2).

## Usuario y acceso

- Usuario: `red-mat` (UID/GID 1000)
- Contraseña inicial: `123456` — **cambiarla con `passwd` después del primer
  inicio**.
- Shell: Zsh.
- `sudo` habilitado por pertenencia al grupo `wheel`.
- El acceso directo de `root` está deshabilitado (`root` tiene `*` como
  contraseña). Para tareas administrativas: `sudo -i` o `sudo comando`.
- Hostname: `MS-7721`.
- Zona horaria: `America/Argentina/Jujuy`.
- Locale: `es_ES.utf8`.
- Teclado: `latam`.

## Carpetas de datos

La partición `/dev/sda5` se monta en `/mnt/datos`. Al crear la cuenta, un
servicio de activación crea enlaces simbólicos desde el home:

```
~/Documentos   -> /mnt/datos/Documentos
~/Descargas    -> /mnt/datos/Descargas
~/Imágenes     -> /mnt/datos/Imágenes
~/Vídeos       -> /mnt/datos/Vídeos
~/Proyectos    -> /mnt/datos/Proyectos
~/scripts      -> /mnt/datos/scripts
~/SteamLibrary -> /mnt/datos/SteamLibrary
```

Los archivos de configuración (dotfiles) **no** se enlazan a la partición de
datos: viven en el home y este repositorio es la copia maestra para
reinstalaciones.

Si hiciera falta recrear los enlaces manualmente:

```sh
for d in Documentos Descargas Imágenes Vídeos Proyectos scripts SteamLibrary; do
    [ -e "$HOME/$d" ] || ln -s "/mnt/datos/$d" "$HOME/$d"
done
```

## Estructura del repositorio

```
guix-system/
├── install.scm                    # Manifesto de instalación de Guix System
├── guix/
│   └── nonguix-signing-key.pub    # clave pública de Nonguix
├── channels/                      # Canales externos
│   ├── nonguix.scm                 # Canal externo: Nonguix
│   └── guix.scm                    # Canal externo: Guix
├── packages/                      # Paquetes locales (construidos en el repo)
│   └── opencode.scm               # Paquete local: OpenCode (no público en canales)
├── home/
│   ├── .zshrc
│   ├── .config/
│   │   ├── hypr/hyprland.conf
│   │   ├── waybar/{config.jsonc,style.css}
│   │   ├── wofi/{config,style.css}
│   │   ├── kitty/kitty.conf
│   │   ├── mako/config
│   │   ├── gtk-3.0/settings.ini
│   │   ├── gtk-4.0/settings.ini
│   │   ├── mimeapps.list
│   │   └── user-dirs.dirs
│   └── .local/
│       ├── bin/hyprland-session
│       └── share/applications/app.zen_browser.zen.desktop
└── scripts/
    ├── install-cyberarch.sh
    └── install-zen.sh
```

`install.scm` copia `home/` al home del usuario a través de `/etc/skel`. Para
ello usa la variable `GUIX_DOTFILES`, que debe apuntar a la raíz de este
repositorio al construir o instalar:

```sh
export GUIX_DOTFILES=/ruta/a/guix-system
guix system build "$GUIX_DOTFILES/install.scm"
```

Si no se define, se usa `/mnt/datos/Proyectos/guix-system`.

## CyberArch-Shell (GUI base)

La shell **CyberArch** (Night City RICE de Hyprland, ver
https://github.com/ARCANGEL0/CyberArch-Shell) se integra como base del entorno
gráfico del sistema.

- `./scripts/install-cyberarch.sh` clona el repositorio de la shell, crea el
  enlace simbólico `~/.config/hypr/themes/cyberpunk` y genera
  `~/.config/hypr/hyprland.lua` para cargar el tema.
- El manifiesto copia `~/.config/hypr/hyprland.lua` vía `skeletons`.

### Personalización por usuario (sin instalaciones/modificaciones globales)

- Temas, keybinds, widgets, wallpapers y overrides viven en el home del
  usuario (`~/.config/hypr/themes/cyberpunk/`, `~/.config/hypr/user.lua`).
- Paquetes adicionales se instalan en el **perfil del usuario** con
  `guix package -i <paquete>`; el PATH de la sesión Hyprland
  (`hyprland-session`) e `zsh` ya incluye `~/.guix-profile/bin`.
- Flatpak por usuario: `./scripts/install-zen.sh`.

## Reinstalar Guix System

Requisitos: livecd de Guix actualizado, conexión a Internet, la partición
`/dev/sda8` ya creada y la ESP intacta con Windows/Ubuntu.

La instalación es puramente declarativa: el sistema se construye desde el
manifiesto `install.scm` con `guix system init` (no existe script de
instalación).

```sh
# 1. Autorizar la clave de Nonguix en el sistema live
guix archive --authorize < guix/nonguix-signing-key.pub

# 2. Montar las particiones ya preparadas
mount /dev/disk/by-uuid/cb76479d-aad8-4c5e-9a9c-34380af289e4 /mnt
mkdir -p /mnt/boot/efi
mount /dev/disk/by-uuid/9D28-B435 /mnt/boot/efi

# 3. Instalar el sistema desde el manifiesto declarativo
export GUIX_DOTFILES=/mnt/datos/Proyectos/guix-system
sudo guix system init "$GUIX_DOTFILES/install.scm" /mnt \
  --substitute-urls="https://substitutes.nonguix.org https://ci.guix.gnu.org https://bordeaux.guix.gnu.org"
```

No se formatea ni se re-particiona nada; Guix genera el sistema sobre la
partición destino.

Al terminar, GRUB de Guix queda instalado en la ESP y arranca primero. Las
entradas de Ubuntu y Windows siguen disponibles en el menú.

## Primer inicio

1. Iniciar sesión en `tuigreet` con `red-mat` / `123456`.
2. Abrir Kitty (`Super+Return`) y cambiar la contraseña:

   ```sh
   passwd
   ```

3. Comprobar audio y micrófono:

   ```sh
   wpctl status
   pavucontrol
   ```

4. Zen Browser ya está instalado en el home (`~/.local/share/flatpak`). Si
   faltara, ejecutar `./scripts/install-zen.sh`.
5. Abrir Zen con `Super+B` o desde Wofi (`Super+D`).
6. Comprobar OpenCode:

   ```sh
   opencode --version
   ```

## Atajos de Hyprland

| Atajo | Acción |
|---|---|
| `Super+Return` | Kitty |
| `Super+D` | Wofi (aplicaciones) |
| `Super+E` | Thunar |
| `Super+B` | Zen Browser |
| `Super+A` | pavucontrol |
| `Super+Q` | Cerrar ventana |
| `Super+L` | Bloquear pantalla |
| `Super+1..9` | Cambiar de espacio |
| `Super+Shift+1..9` | Mover ventana a espacio |
| `Super+flechas` | Cambiar foco |
| `Super+M` | Salir de Hyprland |

## Actualizar el sistema

```sh
guix pull
sudo guix system reconfigure /run/current-system/etc/config.scm
```

Si se actualiza el canal Nonguix, regenerar `channels/nonguix.scm` con las
nuevas revisiones y subir el repositorio.

## Solución de problemas

- **Sin red:** `nmcli device status` y `nmcli connection up <nombre>`.
- **Sin audio:** comprobar `wpctl status`, reiniciar `pipewire`,
  `pipewire-pulse` y `wireplumber`.
- **Zen no arranca:** ejecutar `flatpak run app.zen_browser.zen` en Kitty y
  revisar el error; reinstalar con `./scripts/install-zen.sh`.
- **GRUB no muestra Windows/Ubuntu:** entrar al firmware y elegir el
  cargador de Guix; las entradas `chain-loader` apuntan a los shim de la ESP.
- **OpenCode no arranca:** verificar `ldd "$(command -v opencode)"`; el
  binario se parchea al construir con el loader de glibc de Guix.

## Notas

- La partición de datos sigue siendo accesible desde Ubuntu en `/dev/sda5`.
- No se movieron dotfiles ni configuraciones a `/mnt/datos`.
- El repositorio puede copiarse a otro medio; el manifiesto `install.scm` solo
  necesita que `GUIX_DOTFILES` apunte a él.
