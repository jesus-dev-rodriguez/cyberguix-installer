;;; installer/tui/widgets.scm --- Componentes interactivos reutilizables para CyberGuix TUI
;;; Parte del CyberGuix Installer.

(define-module (installer tui widgets)
  #:use-module (ice-9 format)
  #:use-module (ice-9 copy-tree)
  #:use-module (installer tui ansi)
  #:use-module (installer tui box)
  #:export (;; Text Input
            make-input-state
            input-handle-key
            render-widget-input

            ;; Radio Selector / List
            make-radio-state
            radio-handle-key
            render-widget-radio

            ;; Modal Alert
            make-modal-state
            modal-handle-key
            render-widget-modal))

;;;
;;; 1. Campo de Entrada de Texto Interactivo (Text Input)
;;;

(define* (make-input-state label value #:key (password? #f) (max-len 32))
  "Crea el estado para un campo de texto interactivo."
  `((label . ,label)
    (value . ,value)
    (password? . ,password?)
    (max-len . ,max-len)))

(define (input-get key state)
  (assq-ref state key))

(define (input-set key val state)
  (assq-set! (copy-tree state) key val))

(define (input-handle-key state key)
  "Procesa una tecla sobre un campo de texto y retorna el nuevo estado."
  (let* ((val (input-get 'value state))
         (max-len (input-get 'max-len state)))
    (cond
     ;; Borrar caracter
     ((eq? key 'backspace)
      (if (> (string-length val) 0)
          (input-set 'value (substring val 0 (1- (string-length val))) state)
          state))
     ;; Escribir caracter si no superó longitud máxima
     ((char? key)
      (if (< (string-length val) max-len)
          (input-set 'value (string-append val (string key)) state)
          state))
     (else state))))

(define* (render-widget-input row col state width #:key (focused? #f))
  "Renderiza el input interactivo en (ROW, COL)."
  (let ((label (input-get 'label state))
        (val   (input-get 'value state))
        (pass? (input-get 'password? state)))
    (draw-input row col label val width #:focused? focused? #:password? pass?)))

;;;
;;; 2. Selector de Opciones (Radio List)
;;;

(define* (make-radio-state options #:optional (selected-index 0))
  "Crea el estado para un grupo de opciones seleccionables.
OPTIONS es una lista de pares o strings: '((id . label) ...)."
  `((options . ,options)
    (selected . ,selected-index)))

(define (radio-get-selected-id state)
  (let* ((opts (assq-ref state 'options))
         (sel  (assq-ref state 'selected))
         (item (list-ref opts sel)))
    (if (pair? item) (car item) item)))

(define (radio-handle-key state key)
  "Maneja flechas arriba/abajo para cambiar la opción seleccionada."
  (let* ((opts (assq-ref state 'options))
         (len  (length opts))
         (sel  (assq-ref state 'selected)))
    (case key
      ((up)
       (assq-set! (copy-tree state) 'selected (if (> sel 0) (1- sel) (1- len))))
      ((down)
       (assq-set! (copy-tree state) 'selected (if (< sel (1- len)) (1+ sel) 0)))
      (else state))))

(define* (render-widget-radio row col state #:key (focused? #f) (spacing 2))
  "Renderiza la lista de opciones de radio."
  (let ((opts (assq-ref state 'options))
        (selected (assq-ref state 'selected)))
    (do ((i 0 (1+ i))
         (r row (+ r spacing)))
        ((>= i (length opts)))
      (let* ((item (list-ref opts i))
             (label (if (pair? item) (cdr item) item))
             (is-sel? (= i selected))
             (is-focus? (and focused? is-sel?)))
        (draw-menu-item r col label #:selected? is-sel? #:focused? is-focus?)))))

;;;
;;; 3. Ventana Modal de Alerta y Confirmación (Alert / Breach Dialog)
;;;

(define* (make-modal-state title message #:key (type 'info) (danger? #f) (actions '("CANCELAR" "CONFIRMAR")))
  "Crea el estado para una ventana modal emergente interactiva."
  `((title . ,title)
    (message . ,message)
    (type . ,type)
    (danger? . ,danger?)
    (actions . ,actions)
    (focused-btn . 0)))

(define (modal-handle-key state key)
  "Maneja la navegación entre los botones del modal."
  (let* ((actions (assq-ref state 'actions))
         (btn-count (length actions))
         (cur-btn (assq-ref state 'focused-btn)))
    (case key
      ((left tab)
       (assq-set! (copy-tree state) 'focused-btn (if (> cur-btn 0) (1- cur-btn) (1- btn-count))))
      ((right)
       (assq-set! (copy-tree state) 'focused-btn (if (< cur-btn (1- btn-count)) (1+ cur-btn) 0)))
      (else state))))

(define (render-widget-modal state)
  "Renderiza el cuadro de diálogo modal sobre la pantalla actual."
  (let* ((title (assq-ref state 'title))
         (msg   (assq-ref state 'message))
         (danger? (assq-ref state 'danger?))
         (actions (assq-ref state 'actions))
         (cur-btn (assq-ref state 'focused-btn))
         (border-color (if danger? %color-red-crimson %color-cyan-neon))
         (title-color  (if danger? %color-red-crimson %color-cyan-neon)))

    ;; Fondo modal superpuesto (Row 8, Col 12, Ancho 58, Alto 10)
    (draw-card 8 12 58 10
               #:title title
               #:title-fg title-color
               #:border-fg border-color
               #:bg %color-bg-void)

    ;; Mensaje del modal
    (draw-text 10 15 msg #:fg (if danger? %color-red-crimson %color-text-ice) #:bold? danger?)

    ;; Botones de acción del modal
    (let ((col-start 20))
      (do ((i 0 (1+ i))
           (c col-start (+ c 18)))
          ((>= i (length actions)))
        (let* ((btn-label (list-ref actions i))
               (is-foc? (= i cur-btn))
               (btn-state (cond
                           ((and is-foc? danger? (= i (1- (length actions)))) 'danger)
                           (is-foc? 'focused)
                           (else 'normal))))
          (draw-button 15 c btn-label #:state btn-state))))))
