---
name: mexorbit-asset-3d
description: Pipeline de un asset 3D de MexOrbit, de Meshy al juego. La malla GLB es el UNICO cuerpo de cada entidad, en los tres niveles de calidad (desde el 1-sep-2026 no hay PNG horneado ni atlas). Invocar antes de montar desde un modelo 3D cualquier bicho, nave o PROP del mapa (estacion, portal, caja), y antes de tocar normalize-model.py, riguear-modelo.py, marcar-anclajes.py, el camino 3D de entity_node.gd, portal_node.gd o el de la estacion/caja en world.gd. Cubre tambien la emision por canal, los rig radiales y por que un prop no se tumba como un bicho.
---

# Skill: montar un asset 3D de MexOrbit

**Un asset, UNA salida.** El GLB es la fuente y es el cuerpo de la entidad en los tres
niveles de calidad; la calidad ya no cambia *qué* es una nave, cambia cuánto cuesta
dibujarla (resolución del render, antialias, luces, partículas — ver «Calidad gráfica»
en el README del cliente). Hasta el 1-sep-2026 media y baja eran PNG horneados del
mismo modelo: eso murió, con su horno, sus atlas de vídeo y su homologación.
**Una entidad sin `modelo` en su JSON no se dibuja** — existe (HUD, click, combate)
pero no tiene cuerpo. No hay respaldo, a propósito: un respaldo que nadie mira es la
forma de que una especie se quede sin malla para siempre.

## La cadena, en orden

Rutas relativas a `C:\Source\MexOrbit\mex-orbit-v1\`. Blender es
`"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe"`.

**1. Meshy.** Remesh a ~10-15 k tris **encendido** (sin él da una sopa de cáscaras
solapadas). Modo Ultra **apagado**. Pose de la imagen = pose de reposo. Texturas
4096. La tabla completa está en el README de arte, sección «LA RECETA». **El
presupuesto de polígonos se resuelve AQUÍ, no en `normalize-model.py`** (31-ago-2026:
el decimador salió del script — ver más abajo). Si un crudo llega por encima de
presupuesto, se reexporta de Meshy con el remesh corregido; `normalize-model.py`
ya no decima nada.

**1b. Si el bicho «solo se ve bien» a 100 k: hornear, no aceptar.** Meshy remeshea pero no
hornea. `tools/hornear-normales.py <alto.glb> <bajo.glb> <salida.glb>` (mex-orbit-art) cuece el
relieve del crudo de 100 k como normal map sobre su remesh de 12–15 k (mismo generado, mismo
espacio) en ~2 s, y la salida entra en la cadena como crudo. Medido con el Skarn (104 k → 12 k): en
el retrato del bestiario no se distingue. Juzga siempre al tamaño de juego (124–248 px), nunca en
el visor de Meshy a pantalla completa. En Meshy: generar SIN textura (sale el alto de 1,5–3 M) →
remesh a 12–15 k → texturizar solo el remesh. El alto va a `source/3d-models/crudo/alto/<bicho>.glb`
y el remesh texturizado a `source/3d-models/crudo/<bicho>.glb`; ninguno se versiona (`crudo/` está
en el .gitignore), el master normalizado sí.

**2. Crudo → master normalizado** (en `mex-orbit-art`):

```bash
blender --background --factory-startup --python tools/normalize-model.py -- \
    source/3d-models/crudo/<bicho>-vN.glb source/3d-models/<bicho>.glb 1024 r 1.0 0.0005
```

**El canal es el COLOR de lo que brilla**, y hay seis: `r/g/b` primarios y
`c/m/y` secundarios. **Un color secundario no lo ve la dominancia por canal**: la
máscara es «canal menos el mayor de los otros dos», y el cian es verde *y* azul
altos a la vez, así que ninguno domina y sale ~0. Medido en el Vorax de cristales
cian: por canal, el verde cazaba un 6,3 % con p99 de 0,031 —ruido— y el azul un
0,0 %; como cian (`min(g,b) − r`), un 40 % con p99 de 0,569.

Pedirlo por primario **no da error**: da un modelo que no brilla, y eso solo se
descubre mirándolo en el juego. Antes de elegir canal, mira de qué color es lo que
tiene que encenderse.

**El albedo se apaga donde emite** (`APAGAR`, 1,0 por defecto desde el 2-sep-2026): si el base
color conserva el acento saturado, el sol lo enciende con la emisión a cero y el pulso no se ve
(medido: ACI-01 igual de brillante con energía 0,05 y 3,0). Un pulso «que no se nota» se mide con
dos bestiarios con la emisiva fija en el mínimo y en el máximo, no a ojo.

**La GANANCIA es la palanca del COLOR.** Si el bicho pide más intensidad de la que
el albedo da (la lava del Skarnox: grietas a 0,4 que ni el pulso ni el glow
levantaban a «naranja intenso»), la palanca es la ganancia del normalizador (el
Skarnox va a **2,0**) — no subir el pulso a lo loco ni inventar diales aguas abajo.

**`UMBRAL` (variable de entorno del normalizador) es para el cuerpo que ES del color de su
acento.** El Mordax es rojo oscuro con venas rojo vivo: con la máscara a secas emitía el
99,9 % (p50 0,18, cinco veces el marfil del Ferox) — la trampa de la estación sin un segundo
color al que huir. `UMBRAL=0.3` deja solo lo que domina por encima de 0,3, reescalado a 0..1:
quedaron las venas (9,5 %). 0 = sin umbral, como siempre.

**Y la cifra de cobertura sola no dice nada, en NINGUNA dirección.** La trampa de
la estación es cobertura alta que sí era veneno (el azul dominaba el 92 % porque
el casco entero es azul-gris). El Ferox fue lo contrario: «80,6 % de la textura
emite» con canal `r` huele a esa trampa, pero medida la **distribución** era
benigna — el marfil del cuerpo es apenas r-dominante (máscara ~0,04, emisiva
resultante ~0,02) y los acentos reales, ojos y vetas con albedo 0,72/0,19/0,21,
son el 5,4 % por encima de 0,35 con p99 de 0,62. Ni el pánico ni la confianza se
sacan del porcentaje: antes de cambiar canal o ganancia, mide p50/p99 de la
máscara y el albedo de donde pega alto contra donde pega bajo. Un minuto de
numpy ahorra una vuelta a ciegas.

**3. Master → asset de juego con esqueleto:**

```bash
blender --background --factory-startup --python tools/riguear-modelo.py -- \
    source/3d-models/<bicho>.glb <cliente>/assets/npcs/<bicho>.glb 0.30 0.22 0.32 3
