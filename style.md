# Sistema de Diseño y Estilo TUI — CyberGuix Installer ("Breach" Edition)

Este documento define la **especificación estética y visual oficial** para el **CyberGuix Installer** (TUI interactiva de instalación para GNU Guix). La identidad visual está directamente extraída de la atmósfera de `wallpaper.jpg`: **estética Cyberpunk / Hacker Terminal / High-Contrast Glitch**, caracterizada por un fondo oscuro abisal, una tipografía digital estilo matriz/LED y la dualidad de iluminación de alto impacto entre **Cian Neón Eléctrico** y **Rojo Carmesí Glitch**.

---

## 1. Atmósfera e Identidad Visual (Referencia: `wallpaper.jpg`)

La interfaz del instalador no es una TUI estándar de oficina ni un tema pastel:
- **Atmósfera:** Terminal de operaciones cibernéticas, sobria, técnica, inmersiva y de alto contraste.
- **Dualidad cromática:**
  - **Cyber Cyan (Luz derecha):** Precisión, tecnología activa, selección, navegación y confirmación.
  - **Crimson Red (Luz izquierda / "DATA BREACH"):** Alerta, elevación de privilegios `sudo`, advertencias críticas, acento de contraste y potencia visual.
- **Tipografía e iconografía:** Inspirada en el texto matricial/pixelado y las líneas de escaneo (*scanlines*) del wallpaper.

---

## 2. Paleta Cromática "CyberArch Breach"

Valores exactos muestreados para la TUI en consola (TTY Linux framebuffer con soporte TrueColor / ANSI 256):

| Rol Semántico | Color Hex | RGB | ANSI 256 | ANSI 16 | Propósito en la TUI |
|---|---|---|---|---|---|
| **Abyss Void (Fondo Base)** | `#0a0b10` | `10, 11, 16` | `232` | `Black` | Fondo absoluto de la pantalla TTY |
| **Terminal Surface (Cards)** | `#12151f` | `18, 21, 31` | `234` | `Black` | Fondo de ventanas modales y paneles |
| **Sub-Surface (Inputs/Cajas)** | `#1a1e2c` | `26, 30, 44` | `236` | `Bright Black` | Interior de campos de texto y listas |
| **Grid / Borde Inactivo** | `#2d3548` | `45, 53, 72` | `238` | `Bright Black` | Líneas divisorias, bordes sin foco |
| **Cyber Cyan (Acento 1)** | `#00f0ff` | `0, 240, 255` | `51` | `Bright Cyan` | Bordes enfocados, cursor, selecciones, progreso |
| **Crimson Red (Acento 2)** | `#ff003c` | `255, 0, 60` | `196` | `Bright Red` | Título del instalador, avisos críticos, `sudo` |
| **Ice White (Texto Primario)** | `#e6f1f8` | `230, 241, 248` | `255` | `Bright White` | Texto de lectura, etiquetas y valores activos |
| **Slate / Dimmed Text** | `#5c6e82` | `92, 110, 130` | `243` | `White` | Descripciones secundarias, teclas de ayuda |
| **Matrix Green (Éxito)** | `#00ff88` | `0, 255, 136` | `48` | `Bright Green` | Operación completada, disco montado `[✓]` |
| **Amber Warning (Aviso)** | `#ffb300` | `255, 179, 0` | `214` | `Bright Yellow` | Confirmación destructiva de partición |

---

## 3. Caracteres, Glifos y Estilo Matricial TTY

Para emular el estilo digital/pixelado del wallpaper sin depender de fuentes externas en el Live-CD:

### 3.1 Banner y Tipografía de Matriz (Dot-Matrix Feel)
El titular de bienvenida y los encabezados principales emplean bloques Unicode sólidos y medios para emular las letras LED de `wallpaper.jpg`:

```
█▀▀ █▄█ █▀▄ █▀▀ █▀█   █▀▀ █░█ █ ▀▄▀   █ █▄░█ █▀▀ ▀█▀ ▄▀█ █░░ █░░
█▄▄ ░█░ █▀▄ ██▄ █▀▄   █▄█ █▄█ █ █░█   █ █░▀█ ▄██ ░█░ █▀█ █▄▄ █▄▄
```

