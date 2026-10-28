;;; installer/tui/screens/hardware.scm --- Pantalla 3: Perfil de Hardware (100% Dinamica)
;;; Parte del CyberGuix Installer.

(define-module (installer tui screens hardware)
  #:use-module (ice-9 copy-tree)
  #:use-module (ice-9 format)
  #:use-module (installer tui ansi)
  #:use-module (installer tui box)
  #:use-module (installer tui screen)
  #:use-module (installer tui widgets)
  #:export (make-hardware-state
            hardware-handle-key
            hardware-get-selection
            render-hardware-screen))

(define (make-hardware-state)
  `((focus . radio) ; 'radio, 'btn-back, 'btn-next
    (radio . ,(make-radio-state
               '(("host-custom" . "Perfil Detectado (Microcodigo CPU + Firmware non-free)")
                 ("generic"     . "Perfil Generico UEFI (Linux-Libre FSF 100% puro)"))
               0))))

(define (hardware-get-selection state)
  (let* ((radio-st (assq-ref state 'radio))
         (opts (assq-ref radio-st 'options))
         (sel  (assq-ref radio-st 'selected)))
    (car (list-ref opts sel))))

(define (hardware-handle-key state key)
  "Maneja la navegación y selección del perfil de hardware."
  (let ((focus (assq-ref state 'focus)))
    (case key
      ((tab)
       (let ((next-focus (case focus
                           ((radio) 'btn-next)
                           ((btn-next) 'btn-back)
                           ((btn-back) 'radio))))
         `((state . ,(assq-set! (copy-tree state) 'focus next-focus)))))

      ((shift-tab)
       (let ((prev-focus (case focus
                           ((radio) 'btn-back)
                           ((btn-next) 'radio)
                           ((btn-back) 'btn-next))))
         `((state . ,(assq-set! (copy-tree state) 'focus prev-focus)))))

      ((enter)
       (case focus
         ((btn-next) '((action . next)))
         ((btn-back) '((action . back)))
         (else (hardware-handle-key state 'tab))))

      (else
       (case focus
         ((radio)
          (if (or (eq? key 'up) (eq? key 'down))
              (let* ((r-state (assq-ref state 'radio))
                     (new-r (radio-handle-key r-state key)))
                `((state . ,(assq-set! (copy-tree state) 'radio new-r))))
              `((state . ,state))))

         ((btn-back btn-next)
          (if (or (eq? key 'left) (eq? key 'right))
              (let ((new-btn (if (eq? focus 'btn-back) 'btn-next 'btn-back)))
                `((state . ,(assq-set! (copy-tree state) 'focus new-btn))))
              `((state . ,state)))))))))

(define* (render-hardware-screen state #:key (hw-data #f))
  "Renderiza la pantalla de hardware mostrando los dispositivos reales detectados."
  (let* ((focus    (assq-ref state 'focus))
         (radio-st (assq-ref state 'radio))
         (cpu-name (or (and hw-data (assq-ref hw-data 'cpu-name)) "CPU x86_64"))
         (mobo     (or (and hw-data (assq-ref hw-data 'motherboard)) "Sistema Host"))
         (gpu-desc (or (and hw-data (assq-ref hw-data 'gpu-desc)) "Graficos VGA"))
         (online?  (if hw-data (assq-ref hw-data 'online?) #t)))

    (ansi-clear-screen)
    (render-installer-chrome #:step "STEP 03/06: HARDWARE"
                             #:hardware mobo
                             #:online? online?)

    (draw-card 5 7 68 16
               #:title "DETECCION Y PERFIL DE HARDWARE"
               #:title-fg %color-cyan-neon
               #:border-fg %color-cyan-neon
               #:bg %color-bg-card)

    (draw-text 7 10 "Dispositivos identificados dinamicamente por el kernel:"
               #:fg %color-text-ice)

    (let* ((m-short (if (> (string-length mobo) 45) (substring mobo 0 45) mobo))
           (c-short (if (> (string-length cpu-name) 45) (substring cpu-name 0 45) cpu-name))
           (g-short (if (> (string-length gpu-desc) 45) (substring gpu-desc 0 45) gpu-desc)))
      (draw-text 8 10 (format #f "• PLACA BASE : ~a" m-short) #:fg %color-cyan-neon #:bold? #t)
      (draw-text 9 10 (format #f "• PROCESADOR : ~a" c-short) #:fg %color-text-dim)
      (draw-text 10 10 (format #f "• GRAFICOS   : ~a" g-short) #:fg %color-text-dim))

    (draw-hline 11 10 62 #:char "┄" #:fg %color-border-dim)
    (draw-text 12 10 "Seleccione la estrategia de drivers para config.scm:" #:fg %color-text-ice)

    (render-widget-radio 14 11 radio-st #:focused? (eq? focus 'radio) #:spacing 2)

    (draw-button 19 18 "< ATRAS" #:state (if (eq? focus 'btn-back) 'focused 'normal))
    (draw-button 19 38 "CONTINUAR ▶" #:state (if (eq? focus 'btn-next) 'focused 'normal))

    (force-output)))