```

**Las tres partes son opcionales, y la señal es la MALLA.** Las alas se saltan si
ningún vértice pasa la bisagra, los cuernos con `CUERNO_DESDE = 0` y la cola con
`COLA_SEG = 0`. Forzar los diales para fingir que existen no monta un bicho raro:
monta **huesos sin un solo vértice que pese en ellos**, y un hueso muerto no avisa
— se descubre el día que alguien intenta animarlo. Peor con los cuernos, que están
acotados por `BISAGRA`: subirla para «desactivar» las alas les da la cabeza entera.

Y apagar por diales **no es apagar**. Intentar quitar la cola con un `COLA_DESDE`
minúsculo dejó `cola_1` cogiendo peso entero encima del de `raiz`: la suma por
vértice salió **2,000 exacto**, que es la firma de dos huesos reclamando lo mismo
al 100 %.

**Bicho RADIAL** (una estrella de tentáculos, no un bicho con alas): `RADIAL=N`
monta un anillo de huesos hermanos colgados de la raíz.

```bash
RADIAL=8 RADIAL_DESDE=0.45 RADIAL_ARCO=26 \
blender --background --factory-startup --python tools/riguear-modelo.py -- \
    <master> <salida.glb> 3.0 0.10 0.0 0 0 0.075
#   bisagra alta = sin alas · cola 0 = sin cola · cuerno 0 = sin cuernos
```

Los ángulos **se miden**, no se reparten a 360/N: un modelo generado sale
asimétrico, y los ocho brazos del Vorax caen en 36, 84, 102, 122, 146, 188, 286 y
342 grados. Repartirlos habría puesto huesos entre dos brazos. El histograma
angular tiene que ser **circular** —envolviendo— o un brazo a 358° se parte en dos
y sale como dos brazos flacos.

El peso de un brazo es el **producto de dos rampas, radial y angular**: con solo
la radial el hueso se lleva un anillo entero, y con solo la angular una cuña que
llega hasta el centro. Los brazos vecinos se reparten el solape en vez de sumar
más de 1 — mismo fallo que tuvieron los cuernos.

**4. Validar antes de seguir** (en `mex-orbit-testing`, Python puro, sin Blender ni Godot):

```bash
py mex-orbit-testing/assets/validar-modelo.py <cliente>/assets/npcs/<bicho>.glb
```

Comprueba piezas, triángulos, texturas, caja, pivote, emisión, desbalance de luz
cocida y **esqueleto**. La caja tiene que salir plana (el eje fino es el alto).

**Rechazo conocido que NO es del asset**: el tope de textura del validador (512)
está desfasado de la receta, que saca el master a 1024 — el Vex y el Vexor, en
producción y correctos, dan el mismo `RECHAZAR ... el tope es 512` con exit 1.
Hasta que se alinee el contrato, ese rechazo se ignora; lo que NO se hace es
«arreglar» el asset bajándolo a 512, que es la reacción natural al mensaje. El
resto de rechazos sí mandan.

**5. Enchufarlo al cliente.** En `data/npcs/<bicho>.json` (o `data/props/<prop>.json`,
`data/ships/<nave>.json`):

```json
"modelo": "res://assets/npcs/<bicho>.glb",
```

Y ya está: `entity_node._build_visual()` monta la malla en todos los niveles;
la estación, la caja y el portal hacen lo mismo desde `world.gd` / `portal_node.gd`
(escalados a `world_size` por su huella). Si el bicho pide **emisión que VIAJA**
(lava, energía recorriendo vetas), existe el dial `lava` en el JSON: monta
`game/shaders/lava_flow.gdshader` como `next_pass` aditivo sobre la copia del
material — el ruido corre sobre la **posición local** (los islotes de UV de Meshy
partirían el flujo) y late en fase con el pulso, que no se toca. El destello 3D
va al reloj de las **alas**: un bicho sin alas hereda el ciclo del Vexor (2,17 s)
salvo que su JSON declare `"alas": {"ciclo": N}` — solo el reloj, sin huesos. Con
`emissive` a 0 (solo por auto-calidad) el pulso se congela y la lava no se monta.

Y existe el bloque **`luz`** (`{"sol": N, "ambiente": N}`): la excepción por bicho
a la luz del mundo, para el que se lee **autoiluminado** (el Skarnox va a un
cuarto del mundo). El bicho se mira al lado de un vecino normal: dos luces
distintas pueden leerse como dos recortes pegados.

**Reimportar** después de copiar un GLB o una textura (`godot --headless --path .
--import`): sin eso Godot sirve el recurso viejo de la caché y parece que el
cambio no hizo nada.

## LOS DIALES SON POR BICHO

Los valores que aparecen arriba se calibraron con el **Vexor**. **No se heredan.**
El Vex, segundo bicho de la cadena, cambió casi todos: es más largo que ancho (al
revés que el Vexor) y emite en un solo ojo en vez de en toda la superficie.

| | Vexor | Vex | Vorax |
|---|---|---|---|
| forma | alas + cola | alas + cola | **radial, 8 brazos** |
| `BISAGRA` / `BANDA` del ala | 0,30 / 0,22 | 0,18 / 0,16 | sin alas (3,0) |
| `COLA_DESDE` | 0,32 | 0,24 |
| `cuernos_grados` / `cuernos_eje` | [−14, +14] / eje 1 | [−20, 0] / **eje 2** |

Ferox: alas 0,24/0,14, cola 0,28, sin cuernos. Gravit, Gravon, Mordax y Skarn (1-sep) van **sin
esqueleto**: discos y bolas con perfil liso, sin lóbulos que riguear; su vida es el pulso. La
tabla completa del catálogo, con canal, umbral, triángulos y tumbado por especie, está en el README
de arte («El catálogo entero por la cadena solo-malla»).

**Las bisagras salen del perfil de la malla**, no de copiar el bicho anterior: saca
el ancho (`|X|` p95) por bandas de Y y busca el salto. En el Vex pasa de 0,101 a
0,749 entre Y −0,599 y −0,479 — ahí empiezan las alas y ahí acaba la cola.

**La luz del mundo vive en UN dial**: `AssetDefs.world_ambient` + `AssetDefs.world_sun`
(antes estaba copiada a mano en ocho sitios y subirla exigía acertar ocho ediciones).
Nunca montes un `Environment` 3D a mano, ni en una escena de pruebas.

**Si el crudo viene por encima de presupuesto, se reexporta de Meshy con el remesh
corregido** (31-ago-2026: `normalize-model.py` ya no decima — ver «El remesh vive
en Meshy» más abajo). Está medido que el presupuesto importa: 10k → 31k tris
cuesta un 38 % de fps, así que un crudo pasado de tris no se acepta tal cual.

## Si es una NAVE: los anclajes de motores y cañones

Una nave necesita dos cosas que un bicho no: de dónde sale cada llama y por dónde
dispara cada cañón, en el espacio del modelo que gira.

**Paso extra en la cadena, entre normalizar y enchufar:**

```bash
blender --background --factory-startup --python tools/marcar-anclajes.py -- \
    source/3d-models/<nave>.glb <cliente>/assets/ships/<nave>.glb \
    0.09 0.75 60 <n_toberas> "<x1,x2,...>" <ancho>
