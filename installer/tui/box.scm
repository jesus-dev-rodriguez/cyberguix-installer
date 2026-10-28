;;; installer/tui/box.scm --- Primitivas de dibujo y widgets TTY para CyberGuix
;;; Parte del CyberGuix Installer.

(define-module (installer tui box)
  #:use-module (ice-9 format)
  #:use-module (installer tui ansi)
  #:export (draw-text
            draw-hline
            draw-card
            draw-button
            draw-input
            draw-progress-bar
            draw-menu-item))

;;;
;;; 1. Primitivas de Texto y Posicionamiento
;;;

(define* (draw-text row col text #:key (fg %color-text-ice) (bg #f) (bold? #f))
  "Imprime TEXT en la posición (ROW, COL) con los colores y atributos indicados."
  (ansi-move-cursor row col)
  (let* ((prefix (if bold? ansi-bold ""))
         (styled (cond
                  ((and fg bg) (paint fg bg text))
                  (fg          (paint-fg fg text))
                  (bg          (paint-bg bg text))
                  (else        text))))
    (display (string-append prefix styled ansi-reset))
    (force-output)))

(define* (draw-hline row col width #:key (char "─") (fg %color-border-dim) (bg #f))
  "Dibuja una línea horizontal de ancho WIDTH comenzando en (ROW, COL)."
  (let ((line (make-string width (string-ref char 0))))
    (draw-text row col line #:fg fg #:bg bg)))

;;;
;;; 2. Tarjetas y Marcos Técnicos (Cards)
;;;

(define* (draw-card row col width height
                    #:key
                    (title #f)
                    (title-fg %color-cyan-neon)
                    (border-fg %color-cyan-neon)
                    (bg %color-bg-card))
  "Dibuja una tarjeta técnica con fondo BG y borde BORDER-FG en (ROW, COL) con dimensiones WIDTHxHEIGHT."
  (let* ((h-char (string-ref "─" 0))
         (v-char "│")
         (c-tl "┌")
         (c-tr "┐")
         (c-bl "└")
         (c-br "┘"))

    ;; 1. Borde superior (con título opcional tipo `┌──[ TITULO ]──────┐`)
    (ansi-move-cursor row col)
    (if title
        (let* ((prefix (paint-fg border-fg "┌──[ "))
               (title-str (paint-fg title-fg title))
               (mid (paint-fg border-fg " ]"))
               (raw-len (+ 5 (string-length title) 2)) ; "┌──[ " + title + " ]"
               (remaining (max 0 (- width raw-len 1)))
               (tail (paint-fg border-fg (string-append (make-string remaining h-char) c-tr))))
          (display (string-append prefix title-str mid tail)))
        (let ((top-line (string-append c-tl (make-string (- width 2) h-char) c-tr)))
          (display (paint-fg border-fg top-line))))

    ;; 2. Filas interiores con fondo relleno
    (let ((inner-spaces (make-string (- width 2) #\space)))
      (do ((i 1 (1+ i)))
          ((>= i (1- height)))
        (ansi-move-cursor (+ row i) col)
        (display (paint-fg border-fg v-char))
        (display (paint-bg bg inner-spaces))
        (display (paint-fg border-fg v-char))))

    ;; 3. Borde inferior
    (ansi-move-cursor (+ row (1- height)) col)
    (let ((bottom-line (string-append c-bl (make-string (- width 2) h-char) c-br)))
      (display (paint-fg border-fg bottom-line)))

    (force-output)))

;;;
;;; 3. Widgets de Interfaz (Botones, Inputs, Menús)
;;;

(define* (draw-button row col label #:key (state 'normal))
  "Dibuja un botón en (ROW, COL). STATE puede ser 'normal, 'focused o 'danger."
  (case state
    ((focused)
     ;; Botón enfocado: bloque cian brillante de alto contraste
     (let ((text (format #f " ▶ [ ~a ] " label)))
       (draw-text row col text
                  #:fg %color-bg-void
                  #:bg %color-cyan-neon
                  #:bold? #t)))
    ((danger)
     ;; Botón de peligro (ej. Formatear disco)
     (let ((text (format #f " ! [ ~a ] " label)))
       (draw-text row col text
                  #:fg %color-text-ice
                  #:bg %color-red-crimson
                  #:bold? #t)))
    (else
     ;; Botón normal inactivo
     (let ((text (format #f "   [ ~a ]   " label)))
       (draw-text row col text
                  #:fg %color-text-dim
                  #:bg %color-bg-input)))))

(define* (draw-input row col label value width #:key (focused? #f) (password? #f))
  "Dibuja un campo de entrada con etiqueta LABEL y contenido VALUE."
  ;; 1. Etiqueta a la izquierda
  (let ((lbl (format #f "~14a : " label)))
    (draw-text row col lbl
               #:fg (if focused? %color-cyan-neon %color-text-dim)
               #:bold? focused?))

  ;; 2. Valor del input con máscara opcional
  (let* ((input-col (+ col 17))
         (val-display (if password?
                          (make-string (string-length value) (string-ref "•" 0))
                          value))
         (cursor-char (if focused? "█" " "))
         (prompt (if focused? ">" " "))
         (content (string-append prompt val-display cursor-char))
         (padded (if (< (string-length content) width)
                     (string-append content (make-string (- width (string-length content)) #\space))
                     (substring content 0 width))))
    (draw-text row input-col (format #f "[~a]" padded)
               #:fg (if focused? %color-text-ice %color-text-dim)
               #:bg %color-bg-input
               #:bold? focused?)))

(define* (draw-progress-bar row col label percentage width)
  "Dibuja una barra de progreso estilo digital matrix."
  (let* ((bar-width (- width (string-length label) 10))
         (filled-len (inexact->exact (round (* (/ percentage 100.0) bar-width))))
         (empty-len (max 0 (- bar-width filled-len)))
         (filled-str (make-string filled-len (string-ref "█" 0)))
         (empty-str (make-string empty-len (string-ref "░" 0))))
    (ansi-move-cursor row col)
    (display (paint-fg %color-cyan-neon (format #f "[~a] [" label)))
    (display (paint-fg %color-cyan-neon filled-str))
    (display (paint-fg %color-border-dim empty-str))
    (display (paint-fg %color-text-ice (format #f "] ~3d% " percentage)))
    (force-output)))

(define* (draw-menu-item row col label #:key (selected? #f) (focused? #f))
  "Dibuja una opción de menú/lista."
  (let* ((bullet (if selected? "●" "○"))
         (prefix (if focused? "▶ " "  "))
         (text (format #f "~a~a ~a" prefix bullet label)))
    (draw-text row col text
               #:fg (cond
                     (focused? %color-cyan-neon)
                     (selected? %color-text-ice)
                     (else %color-text-dim))
               #:bg (if focused? %color-bg-input #f)
               #:bold? focused?)))
