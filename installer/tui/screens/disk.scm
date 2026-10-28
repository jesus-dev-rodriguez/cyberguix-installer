;;; installer/tui/screens/disk.scm --- Pantalla 4: Almacenamiento Dinámico con Modal
;;; Parte del CyberGuix Installer.

(define-module (installer tui screens disk)
  #:use-module (ice-9 copy-tree)
  #:use-module (ice-9 format)
  #:use-module (installer hardware)
  #:use-module (installer tui ansi)
  #:use-module (installer tui box)
  #:use-module (installer tui screen)
  #:use-module (installer tui widgets)
  #:export (make-disk-state
            disk-handle-key
            disk-get-selection
            render-disk-screen))

(define* (make-disk-state #:optional (available-disks #f))
  (let ((disks (or available-disks (detect-host-disks))))
    `((focus . radio-disk)
      (modal-active? . #f)
      (modal . ,(make-modal-state
                 "! BREACH ALERT: DISK OVERWRITE !"
                 "¿Desea formatear la unidad seleccionada? TODOS LOS DATOS SE PERDERAN."
                 #:danger? #t
                 #:actions '("CANCELAR" "BORRAR DISCO")))
      (radio-disk . ,(make-radio-state disks 0)))))

(define (disk-get-selection state)
  (let* ((radio-st (assq-ref state 'radio-disk))
         (opts (assq-ref radio-st 'options))
         (sel  (assq-ref radio-st 'selected)))
    (if (and opts (not (null? opts)) (< sel (length opts)))
        (car (list-ref opts sel))
        "/dev/sda")))

(define (disk-handle-key state key)
  "Maneja la navegación de discos y el modal de confirmación destructiva."
  (let ((modal-active? (assq-ref state 'modal-active?))
        (focus (assq-ref state 'focus)))

    (if modal-active?
        ;; Interacción dentro del Modal Breach Alert
        (let* ((modal-st (assq-ref state 'modal))
               (cur-btn  (assq-ref modal-st 'focused-btn)))
          (case key
            ((left right tab)
             (let ((new-modal (modal-handle-key modal-st key)))
               `((state . ,(assq-set! (copy-tree state) 'modal new-modal)))))
            ((enter)
             (if (= cur-btn 1)
                 ;; Confirmó "BORRAR DISCO": avanzar al siguiente paso
                 '((action . next))
                 ;; Canceló: cerrar modal y volver
                 `((state . ,(assq-set! (copy-tree state) 'modal-active? #f)))))
            ((escape)
             `((state . ,(assq-set! (copy-tree state) 'modal-active? #f))))
            (else `((state . ,state)))))

        ;; Interacción en la pantalla principal de disco
        (case key
          ((tab)
           (let ((next-focus (case focus
                               ((radio-disk) 'btn-apply)
                               ((btn-apply)  'btn-back)
                               ((btn-back)   'radio-disk))))
             `((state . ,(assq-set! (copy-tree state) 'focus next-focus)))))

          ((shift-tab)
           (let ((prev-focus (case focus
                               ((radio-disk) 'btn-back)
                               ((btn-apply)  'radio-disk)
                               ((btn-back)   'btn-apply))))
             `((state . ,(assq-set! (copy-tree state) 'focus prev-focus)))))

          ((enter)
           (case focus
             ((btn-apply)
              ;; Configurar mensaje dinámico en el modal según el disco seleccionado
              (let* ((selected-disk (disk-get-selection state))
                     (msg (format #f "¿Desea formatear ~a? TODOS LOS DATOS SE PERDERAN." selected-disk))
                     (updated-modal (make-modal-state "! BREACH ALERT: DISK OVERWRITE !"
                                                      msg
                                                      #:danger? #t
                                                      #:actions '("CANCELAR" "BORRAR DISCO"))))
                `((state . ,(assq-set! (assq-set! (copy-tree state) 'modal updated-modal)
                                       'modal-active? #t)))))
             ((btn-back)
              '((action . back)))
             (else (disk-handle-key state 'tab))))

          (else
           (case focus
             ((radio-disk)
              (if (or (eq? key 'up) (eq? key 'down))
                  (let* ((r-state (assq-ref state 'radio-disk))
                         (new-r (radio-handle-key r-state key)))
                    `((state . ,(assq-set! (copy-tree state) 'radio-disk new-r))))
                  `((state . ,state))))

             ((btn-back btn-apply)
              (if (or (eq? key 'left) (eq? key 'right))
                  (let ((new-btn (if (eq? focus 'btn-back) 'btn-apply 'btn-back)))
                    `((state . ,(assq-set! (copy-tree state) 'focus new-btn))))
                  `((state . ,state))))))))))

(define* (render-disk-screen state #:key (hw-data #f))
  "Renderiza la pantalla de disco y el modal si está activo."
  (let* ((focus (assq-ref state 'focus))
         (modal-active? (assq-ref state 'modal-active?))
         (radio-st (assq-ref state 'radio-disk))
         (mobo (or (and hw-data (assq-ref hw-data 'motherboard)) "Sistema Host"))
         (online? (if hw-data (assq-ref hw-data 'online?) #t)))

    (ansi-clear-screen)
    (render-installer-chrome #:step "STEP 04/06: STORAGE"
                             #:hardware mobo
                             #:online? online?)

    (draw-card 5 7 68 16
               #:title "SELECCION DE UNIDAD DE ALMACENAMIENTO"
               #:title-fg %color-cyan-neon
               #:border-fg %color-cyan-neon
               #:bg %color-bg-card)

    (draw-text 7 10 "Unidades de almacenamiento detectadas en /sys/block:"
               #:fg %color-text-ice)

    ;; Selector de disco interactivo con discos reales
    (render-widget-radio 9 11 radio-st #:focused? (and (not modal-active?) (eq? focus 'radio-disk)) #:spacing 2)

    (draw-hline 13 10 62 #:char "┄" #:fg %color-border-dim)
    (draw-text 14 10 "Estrategia de particionado:" #:fg %color-text-ice)
    (draw-text 15 11 "● Borrado completo guiado (ESP 512MB + Root Btrfs declarativo)"
               #:fg %color-text-ice)
    (draw-text 16 11 "○ Particionamiento manual avanzado (cfdisk)"
               #:fg %color-text-dim)

    (draw-button 19 18 "< ATRAS" #:state (if (and (not modal-active?) (eq? focus 'btn-back)) 'focused 'normal))
    (draw-button 19 38 "APLICAR CAMBIOS ▶" #:state (if (and (not modal-active?) (eq? focus 'btn-apply)) 'danger 'normal))

    ;; Modal superpuesto si está activo
    (when modal-active?
      (render-widget-modal (assq-ref state 'modal)))

    (force-output)))
