;;; installer/tui/screen.scm --- Ensamblador de pantalla y layouts para CyberGuix
;;; Parte del CyberGuix Installer.

(define-module (installer tui screen)
  #:use-module (ice-9 format)
  #:use-module (installer tui ansi)
  #:use-module (installer tui box)
  #:export (render-installer-chrome
            render-demo-user-screen))

;;;
;;; 1. Chrome / Marco Global del Instalador (Header + Telemetría + Footer)
;;;

(define* (render-installer-chrome #:key (step "STEP 03/06: USER") (hardware "MS-7721") (online? #t))
  "Renderiza la barra superior de telemetría y el footer con los atajos globales."
  (let ((term-cols 80)
        (h-double (string-ref "═" 0)))

    ;; 1. Header superior
    (ansi-move-cursor 1 1)
    (let* ((prefix (paint-fg %color-border-dim "┌──[ "))
           (title1 (paint-fg %color-red-crimson "CYBERGUIX"))
           (sep    (paint-fg %color-border-dim " // "))
           (title2 (paint-fg %color-cyan-neon "SYSTEM INSTALLER"))
           (mid1   (paint-fg %color-border-dim " ]"))
           (left-len (+ 5 9 4 16 2)) ; "┌──[ CYBERGUIX // SYSTEM INSTALLER ]"
           (step-box (string-append (paint-fg %color-border-dim "[ ")
                                    (paint-fg %color-text-ice step)
                                    (paint-fg %color-border-dim " ]──┐")))
           (step-len (+ 2 (string-length step) 5))
           (padding-len (max 0 (- term-cols left-len step-len)))
           (filler (paint-fg %color-border-dim (make-string padding-len (string-ref "─" 0)))))
      (display (string-append prefix title1 sep title2 mid1 filler step-box)))

    ;; 2. Fila de telemetría con conectividad reactiva
    (ansi-move-cursor 2 1)
    (let* ((v (paint-fg %color-border-dim "│"))
           (net-tag (if online?
                        (paint-fg %color-matrix-green "ONLINE")
                        (paint-fg %color-red-crimson "OFFLINE (NO NET)")))
           (telemetry (format #f " STATUS: ~a │ HARDWARE: ~a │ SECURITY: ~a"
                              net-tag
                              (paint-fg %color-cyan-neon hardware)
                              (paint-fg %color-red-crimson "SUDO_ONLY")))
           (pad-len (if online? 14 5))
           (pad (make-string pad-len #\space)))
      (display (string-append v telemetry pad v)))

    ;; 3. Separador doble
    (ansi-move-cursor 3 1)
    (let ((sep-line (string-append "╞" (make-string (- term-cols 2) h-double) "╡")))
      (display (paint-fg %color-border-dim sep-line)))

    ;; 4. Separador inferior previo al footer (Fila 23)
    (ansi-move-cursor 23 1)
    (let ((bot-sep (string-append "├" (make-string (- term-cols 2) (string-ref "─" 0)) "┤")))
      (display (paint-fg %color-border-dim bot-sep)))

    ;; 5. Barra de comandos / Atajos (Fila 24)
    (ansi-move-cursor 24 1)
    (let* ((v (paint-fg %color-border-dim "│"))
           (k-tab   (paint-fg %color-cyan-neon "[TAB]"))
           (a-nav   (paint-fg %color-text-dim " NAVIGATE  │  "))
           (k-ent   (paint-fg %color-cyan-neon "[ENTER]"))
           (a-run   (paint-fg %color-text-dim " EXECUTE  │  "))
           (k-esc   (paint-fg %color-cyan-neon "[ESC]"))
           (a-back  (paint-fg %color-text-dim " BACK  │  "))
           (k-f1    (paint-fg %color-cyan-neon "[F1]"))
           (a-help  (paint-fg %color-text-dim " DIAGNOSTICO"))
           (content (string-append " " k-tab a-nav k-ent a-run k-esc a-back k-f1 a-help))
           (pad (make-string 10 #\space)))
      (display (string-append v content pad v)))

    ;; 6. Cierre inferior (Fila 25)
    (ansi-move-cursor 25 1)
    (let ((bottom-line (string-append "└" (make-string (- term-cols 2) (string-ref "─" 0)) "┘")))
      (display (paint-fg %color-border-dim bottom-line)))

    (force-output)))

;;;
;;; 2. Pantalla Demo de Demostración Visual (Paso de Usuario Administrador)
;;;

(define (render-demo-user-screen)
  "Renderiza la pantalla completa de demostración con la card de configuración de usuario."
  (ansi-clear-screen)
  (ansi-hide-cursor)

  ;; 1. Pintar fondo de pantalla y marco global
  (render-installer-chrome #:step "STEP 03/06: USER" #:hardware "MS-7721")

  ;; 2. Card Central (Fila 5, Columna 9, 64 columnas, 16 filas de alto)
  (draw-card 5 9 64 16
             #:title "CUENTA ADMINISTRADORA"
             #:title-fg %color-red-crimson
             #:border-fg %color-cyan-neon
             #:bg %color-bg-card)

  ;; 3. Textos explicativos dentro de la card
  (draw-text 7 13 "Defina las credenciales del usuario con acceso sudo."
             #:fg %color-text-ice)
  (draw-text 8 13 "! AVISO: Cuenta 'root' deshabilitada por seguridad."
             #:fg %color-amber-warn
             #:bold? #t)

  ;; 4. Inputs de usuario
  (draw-input 10 13 "FULL_NAME" "Matías Rossi" 24 #:focused? #f)
  (draw-input 12 13 "USER_NAME" "red-mat" 24 #:focused? #t)
  (draw-input 14 13 "PASSWORD" "mypassword123" 24 #:password? #t)
  (draw-input 16 13 "CONFIRM"  "mypassword123" 24 #:password? #t)

  ;; 5. Botones de acción
  (draw-button 18 22 "CANCEL" #:state 'normal)
  (draw-button 18 40 "PROCEED" #:state 'focused)

  (force-output))
