#!/usr/bin/env -S guile -L . -s
!#
;;; installer/preview.scm --- Ejecutable de previsualización visual del CyberGuix Installer
;;; Uso: ./installer/preview.scm  o  guile -L . installer/preview.scm

(add-to-load-path (dirname (dirname (current-filename))))

(use-modules (installer tui app))

(define (main args)
  (run-cyberguix-tui))

(main (command-line))
