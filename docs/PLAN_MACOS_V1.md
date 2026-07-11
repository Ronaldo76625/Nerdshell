# Nerdshell Desktop para macOS — plan de producto y arquitectura v1

Estado: planificación previa a implementación  
Plataforma inicial: macOS 14 o posterior  
Distribución inicial: descarga directa firmada y notarizada, fuera de Mac App Store

## 1. Decisión ejecutiva

Nerdshell v1 será una aplicación de terminal nativa y profesional para macOS,
independiente de Terminal.app, Ghostty y de la terminal predeterminada del
sistema. Su referencia funcional mínima será Terminal.app: una persona debe
poder realizar en Nerdshell su trabajo local y remoto habitual, incluyendo SSH,
sin abrir otra aplicación de terminal. Ejecutará el shell del usuario dentro de
un pseudoterminal (PTY) y cargará desde el primer inicio la apariencia y las
herramientas que distinguen a Nerdshell.

La app no reemplazará ni reescribirá `~/.zshrc`, `~/.zprofile`, `~/.gitconfig`
ni configuraciones de otras terminales. Nerdshell tendrá un perfil administrado
propio, pero seguirá siendo compatible con las herramientas, claves SSH,
agentes, runtimes y comandos instalados por el usuario.

La primera versión no intentará crear un emulador de terminal desde cero. Usará
un componente de emulación probado detrás de una interfaz interna, de modo que
el motor pueda cambiarse más adelante sin reescribir la aplicación.

La apuesta inicial será una terminal completa que ya viene bien configurada.
Nerdshell no será solo un instalador, un launcher ni una capa para otras
terminales.

## 2. Objetivos de la primera versión

La v1 debe permitir que una persona:

1. Descargue y abra `Nerdshell.app` como una aplicación normal.
2. Complete un onboarding corto sin modificar su configuración global.
3. Abra una sesión interactiva de Zsh en su directorio personal o en una carpeta.
4. Use colores ANSI, Unicode, Nerd Fonts, selección, copiar/pegar, scroll y cambio
   de tamaño de ventana correctamente.
5. Abra varias pestañas y cierre cada sesión de forma segura.
6. Consulte qué herramientas opcionales están disponibles o faltan.
7. Cambie preferencias básicas: fuente, tamaño, tema, shell y directorio inicial.
8. Cierre y desinstale la app sin que su terminal habitual haya cambiado.
9. Ejecute `ssh`, `scp`, `sftp`, port forwarding y herramientas remotas desde la
   sesión, usando OpenSSH y el agente del sistema.
10. Use Vim/Neovim, tmux, less, top, fzf, lazygit, REPLs y depuradores sin
    incompatibilidades importantes.
11. Abra carpetas como sesiones, arrastre rutas y use menús, teclado,
    accesibilidad y portapapeles propios de macOS.

## 3. No objetivos de la v1

Quedan expresamente fuera:

- Renderizador GPU propio.
- Sincronización en la nube y cuentas.
- Una interfaz propia para administrar hosts SSH, bóvedas de credenciales o
  sesiones remotas sincronizadas. El comando y protocolo SSH sí forman parte de
  la v1.
- Multiplexor completo tipo tmux.
- Marketplace de plugins.
- IA integrada.
- Compatibilidad con Linux o Windows en el mismo entregable.
- Instalación automática masiva de Homebrew, SDKMAN, NVM o toolchains.
- Mac App Store.
- Protocolos gráficos especializados como RDP o VNC.

Estos puntos podrán evaluarse después de validar estabilidad, adopción y uso.

## 3.1 Paridad mínima con Terminal.app

“Como Terminal.app” significa que Nerdshell deberá cubrir, como mínimo:

- Shells login e interactivos, ventanas, pestañas, títulos, pantalla completa y
  restauración.
- ANSI, VT100/xterm, 256 colores, true color, alternate screen, mouse y
  bracketed paste.
- Scrollback, búsqueda, selección, copiar/pegar y apertura de enlaces.
- Unicode, emoji, composición y caracteres de ancho doble.
- Drag and drop de rutas y apertura de una sesión en una carpeta.
- Señales y job control: `Ctrl-C`, `Ctrl-Z`, foreground/background y resize.
- Bell configurable y notificaciones cuando corresponda.
- `ssh`, `mosh` si está instalado, `scp`, `sftp`, túneles y agentes SSH.
- Uso de `~/.ssh/config`, `known_hosts`, claves y `SSH_AUTH_SOCK` sin copiar ni
  almacenar secretos dentro de Nerdshell.

