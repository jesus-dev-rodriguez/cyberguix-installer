;;; installer/tui/screens/keymap.scm --- Pantalla 2: Teclado e Idioma (Interactiva)
;;; Parte del CyberGuix Installer.

(define-module (installer tui screens keymap)
  #:use-module (ice-9 copy-tree)
  #:use-module (installer tui ansi)
  #:use-module (installer tui box)
  #:use-module (installer tui screen)
  #:use-module (installer tui widgets)
  #:export (make-keymap-state
            keymap-handle-key
            keymap-get-selection
            render-keymap-screen))

(define (make-keymap-state)
  `((focus . radio) ; 'radio, 'test-input, 'btn-back, 'btn-next
    (radio . ,(make-radio-state
               '(("es-latam" . "Espanol (Latinoamerica - latam)")
                 ("es-es"    . "Espanol (Espana - es)")
                 ("us-intl"  . "Ingles (US Internacional con altgr)")
                 ("us"       . "Ingles (US Estandar)"))
               0))
    (test-input . ,(make-input-state "TEST_INPUT" "ñ ! / $ ~ @" #:max-len 24))))

(define (keymap-get-selection state)
  (let* ((radio-st (assq-ref state 'radio))
         (opts (assq-ref radio-st 'options))
         (sel  (assq-ref radio-st 'selected)))
    (car (list-ref opts sel))))

(define (keymap-handle-key state key)
  "Maneja la interacción en la pantalla de teclado."
  (let ((focus (assq-ref state 'focus)))
    (case key
      ;; Cambio de foco entre componentes con TAB
      ((tab)
       (let ((next-focus (case focus
                           ((radio) 'test-input)
                           ((test-input) 'btn-next)
                           ((btn-next) 'btn-back)
                           ((btn-back) 'radio))))
         `((state . ,(assq-set! (copy-tree state) 'focus next-focus)))))

      ;; Shift-Tab (retroceder foco)
      ((shift-tab)
       (let ((prev-focus (case focus
                           ((radio) 'btn-back)
                           ((test-input) 'radio)
                           ((btn-next) 'test-input)
                           ((btn-back) 'btn-next))))
         `((state . ,(assq-set! (copy-tree state) 'focus prev-focus)))))

      ;; Enter sobre botones
      ((enter)
       (case focus
         ((btn-next) '((action . next)))
         ((btn-back) '((action . back)))
         (else
          ;; Enter en campos avanza al siguiente control
          (keymap-handle-key state 'tab))))

      ;; Interacción específica del componente en foco
      (else
       (case focus
         ((radio)
          (if (or (eq? key 'up) (eq? key 'down))
              (let* ((r-state (assq-ref state 'radio))
                     (new-r (radio-handle-key r-state key)))
                `((state . ,(assq-set! (copy-tree state) 'radio new-r))))
              `((state . ,state))))

         ((test-input)
          (let* ((in-state (assq-ref state 'test-input))
                 (new-in (input-handle-key in-state key)))
            `((state . ,(assq-set! (copy-tree state) 'test-input new-in)))))

         ((btn-back btn-next)
          (if (or (eq? key 'left) (eq? key 'right))
              (let ((new-btn (if (eq? focus 'btn-back) 'btn-next 'btn-back)))
                `((state . ,(assq-set! (copy-tree state) 'focus new-btn))))
              `((state . ,state)))))))))

(define* (render-keymap-screen state #:key (hw-data #f))
  "Renderiza la pantalla interactiva de teclado."
  (let* ((focus (assq-ref state 'focus))
         (radio-st (assq-ref state 'radio))
         (test-in  (assq-ref state 'test-input))
         (mobo (or (and hw-data (assq-ref hw-data 'motherboard)) "Sistema Host"))
         (online? (if hw-data (assq-ref hw-data 'online?) #t)))
    (ansi-clear-screen)
    (render-installer-chrome #:step "STEP 02/06: KEYBOARD"
                             #:hardware mobo
                             #:online? online?)

    (draw-card 5 8 66 16
               #:title "DISTRIBUCION DE TECLADO E IDIOMA"
               #:title-fg %color-cyan-neon
               #:border-fg %color-cyan-neon
               #:bg %color-bg-card)

    (draw-text 7 11 "Seleccione la disposicion de teclado para la consola y la sesion:"
               #:fg %color-text-ice)

    ;; Selector de radio interactivo
    (render-widget-radio 9 12 radio-st #:focused? (eq? focus 'radio) #:spacing 2)

    ;; Campo de prueba donde el usuario puede escribir
    (draw-hline 16 11 60 #:char "┄" #:fg %color-border-dim)
    (render-widget-input 17 11 test-in 20 #:focused? (eq? focus 'test-input))

    ;; Botones
    (draw-button 19 18 "< ATRAS" #:state (if (eq? focus 'btn-back) 'focused 'normal))
    (draw-button 19 38 "CONTINUAR ▶" #:state (if (eq? focus 'btn-next) 'focused 'normal))

    (force-output)))
