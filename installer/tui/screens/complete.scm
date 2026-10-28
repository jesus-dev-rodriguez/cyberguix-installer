;;; installer/tui/screens/complete.scm --- Pantalla 7: Finalización (Interactiva)
;;; Parte del CyberGuix Installer.

(define-module (installer tui screens complete)
  #:use-module (ice-9 copy-tree)
  #:use-module (installer tui ansi)
  #:use-module (installer tui box)
  #:use-module (installer tui screen)
  #:use-module (installer tui widgets)
  #:export (make-complete-state
            complete-handle-key
            render-complete-screen))

(define (make-complete-state)
  `((focus . btn-reboot) ; 'btn-exit, 'btn-reboot
    (modal-active? . #f)
    (modal . ,(make-modal-state "REINICIO DEL EQUIPO" "El instalador ha concluido. Presione Enter para salir."
                                #:type 'info
                                #:actions '("FINALIZAR")))))

(define (complete-handle-key state key)
  "Maneja la acción de reinicio o salida a la consola."
  (let ((modal-active? (assq-ref state 'modal-active?))
        (focus (assq-ref state 'focus)))

    (if modal-active?
        (case key
          ((enter escape space) '((action . quit)))
          (else `((state . ,state))))

        (case key
          ((left right tab)
           (let ((new-foc (if (eq? focus 'btn-reboot) 'btn-exit 'btn-reboot)))
             `((state . ,(assq-set! (copy-tree state) 'focus new-foc)))))
          ((enter)
           (if (eq? focus 'btn-reboot)
               `((state . ,(assq-set! (copy-tree state) 'modal-active? #t)))
               '((action . quit))))
          (else `((state . ,state)))))))

(define* (render-complete-screen state #:key (hw-data #f))
  "Renderiza la pantalla de finalización interactiva con el resumen de la instalación."
  (let* ((focus (assq-ref state 'focus))
         (modal-active? (assq-ref state 'modal-active?))
         (mobo (or (and hw-data (assq-ref hw-data 'motherboard)) "Sistema Host"))
         (online? (if hw-data (assq-ref hw-data 'online?) #t)))
    (ansi-clear-screen)
    (render-installer-chrome #:step "STATUS: COMPLETE"
                             #:hardware mobo
                             #:online? online?)

    (draw-card 5 8 66 16
               #:title "¡INSTALACION COMPLETADA CON EXITO!"
               #:title-fg %color-matrix-green
               #:border-fg %color-matrix-green
               #:bg %color-bg-card)

    (draw-text 7 11 "El sistema operativo CyberGuix ha sido instalado correctamente."
               #:fg %color-text-ice #:bold? #t)

    (draw-hline 9 11 60 #:char "┄" #:fg %color-border-dim)

    (draw-text 10 11 "RESUMEN DEL SISTEMA DESPLEGADO:" #:fg %color-cyan-neon #:bold? #t)
    (draw-text 11 11 "• Usuario Administrador  : red-mat (Acceso sudo habilitado)" #:fg %color-text-ice)
    (draw-text 12 11 "• Entorno de Escritorio : Hyprland + CyberArch Shell" #:fg %color-text-ice)
    (draw-text 13 11 "• Perfil de Hardware     : MSI MS-7721 (Non-free firmware listo)" #:fg %color-text-ice)
    (draw-text 14 11 "• Manifiesto Declarativo : /etc/config.scm" #:fg %color-text-ice)

    (draw-text 16 11 "Puede retirar el medio de instalacion (Live-CD / USB)."
               #:fg %color-amber-warn)

    (draw-button 18 16 "SALIR A CONSOLA" #:state (if (and (not modal-active?) (eq? focus 'btn-exit)) 'focused 'normal))
    (draw-button 18 38 "REINICIAR EQUIPO ▶" #:state (if (and (not modal-active?) (eq? focus 'btn-reboot)) 'focused 'normal))

    (when modal-active?
      (render-widget-modal (assq-ref state 'modal)))

    (force-output)))