```

Mete en el GLB nodos vacíos `tobera_1..N` y `canon_izq`/`canon_der` en **unidades
del modelo**, con el **ancho de cada boca en la escala del nodo** (un sitio estándar
de glTF, sobrevive al importador). `validar-modelo.py` los lista en MARCADORES.
En el cliente los lee `_montar_anclajes`: las llamas (GPUParticles3D, el thruster
del original) y las bocas cuelgan del cuerpo que gira.

### Mide las bocas en el RENDER, no en la malla

**Esto es lo que costó cinco rondas.** Contar densidad de vértices NO funciona: la
popa tiene anillos, soportes y tubería entre toberas que el histograma mete en el
mismo saco. Se probaron tres variantes sobre la malla (media del lóbulo, punto
medio del extremo, convergencia en ventana) y **ninguna** salió simétrica, que es
la propiedad que una nave tiene de verdad.

`tests/view_anchors.tscn` renderiza con la **misma proyección del juego**, pinta
una cruz en cada marcador con una barra de su ancho, **y mide las bocas sobre la
silueta**. Sus números son los que se le pasan a `marcar-anclajes.py`.

```bash
godot --path . res://tests/view_anchors.tscn -- --model=ships/<nave>.glb
```

En el Phoenix: la malla daba centros asimétricos y ancho 0,103; el render dio
−0,233 / −0,094 / +0,090 / +0,229 y ancho 0,135. **Cuando la malla y la imagen
discrepan, manda la imagen** — el problema es del ojo.

**PERO la imagen tiene que ser la del juego de verdad, y con la cámara 3D
inclinada la cenital ya no lo es.** La Phoenix v2 trae la popa en **ANILLO** de
seis campanas: la silueta cenital solo ve la fila de abajo (los pares superiores
proyectan encima de los inferiores) y con ella se montaron **cuatro llamas en
fila, flacas** (ancho de silueta 0,134 contra 0,165 real de cada boca) sobre una
popa de seis. Vistas con el tilt del cliente 3D, cantaban. Para una popa en
anillo: `tools/medir-campanas.py` (mex-orbit-art) agrupa la banda de popa en el
plano X-Z y da las seis bocas con su altura, y `marcar-anclajes.py` las acepta
como `x@z` (la vecindad se acota también en Z, o la boca de arriba coge los
vértices de la de abajo). La verificación que manda pasa a ser la captura del
autotest con la cámara inclinada, no el render cenital.

Y **la rebanada no se toma al ras de la popa**: ahí las campanas se tocan de dos en
dos, que era literalmente el síntoma («veo dos motores en una nave de cuatro»). Hay
que subir hasta la primera fila donde salgan separadas.

### La llama: lo que quedó de tres trampas

Las llamas son partículas (el `thruster.awp` del original) y su tamaño va en la
escala del nodo, que `_process` **multiplica** por el empuje cada fotograma —
fijarla al crearla dura un frame. Se dimensiona por el ancho de **su** boca, no por
la separación entre bocas. Y el disco de emisión va **en el filo** del marcador:
el medio ancho hacia proa era del quad viejo.

### Lo demás

- **Pasa el número de toberas.** Contarlas por valles dio 2 en vez de 4.
- **De la tobera, su punto más trasero; del cañón, su punta delantera.** No el
  centro de masa: la llama sale de la boca y un cañón es un tubo.
- **Los `cannons` del JSON son solo el respaldo** de un modelo sin marcadores; los
  `engines` del JSON murieron con el quad. Ojo al orden: en `setup()` el bucle de
  `cannons` corre **después** de `_build_visual`, y solo si el modelo no trajo
  los suyos.

## Si es una ESTACIÓN, un PORTAL o una CAJA (props)

Un bicho es un objeto **plano visto desde arriba**, hay muchos a la vez y vive en `EntityNode`. Un
prop rompe alguna de esas cosas, y cada una cambia un dial de la cadena.

**Una estación no se tumba.** `TUMBAR=0`. El contrato del normalizador —el eje fino acaba en el alto—
*codifica* «plano visto desde arriba». Una estación es una **torre vertical**: tumbarla la acuesta. No
hay heurística que distinga los dos casos mirando la caja, porque la diferencia no está en el modelo
sino en cómo se mira.

**No se decima.** Es UNA instance, no quince Vex. La base entró con 30 228 tris y se quedó con ellos.

**Puede tener DOS colores de acento.** El canal admite una suma: `c+m` toma el **máximo** de las dos
máscaras (no la suma: un píxel es del acento que más domine). Y ojo con elegir el canal por cobertura
— en la estación el azul dominaba en el **92,2 %** de la textura porque el casco entero es azul-gris,
así que habría encendido la torre entera. Los acentos reales eran magenta (p99 0,298) y cian (0,153).

**La cámara no es cenital, y eso arrastra el encuadre.** `extent_3d` mide la **huella**
(X y Z), que a 90° es exactamente lo que se ve. En cuanto la cámara baja deja de serlo: la altura pasa
a proyectarse en pantalla y una torre de 1,92 sobre una planta de 1,05 se sale por arriba. Para
cámaras oblicuas, `view_extent` proyecta las ocho esquinas de la caja al espacio de la cámara.

**El tamaño tiene techos que no son el gusto.** En la estación fue su **zona segura** (el server
manda 1500 de radio, así que a ×4 la base asomaría fuera de su propio anillo y se lee como un error).

**Portal y caja tienen malla desde la tarde del 1-sep-2026** (canal `c` el portal, `y` —ámbar— la
caja): `data/props/<prop>.json` declara `"modelo"` y `world_size`, y `portal_node.gd` / `_crear_caja`
la montan escalada por su huella, como la estación. **El portal va DE PIE** (`TUMBAR=0`, como la
estación: es el jumpgate vertical del DO 3D, no un disco): el cliente lo pone **de cara a la
cámara** (la normal del aro apunta a la cámara del rig, tilt base + pan del mapa — una pose fija, no
un billboard) y **centrado en el plano de vuelo**, no apoyado: la nave se queda dentro del aro. A
tres cuartos y apoyado, la nave colgaba bajo el aro (reportado en vivo). Le pone el balanceo de ±3° y el
glow de 5 s del original, y su **encendido** (los 2,1 s que cubren la latencia del salto) es luces
en rampa + giro del aro sobre su eje + un destello del pool — al final queda abierto y emite
`encendido_terminado`. Lo que gira es **solo el centro** (el vórtice, oculto en reposo): Meshy
entrega un solo objeto, y `tools/partir-centro.py` (mex-orbit-art) lo parte en dos, `aro` y
`centro`, repartiendo **islas enteras** (al centro las que entran por debajo de un radio). **No
se cortan triángulos**: la primera versión cortaba por centroide y el borde del aro salió
dentado, porque el disco entra por debajo del anillo con triángulos largos. Y las islas solas
tampoco bastaron: la pared del aro viene FUSIONADA con trozos de disco, y hay astillas del
remesh. Quedaron cinco criterios (radio, losa del disco medida por percentiles, astillas, firma
del disco dentro de las islas mixtas, largo del triángulo), cada uno con su medida en el README
de arte, y `INFORME=1` lista lo que queda del aro por dentro del labio para afinar midiendo, no
a ojo. `PortalNode` busca el hijo `centro` y le pone el giro y la aparición; sin él gira el aro
entero, de respaldo.

## Un prop con varios caminos: los guardianes por exclusión caducan

Cuando la estación tenía PNG fijo, atlas y malla, su capa emisiva 2D —el reactor de una base
anterior— se montaba con un guardián que decía «solo si **no** hay atlas». Al aparecer el tercer
camino, nadie lo actualizó: volvió a montarse sobre el modelo, en blend aditivo, y pintó un aro cian
perfecto sobre una estructura que no tiene esa forma. Se leyó como «el reactor brilla demasiado» y
se tocó el glow — mientras la causa era **una capa que no debería estar ahí**.

**Enuncia el guardián por lo que la cosa PERTENECE, no por lo que no es.** Hoy solo queda un
camino, y es la razón de que se retiraran los otros dos en vez de dejarlos «por si acaso».

## Fuentes de verdad

- `mex-orbit-art/README.md` — la receta de Meshy y los dos diales (polígonos vs textura).
- `mex-orbit-client/README.md` — «Calidad gráfica» (qué baja con cada nivel) y «Un solo tipo de asset».
- `mex-orbit-client/tests/README.md` — el banco y la trampa del `SubViewport`.

Todo dial calibrable se documenta en el README de su repo **en el mismo commit**.

## Las trampas, todas medidas

**Blender headless**
- **Ignora en silencio las operaciones a nivel de objeto**: `transform_apply`,
  `rotation_euler`, `matrix_world`. El depsgraph no se evalúa. Transforma **datos de
  malla** o acumula las transformaciones **a mano** subiendo por los padres.
- **Las rutas de salida relativas se van a un sitio fantasma.** Blender resuelve un
  `render.filepath` relativo contra su propia ruta base, no contra el directorio de
  lanzamiento: el script dice que escribió, no da ningún error y los archivos se
  quedan igual. Fuerza `os.path.abspath` en cualquier script nuevo.
- **Blender 5 cambió el compositor**: no hay `scene.node_tree`, es un grupo de nodos
  en `scene.compositing_node_group`, los ajustes del Glare son *entradas* y los
  valores de menú son texto legible (`"Bloom"`, `"Replace Alpha"`).
- **Nunca metas un ajuste en `try/except`.** Un valor mal escrito se traga solo, el
  nodo se queda en su modo por defecto y el render sale pareciendo bueno.

**Los scripts de la cadena**
- **El remesh vive en Meshy, no en `normalize-model.py` (31-ago-2026).** El script
  decimaba con un ratio propio (`TRIS`, tercer argumento) después de soldar — una
  segunda pasada de remesh encima de la que Meshy ya hacía. El usuario pasó a
  resolver el presupuesto de polígonos en el propio Meshy (bichos Y naves por
  igual: nunca fue solo cosa de naves), así que la capacidad se quitó ENTERA del
  script en vez de dejarla apagada con `TRIS=0` — el argumento ya no existe y los
  que venían después (`lado_textura`, `canal`, `ganancia`, `soldar`) recorrieron
  una posición. La soldadura de costuras (`SOLDAR`) se queda: no es remesh, es
  limpieza de las cáscaras solapadas del export crudo, y sigue haciendo falta.
- **`normalize-model.py` solo sabía tumbar desde Y.** El eje fino puede entrar en
  **X**: entonces imprimía un aviso y **no tumbaba nada**, y como ese aviso convive
  con un «ya venía en el plano» en la línea siguiente, el modelo se daba por bueno
  **de pie**. Lo cazó el validador, no el script. Ya cubre las dos entradas — desde
  X hacen falta **dos giros**, porque ninguno de 90° sobre un solo eje lleva dos
  ejes a la vez a donde deben ir.

  La lección general: **un aviso impreso al lado de un mensaje de éxito se lee como
  éxito.** Si un paso no puede hacer su trabajo, tiene que fallar, no avisar.
- **Corre el validador después de CADA paso, no al final.** Es Python puro y tarda
  segundos, y es lo único que mira el resultado en vez de lo que el script dice que
  hizo.

**Los diales NO cruzan de medio**
- Un valor calibrado sobre un **sprite aditivo** no vale sobre la **emisión de un
  material**, aunque se llame igual. El latido de la estación (0,55–1,8) funcionaba
  en 2D porque un blend aditivo satura de por sí; sobre una emisión cuya textura
  promedia **0,143 sobre 1**, ese mismo recorrido da de 0,079 a 0,257: se mueve y
  no se ve. Multiplicar poco por poco sigue siendo poco.
- Antes de reutilizar un dial, mira **qué tan brillante es lo que multiplica**.
  Medir el promedio y el máximo de la textura emisiva contesta en un minuto lo que
  si no se convierte en varias rondas de "súbelo un poco más".

**GDScript**
- **No hay comprensiones de lista.** `[f(i) for i in n]` está escrito como en
  Python y aquí es un error de **parseo**, igual que la asignación múltiple: tumba
  el script entero. Un bucle explícito.
- **No hay asignación múltiple.** `a, b = x, y` está escrito como en Python y aquí es
  un error de **parseo**, no de ejecución: tumba el script entero y con él todo el
  que dependa de su `class_name`. Escribir `_cuernos_min, _cuernos_max = ...` dejó
  el juego en negro después del login, porque `world.gd` no podía cargar
  `EntityNode`. Una asignación por línea.

**glTF → Godot**
- Los ejes se permutan: el largo por **Y** en Blender sale por **Z** en Godot, y el
  alto de Blender (**Z**) es la **Y** de Godot.
- **glTF no tiene bandera de bucle.** Una animación importada se reproduce una vez y
  se congela: hay que poner `loop_mode = Animation.LOOP_LINEAR`.
- `set_bone_pose_rotation` fija la pose **entera**, no un incremento. Hay que
  componer sobre el reposo: `get_bone_rest(i).basis.get_rotation_quaternion() * giro`.
  Sin eso la malla sale aplastada sin haber rotado.

**Cómo NO medir**
- **Contar píxeles sobre la PANTALLA ENTERA no es comparable entre corridas del
  autotest.** La nave se mueve, así que el asset entra o sale del encuadre y el
  recuento cambia por eso. Una lectura que "bajaba un 94%" resultó ser una captura
  donde la estación casi no salía. **Recorta el asset primero** — localizarlo por
  su color de acento funciona bien.
- La cifra puede ser real y la conclusión falsa. Antes de creerte una caída, mira
  la imagen de la que salió.

**Cliente**
- **El cliente mapeaba una LISTA FIJA de nombres de hueso.** `_mapear_huesos`
  recorría `ala_izq, ala_der, cuerno_izq, cuerno_der, cola_1..3`, así que los
  `brazo_*` del Vorax **nunca llegaron**: `_poner_hueso` salía por la puerta de
  atrás en cada fotograma y los tentáculos no se movían. Ahora se mapea lo que el
  **esqueleto** trae, y un hueso nuevo funciona sin tocar el cliente.

  El síntoma es lo peligroso: **un bicho quieto se ve exactamente igual que uno
  bien animado con amplitud pequeña**, y en un bicho radial la pose de reposo
  tampoco delata nada. Se dio el retrato por bueno mirando un fotograma.
- **El giro es `-deg_to_rad(_visual_angle)`, sin sumandos.** El modelo mira a −Z a
  giro 0. Cualquier cuarto de vuelta de más hace que el bicho persiga de costado.
- **La luz del mundo sale de `AssetDefs`**, el dial ÚNICO: nunca montes un
  `Environment` 3D a mano, ni en una escena de pruebas — estaba copiado en ocho
  sitios y cada rig medía contra una luz distinta.
- **Los pesos tienen que sumar 1, y se vigila por ARRIBA también.** Sumar de menos
  aplasta el vértice contra el origen del hueso; sumar de más lo mueve de más. El
  rig normaliza siempre — un guardián que solo mira el mínimo deja pasar la mitad
  de los casos, y así llevaba un 1,416 sin que nadie lo viera.
- **La emisión necesita `glow_enabled`** o se recorta a 1.0 y se lee como «claro» en
  vez de «encendido».

## Cómo se verifica

En `mex-orbit-client/tests/` hay escenas que son herramientas, no adornos.
**Se corren CON VENTANA, nunca con `--headless`**: headless monta el renderer
dummy, que no puede volcar texturas — la escena arranca, lista los huesos como si
todo fuera bien y luego escupe `Parameter "t" is null` y `save_png on a null
value` en bucle, sin salir nunca. El `--headless` vale para `--import`, no para
renderizar. Todas estas escenas abren su ventana un momento y salen solas.

| escena | para qué |
|---|---|
| `repro_orientation.tscn` | renderiza el modelo a 0/90/180/270° de giro. **La orientación de un modelo nuevo se comprueba mirando cuatro PNG**, no razonando sobre permutaciones de ejes. |
| `repro_viewport.tscn` | monta **seis** viewports y vuelca el primero a 0,5 s y 9 s. Con uno solo el fallo del mundo compartido no aparece. |
| `repro_bone_axis.tscn` | renderiza un hueso girado en X, Y y Z **más el reposo al lado**. **El eje de un gesto nuevo se elige mirando**, no deduciéndolo de la permutación de ejes. `-- --model=npcs/vorax.glb --bone=brazo_1 --degrees=35`, y con `--only-axis=N` escribe `..._gNN.png` (nombre distinto: ojo al recoger la salida) |
| `view_anchors.tscn` | pinta los marcadores sobre el render **y mide las bocas en la silueta**. Para naves es la herramienta, no un extra: la malla no sabe distinguir una campana de la tubería que tiene al lado. |

**Una herramienta de verificación puede mentir, y estas ya lo hicieron.**
`repro_bone_axis` prefijaba `npcs/` siempre, así que `--model=npcs/vorax.glb` daba
`assets/npcs/npcs/vorax.glb`: el modelo **no cargaba** y la escena seguía adelante
guardando **cuatro PNG negros diciendo «guardado»**. Se llegó a diagnosticar mal la
causa —se culpó al encuadre, que también estaba a constante— antes de mirar la
ruta. Ya aborta si el recurso no existe y mide el encuadre del modelo.

Antes de sacar una conclusión de un render, comprueba que hay algo dentro. **Un
render vacío que se anuncia como bueno es peor que un error**, porque se analiza
como si fuera un resultado.

Y `bench_3d.tscn` mide rendimiento — **ojo: sus cifras son N modelos en UN mundo con
UNA cámara**, que es exactamente la escena única del cliente de hoy.

## Verificar que algo se MUEVE

**Un fotograma no puede demostrar movimiento.** Es la trampa más cara de esta
cadena porque la foto sale perfecta: un bicho congelado se ve igual que uno bien
animado con amplitud pequeña.

El **bestiario ya toma dos fotogramas** por bicho —su propio comentario decía que
una foto fija no demuestra que un shader se mueva— pero durante meses solo los
guardó: comparar quedaba para el ojo de quien los mirase, y **nadie mira nueve
pares de PNG uno por uno**. Ahora mide la diferencia entre los dos y reporta los
**quietos**:

```
MOVIMIENTO por especie: vex 0,515 · ferox 0,127 · skarnox 0,110 · vorax 0,097
  gravit 0,085 · gravon 0,083 · mordax 0,055 · vexor 0,036 · skarn 0,034