La paridad se mantendrá como una matriz verificable. Una capacidad podrá
posponerse, pero no declararemos una versión profesional sin documentar las
brechas que obligarían al usuario a volver a Terminal.app.

## 4. Stack tecnológico recomendado

### Aplicación

- Swift 6 como lenguaje principal.
- SwiftUI para escenas, pestañas, toolbar, onboarding y preferencias.
- AppKit únicamente para alojar la vista de terminal, controlar first responder,
  teclado, portapapeles, arrastre de archivos y detalles de `NSWindow` que SwiftUI
  no pueda resolver limpiamente.
- Swift Package Manager para dependencias y módulos internos.
- Un proyecto Xcode nativo para construir, firmar, archivar y notarizar la app.

Se prioriza una app nativa sobre Tauri/Electron porque la primera plataforma es
solo macOS, la interacción de teclado y ventanas es crítica, y queremos menor
consumo de memoria, integración correcta con menús y una distribución sencilla.

### Motor de terminal

Primera opción para el prototipo: SwiftTerm, envuelto en un adaptador propio
`TerminalEngine`. Antes de adoptarlo definitivamente se hará un spike técnico
que valide:

- PTY local con Zsh interactivo.
- Teclas especiales, Option/Command, IME y composición de caracteres.
- Cambio de tamaño (`SIGWINCH`).
- Unicode, emoji, caracteres de ancho doble y Nerd Font.
- ANSI/256 colores/true color.
- Scrollback, selección, copiar/pegar y enlaces.
- Rendimiento con salida sostenida y archivos grandes.
- Alternate screen, mouse reporting, bracketed paste y shells remotos por SSH.
- Vim/Neovim, tmux, mosh, top/btop, fzf y lazygit local y remotamente.
- Licencia, mantenimiento y posibilidad de distribución comercial.

Si el spike no supera los criterios, se evaluará un motor AppKit alternativo.
No se acoplará la UI directamente a SwiftTerm.

### PTY y procesos

La capa `ShellSession` será responsable de:

- Crear y administrar el pseudoterminal.
- Lanzar el shell sin pasar por comandos concatenados o evaluados.
- Propagar tamaño, señales y estado de terminación.
- Mantener identificadores de proceso y cerrar hijos sin procesos huérfanos.
- Construir un entorno explícito y auditable.

Siempre que el motor elegido lo permita, usaremos sus primitivas PTY ya
probadas. Si no son suficientes, la implementación será nativa sobre `forkpty`
o `posix_spawn` y APIs POSIX, aislada detrás de `ShellSessionProtocol`.

## 5. Modelo de aislamiento

Los recursos administrados por la app vivirán dentro de:

```text
~/Library/Application Support/Nerdshell/
├── profiles/
│   └── default/
│       ├── zdotdir/
│       │   ├── .zshenv
│       │   ├── .zprofile
│       │   └── .zshrc
│       └── starship.toml
├── state/
└── logs/
```

Cada sesión recibirá variables controladas, como:

```text
ZDOTDIR=~/Library/Application Support/Nerdshell/profiles/default/zdotdir
STARSHIP_CONFIG=~/Library/Application Support/Nerdshell/profiles/default/starship.toml
TERM=xterm-256color
COLORTERM=truecolor
NERDSHELL=1
```

La v1 no copiará los archivos actuales del repositorio directamente sobre el
home del usuario. La configuración existente se refactorizará para:

- No asumir rutas de Homebrew concretas.
- Cargar integraciones solo cuando el binario correspondiente exista.
- No instalar herramientas durante el arranque del shell.
- No emitir errores si falta un complemento opcional.
- Mantener un tiempo de inicio objetivo inferior a 500 ms en una máquina normal.

El usuario podrá optar posteriormente por importar aliases o fragmentos de su
configuración, pero no se hará de manera implícita en la v1.

## 6. Arquitectura de módulos

