;; -*- mode: scheme; -*-
;; Canal externo: Nonguix (kernel LTS, firmware no libre, microcódigo de CPU).

(define %nonguix-channel
  (channel
   (name 'nonguix)
   (url "https://gitlab.com/nonguix/nonguix")
   (commit "c241d19ff840dc75556f722b231760d119b6adea")
   (introduction
    (make-channel-introduction
     "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
     (openpgp-fingerprint
      "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5")))))