### 3.2 Marcos y Bordes de Terminal Técnica
En lugar de esquinas redondeadas suaves, la estética *Breach* utiliza esquinas angulares técnicas o dobles, evocando consolas industriales de ciberseguridad:

- **Marco con esquinas técnicas y acentos:**
  ```
  ┌──[ // CYBERGUIX_INSTALLER // ]──────────────────────────────┐
  │                                                             │
  │  > INICIALIZANDO ENTORNO DECLARATIVO...                     │
  │                                                             │
  └─────────────────────────────────────────────────────────────┘
  ```
- Caracteres de línea estándar:
  - Esquinas: `┌` `┐` `└` `┘`
  - Conectores y derivaciones: `├` `┤` `┬` `┴` `┼`
  - Barras dobles para modales críticos: `╔` `╗` `╚` `╝` `═` `║`
  - Divisores de escaneo punteados: `┄` `┈` `╌`

### 3.3 Símbolos de Estado e Indicadores Glitch
- **Prompt activo:** `>` o `>>` en Cyber Cyan (`#00f0ff`)
- **Seleccionado:** `[■]` o `[●]`
- **No seleccionado:** `[ ]` o `[○]`
- **Check exitoso:** `[✓]` en Matrix Green (`#00ff88`)
- **Alerta / Peligro:** `[!]` o `[BREACH]` en Crimson Red (`#ff003c`)
- **Cursor de entrada de texto:** `█` parpadeante o `_`

### 3.4 Barra de Progreso "Digital Matrix"
Inspirada en las barras de estado y fragmentos de datos:
```
  [SYS_INSTALL] [████████████████░░░░░░░░░░░░] 64%  DESPLEGANDO NUCLEO
```
- Bloque activo: `█` (`#00f0ff` Cyber Cyan)
- Bloque inactivo: `░` o `·` (`#2d3548` Slate oscuro)

---

## 4. Anatomía de la Pantalla (Screen Layout)

Diseño de la consola TTY (resolución base de 80×25 caracteres, expansible dinámicamente):

```
┌──[ CYBERGUIX // SYSTEM INSTALLER ]────────────────────[ STEP 03/06: USER ]──┐
│ STATUS: ONLINE │ HARDWARE: MS-7721 │ SECURITY: SUDO_ONLY                     │
╞══════════════════════════════════════════════════════════════════════════════╡
│                                                                              │
│         ┌──[ CUENTA ADMINISTRADORA ]───────────────────────────────┐         │
│         │                                                          │         │
│         │  Defina las credenciales del usuario con acceso sudo.    │         │
│         │  ! AVISO: Cuenta 'root' deshabilitada por seguridad.     │         │
│         │                                                          │         │
│         │  FULL_NAME : [ Matías Rossi                            ] │         │
│         │  USER_NAME : [ red-mat                                 ] │         │
│         │  PASSWORD  : [ ••••••••••••••••                        ] │         │
│         │  CONFIRM   : [ ••••••••••••••••                        ] │         │
│         │                                                          │         │
│         │             [ < CANCEL ]      [ PROCEED ▶ ]              │         │
│         └──────────────────────────────────────────────────────────┘         │
│                                                                              │
├──────────────────────────────────────────────────────────────────────────────┤
│ [TAB] NAVIGATE  │  [ENTER] EXECUTE  │  [ESC] BACK  │  [F1] TELEMETRY         │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 4.1 Barra Superior (Header & Telemetría)
- **Marco:** `#2d3548` con rótulos en **Crimson Red** (`CYBERGUIX`) y **Cyber Cyan** (`SYSTEM INSTALLER`).
- **Sub-barra de telemetría:** Informa de perfil detectado (`MS-7721`) y estado del sistema en texto `#5c6e82`.

### 4.2 Ventana de Interacción (Card Central)
- **Fondo:** `#12151f` (Negro azabache con leve tinte azulado).
- **Borde enfocado:** `#00f0ff` (Brillo cian intenso).
- **Rótulo del módulo:** En corchetes técnicos `┌──[ TITULO ]──`.