```text
NerdshellApp
├── App
│   ├── escenas, comandos y ciclo de vida
│   └── composición de dependencias
├── Features
│   ├── Terminal
│   ├── Tabs
│   ├── Onboarding
│   ├── Diagnostics
│   └── Settings
├── Core
│   ├── TerminalEngine
│   ├── ShellSession
│   ├── ProfileManager
│   ├── ToolDetector
│   └── AppPaths
├── Platform
│   ├── AppKitTerminalView
│   ├── Pasteboard
│   └── WindowIntegration
└── Resources
    ├── DefaultProfile
    ├── Themes
    └── Fonts metadata
```

### Límites importantes

- SwiftUI será la fuente de verdad para pestañas, preferencias y estado visible.
- El objeto AppKit de terminal permanecerá dentro de un
  `NSViewRepresentable`; no será un singleton ni almacenará estado general.
- `TerminalEngine` expondrá entrada, salida, tamaño, título, estado y cierre.
- `ShellSession` no conocerá vistas.
- `ProfileManager` será la única capa autorizada a escribir configuración
  administrada por Nerdshell.
- Cada ventana tendrá su propio `WorkspaceModel`; las preferencias serán
  compartidas por la aplicación.
- SSH se ejecutará mediante OpenSSH dentro del PTY. Nerdshell conservará la
  configuración, las claves y el agente del sistema, en vez de implementar un
  transporte SSH incompatible o guardar credenciales propias.

## 7. Modelo de ventanas e interacción

- `WindowGroup` será la escena principal y permitirá múltiples ventanas.
- `Settings` será una escena nativa separada.
- Las pestañas pertenecerán a cada ventana, no a un estado global.
- Tamaño inicial sugerido: 1,000 × 680 puntos, con mínimo usable definido.
- Se conservarán tamaño y posición según el comportamiento estándar de macOS.
- La primera versión mantendrá titlebar y controles estándar; no comenzará con
  una ventana borderless personalizada.

Atajos mínimos:

| Acción | Atajo |
| --- | --- |
| Nueva ventana | Command-N |
| Nueva pestaña | Command-T |
| Cerrar pestaña | Command-W |
| Pestaña anterior/siguiente | Command-Shift-[ / Command-Shift-] |
| Limpiar pantalla | Command-K |
| Buscar en buffer | Command-F |
| Aumentar/reducir fuente | Command-+ / Command-- |
| Preferencias | Command-, |

Los comandos actuarán sobre la sesión enfocada mediante `FocusedValue` o un
puente equivalente. La vista AppKit manejará first responder, composición de
texto y eventos que no deban convertirse en shortcuts de la aplicación.

## 8. Pantallas de la v1

### Onboarding

- Presentación breve de Nerdshell.
- Confirmación del shell detectado.
- Verificación de una fuente compatible.
- Explicación explícita de que no se modificarán dotfiles globales.
- Creación del perfil administrado.

### Ventana principal

- Barra de pestañas.
- Área de terminal que ocupa el espacio disponible.
- Indicador discreto de proceso finalizado o error de inicio.
- Menú contextual para copiar, pegar, abrir enlace y reiniciar sesión.
- Drag and drop insertará rutas correctamente escapadas.
- “Nueva terminal en carpeta” aceptará carpetas elegidas por el usuario o
  recibidas desde Finder y servicios del sistema.

### Preferencias

- General: shell, directorio inicial y comportamiento al iniciar.
- Apariencia: tema, fuente, tamaño, cursor y opacidad si el motor la soporta.
- Perfiles: inicialmente un perfil predeterminado editable de forma limitada.
- Diagnóstico: rutas detectadas, shell, arquitectura y herramientas disponibles.

### Diagnóstico de herramientas

La v1 detectará, sin instalar automáticamente:

- Git, Zsh, Starship, eza, bat, fzf, fd, ripgrep, zoxide y delta.
- Homebrew y sus prefijos Apple Silicon/Intel.
- Node/NVM y Java/SDKMAN cuando existan.
- OpenSSH, `ssh-agent`, mosh y variables de agente disponibles.

Las instalaciones se ofrecerán posteriormente como acciones individuales con
explicación y confirmación.

## 9. Seguridad y privacidad