```

Se mide dentro de la **caja del bicho**, no en la pantalla entera: el campo de
estrellas tiene paralaje y se mueve solo, así que la pantalla siempre «cambia» y
el número no diría nada del bicho.

Se **reporta y no falla** todavía, porque el umbral bueno para las nueve especies
no está medido — un 0,034 puede ser legítimo. Lo que no puede volver a pasar es
que un bicho se quede congelado y nadie se entere. **Y desde el 1-sep una especie
sin GLB no tiene cuerpo**: su MOVIMIENTO es el del fondo dentro de la caja (polvo
estelar, ~0,03–0,05 medido con Gravit, Gravon, Mordax y Skarn), no el del bicho.
Eso no es un bicho congelado, es un bicho pendiente de malla.

**El bestiario corre en la calidad que la sesión traiga guardada.** Ya no hay un
camino distinto por nivel (la malla es la misma en los tres), pero las cifras de
MOVIMIENTO sí cambian con la resolución del render (`render` 0,5× en BAJA
difumina la diferencia entre fotogramas): para un antes/después fiable, misma
calidad en las dos corridas —`-Calidad alta`— y mide sobre capturas frescas
(comprueba su mtime), recortando la caja del bicho.

## Añadir una parte móvil nueva (cuernos, tentáculos)

El orden que funcionó, y ninguno de los pasos sobra:

1. **Mide la zona** en Blender: cuántos vértices, qué porcentaje, y si el histograma
   de posición muestra lóbulos separados. Los cuernos del Vexor: 944 verts (5,0 %),
   dos lóbulos con un valle en el centro. **La conectividad no sirve** para aislar —
   la malla viene partida por costuras de UV (18 716 verts para 10 254 caras).
2. **Simula el gesto sin riguear**, moviendo vértices con una banda *smoothstep*, y
   **ríndelo al tamaño de juego** (`screen_size` px). Si a ese tamaño no se
   distingue, el rig sobra. Lo que se lee es el cambio de **silueta**, no el detalle.
3. **Añade los huesos** en `riguear-modelo.py` con la bisagra **medida** de la malla,
   y cede terreno a los huesos vecinos de forma continua (`w * (1 - w_vecino)`), no
   con un corte: un corte deja una franja pesando en los dos.
4. **Mide el eje** con `repro_bone_axis.tscn`, y **prueba la legibilidad con cada
   eje, no solo con el que creas bueno**. No hay eje universal: depende de cómo esté
   plantada la pieza. En el Vexor el 1 gira dentro del plano (`dy ≈ 0`, área
   creciente) y abre las pinzas; en el Vex el 1 casi no las mueve (0,5 px a 35°) y
   el bueno es el 2. Se llegó a descartar los cuernos del Vex por probar la
   legibilidad **con el eje que menos los movía** — la conclusión buena no era «esta
   pieza no se lee» sino «este gesto no se lee en este bicho».
5. **Renderiza los DOS extremos del recorrido** (`--both`, que posa el par en
   espejo como el juego). Un extremo puede **cruzar** las piezas: los cuernos del Vex
   están casi juntos en reposo y hacia el positivo las puntas se solapan. Por eso el
   dial del JSON es un **rango con sus dos extremos** (`[-20, 0]`) y no una amplitud
   alrededor del reposo — el límite seguro es lo que hay que dejar dicho.
6. **La amplitud puede estar acotada por los VECINOS, no por lo que se lea.** En
   el Vorax los brazos más juntos están a 18-20 grados uno de otro, así que un
   barrido grande los cruza — y la legibilidad seguía subiendo ahí (la silueta
   cambia un 8,0 % con 18 grados y un 10,6 % con 45). El límite lo puso la
   geometría, no el ojo: se dejó en 16, justo por debajo del hueco entre vecinos.
   Mide la separación entre piezas antes de elegir.
7. **Elige la amplitud mirando el barrido a tamaño de juego**, no calculándola. En el
   Vex: 12° se queda corto, 28° abre demasiado, 20° abre claro sin aspaviento.
8. **Enchúfalo al reloj que ya existe** en `_process`. Si es un anillo de piezas
   iguales, **desfasa por índice**: la onda recorre el bicho girando alrededor del
   centro. Mover las ocho a la vez se lee como que respira, no como que se mueve.
9. **Comprueba que el cliente CONOCE el hueso.** Un nombre nuevo puede no estar en
   el mapeo y entonces no se mueve nada, sin un solo error. Ver la sección de
   verificación de movimiento.

**Y puede salir que no** — pero asegúrate de que el «no» es del bicho y no de tu
método. Aquí se dijo que no y era falso: se había probado con el eje equivocado.
Antes de descartar una pieza, prueba **los tres ejes** a tamaño de juego.

## La disciplina

1. **Si no puedes medir que algo cambió, no cambió.** Cuatro renders salieron
   byte-idénticos y se dieron por buenos.
2. **El número no basta: mira la imagen.** Subir la emisión a ×16 empataba la cifra
   de brillo y pintaba las venas rosas.
3. **Aísla antes de tocar.** Un repro sin servidor ni cuenta cierra en un minuto lo
   que en el juego entero cuesta media sesión. Y reproduce con **N>1**: con un solo
   bicho el fallo más caro de esta sesión no aparecía.
4. **Separa acumulación de geometría** volcando la textura del viewport pronto y
   tarde (0,5 s y 9 s).
5. **Cuando el dato es correcto tres veces, el sospechoso deja de ser el dato.**
   Los marcadores llegaban bien y la pantalla no les hacía caso: el culpable era
   `_process` pisando la escala. Se perdieron dos rondas midiendo mejor algo que ya
   estaba bien medido.
6. **Si llevas tres ajustes a ojo, construye la herramienta que lo mida.**
   `view_anchors.tscn` cerró en un intento lo que tres rondas de tanteo sobre una
   nave en movimiento no habían cerrado.
7. **Dos ajustes distintos que dan la MISMA cifra hasta el último decimal no son
   un dial que no sirve: son un dial que no se está ejecutando.** Y la segunda vez
   que pasó, la causa no estaba en el script sino en el `cp` que recogía la
   salida: con `--only-axis` la escena escribe `..._gNN.png`, y se estaba copiando
   tres veces el fichero de una corrida anterior. **Comprueba la marca de tiempo
   del archivo del que sacas el número.** Nunca escondas la salida de un paso que
   estás calibrando.
8. **Un log limpio no es una prueba** si no confirmaste que la ejecución llegó al
   sitio del fallo. Ver la sección del autotest.
9. **Ante algo que sobra en la imagen, pregunta DE DÓNDE SALE antes de cómo
   quitarlo.** El aro cian de la estación se atacó como "brilla demasiado" —bajando
   glow y emisión, los dos sospechosos razonables— y era una capa de otra estación
   montada encima. La pregunta "¿cómo lo atenúo?" da por supuesto que la cosa
   pertenece ahí. La pregunta "¿de dónde sale?" lo comprueba.
10. **Si una capacidad deja de gustar, quítala ENTERA**: shader, constructor,
   campos, ficha y documentación. No la dejes apagada desde el JSON. Código que no
   se ejecuta no avisa de que está ahí, y en esta cadena ya ha mordido dos veces —
   los huesos de ala en un gusano y la capa emisiva de una estación anterior. El
   "por si acaso" vive mejor en el historial de git que en el árbol de trabajo. El
   1-sep-2026 se aplicó a lo grande: el PNG horneado, el atlas de vídeo y su horno
   salieron enteros, y seis entidades quedaron sin cuerpo antes que con un respaldo
   que nadie iba a mirar.

## Si algo falla DESPUÉS del login, usa el autotest

`/godot autotest` (`dev-run.ps1 -Autotest`) entra con **TestBot**, recorre el bucle
completo y deja una captura en `C:/Tools/autotest.png`. Es la herramienta para
cualquier fallo que ocurra ya dentro del mundo.

Relanzar el cliente y mirar la ventana **no sirve** y engaña: el cliente automático
entra con la cuenta de desarrollo, y si el usuario ya está jugando con ella se
queda en el login — que carga y dibuja perfectamente, porque no toca `entity_node`.
El log sale **vacío** y parece que no hay ningún error. Pasó exactamente eso: tres
arranques con la salida capturada, cero errores, y el fallo era un error de parseo
que el autotest sacó en cascada al primer intento (`Could not parse global class
EntityNode`).

**Un log vacío puede significar que no llegaste al sitio del fallo, no que no lo
haya.** Antes de creerte un log limpio, comprueba que la ejecución pasó por donde
te interesa.

## Al lanzar el cliente

Usa `/godot` (`tools/dev-run.ps1`). **Mata los Godot viejos antes**: el proceso se
llama `Godot_v4.7.1-stable_win64`, no `godot.exe`, así que un `taskkill /IM
godot.exe` no encuentra nada y te quedas mirando una ventana anterior creyendo que
el cambio no funcionó. Y **una sesión por cuenta**: si el usuario está jugando con
`odrack`, el cliente automático no entra.