### 4.3 Barra Inferior (Footer de Comandos)
- Fondo `#0a0b10` con los atajos en corchetes de alto contraste:
  - Tecla: Negrita en `#00f0ff` (ej. `[TAB]`).
  - Acción: `#5c6e82` (ej. `NAVIGATE`).

---

## 5. Especificación de Componentes de Interfaz

### 5.1 Botones de Acción
- **Botón Primario / En Foco:**
  - Formato: `▶ [ PROCEED ]`
  - Fondo: `#00f0ff` (Cian sólido)
  - Texto: `#0a0b10` (Negro profundo, negrita de alto contraste)
- **Botón Secundario / Sin Foco:**
  - Formato: `  [ CANCEL ]  `
  - Borde: `#2d3548`
  - Texto: `#5c6e82`
- **Botón de Acción Destructiva / Peligro (Formatear particiones):**
  - Formato: `! [ FORMAT DRIVE ]`
  - En foco: Fondo `#ff003c` (Rojo carmesí sólido), Texto `#ffffff`

### 5.2 Campos de Entrada de Texto (Inputs)
- **Sin foco:**
  `FIELD_NAME : [ texto inactivo                ]`
  - Borde: `#2d3548`, Texto: `#5c6e82`
- **En foco (Edición activa):**
  `FIELD_NAME : [>texto activo█                 ]`
  - Borde: `#00f0ff` (Cian), Prompt `>` y cursor de bloque `█`
  - Texto: `#e6f1f8` (Ice White)
- **Contraseñas:**
  - Ocultación mediante punto denso: `[>••••••••••••                ]`

### 5.3 Menús de Selección (Listas y Perfiles)
```
  [ ] 01. Perfil Generico Libre (linux-libre)
  [■] 02. Perfil MS-7721 (AMD Microcode + Nonguix Firmware)  <-- Foco
  [ ] 03. Perfil Servidor Minimal
```
- El elemento enfocado resalta con prefijo `[■]` en `#00f0ff` y fondo de fila sutil `#1a1e2c`.

### 5.4 Diálogo Modal de Alerta / Peligro ("Breach Alert")
Cuando se advierte sobre la sobreescritura del disco o pérdida de datos:
- Borde doble completo en **Crimson Red**: `╔═══[ ! WARNING: DISK OVERWRITE ]═══╗`
- Texto de aviso en Ice White con palabras clave resaltadas en rojo.
- Opciones de confirmación explícita: `[ CANCEL ]` predeterminado, `[ FORCE ERASE ]` en rojo neón.

---

## 6. Implementación en Guile Scheme (TTY Ansi Driver)

Mapeo de secuencias de escape en el módulo `(installer tui ansi)`:

```scheme
(define-module (installer tui ansi)
  #:export (%color-bg-void
            %color-bg-card
            %color-cyan-neon
            %color-red-crimson
            %color-text-ice
            %color-text-dim
            %color-matrix-green
            ansi-fg
            ansi-bg
            ansi-reset))

;; Colores CyberArch Breach (TrueColor RGB)
(define %color-bg-void     "\x1b[48;2;10;11;16m")
(define %color-bg-card     "\x1b[48;2;18;21;31m")
(define %color-cyan-neon   "\x1b[38;2;0;240;255m")
(define %color-red-crimson "\x1b[38;2;255;0;60m")
(define %color-text-ice    "\x1b[38;2;230;241;248m")
(define %color-text-dim    "\x1b[38;2;92;110;130m")
(define %color-matrix-green "\x1b[38;2;0;255;136m")

(define ansi-reset "\x1b[0m")
```

---

## 7. Criterios de Calidad Visual
1. **Contraste Extremo:** La combinación de fondo negro azabache con cian y rojo debe mantenerse nítida en monitores CRT, LCD o paneles de baja gama.
2. **Cero Artefactos en TTY:** Ningún carácter debe depender de parches UTF-8 no estándar; todo el renderizado se basa en ASCII imprimible y Unicode Box-Drawing universal.
3. **Identidad Inmediata:** Quien ejecute el instalador debe reconocer de inmediato la estética de `wallpaper.jpg` y saber que está instalando CyberArch sobre GNU Guix.