- No se registrará el contenido escrito ni la salida de la terminal.
- Nerdshell no leerá, copiará ni sincronizará claves privadas SSH.
- Los logs contendrán solo eventos técnicos y estarán desactivables.
- No habrá telemetría en la primera versión.
- No se ejecutarán strings mediante `sh -c` para iniciar una sesión.
- Shell, argumentos y directorios se pasarán como valores estructurados.
- Los enlaces externos requerirán una acción explícita del usuario.
- El pegado de texto multilínea mostrará advertencia antes de enviarse al shell.
- La verificación de host, passphrases y autenticación ocurrirá mediante OpenSSH
  dentro de la sesión; Nerdshell no interceptará credenciales.
- El proceso se distribuirá con Hardened Runtime, firma Developer ID y
  notarización.
- La primera distribución no activará App Sandbox: una terminal necesita lanzar
  procesos y acceder a los archivos que el usuario usa. Esta decisión deberá
  documentarse y revisarse antes de considerar Mac App Store.
- No se solicitarán Full Disk Access, Accessibility ni privilegios de
  administrador para el funcionamiento normal.

## 10. Persistencia

- `UserDefaults`/`@AppStorage` para preferencias simples.
- Archivos JSON versionados para perfiles cuando excedan preferencias simples.
- Keychain únicamente si una fase futura almacena secretos; la v1 no debe
  guardar contraseñas ni tokens.
- Escrituras atómicas y migraciones explícitas por versión de perfil.
- Restauración de ventanas siguiendo la configuración normal de macOS.

## 11. Calidad y criterios técnicos

### Pruebas automatizadas

- Unitarias para rutas, perfiles, variables, detección de herramientas y
  migraciones.
- Integración para crear una PTY, ejecutar comandos conocidos, redimensionar y
  cerrar sin dejar procesos.
- Integración SSH contra un servidor de prueba controlado: login, comando
  remoto, TUI, resize, desconexión y port forwarding.
- Pruebas de aislamiento que verifiquen que los dotfiles globales no cambian.
- UI tests para onboarding, pestañas, preferencias y recuperación tras cerrar
  una sesión.

### Pruebas manuales obligatorias

- Apple Silicon y, si se mantiene como objetivo, Intel.
- Teclado español e inglés, dead keys, Option y emojis.
- Light/Dark Mode, varias escalas de pantalla y monitor externo.
- Vim/Neovim, less, top/btop, fzf y una TUI como lazygit.
- SSH, SCP/SFTP, túneles, `~/.ssh/config`, agente y sesión TUI remota.
- Salida de colores, Unicode, enlaces, mouse reporting y resize.
- Suspender/reactivar, cerrar ventana, Command-Q y terminación de procesos.
- Directorios con espacios, tildes y caracteres no ASCII.

### Metas iniciales

- Primera ventana utilizable en menos de 1.5 segundos en hardware Apple Silicon
  reciente, después del primer lanzamiento.
- Shell interactivo disponible en menos de 700 ms; objetivo interno de 500 ms.
- Uso inactivo de memoria razonable y medido durante el spike; no se fijará una
  cifra contractual antes de conocer el motor.
- Cero modificaciones fuera del contenedor de datos de Nerdshell, salvo acciones
  explícitas del usuario.
- Cero procesos de shell huérfanos después de salir normalmente de la app.
- Cero flujos profesionales esenciales que obliguen a abrir Terminal.app sin
  que la brecha esté aceptada y documentada.

## 12. Fases de ejecución

### Fase 0 — decisiones y spike técnico

Entregables:

- Matriz de compatibilidad y licencia del motor elegido.
- Prototipo desechable: ventana, vista terminal, PTY y Zsh.
- Evidencia de teclado, Unicode, resize, TUI y cierre de procesos.
- Matriz inicial de paridad con Terminal.app, incluyendo SSH local/remoto.
- Medidas iniciales de arranque, CPU y memoria.
- Decisión documentada `go/no-go` para SwiftTerm.

Criterio de salida: el motor supera los casos esenciales o existe una alternativa
seleccionada. El código del spike no se promoverá automáticamente a producción.

### Fase 1 — runtime Nerdshell aislado

Entregables:

- Perfil Zsh autocontenido y refactorizado.
- `ProfileManager`, rutas de aplicación y generación versionada de configuración.
- Lanzador PTY con entorno explícito.
- Pruebas que demuestren que `~/.zshrc` y otros dotfiles no cambian.

