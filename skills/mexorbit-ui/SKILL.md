---
name: mexorbit-ui
description: Sistema de diseño UI de MexOrbit (dirección N aprobada). Invocar SIEMPRE antes de crear o modificar cualquier interfaz del juego — mockups HTML, UI del cliente Godot, CMS o herramientas. Carga los tokens, el chrome de ventana y las leyes de UX dictaminadas.
---

# Skill: interfaces de MexOrbit

Toda interfaz de MexOrbit se construye bajo la **dirección N** aprobada. Antes de escribir una sola línea de UI:

## 1. Cargar la fuente de verdad

Lee el documento canónico completo:

```
C:\Source\MexOrbit\mex-orbit-v1\mex-orbit-docs\05-arte\03-sistema-diseno-ui.md
```

Contiene: leyes de UX (dictámenes), tokens de color, tipografías, anatomía del chrome de ventana, taskbar, barras de acción, minimapa, overlays, iconografía y el checklist obligatorio.

La **referencia viva** (comportamiento e interacciones reales) es:

```
C:\Source\MexOrbit\mex-orbit-v1\mex-orbit-docs\05-arte\prototipo-ui-n.html
```

Ante cualquier duda visual o de interacción, se consulta el prototipo N, no capturas ni memoria.

## 2. Reglas de oro (resumen ejecutivo — el documento manda)

- **Todo es ventana**: minimizable, cerrable, arrastrable por su barra de título, reaperturable desde su icono del menú.
- **Un solo estado**: icono ámbar `#FFC85C` = ventana abierta; neutro = cerrada. Nunca doble código de color.
- **Solo iconos** en menús y barras; los textos localizables viven en tooltips.
- **Firma tipográfica**: etiqueta fría `#8A97B8` + número ámbar en JetBrains Mono con miles con punto (`8.421.900`). Títulos en Michroma uppercase con tracking; cuerpo en Exo 2.
- **Paleta cerrada**: fondo `#07070F`, cristal `rgba(13,17,29,.74)` con blur, cian `#00E5FF` (acento), violeta `#A78BFA`, hostil `#FF3D6E`, vida `#3DF58C`, escudo `#4DA6FF`. **No inventar colores.**
- Chrome de ventana: esquinas en L cian, banda de título con degradado y franja cian de 3px, chip de icono, botones `–`/`×`, grip diagonal.
- Dos barras de acción hexagonales (1–0 y F1–F10) con colores de contador heredados del cliente.

## 3. Flujo de trabajo

1. Leer el documento canónico (§1).
2. Construir aplicando el checklist del §12 del documento, punto por punto.
3. Si aparece un caso no cubierto (componente, color, patrón nuevo): **proponerlo al usuario**, y tras su aprobación **registrarlo en `03-sistema-diseno-ui.md`** en la sección que corresponda, en el mismo commit.
4. Para mockups HTML: verificar cero errores de consola en el navegador, republicar el artifact correspondiente (misma ruta = misma URL) y hacer commit+push a `mex-orbit-docs` con mensaje en español.
5. Para UI en Godot: aplicar §11 del documento (Theme central con los tokens, fuentes Michroma/Exo 2/JetBrains Mono, re-estilizar FloatingPanel conservando su comportamiento).

## 4. Prohibiciones

- No usar assets, colores ni texturas del cliente Flash/BigPoint.
- No introducir tipografías nuevas.
- No poner texto fijo dentro de botones de icono o barras (rompe i18n).
- No crear una segunda familia visual de iconos o estados: todo pertenece al mismo sistema.
