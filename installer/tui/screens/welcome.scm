;;; installer/tui/screens/welcome.scm --- Pantalla 1: Bienvenida CyberGuix (100% Dinamica)
;;; Parte del CyberGuix Installer.

(define-module (installer tui screens welcome)
  #:use-module (ice-9 copy-tree)
  #:use-module (ice-9 format)
  #:use-module (installer tui ansi)
  #:use-module (installer tui box)
  #:use-module (installer tui screen)
  #:export (make-welcome-state
            welcome-handle-key
            render-welcome-screen))

(define (make-welcome-state)
  `((focus-btn . 1))) ; 0 = SALIR AL SHELL, 1 = INICIAR INSTALACION

(define (welcome-handle-key state key)
  "Maneja la navegación entre botones en la pantalla de bienvenida."
  (let ((focus (assq-ref state 'focus-btn)))
    (case key
      ((left right tab)
       (let ((new-focus (if (= focus 0) 1 0)))
         `((state . ,(assq-set! (copy-tree state) 'focus-btn new-focus)))))
      ((enter)
       (if (= focus 1)
           '((action . next))
           '((action . quit))))
      (else
       `((state . ,state))))))

(define* (render-welcome-screen state #:key (hw-data #f))
  "Renderiza la pantalla inicial interactiva con telemetría de hardware 100% dinámica."
  (let* ((focus (assq-ref state 'focus-btn))
         (cpu-name  (or (and hw-data (assq-ref hw-data 'cpu-name)) "CPU x86_64"))
         (cpu-cores (or (and hw-data (assq-ref hw-data 'cpu-cores)) 1))
         (ram-gib   (or (and hw-data (assq-ref hw-data 'ram-gib)) 0.0))
         (boot-mode (or (and hw-data (assq-ref hw-data 'boot-mode)) "Desconocido"))
         (mobo      (or (and hw-data (assq-ref hw-data 'motherboard)) "Sistema Host"))
         (gpu-desc  (or (and hw-data (assq-ref hw-data 'gpu-desc)) "Controlador VGA"))
         (online?   (if hw-data (assq-ref hw-data 'online?) #f)))

    (ansi-clear-screen)
    (render-installer-chrome #:step "STEP 01/06: WELCOME"
                             #:hardware mobo
                             #:online? online?)

    ;; Card central
    (draw-card 5 6 70 16
               #:title "CYBER GUIX // INSTALADOR DECLARATIVO"
               #:title-fg %color-red-crimson
               #:border-fg %color-cyan-neon
               #:bg %color-bg-card)

    ;; Banner ASCII matricial: CYBER GUIX (Letra 'B' con doble lazo diferenciada de 'D')
    (draw-text 7 8  "█▀▀ █▄█ █▀▄ █▀▀ █▀█   █▀▀ █░█ █ ▀▄▀   █ █▄░█ █▀▀ ▀█▀ ▄▀█ █░░ █░░"
               #:fg %color-cyan-neon #:bold? #t)
    (draw-text 8 8  "█▄▄ ░█░ █▀▄ ██▄ █▀▄   █▄█ █▄█ █ █░█   █ █░▀█ ▄██ ░█░ █▀█ █▄▄ █▄▄"
               #:fg %color-red-crimson #:bold? #t)

    (draw-hline 10 9 64 #:char "┄" #:fg %color-border-dim)

    ;; Datos dinámicos reales del sistema anfitrión
    (draw-text 11 9 "VISTAZO DEL SISTEMA ANFITRION (HARDWARE DETECTADO):"
               #:fg %color-cyan-neon #:bold? #t)

    (let* ((cpu-short (if (> (string-length cpu-name) 42)
                          (substring cpu-name 0 42)
                          cpu-name))
           (cpu-str (format #f "• CPU : ~a (~a nucleos)" cpu-short cpu-cores)))
      (draw-text 12 9 cpu-str #:fg %color-text-ice))

    (let* ((gpu-short (if (> (string-length gpu-desc) 54)
                          (string-append (substring gpu-desc 0 51) "...")
                          gpu-desc))
           (gpu-str (format #f "• GPU : ~a" gpu-short)))
      (draw-text 13 9 gpu-str #:fg %color-text-ice))

    (let ((ram-str (format #f "• RAM : ~a GiB  │  MODO: ~a" ram-gib boot-mode)))
      (draw-text 14 9 ram-str #:fg %color-text-ice))

    ;; Conectividad a Internet reactiva
    (if online?
        (draw-text 15 9 "• RED : CONEXION A INTERNET DETECTADA [ OK ]"
                   #:fg %color-matrix-green #:bold? #t)
        (draw-text 15 9 "• RED : SIN CONEXION A INTERNET [ ALERTA: OFFLINE ]"
                   #:fg %color-red-crimson #:bold? #t))

    (draw-text 17 9 "Presione INICIAR INSTALACION para configurar teclado y almacenamiento."
               #:fg %color-text-dim)

    (draw-button 19 14 "SALIR AL SHELL" #:state (if (= focus 0) 'focused 'normal))
    (draw-button 19 38 "INICIAR INSTALACION ▶" #:state (if (= focus 1) 'focused 'normal))

    (force-output)))
