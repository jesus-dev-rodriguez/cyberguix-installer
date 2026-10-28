;;; installer/tui/screens/progress.scm --- Pantalla 6: Despliegue e Inicialización (Interactiva)
;;; Parte del CyberGuix Installer.

(define-module (installer tui screens progress)
  #:use-module (ice-9 copy-tree)
  #:use-module (installer tui ansi)
  #:use-module (installer tui box)
  #:use-module (installer tui screen)
  #:export (make-progress-state
            progress-handle-key
            render-progress-screen))

(define (make-progress-state)
  `((focus . btn-finish) ; 'btn-cancel, 'btn-finish
    (percentage . 100)))

(define (progress-handle-key state key)
  "Maneja la navegación en la pantalla de progreso/despliegue."
  (let ((focus (assq-ref state 'focus)))
    (case key
      ((left right tab)
       (let ((new-foc (if (eq? focus 'btn-finish) 'btn-cancel 'btn-finish)))
         `((state . ,(assq-set! (copy-tree state) 'focus new-foc)))))
      ((enter)
       (if (eq? focus 'btn-finish)
           '((action . next))
           '((action . back))))
      (else `((state . ,state))))))

(define* (render-progress-screen state #:key (hw-data #f))
  "Renderiza la pantalla de progreso del despliegue."
  (let* ((focus (assq-ref state 'focus))
         (pct   (assq-ref state 'percentage))
         (mobo (or (and hw-data (assq-ref hw-data 'motherboard)) "Sistema Host"))
         (online? (if hw-data (assq-ref hw-data 'online?) #t)))
    (ansi-clear-screen)
    (render-installer-chrome #:step "STEP 06/06: DEPLOY"
                             #:hardware mobo
                             #:online? online?)

    (draw-card 5 7 68 16
               #:title "DESPLEGANDO CYBERGUIX SYSTEM"
               #:title-fg %color-cyan-neon
               #:border-fg %color-cyan-neon
               #:bg %color-bg-card)

    (draw-text 7 10 "Inicializando construccion del sistema operativo via Guix Store:"
               #:fg %color-text-ice)

    ;; Barra de progreso interactiva
    (draw-progress-bar 9 10 "GUIX_INIT" pct 62)

    (draw-text 11 10 "TELEMETRIA DE LA CONSTRUCCION:" #:fg %color-text-dim #:bold? #t)
    (draw-text 12 11 "✓ [01/05] Generando declaracion /mnt/etc/config.scm" #:fg %color-matrix-green)
    (draw-text 13 11 "✓ [02/05] Sincronizando canales: guix (f02c1) y nonguix (a83fe)" #:fg %color-matrix-green)
    (draw-text 14 11 "✓ [03/05] Compilando perfil de hardware MS-7721 (AMD microcode)" #:fg %color-matrix-green)
    (draw-text 15 11 "✓ [04/05] Descargando sustitutos para Hyprland y Wayland stack" #:fg %color-matrix-green)
    (draw-text 16 11 "✓ [05/05] Inicializando esqueleto CyberArch en /home/red-mat" #:fg %color-matrix-green)

    (draw-text 18 10 "Construccion simulada finalizada. Listo para completar."
               #:fg %color-matrix-green #:bold? #t)

    (draw-button 19 14 "< CANCELAR" #:state (if (eq? focus 'btn-cancel) 'focused 'normal))
    (draw-button 19 36 "FINALIZAR DESPLIEGUE ▶" #:state (if (eq? focus 'btn-finish) 'focused 'normal))

    (force-output)))
