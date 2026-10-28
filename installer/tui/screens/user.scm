;;; installer/tui/screens/user.scm --- Pantalla 5: Usuario Administrador (Interactiva)
;;; Parte del CyberGuix Installer.

(define-module (installer tui screens user)
  #:use-module (ice-9 copy-tree)
  #:use-module (installer tui ansi)
  #:use-module (installer tui box)
  #:use-module (installer tui screen)
  #:use-module (installer tui widgets)
  #:export (make-user-state
            user-handle-key
            user-get-data
            render-user-screen))

(define (make-user-state)
  `((focus . full-name) ; 'full-name, 'user-name, 'password, 'confirm, 'btn-back, 'btn-next
    (modal-active? . #f)
    (modal . ,(make-modal-state "VALIDACION DE SEGURIDAD" "Las contraseñas no coinciden o el usuario esta vacio."
                                #:danger? #t
                                #:actions '("ENTENDIDO")))
    (input-fullname . ,(make-input-state "FULL_NAME" "Matias Rossi"))
    (input-username . ,(make-input-state "USER_NAME" "red-mat"))
    (input-password . ,(make-input-state "PASSWORD"  "password123" #:password? #t))
    (input-confirm  . ,(make-input-state "CONFIRM"   "password123" #:password? #t))))

(define (user-get-data state)
  `((fullname . ,(assq-ref (assq-ref state 'input-fullname) 'value))
    (username . ,(assq-ref (assq-ref state 'input-username) 'value))
    (password . ,(assq-ref (assq-ref state 'input-password) 'value))))

(define %user-field-sequence
  '(full-name user-name password confirm btn-next btn-back))

(define (next-user-focus current)
  (let loop ((seq %user-field-sequence))
    (cond
     ((null? (cdr seq)) (car %user-field-sequence))
     ((eq? (car seq) current) (cadr seq))
     (else (loop (cdr seq))))))

(define (prev-user-focus current)
  (let loop ((prev (car (reverse %user-field-sequence)))
             (seq %user-field-sequence))
    (cond
     ((null? seq) prev)
     ((eq? (car seq) current) prev)
     (else (loop (car seq) (cdr seq))))))

(define (user-handle-key state key)
  "Maneja la edición de campos y validación del usuario."
  (let ((modal-active? (assq-ref state 'modal-active?))
        (focus (assq-ref state 'focus)))

    (if modal-active?
        ;; Modal de error activo
        (case key
          ((enter escape space)
           `((state . ,(assq-set! (copy-tree state) 'modal-active? #f))))
          (else `((state . ,state))))

        ;; Navegación y edición normal
        (case key
          ((tab)
           `((state . ,(assq-set! (copy-tree state) 'focus (next-user-focus focus)))))

          ((shift-tab)
           `((state . ,(assq-set! (copy-tree state) 'focus (prev-user-focus focus)))))

          ((enter)
           (case focus
             ((btn-next)
              (let* ((user (assq-ref (assq-ref state 'input-username) 'value))
                     (p1   (assq-ref (assq-ref state 'input-password) 'value))
                     (p2   (assq-ref (assq-ref state 'input-confirm)  'value)))
                (if (or (string-null? user) (not (string=? p1 p2)))
                    ;; Mostrar modal de validación
                    `((state . ,(assq-set! (copy-tree state) 'modal-active? #t)))
                    '((action . next)))))
             ((btn-back)
              '((action . back)))
             (else
              ;; Enter en un campo de texto avanza al siguiente
              `((state . ,(assq-set! (copy-tree state) 'focus (next-user-focus focus)))))))

          (else
           (case focus
             ((full-name)
              (let* ((in (assq-ref state 'input-fullname))
                     (new-in (input-handle-key in key)))
                `((state . ,(assq-set! (copy-tree state) 'input-fullname new-in)))))
             ((user-name)
              (let* ((in (assq-ref state 'input-username))
                     (new-in (input-handle-key in key)))
                `((state . ,(assq-set! (copy-tree state) 'input-username new-in)))))
             ((password)
              (let* ((in (assq-ref state 'input-password))
                     (new-in (input-handle-key in key)))
                `((state . ,(assq-set! (copy-tree state) 'input-password new-in)))))
             ((confirm)
              (let* ((in (assq-ref state 'input-confirm))
                     (new-in (input-handle-key in key)))
                `((state . ,(assq-set! (copy-tree state) 'input-confirm new-in)))))
             ((btn-back btn-next)
              (if (or (eq? key 'left) (eq? key 'right))
                  (let ((new-btn (if (eq? focus 'btn-back) 'btn-next 'btn-back)))
                    `((state . ,(assq-set! (copy-tree state) 'focus new-btn))))
                  `((state . ,state))))))))))

(define* (render-user-screen state #:key (hw-data #f))
  "Renderiza la pantalla interactiva de usuario."
  (let* ((focus (assq-ref state 'focus))
         (modal-active? (assq-ref state 'modal-active?))
         (in-full (assq-ref state 'input-fullname))
         (in-user (assq-ref state 'input-username))
         (in-pass (assq-ref state 'input-password))
         (in-conf (assq-ref state 'input-confirm))
         (mobo (or (and hw-data (assq-ref hw-data 'motherboard)) "Sistema Host"))
         (online? (if hw-data (assq-ref hw-data 'online?) #t)))
    (ansi-clear-screen)
    (render-installer-chrome #:step "STEP 05/06: USER"
                             #:hardware mobo
                             #:online? online?)

    (draw-card 5 8 66 16
               #:title "CUENTA ADMINISTRADORA (SUDO ONLY)"
               #:title-fg %color-red-crimson
               #:border-fg %color-cyan-neon
               #:bg %color-bg-card)

    (draw-text 7 11 "Configure el usuario principal del sistema CyberGuix:"
               #:fg %color-text-ice)
    (draw-text 8 11 "! AVISO: Cuenta 'root' deshabilitada (paradigma de seguridad Ubuntu)."
               #:fg %color-amber-warn #:bold? #t)

    ;; Renderizado de campos interactivos
    (render-widget-input 10 11 in-full 24 #:focused? (and (not modal-active?) (eq? focus 'full-name)))
    (render-widget-input 12 11 in-user 24 #:focused? (and (not modal-active?) (eq? focus 'user-name)))
    (render-widget-input 14 11 in-pass 24 #:focused? (and (not modal-active?) (eq? focus 'password)))
    (render-widget-input 16 11 in-conf 24 #:focused? (and (not modal-active?) (eq? focus 'confirm)))

    ;; Botones
    (draw-button 19 18 "< ATRAS" #:state (if (and (not modal-active?) (eq? focus 'btn-back)) 'focused 'normal))
    (draw-button 19 38 "CONTINUAR ▶" #:state (if (and (not modal-active?) (eq? focus 'btn-next)) 'focused 'normal))

    (when modal-active?
      (render-widget-modal (assq-ref state 'modal)))

    (force-output)))
