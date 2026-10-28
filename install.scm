;; -*- mode: scheme; -*-
;; Manifesto de instalación de Guix System para el equipo MS-7721.
;;
;; Este manifiesto está pensado para reinstalar el sistema desde un
;; livecd de Guix, conservando Windows y Ubuntu en el mismo disco.
;;
;; Instalación declarativa (sin scripts de instalación):
;;
;;   export GUIX_DOTFILES=/mnt/datos/Proyectos/guix-system
;;   sudo guix system init "$GUIX_DOTFILES/install.scm" /mnt
;;
;; Los archivos de configuración de usuario viven en home/ y se copian
;; al crear la cuenta mediante /etc/skel.

(use-modules (gnu)
             (gnu services)
             (gnu services base)
             (gnu services dbus)
             (gnu services desktop)
             (gnu services networking)
             (gnu services sound)
             (gnu services xorg)
             (gnu system shadow)
             (gnu system locale)
             (gnu packages)
             (gnu packages admin)
             (gnu packages base)
             (gnu packages bash)
             (gnu packages elf)
             (gnu packages freedesktop)
             (gnu packages linux)
             (gnu packages package-management)
             (gnu packages polkit)
             (gnu packages pulseaudio)
             (gnu packages shells)
             (gnu packages terminals)
             (gnu packages video)
             (gnu packages wm)
             (gnu packages xdisorg)
             (gnu packages xorg)
             (nongnu packages linux)
             (nongnu system linux-initrd)
             (guix build-system copy)
             (guix channels)
             (guix download)
             (guix gexp)
             (guix licenses)
             (guix packages))

;; ---------------------------------------------------------------------------
;; Repositorio de dotfiles y archivos de usuario
;; ---------------------------------------------------------------------------

(define %dotfiles
  (or (getenv "GUIX_DOTFILES")
      "/mnt/datos/Proyectos/guix-system"))

(define (dotfile source name)
  "Devuelve el archivo SOURCE dentro del repositorio de dotfiles."
  (local-file (string-append %dotfiles "/" source) name))

