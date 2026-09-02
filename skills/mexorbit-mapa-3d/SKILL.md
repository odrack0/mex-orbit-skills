---
name: mexorbit-mapa-3d
description: Cómo montar el fondo 3D de un mapa al estilo DarkOrbit (display3D) en el cliente Godot — extraer el descriptor del decompilado, convertir coordenadas/rotaciones (espejo z), convertir mallas AWD y texturas ATF, montar planos esféricos, lensFlare, tilemap con máscara, skybox y luz, y calibrar contra el DO vivo. Invocar antes de montar o retocar el fondo de CUALQUIER mapa (props de data/maps/*.json, backdrop3d.gd, skybox, luz del mundo, pan de cámara) o de convertir assets del original.
---

# Skill: montar un mapa 3D estilo DarkOrbit

Todo lo de aquí se pagó con bugs reales el 31-ago-2026 montando el 1-1 de
referencia (commits `49d64eb`…`19f3576` del cliente). Regla madre del proyecto:
**tal cual DarkOrbit 3D, pero en Godot** — el valor se busca en el decompilado y
se aplica global; nada de calibraciones propias ni parches por objeto. Y cuando
el decompilado y el juego vivo discrepan, **el DO vivo jugado por el usuario es
el oráculo** (así se calibró el pan: la guía decía 25 y el juego real pedía 0).

## 1. Dónde vive cada cosa

| Qué | Dónde |
|---|---|
| Descriptor `display3D` por mapa | `D:\MexOrbit\Decompiled\spacemap\main\binaryData\178_...UberAssetsLib_LIB_MAPS_XML.bin` (buscar `map_X-Y`) |
| Registro de backgrounds (tilemaps) y máscaras | `...\binaryData\191__-N4e._-M29.bin` (`<background type=...>`, `<backgroundMask type=...>`) |
| Mallas AWD y texturas ATF | `C:\Source\MexOrbit\MexOrbit.CMS\public\spacemap\3d\{meshes,textures}` y `graphics\backgrounds\tilemaps` |
| PNG ya extraídos por el decompilador (¡preferirlos!) | `D:\MexOrbit\Decompiled\spacemap\3d\textures\*.png`, `...\graphics\...` |
| Máscaras de tiles | `Decompiled\spacemap\graphics\backgroundmasks\<resKey>\images\1_mask.png` |
| Lentes del flare | `Decompiled\spacemap\graphics\lensflares\lensflare<N>\sprites\DefineSprite_*_lens<i>\1.png` |
| Parser del display3D (verdad de las fórmulas) | `Decompiled\spacemap\main\scripts\§_-n3Z§\§_-115§.as` |
| Nuestro montaje | `mex-orbit-client\data\maps\<code>.json` + `game/backdrop3d.gd` + `game/stage3d.gd` |
| Conversores | `mex-orbit-art\tools\awd2obj.py`, `tools\atf2png.py` |

## 2. La conversión de coordenadas — el espejo z y sus consecuencias

Away3D es ZURDO; Godot diestro. Nuestro mundo espeja la z (`z_godot = −z_xml`
para posiciones de mallas; en términos de mapa, `z_godot = +y_mapa`). El espejo
arrastra TODO esto — cada punto olvidado fue un bug:

- **Posiciones**: x e y (altura) igual; z negada.
- **Rotaciones**: la reflexión NIEGA `rot_x` y `rot_y`; **`rot_z` queda igual**.
  Igual con los spins del `background_animation`: negar componentes x e y.
  (Los planos con `rotationX 45` del original van con `rot_x -45` aquí.)
- **Pan de cámara**: el signo se invierte… y la MAGNITUD se calibra en vivo
  (§8). Hoy: pan 0 para el 1-1.
- **Mallas**: awd2obj ya espeja z e invierte el orden de los triángulos. Los
  transforms del JSON NO deben re-espejar lo que la malla ya trae.

**Coordenadas esféricas** (planos de planeta/nebulosa). Fórmula EXACTA del
parser (`§_-rA§`), sobre el offset x/y/z del propio nodo:

```
x += R·sin(θ)·cos(φ);   y −= R·cos(θ);   z −= R·sin(θ)·sin(φ)     [luego espejar z]
```

Ej. 1-1: `planet114` φ=−90, θ=30, R=50000, x=10000 → Godot `(10000, −43301, −25000)`.

**lensFlare**: sus atributos XML se remapean `(x, −z, −y)` = (x_mapa, y_mapa,
altura). Ej. 1-1: XML `(34000, 48000, 26000)` → Godot `(34000, −48000, −26000)`.

## 3. Convertir assets

- **AWD → OBJ**: `py tools/awd2obj.py in.awd out.obj`. Exporta **normales**
  (stream 4 o calculadas). LECCIÓN: sin `vn`, Godot deja la malla sin difuso y
  se ve como **silueta negra** hagas lo que hagas con las luces.
- **ATF → PNG**: `py tools/atf2png.py in.atf out.png` (híbrido JXR+LZMA,
  Windows-only). Antes de convertir, buscar el PNG **ya extraído** en
  `Decompiled` — suele existir y evita errores del decodificador.
- **Atlas TexturePacker → atlas regular**: los subtextures del original son
  irregulares; nuestro `sprite_plano` usa hframes/vframes, así que se reempacan
  centrados en una rejilla (ej. clouds-grey: 3 nubes → rejilla 2×2 de 512,
  `celdas: 3, grid: 2`).
- **Máscaras de tiles**: la forma vive en el canal **ALFA** (el original hace
  `getPixel32 == 0` → celda vacía). Exportar EL ALFA como gris; convertir por
  luminancia deja la máscara vacía y "no salen nebulosas".

## 4. El JSON del mapa (lo que consume backdrop3d)

```jsonc
"pan_camara": 0,                  // opcional; ver §8
"props": [
  { "malla": "res://.../x.obj", "tex": "res://.../x.png",
    "x":, "y":, "z":, "escala":, "rot_x":, "rot_y":,      // signos YA espejados
    "spin": {"x":, "y":, "z":} },                          // grados/s, centro del rango random
  { "plano": true, "aditivo": true, "tex": ..., "escala": 50000,
    "x":, "y":, "z":, "rot_x": -45, "prioridad": -3, "modulate": "FFFFFF" },
  { "lensflare": true, "x":, "y":, "z": }                  // ya remapeado (§2)
],
"tiles_far": [
  { "tex": "res://.../atlas.png", "celdas": 3, "grid": 2,
    "y": -1300,          // cota ABSOLUTA: -3500 + layer·550
    "lado": 1536,        // tileWidth · tileScale del registro
    "margen": 1.3,       // mapScale
    "mask": "res://.../mask.png", "alpha": 1.0 }
]
```

Claves del original que informan el JSON:

- `plane`: `billboard` (por defecto true; los del 1-1 van `false`),
  `alphaBlending` (transparencia), `blendMode="add"` → `aditivo`.
  **`prioridad`** = `render_priority`: `background1` va R 50010 (10 unidades
  DETRÁS del planeta R 50000) → prioridad −3 vs −2, y así sus estrellas jamás
  se ven sobre el disco.
- `mesh`: `rotationY="random(360)"` → no hay guiñada canónica; se fija a ojo
  contra el DO vivo. `background_animation <append>` → `spin` (centro del rango).
- `tilemap`: `typeID` se resuelve en el registro 191 (`type 2024 =
  clouds-grey`, tileWidth 256…), `maskID` en `<backgroundMask>`; `layer` da la
  cota; los tiles llevan jitter propio −500..−200 (ya en backdrop3d).
- `lensFlare typeID N` → 11 lentes `lens0..lens10` del SWF; la cadena es
  `lente_i = sol_px + i · (−(sol_px − centro)·3/N)`; TODO el flare se oculta si
  el sol proyecta fuera del viewport. **NO** hay oclusión por ventanas del HUD
  (se probó y el DO vivo dice que no).

## 5. El skybox (el cielo NO es procedural)

`DOSkybox`: malla `skybox_geometry` + texturas `skybox_stars` (clamp) y
`skybox_mask` (repeat), pase exacto:

```
t = seg/120;  color = mask(uv+(2t, t+1)) · mask(uv+(−1.5t, t+0.3)) · stars(uv)
```

Réplica: `game/shaders/skybox_do.gdshader` sobre el OBJ, siguiendo a la cámara.
**Escala 160000** (radio ~69000, bajo el far 80000), NO el ×10000 del original:
su skybox es un pre-pase sin test de profundidad; el nuestro es un transparente
con prioridad −10 que SÍ testea — chico, **tapa con su negro estrellado todo lo
opaco más lejano que su radio** (pista del bug: estrellas DENTRO de la silueta
de un asteroide). `ALPHA = 1.0` explícito lo fuerza al pase de transparencias.

## 6. La luz del mundo

Es la del `<light>` del display3D (defaults si el mapa no lo trae): **blanca,
diffuse 1.0, specular 0.7, tilt 100 / pan 35** (misma fórmula esférica →
dirección, z espejada), **ambiente 0xFFA5AE a 0.2**. Vive en `AssetDefs`
(`world_sun`/`world_ambient`) y baña TODO por igual. Lecciones: con ambiente
0.5 los props se ven vivos/despegados; nada de luces extra por capa ni emisión
por prop para "arreglar" un objeto — si algo se ve mal, la causa es otra
(normales, oclusión del skybox, textura).

## 7. Trampas medidas (cada una fue un bug hoy)

- **Lineal vs sRGB**: 0.035 en un shader ES ~0.21 sRGB en pantalla — un "azul
  muy oscuro" de shader lava el cielo a gris. Verificar MUESTREANDO PÍXELES de
  la captura (`PIL im.getpixel`), no a ojo.
- **Un color liso y constante en el cielo** = no es textura: es un flat
  (BG_COLOR, base de shader, luz) — descartar por experimento (apagar una capa
  y recapturar).
- **Silueta negra con estrellas dentro** = skybox tapando (§5). **Silueta negra
  sin estrellas** = OBJ sin normales (§3).
- **DXT del ATF**: formato 4/5 lleva alfa; verificar `alfa media` del PNG
  resultante contra lo esperado antes de culpar al montaje.
- El polvo estelar debe leerse **solo en movimiento** (motas 2.4 u, rampa de
  grises 0.28–0.52): a 4 u casi blancas parecían "estrellas pegadas al mapa".

## 8. Calibrar contra el DO vivo

El usuario da referencias jugables ("en la base no se ve el sol", "aparece
bajando en diagonal en 42/35", "en el portal el sol queda a la derecha con
aire", "el portal está 25% sobre el planeta"). Con eso se SIMULA la proyección
(script Python: cámara FOV 30 vertical, dist 1740/zoom, tilt 135, viewport del
usuario) y se resuelve el pan/posición que cuadra TODAS a la vez — nunca mover
un dial a ojo por una sola observación. El bestiario (`dev-run.ps1 -Bestiario
-Calidad alta`) da capturas reproducibles para medir; para iterar con el
usuario basta **relanzar el cliente** (`dev-run.ps1`), sin gates.

## 9. Disciplinas al cerrar

- Commit por **lista explícita** de archivos (NUNCA `git add -A`: varias
  sesiones comparten el working tree), verificar `dev_login.cfg` fuera, mensaje
  en español, push a main, relanzar el cliente con ventana.
- Diales y lecciones nuevas → README del repo en el MISMO commit.
- Los assets del original en `assets/do-ref/` son TEMPORALES: confirmada la
  composición, se genera arte propio con estas especificaciones y se desmonta.
