;; -*- mode: scheme; -*-
;; Paquetes locales del sistema Guix System.
;;
;; Programas que no se encuentran en los canales públicos de Guix y que se
;; construyen localmente en el repositorio.

(define opencode
  (package
    (name "opencode")
    (version "2.1.4")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://registry.npmjs.org/@opencode/cli-linux-x64-baseline/-/"
              "cli-linux-x64-baseline-" version ".tgz"))
        (sha256
         (base32 "09gx35ab9vdyspq32z677v99hdgb6ppg3x4y2wsrhgh664cmrjxz"))))
    (build-system copy-build-system)
    (arguments
      (list #:install-plan
            #~'(("package/bin/opencode" "bin/opencode"))
            #:phases
            #~(modify-phases %standard-phases
                (add-after 'install 'patch-interpreter
                  (lambda* (#:key outputs #:allow-other-keys)
                    (let ((binary (string-append (assoc-ref outputs "out")
                                                 "/bin/opencode")))
                      (invoke #$(file-append patchelf "/bin/patchelf")
                              "--set-interpreter"
                              #$(file-append glibc "/lib/ld-linux-x86-64.so.2")
                              binary)))))
            #:strip-binaries? #f
            #:validate-runpath? #f))
    (native-inputs (list patchelf))
    (inputs (list glibc))
    (home-page "https://opencode.ai")
    (synopsis "Agente de programación con IA para el terminal")
    (description
      "OpenCode es un agente de programación asistido por IA que se ejecuta
      en la terminal.  Esta es la compilación autónoma para Linux x86-64 sin AVX2.")
    (license expat)))