(define %nonguix-key
  (plain-file
   "nonguix-signing-key.pub"
   "(public-key
 (ecc
  (curve Ed25519)
  (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))"))

;; Canales externos y paquetes internos definidos en el repositorio.
(load (string-append %dotfiles "/channels/nonguix.scm"))
(load (string-append %dotfiles "/channels/guix.scm"))
(define %external-channels
  (list %nonguix-channel %guix-channel))

(load (string-append %dotfiles "/packages/opencode.scm"))

;; ---------------------------------------------------------------------------
;; Paquetes
;; ---------------------------------------------------------------------------

(define %desktop-packages
  (map specification->package
       '("hyprland"
         "waybar"
         "wofi"
         "kitty"
         "thunar"
         "swaybg"
         "swaylock"
         "mako"
         "hyprpolkitagent"
         "pipewire"
         "wireplumber"
         "alsa-utils"
         "pavucontrol"
         "playerctl"
         "brightnessctl"
         "wl-clipboard"
         "grim"
         "slurp"
         "flatpak"
         "xdg-desktop-portal"
         "xdg-desktop-portal-gtk"
         "xdg-desktop-portal-hyprland"
         "xdg-utils"
         "xdg-user-dirs"
         "shared-mime-info"
         "desktop-file-utils"
         "hicolor-icon-theme"
         "adwaita-icon-theme"
         "gnome-themes-extra"
         "font-dejavu"
         "font-liberation"
         "font-google-noto-emoji"
         "font-awesome"
         "dbus"
         "git"
         "ripgrep"
         "htop"
         "mpv"
         "zsh")))


;; ---------------------------------------------------------------------------
;; Enlaces de las carpetas de datos dentro del home
;; ---------------------------------------------------------------------------

(define %data-home-links
  #~(begin
      (define home "/home/red-mat")
      (define (make-data-link name)
        (let ((link (string-append home "/" name))
              (target (string-append "/mnt/datos/" name)))
          (catch 'system-error
            (lambda ()
              (unless (or (file-exists? link)
                          (false-if-exception (lstat link)))
                (symlink target link)))
            (lambda _
              #t))))
      (when (file-exists? home)
        (for-each make-data-link
                  '("Documentos"
                    "Descargas"
                    "Imágenes"
                    "Vídeos"
                    "Proyectos"
                    "scripts"
                    "SteamLibrary")))
      #t))

;; ---------------------------------------------------------------------------
;; Sistema
;; ---------------------------------------------------------------------------

(operating-system
  (host-name "MS-7721")
  (timezone "America/Argentina/Jujuy")
  (locale "es_ES.utf8")
  (locale-definitions
   (cons (locale-definition (name "es_ES.utf8") (source "es_ES"))
         %default-locale-definitions))
  (keyboard-layout (keyboard-layout "latam"))

  ;; Nonguix: kernel LTS, firmware no libre y microcódigo de CPU.
  (kernel linux-lts)
  (initrd microcode-initrd)
  (firmware (list amdgpu-firmware
                  radeon-firmware
                  realtek-firmware))

  (bootloader
   (bootloader-configuration
    (bootloader grub-efi-bootloader)
    (targets '("/boot/efi"))
    (keyboard-layout keyboard-layout)
    (default-entry 0)
    (timeout 10)
    (menu-entries
     (list
      (menu-entry
       (label "Ubuntu 26.04")
       (device (uuid "9D28-B435" 'fat))
       (chain-loader "/EFI/ubuntu/shimx64.efi"))
      (menu-entry
       (label "Windows")
       (device (uuid "9D28-B435" 'fat))
       (chain-loader "/EFI/Microsoft/Boot/bootmgfw.efi"))))))

  (file-systems
   (cons* (file-system
            (mount-point "/")
            (device (uuid "cb76479d-aad8-4c5e-9a9c-34380af289e4" 'ext4))
            (type "ext4")
            (options "noatime"))
          (file-system
            (mount-point "/boot/efi")
            (device (uuid "9D28-B435" 'fat))
            (type "vfat"))
          (file-system
            (mount-point "/mnt/datos")
            (device (uuid "5e0e4652-59c0-4236-a933-b3be3434a28d" 'ext4))
            (type "ext4")
            (options "noatime")
            (create-mount-point? #t))
          %base-file-systems))

  (swap-devices
   (list (swap-space
          (target (uuid "ea0f0ef1-ef90-4c2c-ab4c-5d31ae95e932")))))

  (users
   (cons* (user-account
           (name "red-mat")
           (comment "Jesus Matias")
           (group "red-mat")
           (uid 1000)
           (home-directory "/home/red-mat")
           (shell (file-append zsh "/bin/zsh"))
           (password "$6$xVHajgNxje8Vq7lm$fLsDanfcwJ.qlkRp62HRFHGKW264rIrVOoeN8P1B7P2ZCZ6ZQ4YxfBXJ0sRc7uqAifKnA8CbamyMq25J1zoni.")
           (supplementary-groups
            '("wheel" "audio" "video" "input" "netdev" "lp"
              "render" "kvm")))
          (user-account
           (name "root")
           (comment "System administrator")
           (group "root")
           (uid 0)
           (home-directory "/root")
           (shell (file-append bash "/bin/bash"))
           (password "*"))
          %base-user-accounts))

  (groups
   (cons* (user-group (name "red-mat") (id 1000))
          (user-group (name "render") (system? #t))
          %base-groups))

  (packages
   (append (list opencode)
           %desktop-packages
           %base-packages))

  (skeletons
   (append
    (list
     (cons ".zshrc"
           (dotfile "home/.zshrc" "zshrc"))
     (cons ".config/hypr/hyprland.conf"
           (dotfile "home/.config/hypr/hyprland.conf" "hyprland.conf"))
     (cons ".config/hypr/hyprland.lua"
           (dotfile "home/.config/hypr/hyprland.lua" "hyprland.lua"))
     (cons ".config/waybar/config.jsonc"
           (dotfile "home/.config/waybar/config.jsonc" "waybar-config.jsonc"))
     (cons ".config/waybar/style.css"
           (dotfile "home/.config/waybar/style.css" "waybar-style.css"))
     (cons ".config/wofi/config"
           (dotfile "home/.config/wofi/config" "wofi-config"))
     (cons ".config/wofi/style.css"
           (dotfile "home/.config/wofi/style.css" "wofi-style.css"))
     (cons ".config/kitty/kitty.conf"
           (dotfile "home/.config/kitty/kitty.conf" "kitty.conf"))
     (cons ".config/mako/config"
           (dotfile "home/.config/mako/config" "mako-config"))
     (cons ".config/gtk-3.0/settings.ini"
           (dotfile "home/.config/gtk-3.0/settings.ini" "gtk3-settings.ini"))
     (cons ".config/gtk-4.0/settings.ini"
           (dotfile "home/.config/gtk-4.0/settings.ini" "gtk4-settings.ini"))
     (cons ".config/mimeapps.list"
           (dotfile "home/.config/mimeapps.list" "mimeapps.list"))
     (cons ".config/user-dirs.dirs"
           (dotfile "home/.config/user-dirs.dirs" "user-dirs.dirs"))
     (cons ".local/bin/hyprland-session"
           (dotfile "home/.local/bin/hyprland-session" "hyprland-session"))
     (cons ".local/share/applications/app.zen_browser.zen.desktop"
           (dotfile "home/.local/share/applications/app.zen_browser.zen.desktop"
                    "zen.desktop")))
    (default-skeletons)))

  (services
   (append
    (list
     (service elogind-service-type)
     (service dbus-root-service-type)
     (service polkit-service-type)
     polkit-wheel-service
     (service network-manager-service-type)
     (service udisks-service-type)
     (service upower-service-type)
     (service ntp-service-type)
     (service x11-socket-directory-service-type)
     (service greetd-service-type
              (greetd-configuration
               (allow-empty-passwords? #f)
               (terminals
                (list
                 (greetd-terminal-configuration
                  (terminal-vt "7")
                  (terminal-switch #t)
                  (default-session-command
                   (greetd-user-session
                    (command (file-append tuigreet "/bin/tuigreet"))
                    (command-args
                     '("--time"
                       "--asterisks"
                       "--remember"
                       "--greeting" "Guix System"
                       "--cmd" "/home/red-mat/.local/bin/hyprland-session")))))))))
     (simple-service 'data-home-links activation-service-type
                     (list %data-home-links)))
    (modify-services %base-services
      (guix-service-type config =>
                         (guix-configuration
                          (inherit config)
                          (channels %external-channels)
                          (substitute-urls
                           (cons "https://substitutes.nonguix.org"
                                 %default-substitute-urls))
                          (authorized-keys
                           (cons %nonguix-key
                                 %default-authorized-guix-keys))))))))
