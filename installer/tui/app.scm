;;; installer/tui/app.scm --- Orquestador, máquina de estados y bucle de eventos reactivo
;;; Parte del CyberGuix Installer.
;;; 100% DINAMICO: El hardware se detecta del sistema anfitrión, CERO datos hardcodeados.

(define-module (installer tui app)
  #:use-module (ice-9 copy-tree)
  #:use-module (ice-9 format)
  #:use-module (installer hardware)
  #:use-module (installer tui ansi)
  #:use-module (installer tui box)
  #:use-module (installer tui keyboard)
  #:use-module (installer tui screens welcome)
  #:use-module (installer tui screens keymap)
  #:use-module (installer tui screens hardware)
  #:use-module (installer tui screens disk)
  #:use-module (installer tui screens user)
  #:use-module (installer tui screens progress)
  #:use-module (installer tui screens complete)
  #:export (run-cyberguix-tui))

;; Secuencia secuencial de pantallas del instalador
(define %flow-steps
  '(welcome keymap hardware disk user progress complete))

(define (next-step-of current)
  (let loop ((seq %flow-steps))
    (cond
     ((null? (cdr seq)) (car seq))
     ((eq? (car seq) current) (cadr seq))
     (else (loop (cdr seq))))))

(define (prev-step-of current)
  (let loop ((prev (car %flow-steps))
             (seq %flow-steps))
    (cond
     ((null? seq) prev)
     ((eq? (car seq) current) prev)
     (else (loop (car seq) (cdr seq))))))

(define (make-app-state)
  (let ((hw (detect-host-hardware)))
    `((current-step . welcome)
      (diag-modal?  . #f)
      (hardware     . ,hw)
      (welcome      . ,(make-welcome-state))
      (keymap       . ,(make-keymap-state))
      (hardware-scr . ,(make-hardware-state))
      (disk         . ,(make-disk-state (assq-ref hw 'disks)))
      (user         . ,(make-user-state))
      (progress     . ,(make-progress-state))
      (complete     . ,(make-complete-state)))))

(define (render-diagnostic-modal hw-data)
  "Renderiza la ventana modal de diagnóstico de hardware y estado del sistema (F1)."
  (let* ((cpu-name  (or (and hw-data (assq-ref hw-data 'cpu-name)) "CPU x86_64"))
         (cpu-cores (or (and hw-data (assq-ref hw-data 'cpu-cores)) 1))
         (ram-gib   (or (and hw-data (assq-ref hw-data 'ram-gib)) 0.0))
         (boot-mode (or (and hw-data (assq-ref hw-data 'boot-mode)) "Desconocido"))
         (mobo      (or (and hw-data (assq-ref hw-data 'motherboard)) "Sistema Host"))
         (gpu-desc  (or (and hw-data (assq-ref hw-data 'gpu-desc)) "Controlador VGA"))
         (online?   (if hw-data (assq-ref hw-data 'online?) #f))
         (disks     (or (and hw-data (assq-ref hw-data 'disks)) '())))

    (draw-card 6 9 64 15
               #:title "DIAGNOSTICO DEL SISTEMA ANFITRION [F1]"
               #:title-fg %color-cyan-neon
               #:border-fg %color-cyan-neon
               #:bg %color-bg-void)

    (let* ((c-short (if (> (string-length cpu-name) 42) (substring cpu-name 0 42) cpu-name))
           (m-short (if (> (string-length mobo) 42) (substring mobo 0 42) mobo))
           (g-short (if (> (string-length gpu-desc) 42) (substring gpu-desc 0 42) gpu-desc)))
      (draw-text 8  12 (format #f "• PLACA BASE : ~a" m-short) #:fg %color-text-ice)
      (draw-text 9  12 (format #f "• PROCESADOR : ~a (~a nucleos)" c-short cpu-cores) #:fg %color-text-ice)
      (draw-text 10 12 (format #f "• GRAFICOS   : ~a" g-short) #:fg %color-text-ice)
      (draw-text 11 12 (format #f "• MEMORIA    : ~a GiB RAM total detectada" ram-gib) #:fg %color-text-ice)
      (draw-text 12 12 (format #f "• ARRANQUE   : ~a verificado" boot-mode) #:fg %color-text-ice)
      (draw-text 13 12 (format #f "• UNIDADES   : ~a unidad(es) de disco activas" (length disks)) #:fg %color-text-ice)

      (if online?
          (draw-text 14 12 "• INTERNET   : CONECTADO [ OK ] (DNS 1.1.1.1 alcanzable)"
                     #:fg %color-matrix-green #:bold? #t)
          (draw-text 14 12 "• INTERNET   : SIN CONEXION [ OFFLINE ] (Revise el cable)"
                     #:fg %color-red-crimson #:bold? #t)))

    (draw-hline 16 12 58 #:char "┄" #:fg %color-border-dim)
    (draw-button 18 24 "CERRAR DIAGNOSTICO [ENTER / ESC]" #:state 'focused)
    (force-output)))

(define (render-active-screen app-state)
  (let* ((step       (assq-ref app-state 'current-step))
         (hw-data    (assq-ref app-state 'hardware))
         (diag-open? (assq-ref app-state 'diag-modal?))
         (st         (assq-ref app-state (if (eq? step 'hardware) 'hardware-scr step))))
    (case step
      ((welcome)  (render-welcome-screen st #:hw-data hw-data))
      ((keymap)   (render-keymap-screen st #:hw-data hw-data))
      ((hardware) (render-hardware-screen st #:hw-data hw-data))
      ((disk)     (render-disk-screen st #:hw-data hw-data))
      ((user)     (render-user-screen st #:hw-data hw-data))
      ((progress) (render-progress-screen st #:hw-data hw-data))
      ((complete) (render-complete-screen st #:hw-data hw-data)))

    ;; Barra de ayuda de navegación interactiva en la parte inferior
    (draw-text 22 10 "[ TAB / Shift-Tab / Flechas: Navegar  │  ENTER: Seleccionar  │  ESC: Salir ]"
               #:fg %color-cyan-neon
               #:bold? #t)

    ;; Si la ventana modal de diagnóstico F1 está abierta, se renderiza encima
    (when diag-open?
      (render-diagnostic-modal hw-data))

    (force-output)))

(define (dispatch-key app-state key)
  "Despacha KEY a la pantalla activa y actualiza el estado de la aplicación."
  (let* ((step     (assq-ref app-state 'current-step))
         (state-id (if (eq? step 'hardware) 'hardware-scr step))
         (st       (assq-ref app-state state-id))
         (res      (case step
                     ((welcome)  (welcome-handle-key st key))
                     ((keymap)   (keymap-handle-key st key))
                     ((hardware) (hardware-handle-key st key))
                     ((disk)     (disk-handle-key st key))
                     ((user)     (user-handle-key st key))
                     ((progress) (progress-handle-key st key))
                     ((complete) (complete-handle-key st key)))))

    (cond
     ;; 1. Acción: Avanzar al siguiente paso o retroceder
     ((assq-ref res 'action)
      (let ((act (assq-ref res 'action)))
        (case act
          ((next)
           (let ((nxt (next-step-of step)))
             (assq-set! (copy-tree app-state) 'current-step nxt)))
          ((back)
           (let ((prv (prev-step-of step)))
             (assq-set! (copy-tree app-state) 'current-step prv)))
          ((quit)
           #f))))

     ;; 2. Estado actualizado dentro de la misma pantalla
     ((assq-ref res 'state)
      (let* ((new-st (assq-ref res 'state))
             (updated (assq-set! (copy-tree app-state) state-id new-st)))
        updated))

     (else app-state))))

(define (handle-network-tick app-state)
  "Comprueba la conectividad de forma asíncrona/no-bloqueante.
Si el estado de la red cambió (ej. de online a offline o viceversa), actualiza el estado y redibuja."
  (let* ((hw (assq-ref app-state 'hardware))
         (cur-online? (assq-ref hw 'online?))
         (new-online? (check-internet-connection #:timeout-ms 350)))
    (if (not (eq? cur-online? new-online?))
        ;; El estado cambió: actualizar estado de hardware y redibujar
        (let* ((updated-hw (assq-set! (copy-tree hw) 'online? new-online?))
               (new-app-st (assq-set! (copy-tree app-state) 'hardware updated-hw)))
          (render-active-screen new-app-st)
          new-app-st)
        app-state)))

(define (run-cyberguix-tui)
  "Inicia el bucle de eventos reactivo de CyberGuix Installer."
  (with-raw-terminal
    (lambda ()
      (dynamic-wind
        (lambda ()
          (ansi-hide-cursor)
          (ansi-clear-screen))
        (lambda ()
          (let loop ((app-state (make-app-state)))
            ;; Render inicial
            (render-active-screen app-state)

            (let event-loop ((state app-state))
              ;; Espera eventos de teclado o tick de temporizador (1 segundo)
              (let ((event (read-event-with-timeout 1)))
                (case (car event)
                  ;; Evento de Temporizador: verificar reactivamente la red
                  ((tick)
                   (let ((updated-state (handle-network-tick state)))
                     (event-loop updated-state)))

                  ;; Evento de Teclado
                  ((key)
                   (let ((key (cdr event))
                         (diag-open? (assq-ref state 'diag-modal?)))
                     (cond
                      ;; Si el modal de diagnóstico está abierto: cualquier tecla lo cierra
                      (diag-open?
                       (let ((closed-state (assq-set! (copy-tree state) 'diag-modal? #f)))
                         (render-active-screen closed-state)
                         (event-loop closed-state)))

                      ;; Si se presiona F1 (o '?') se abre el modal de diagnóstico
                      ((or (eq? key 'f1)
                           (and (eq? key #\?)
                                (not (eq? (assq-ref state 'current-step) 'user))
                                (not (eq? (assq-ref state 'current-step) 'keymap))))
                       (let ((opened-state (assq-set! (copy-tree state) 'diag-modal? #t)))
                         (render-active-screen opened-state)
                         (event-loop opened-state)))

                      ;; Salida global con ESC o EOF
                      ((or (eq? key 'escape) (eq? key 'eof))
                       #t)

                      ;; Tecla 'q' o 'Q' para salir si no estamos en campos de texto
                      ((and (or (eq? key #\q) (eq? key #\Q))
                            (not (eq? (assq-ref state 'current-step) 'user))
                            (not (eq? (assq-ref state 'current-step) 'keymap)))
                       #t)

                      (else
                       (let ((new-app-state (dispatch-key state key)))
                         (if new-app-state
                             (begin
                               (render-active-screen new-app-state)
                               (event-loop new-app-state))
                             #t)))))))))))
        (lambda ()
          (ansi-clear-screen)
          (ansi-show-cursor)
          (display ansi-reset)
          (force-output))))))
