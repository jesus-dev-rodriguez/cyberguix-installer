;;; installer/tui/ansi.scm --- Control de secuencias ANSI TrueColor para CyberGuix
;;; Parte del CyberGuix Installer.

(define-module (installer tui ansi)
  #:use-module (ice-9 format)
  #:export (;; Paleta cromática CyberGuix "Breach"
            %color-bg-void
            %color-bg-card
            %color-bg-input
            %color-border-dim
            %color-cyan-neon
            %color-red-crimson
            %color-text-ice
            %color-text-dim
            %color-matrix-green
            %color-amber-warn

            ;; Secuencias básicas
            ansi-esc
            ansi-reset
            ansi-bold
            ansi-dim

            ;; Constructores de color
            ansi-fg-rgb
            ansi-bg-rgb
            paint-fg
            paint-bg
            paint

            ;; Control del terminal y cursor
            ansi-clear-screen
            ansi-move-cursor
            ansi-hide-cursor
            ansi-show-cursor))

;;;
;;; 1. Constantes de la Paleta "Breach" (RGB)
;;;

(define %color-bg-void      '(10 11 16))    ; #0a0b10 - Fondo base TTY
(define %color-bg-card      '(18 21 31))    ; #12151f - Fondo de card central
(define %color-bg-input     '(26 30 44))    ; #1a1e2c - Fondo de inputs/selectores
(define %color-border-dim   '(45 53 72))    ; #2d3548 - Bordes inactivos
(define %color-cyan-neon    '(0 240 255))   ; #00f0ff - Acento primario Cyber Cyan
(define %color-red-crimson  '(255 0 60))    ; #ff003c - Acento secundario Crimson Red
(define %color-text-ice     '(230 241 248)) ; #e6f1f8 - Texto principal
(define %color-text-dim     '(92 110 130))  ; #5c6e82 - Texto de baja prioridad
(define %color-matrix-green '(0 255 136))   ; #00ff88 - Éxito
(define %color-amber-warn   '(255 179 0))   ; #ffb300 - Advertencia

;;;
;;; 2. Secuencias ANSI de Estilo y Color TrueColor (24-bit)
;;;

(define ansi-esc "\x1b[")
(define ansi-reset "\x1b[0m")
(define ansi-bold "\x1b[1m")
(define ansi-dim "\x1b[2m")

(define (ansi-fg-rgb r g b)
  "Genera la secuencia ANSI de primer plano para el color RGB especificado."
  (format #f "\x1b[38;2;~a;~a;~am" r g b))

(define (ansi-bg-rgb r g b)
  "Genera la secuencia ANSI de fondo para el color RGB especificado."
  (format #f "\x1b[48;2;~a;~a;~am" r g b))

(define (paint-fg color-rgb text)
  "Pinta TEXT con el color de primer plano COLOR-RGB '(r g b) y restablece el estilo."
  (let ((r (car color-rgb))
        (g (cadr color-rgb))
        (b (caddr color-rgb)))
    (string-append (ansi-fg-rgb r g b) text ansi-reset)))

(define (paint-bg color-rgb text)
  "Pinta TEXT con el color de fondo COLOR-RGB '(r g b) y restablece el estilo."
  (let ((r (car color-rgb))
        (g (cadr color-rgb))
        (b (caddr color-rgb)))
    (string-append (ansi-bg-rgb r g b) text ansi-reset)))

(define (paint fg-rgb bg-rgb text)
  "Pinta TEXT con color de primer plano FG-RGB y fondo BG-RGB."
  (let ((fg-r (car fg-rgb))
        (fg-g (cadr fg-rgb))
        (fg-b (caddr fg-rgb))
        (bg-r (car bg-rgb))
        (bg-g (cadr bg-rgb))
        (bg-b (caddr bg-rgb)))
    (string-append (ansi-fg-rgb fg-r fg-g fg-b)
                   (ansi-bg-rgb bg-r bg-g bg-b)
                   text
                   ansi-reset)))

;;;
;;; 3. Control de Pantalla y Cursor
;;;

(define (ansi-clear-screen)
  "Limpia la pantalla y posiciona el cursor en la esquina superior izquierda (1,1)."
  (display "\x1b[2J\x1b[H"))

(define (ansi-move-cursor row col)
  "Mueve el cursor a la fila ROW y columna COL (basado en 1)."
  (format #t "\x1b[~a;~aH" row col))

(define (ansi-hide-cursor)
  "Oculta el cursor del terminal."
  (display "\x1b[?25l"))

(define (ansi-show-cursor)
  "Muestra el cursor del terminal."
  (display "\x1b[?25h"))