Criterio de salida: el mismo runtime inicia de forma reproducible desde pruebas y
desde la app sin escribir configuración global.

### Fase 2 — aplicación mínima funcional

Entregables:

- Proyecto Xcode modular.
- Ventana principal, una sesión y manejo correcto de foco/resize.
- Copiar, pegar con protección multilínea, selección y scroll.
- Errores visibles y cierre limpio.

Criterio de salida: Nerdshell puede utilizarse durante una sesión real de trabajo
local y por SSH sin depender de Ghostty ni de Terminal.app.

### Fase 3 — experiencia de escritorio

Entregables:

- Pestañas y múltiples ventanas.
- Menús, shortcuts, búsqueda y títulos de sesión.
- Apertura en carpeta, drag and drop de rutas y flujos Finder.
- Preferencias y tema inicial.
- Onboarding y diagnóstico de herramientas.

Criterio de salida: todas las historias de usuario de la v1 están completas y
son accesibles por teclado.

### Fase 4 — estabilización y distribución

Entregables:

- Suite de pruebas y matriz manual completadas.
- Icono, About, licencia y créditos de dependencias.
- Build Release reproducible.
- Firma Developer ID, Hardened Runtime, notarización y DMG.
- Actualización del README y guía de recuperación/soporte.

Criterio de salida: una instalación limpia en otra Mac pasa onboarding, sesión,
actualización y desinstalación sin tocar los dotfiles del usuario.

## 13. Orden de implementación dentro del repositorio

1. Mantener los instaladores actuales operativos durante la transición.
2. Crear `docs/adr/` para decisiones de motor, sandbox y perfiles.
3. Crear la app en `apps/macos/Nerdshell/` sin convertir el repositorio en otro
   checkout Git.
4. Extraer el nuevo perfil aislado a `runtime/profiles/default/`.
5. Incorporar recursos a la app mediante un paso de build verificable.
6. Marcar los instaladores heredados como “Nerdshell Environment” cuando la app
   sea suficientemente estable, evitando confundir ambos productos.

El scaffold deberá incluir desde el inicio archivos separados para App, Views,
Models, Stores, Services y Support, además de un script local de build/run y la
configuración de entorno de Codex. No se concentrará la app en un único archivo.

## 14. Decisiones pendientes antes de escribir producción

Estas decisiones deben cerrarse durante la Fase 0:

1. Resultado del spike de SwiftTerm y licencia aprobada.
2. Soporte Intel: incluirlo en v1 o limitar el lanzamiento inicial a Apple
   Silicon. Recomendación: universal si el motor y CI lo permiten sin duplicar
   el esfuerzo de forma importante.
3. Fuente: incluir una fuente con licencia redistribuible o detectar/recomendar
   JetBrains Mono Nerd Font. Recomendación: no descargarla silenciosamente.
4. Política de actualización: manual para builds internos; Sparkle o mecanismo
   equivalente después de estabilizar firma y distribución.
5. Identidad de firma, Team ID, bundle identifier y política de releases.
6. Licencia comercial y avisos de terceros del producto final.

## 15. Definición de “v1 terminada”

Nerdshell v1 estará terminada cuando una persona pueda instalar una app firmada,
usarla como su terminal principal para trabajo local y remoto por SSH, abrir
múltiples sesiones, trabajar con aplicaciones TUI comunes, personalizar lo
esencial y eliminarla sin encontrar cambios en su terminal habitual. La v1 no
estará terminada solo porque muestre un prompt dentro de una ventana.

## 16. Evolución posterior a la terminal local

Una vez que la terminal sea estable y profesional, el producto podrá crecer sin
cambiar su fundamento:

1. Perfiles visuales de hosts SSH y snippets, compatibles con OpenSSH.
2. Cuenta Nerdshell opcional.
3. Sincronización cifrada de preferencias, temas y perfiles no secretos.
4. Equipos, políticas y administración empresarial.
5. Servicios cloud y continuidad de sesiones donde tenga sentido.
6. Evaluación de Mac App Store, entitlements y una variante compatible con sus
   restricciones, sin degradar la distribución profesional directa.

Las funciones cloud serán opcionales. La terminal local deberá seguir
funcionando sin cuenta, sin conexión y sin depender de un servicio de Nerdshell.
