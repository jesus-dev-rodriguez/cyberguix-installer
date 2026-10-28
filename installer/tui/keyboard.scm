;;; installer/tui/keyboard.scm --- Manejo de eventos de teclado en consola TTY
;;; Parte del CyberGuix Installer.

(define-module (installer tui keyboard)
  #:export (with-raw-terminal
            read-key
            read-event-with-timeout))

(define (enable-raw-mode)
  "Configura el terminal en modo raw sin eco."
  (system "stty raw -echo 2>/dev/null"))

(define (restore-cooked-mode)
  "Restaura el modo normal (cooked) del terminal."
  (system "stty -raw echo 2>/dev/null"))

(define (with-raw-terminal thunk)
  "Ejecuta THUNK asegurando restaurar el modo del terminal al salir o ante errores."
  (dynamic-wind
    (lambda () (enable-raw-mode))
    thunk
    (lambda () (restore-cooked-mode))))

(define (parse-key-stream)
  "Lee un carácter o secuencia de escape de terminal ya disponible en stdin."
  (let ((ch (read-char)))
    (cond
     ((eof-object? ch) 'eof)
     ((or (char=? ch #\newline) (char=? ch #\return)) 'enter)
     ((char=? ch #\tab) 'tab)
     ((or (char=? ch #\backspace) (char=? ch (integer->char 127))) 'backspace)

     ;; Secuencia de Escape (Flechas, F1, F2, Esc)
     ((char=? ch (integer->char 27))
      (if (char-ready?)
          (let ((next1 (read-char)))
            (cond
             ;; Prefijo CSI \e[
             ((char=? next1 #\[)
              (let ((code (read-char)))
                (case code
                  ((#\A) 'up)
                  ((#\B) 'down)
                  ((#\C) 'right)
                  ((#\D) 'left)
                  ((#\Z) 'shift-tab)
                  ;; F1 en consola Linux pura (\e[[A)
                  ((#\[)
                   (if (char-ready?)
                       (let ((c (read-char)))
                         (case c
                           ((#\A) 'f1)
                           ((#\B) 'f2)
                           (else 'escape)))
                       'escape))
                  (else
                   ;; F1 en xterm/rxvt (\e[11~) o similares
                   (if (char-numeric? code)
                       (let loop ((acc (string code)))
                         (if (char-ready?)
                             (let ((c (read-char)))
                               (if (char=? c #\~)
                                   (cond
                                    ((string=? acc "11") 'f1)
                                    ((string=? acc "12") 'f2)
                                    ((string=? acc "1")  'f1)
                                    (else 'f1))
                                   (loop (string-append acc (string c)))))
                             'escape))
                       'escape)))))

             ;; Prefijo SS3 \eO (muy común en terminales para F1..F4: \eOP = F1)
             ((char=? next1 #\O)
              (if (char-ready?)
                  (let ((code (read-char)))
                    (case code
                      ((#\P) 'f1)
                      ((#\Q) 'f2)
                      (else 'escape)))
                  'escape))

             (else 'escape)))
          'escape))

     (else ch))))

(define (read-key)
  "Lectura bloqueante simple de tecla."
  (parse-key-stream))

(define* (read-event-with-timeout #:optional (timeout-secs 1))
  "Espera eventos de teclado por hasta TIMEOUT-SECS segundos.
Retorna '(key . <simbolo/char>) si se presionó una tecla, o '(tick) si expiró el tiempo."
  (let ((ready (select (list (current-input-port)) '() '() timeout-secs 0)))
    (if (and ready (not (null? (car ready))))
        (cons 'key (parse-key-stream))
        '(tick))))
