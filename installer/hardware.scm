;;; installer/hardware.scm --- Detección dinámica y agnóstica de hardware y conectividad
;;; Parte del CyberGuix Installer.
;;; CERO VALORES HARDCODEADOS: todo se inspecciona en vivo desde /proc y /sys.

(define-module (installer hardware)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 format)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 popen)
  #:export (detect-host-cpu
            detect-host-ram
            detect-host-boot-mode
            detect-host-motherboard
            detect-host-gpu
            detect-host-disks
            has-default-route?
            has-active-carrier?
            check-internet-connection
            detect-host-hardware))

(define (safe-read-first-line path)
  "Lee la primera línea de PATH si existe y es legible, o retorna #f."
  (catch #t
    (lambda ()
      (if (file-exists? path)
          (call-with-input-file path
            (lambda (port)
              (let ((line (read-line port)))
                (if (string? line) (string-trim-both line) #f))))
          #f))
    (lambda _ #f)))

(define (detect-host-cpu)
  "Inspecciona /proc/cpuinfo y extrae dinámicamente el modelo y número de núcleos."
  (catch #t
    (lambda ()
      (let ((model #f)
            (cores 0))
        (call-with-input-file "/proc/cpuinfo"
          (lambda (port)
            (let loop ((line (read-line port)))
              (cond
               ((eof-object? line)
                (cons (or model "CPU x86_64 Generica") (max 1 cores)))
               ((string-prefix? "model name" line)
                (let ((m (string-trim-both (substring line (1+ (string-index line #\:))))))
                  (unless model (set! model m))
                  (loop (read-line port))))
               ((string-prefix? "processor" line)
                (set! cores (1+ cores))
                (loop (read-line port)))
               (else
                (loop (read-line port)))))))))
    (lambda _
      (cons "CPU x86_64 Generica" 1))))

(define (detect-host-ram)
  "Inspecciona /proc/meminfo y devuelve la memoria total real en GiB."
  (catch #t
    (lambda ()
      (call-with-input-file "/proc/meminfo"
        (lambda (port)
          (let loop ((line (read-line port)))
            (cond
             ((eof-object? line) 0.0)
             ((string-prefix? "MemTotal:" line)
              (let* ((num-str (list-ref (string-tokenize line) 1))
                     (kb (string->number num-str))
                     (gib (/ kb (* 1024.0 1024.0))))
                (/ (round (* gib 10.0)) 10.0)))
             (else (loop (read-line port))))))))
    (lambda _ 0.0)))

(define (detect-host-boot-mode)
  "Determina si la máquina arrancó en modo UEFI o Legacy BIOS."
  (if (file-exists? "/sys/firmware/efi")
      "UEFI x86_64"
      "BIOS (Legacy)"))

(define (detect-host-motherboard)
  "Detecta dinámicamente el fabricante y modelo de placa/equipo desde /sys/class/dmi/id/."
  (let* ((vendor (safe-read-first-line "/sys/class/dmi/id/sys_vendor"))
         (board  (safe-read-first-line "/sys/class/dmi/id/board_name"))
         (prod   (safe-read-first-line "/sys/class/dmi/id/product_name")))
    (cond
     ((and vendor board (not (string-null? board)))
      (format #f "~a ~a" vendor board))
     ((and board (not (string-null? board))) board)
     ((and prod (not (string-null? prod))) prod)
     (else "Equipo x86_64 Estandar"))))

(define (detect-host-gpu)
  "Detecta la tarjeta gráfica instalada mediante lspci o sysfs de forma agnóstica."
  (catch #t
    (lambda ()
      (let ((p (open-pipe* OPEN_READ "lspci")))
        (let loop ((line (read-line p))
                   (best #f))
          (if (eof-object? line)
              (begin
                (close-pipe p)
                (or best "Controlador VGA Estandar"))
              (if (string-contains-ci line "VGA compatible controller")
                  (let* ((idx (string-index line #\:))
                         (rest (if idx (substring line (1+ idx)) line))
                         (idx2 (string-index rest #\:))
                         (desc (if idx2 (substring rest (1+ idx2)) rest)))
                    (loop (read-line p) (string-trim-both desc)))
                  (loop (read-line p) best))))))
    (lambda _ "Controlador VGA Compatible")))

(define (detect-host-disks)
  "Inspecciona dinámicamente /sys/block/ y detecta unidades de disco físicas (SATA, NVMe, USB, VirtIO)."
  (catch #t
    (lambda ()
      (let ((disks '()))
        (when (file-exists? "/sys/block")
          (let ((entries (scandir "/sys/block" (lambda (f) (not (string-prefix? "." f))))))
            (when entries
              (for-each
               (lambda (entry)
                 (unless (or (string-prefix? "loop" entry)
                             (string-prefix? "ram" entry)
                             (string-prefix? "sr" entry))
                   (let* ((sys-path (string-append "/sys/block/" entry))
                          (dev-node (string-append "/dev/" entry))
                          (model-path (string-append sys-path "/device/model"))
                          (size-path  (string-append sys-path "/size"))
                          (model (or (safe-read-first-line model-path) "Disco Generico"))
                          (sectors (or (and=> (safe-read-first-line size-path) string->number) 0))
                          (gib (/ (* sectors 512.0) (* 1024.0 1024.0 1024.0)))
                          (rounded-gib (/ (round (* gib 10.0)) 10.0)))
                     (when (> rounded-gib 0.0)
                       (let ((label (format #f "~a ─ ~a (~a GiB)" dev-node model rounded-gib)))
                         (set! disks (cons (cons dev-node label) disks)))))))
               entries))))
        (if (null? disks)
            '(("none" . "No se detectaron discos de almacenamiento disponibles"))
            (reverse disks))))
    (lambda _
      '(("none" . "Error al inspeccionar unidades de almacenamiento")))))

(define (has-default-route?)
  "Verifica si existe una puerta de enlace predeterminada en la tabla de rutas del kernel."
  (catch #t
    (lambda ()
      (if (file-exists? "/proc/net/route")
          (call-with-input-file "/proc/net/route"
            (lambda (port)
              (let loop ((line (read-line port)))
                (cond
                 ((eof-object? line) #f)
                 ((string-contains line "\t00000000\t") #t)
                 (else (loop (read-line port)))))))
          #f))
    (lambda _ #f)))

(define (has-active-carrier?)
  "Verifica si alguna interfaz física (no loopback) tiene cable conectado o portadora activa."
  (catch #t
    (lambda ()
      (let ((carrier-found? #f))
        (when (file-exists? "/sys/class/net")
          (let ((ifaces (scandir "/sys/class/net" (lambda (f) (not (string-prefix? "." f))))))
            (when ifaces
              (for-each
               (lambda (iface)
                 (unless (string=? iface "lo")
                   (let ((c (safe-read-first-line (string-append "/sys/class/net/" iface "/carrier"))))
                     (when (and c (string=? c "1"))
                       (set! carrier-found? #t)))))
               ifaces))))
        carrier-found?))
    (lambda _ #f)))

(define* (check-internet-connection #:key (timeout-ms 350))
  "Comprueba de forma no bloqueante si hay salida a Internet real.
Primero valida si el kernel tiene cable y ruta por defecto; si existen, realiza un probe TCP a DNS."
  ;; 1. Si no hay cable conectado (carrier) ni ruta por defecto, estamos desconectados inmediatamente
  (if (or (not (has-active-carrier?)) (not (has-default-route?)))
      #f
      ;; 2. Hay enlace: comprobar conexión TCP no bloqueante a 1.1.1.1:53
      (catch #t
        (lambda ()
          (let ((s (socket AF_INET SOCK_STREAM 0)))
            ;; Configurar modo no-bloqueante
            (fcntl s F_SETFL (logior O_NONBLOCK (fcntl s F_GETFL)))
            ;; Iniciar conexión
            (catch #t
              (lambda () (connect s AF_INET (inet-pton AF_INET "1.1.1.1") 53))
              (lambda _ #f))
            ;; select en Guile espera (reads writes excepts secs usecs)
            ;; Donde secs y usecs DEBEN ser enteros exactos:
            (let* ((total-usecs (* (max 50 timeout-ms) 1000))
                   (secs        (quotient total-usecs 1000000))
                   (rem-usecs   (remainder total-usecs 1000000))
                   (res         (select '() (list s) '() secs rem-usecs)))
              ;; Comprobar si fue escribible y si no hubo error de socket
              (let ((connected? (and res
                                     (not (null? (cadr res)))
                                     (zero? (getsockopt s SOL_SOCKET SO_ERROR)))))
                (close-port s)
                connected?))))
        (lambda _ #f))))

(define (detect-host-hardware)
  "Ejecuta una inspección 100% dinámica de los componentes y almacenamiento del anfitrión."
  (let* ((cpu-info (detect-host-cpu))
         (cpu-name (car cpu-info))
         (cpu-cores (cdr cpu-info))
         (ram-gib   (detect-host-ram))
         (boot-mode (detect-host-boot-mode))
         (mobo      (detect-host-motherboard))
         (gpu-desc  (detect-host-gpu))
         (disks     (detect-host-disks))
         (online?   (check-internet-connection #:timeout-ms 500)))
    `((cpu-name    . ,cpu-name)
      (cpu-cores   . ,cpu-cores)
      (ram-gib     . ,ram-gib)
      (boot-mode   . ,boot-mode)
      (motherboard . ,mobo)
      (gpu-desc    . ,gpu-desc)
      (disks       . ,disks)
      (online?     . ,online?))))
