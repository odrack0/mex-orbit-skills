---
name: mexorbit-asset-3d
description: Pipeline de un asset 3D de MexOrbit, de Meshy al juego, en las tres calidades (alta = malla en SubViewport, media y baja = PNG horneados del MISMO modelo). Invocar antes de montar desde un modelo 3D cualquier bicho, nave o PROP del mapa (estacion, portal, caja), y antes de tocar normalize-model.py, riguear-modelo.py, hornear-sprite.py, el camino 3D de entity_node.gd o el de la estacion en world.gd. Cubre tambien la emision por canal, los rig radiales y por que un prop no se tumba como un bicho.
---

# Skill: montar un asset 3D de MexOrbit

**Un asset, dos salidas.** El GLB es la fuente y sirve la calidad **alta**; media y
baja se **hornean desde el mismo GLB**. No son dos catálogos. Si algo no cuadra
entre calidades, se mueve la **salida derivada** (el PNG), nunca el modelo: el PNG
se rehornea cada vez que toques el modelo y un ajuste hecho del otro lado se pierde
solo.

## La cadena, en orden

Rutas relativas a `C:\Source\MexOrbit\mex-orbit-v1\`. Blender es
`"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe"`.

**1. Meshy.** Remesh a ~10-15 k tris **encendido** (sin él da una sopa de cáscaras
solapadas que el decimador convierte en esquirlas). Modo Ultra **apagado**. Pose de
la imagen = pose de reposo. Texturas 4096. La tabla completa está en el README de
arte, sección «LA RECETA».

**2. Crudo → master normalizado** (en `mex-orbit-art`):

```bash
blender --background --factory-startup --python tools/normalize-model.py -- \
    source/3d-models/crudo/<bicho>-vN.glb source/3d-models/<bicho>.glb 0 1024 r 1.0 0.0005
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

**Y la cifra de cobertura sola no dice nada, en NINGUNA dirección.** La trampa de
la estación es cobertura alta que sí era veneno (el azul dominaba el 92 % porque
el casco entero es azul-gris). El Ferox fue lo contrario: «80,6 % de la textura
emite» con canal `r` huele a esa trampa, pero medida la **distribución** era
benigna — el marfil del cuerpo es apenas r-dominante (máscara ~0,04, emisiva
resultante ~0,02) y los acentos reales, ojos y vetas con albedo 0,72/0,19/0,21,
son el 5,4 % por encima de 0,35 con p99 de 0,62. Ni el pánico ni la confianza se
sacan del porcentaje: antes de cambiar canal o ganancia, mide p50/p99 de la
máscara y el albedo de donde pega alto contra donde pega bajo. Un minuto de
numpy ahorra un rehorneado a ciegas.

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

**5. Hornear media y baja** — los tres PNG que el cliente ya consume:

```bash
blender --background --factory-startup --python tools/hornear-sprite.py -- \
    source/3d-models/<bicho>.glb exports/horno <bicho> 512
```

Tres pases, no uno: **BASE** (emisión apagada, o iría dos veces), **EMISIVA** (con
el halo horneado) y **NORMAL** (datos, sin gestión de color). Copiar los tres a
`<cliente>/assets/npcs/` y **reimportar** (`godot --headless --path . --import`):
sin eso Godot sirve la textura vieja de la caché y parece que el cambio no hizo nada.

**6. Enchufarlo al cliente.** En `data/npcs/<bicho>.json`:

```json
"modelo": "res://assets/npcs/<bicho>.glb",
```

Y ya está: `entity_node._construir_visual()` toma el camino 3D cuando
`Quality.nivel("npc") >= 2`. **No se toca `world.gd`** — el 3D entra por debajo, en
un `SubViewport` cuya textura alimenta al `Sprite2D` de siempre, así que posición,
z-index, radio de click, barras y FX siguen siendo los de 2D.

## LOS DIALES SON POR BICHO

Los valores que aparecen arriba se calibraron con el **Vexor**. **No se heredan.**
El Vex, segundo bicho de la cadena, cambió casi todos: es más largo que ancho (al
revés que el Vexor) y emite en un solo ojo en vez de en toda la superficie.

| | Vexor | Vex | Vorax |
|---|---|---|---|
| forma | alas + cola | alas + cola | **radial, 8 brazos** |
| `BISAGRA` / `BANDA` del ala | 0,30 / 0,22 | 0,18 / 0,16 | sin alas (3,0) |
| `COLA_DESDE` | 0,32 | 0,24 |
| `GLOW_NUCLEO` | 0,09 | 0,22 |
| `GLOW_RADIO` / `GLOW_FUERZA` | 0,06 / 1,8 | 0,09 / 3,8 |
| `HORNO_AMBIENTE` | 0,28 | 0,28 (la Phoenix, **1,7**) |
| `cuernos_grados` / `cuernos_eje` | [−14, +14] / eje 1 | [−20, 0] / **eje 2** |

**Las bisagras salen del perfil de la malla**, no de copiar el bicho anterior: saca
el ancho (`|X|` p95) por bandas de Y y busca el salto. En el Vex pasa de 0,101 a
0,749 entre Y −0,599 y −0,479 — ahí empiezan las alas y ahí acaba la cola.

**Los `GLOW_*` se barren contra `medir_emision.tscn`** hasta que media iguale a
alta. Cuál es la palanca depende del bicho: en el Vexor era el núcleo; en el Vex,
que emite en un punto, subirlo de 0,09 a 0,22 solo movió la media de 0,201 a 0,205
y hubo que ir al halo.

**La luz del horno también es un dial.** `HORNO_SOL` (3,2) y `HORNO_AMBIENTE`
(0,28) valen para un bicho de albedo oscuro con vetas emisivas. Para una nave
**metálica** no: un metal casi no tiene difuso, solo devuelve lo que hay alrededor,
y sin entorno que reflejar se apaga — el Phoenix salía casi negro al lado de su
propio render de alta. Con la textura gris de la Phoenix, `HORNO_AMBIENTE=1.7` deja media en
0,224 contra 0,226 de alta. **Recalibra el dial cada vez que cambie la textura**:
no pertenece al modelo, pertenece a la pareja modelo+textura — con la textura
oscura anterior el valor era 1,2 y la referencia de alta, 0,139. **Y el resultado sigue siendo una nave oscura, porque alta también la
dibuja oscura**: homologar es parecerse al modelo, no al PNG 2D que hubiera antes.

**Si el crudo viene por encima de presupuesto, decima.** El Vex llegó a 31 148 tris
y bajó a 12 000: está medido que 10k → 31k cuesta un 38 % de fps. El soldado va
antes de decimar, y eso es lo que lo hace seguro sobre una malla partida por UV.

## Si es una NAVE: los anclajes de motores y cañones

Una nave necesita dos cosas que un bicho no. En 2D las llamas y las bocas de cañón
cuelgan del **sprite** y giran con él; en 3D el sprite **ya no gira** —gira el
modelo dentro del viewport— así que unas coordenadas de textura se quedarían
clavadas en pantalla mientras la nave da la vuelta.

**Paso extra en la cadena, entre normalizar y enchufar:**

```bash
blender --background --factory-startup --python tools/marcar-anclajes.py -- \
    source/3d-models/<nave>.glb <cliente>/assets/ships/<nave>.glb \
    0.09 0.75 60 <n_toberas> "<x1,x2,...>" <ancho>
```

Mete en el GLB nodos vacíos `tobera_1..N` y `canon_izq`/`canon_der` en **unidades
del modelo**, con el **ancho de cada boca en la escala del nodo** (un sitio estándar
de glTF, sobrevive al importador). `validar-modelo.py` los lista en MARCADORES.

En el cliente los lleva `_anclas`, un `Node2D` que hace el papel que hacía el
sprite: carga la rotación del rumbo y de él cuelgan llamas y bocas.

### Mide las bocas en el RENDER, no en la malla

**Esto es lo que costó cinco rondas.** Contar densidad de vértices NO funciona: la
popa tiene anillos, soportes y tubería entre toberas que el histograma mete en el
mismo saco. Se probaron tres variantes sobre la malla (media del lóbulo, punto
medio del extremo, convergencia en ventana) y **ninguna** salió simétrica, que es
la propiedad que una nave tiene de verdad.

`pruebas/ver_anclajes.tscn` renderiza con la **misma proyección del juego**, pinta
una cruz en cada marcador con una barra de su ancho, **y mide las bocas sobre la
silueta**. Sus números son los que se le pasan a `marcar-anclajes.py`.

```bash
godot --path . res://pruebas/ver_anclajes.tscn -- --modelo=ships/<nave>.glb
```

En el Phoenix: la malla daba centros asimétricos y ancho 0,103; el render dio
−0,233 / −0,094 / +0,090 / +0,229 y ancho 0,135. **Cuando la malla y la imagen
discrepan, manda la imagen** — el problema es del ojo.

Y **la rebanada no se toma al ras de la popa**: ahí las campanas se tocan de dos en
dos, que era literalmente el síntoma («veo dos motores en una nave de cuatro»). Hay
que subir hasta la primera fila donde salgan separadas.

### El tamaño de la llama: tres trampas encadenadas

Las tres daban el mismo síntoma —llamas demasiado gruesas— y las dos primeras
hicieron que los arreglos siguientes **no cambiaran nada en pantalla**:

1. **`_process` PISA la escala de la llama** cada fotograma con el ciclo de empuje.
   Fijarla al crearla no sirve de nada: dura un frame. Tiene que **multiplicar**.
   En 2D no se nota porque el sprite padre aporta el factor; en 3D `_anclas` no
   tiene escala y la llama sale a 64 px de textura.
2. **El penacho ocupa solo el 70 % del ancho de su textura** (columnas 10..54 de
   64). Escalar la textura al ancho de la boca deja el chorro visible en un 70 % y
   no la cubre.
3. **La llama se dimensiona por el ancho de SU boca, no por la separación entre
   bocas.** Con la separación sale más gruesa que la tobera de la que sale.

Y se mete **medio ancho hacia proa**: el marcador está en el vértice más trasero,
que es el filo de la campana y no su garganta, así que la llama arrancaba despegada.

### Lo demás

- **Pasa el número de toberas.** Contarlas por valles dio 2 en vez de 4.
- **De la tobera, su punto más trasero; del cañón, su punta delantera.** No el
  centro de masa: la llama sale de la boca y un cañón es un tubo.
- **Los `engines`/`cannons` del JSON dejan de valer**, están en píxeles del PNG
  viejo. Ojo al orden: en `setup()` el bucle de `cannons` corre **después** de
  `_construir_visual`, así que sin condición se **suman** a las medidas.

## Si es una ESTACIÓN (o cualquier prop que no sea un bicho)

Un bicho es un objeto **plano visto desde arriba**, hay muchos a la vez y vive en `EntityNode`. Una
estación rompe las tres cosas, y cada una cambia un dial de la cadena.

**No se tumba.** `TUMBAR=0`. El contrato del normalizador —el eje fino acaba en el alto— *codifica*
«plano visto desde arriba». Una estación es una **torre vertical**: tumbarla la acuesta. No hay
heurística que distinga los dos casos mirando la caja, porque la diferencia no está en el modelo sino
en cómo se mira.

**No se decima.** Es UNA instancia, no quince Vex. La base entró con 30 228 tris y se quedó con ellos.

**Puede tener DOS colores de acento.** El canal admite una suma: `c+m` toma el **máximo** de las dos
máscaras (no la suma: un píxel es del acento que más domine). Y ojo con elegir el canal por cobertura
— en la estación el azul dominaba en el **92,2 %** de la textura porque el casco entero es azul-gris,
así que habría encendido la torre entera. Los acentos reales eran magenta (p99 0,298) y cian (0,153).

**La cámara puede no ser cenital, y eso arrastra el encuadre.** `extension_3d` mide la **huella**
(X y Z), que a 90° es exactamente lo que se ve. En cuanto la cámara baja deja de serlo: la altura pasa
a proyectarse en pantalla y una torre de 1,92 sobre una planta de 1,05 se sale por arriba. Para
cámaras oblicuas, `extension_vista` proyecta las ocho esquinas de la caja al espacio de la cámara.

**El tamaño tiene techos que no son el gusto.** En la estación fueron dos: su **zona segura** (el
server manda 1500 de radio, así que a ×4 la base asomaría fuera de su propio anillo y se lee como un
error) y el **destino de render, que crece con el cuadrado** — a ×3 son 2829 px de lado y 30,5 MB.

## Un prop con TRES caminos: los guardianes por exclusión caducan

La estación tiene PNG fijo, atlas y malla 3D. Su capa emisiva 2D —el reactor de una base anterior—
se montaba con un guardián que decía «solo si **no** hay atlas». Al aparecer el tercer camino, nadie
lo actualizó: volvió a montarse sobre el modelo, en blend aditivo, y pintó un aro cian perfecto sobre
una estructura que no tiene esa forma.

Y engaña dos veces. Se lee como «el reactor brilla demasiado», así que se toca el *glow* y la
ganancia de emisión —los dos sospechosos razonables— mientras la causa es **una capa que no debería
estar ahí**. Ese aro ya se había arreglado una vez, con el mismo síntoma.

**Enuncia el guardián por lo que la cosa PERTENECE, no por lo que no es.** «La capa emisiva 2D es del
PNG fijo» no caduca; «de todo lo que no sea atlas» caduca en cuanto aparece un caso nuevo.

## Fuentes de verdad

- `mex-orbit-art/README.md` — la receta de Meshy, los dos diales (polígonos vs
  textura) y **los cuatro diales del halo** (`GLOW_NUCLEO/UMBRAL/RADIO/FUERZA`).
- `mex-orbit-client/pruebas/README.md` — el banco, la trampa del `SubViewport` y la
  tabla de emisión media-vs-alta.

Todo dial calibrable se documenta en el README de su repo **en el mismo commit**.

## Las trampas, todas medidas

**Blender headless**
- **Ignora en silencio las operaciones a nivel de objeto**: `transform_apply`,
  `rotation_euler`, `matrix_world`. El depsgraph no se evalúa. Transforma **datos de
  malla** o acumula las transformaciones **a mano** subiendo por los padres.
- **Las rutas de salida relativas se van a un sitio fantasma.** Blender resuelve un
  `render.filepath` relativo contra su propia ruta base, no contra el directorio de
  lanzamiento: el script dice que horneó, no da ningún error y los PNG se quedan
  igual. `hornear-sprite.py` ya fuerza `os.path.abspath`; haz lo mismo en cualquier
  script nuevo.
- **Blender 5 cambió el compositor**: no hay `scene.node_tree`, es un grupo de nodos
  en `scene.compositing_node_group`, los ajustes del Glare son *entradas* y los
  valores de menú son texto legible (`"Bloom"`, `"Replace Alpha"`). Para un bloom
  sale más barato numpy sobre el PNG ya rendido.
- **Nunca metas un ajuste en `try/except`.** Un valor mal escrito se traga solo, el
  nodo se queda en su modo por defecto y el render sale pareciendo bueno.

**Los scripts de la cadena**
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
- **`own_world_3d = true` en el `SubViewport`, obligatorio.** Sin él los viewports
  comparten el `World3D` del padre: todos los modelos viven en el mismo mundo y en
  el mismo origen, y cada cámara los ve **todos**. Se ve como una bola de copias del
  bicho que crece según entran más.
- **El giro es `-deg_to_rad(_visual_angle)`, sin sumandos.** El arte 2D mira arriba
  y el modelo también a giro 0. Cualquier cuarto de vuelta de más hace que el bicho
  persiga de costado.
- **Gira el modelo, no el sprite.** Rotar la imagen ya rendida giraría la luz, que es
  justo lo que el 3D viene a arreglar.
- **El encuadre se mide del modelo**, nunca una constante: `cam.size = extensión *
  1.15` y el viewport a `screen_size * 1.15 * 2`. Con una constante el bicho
  desborda su propia barra de vida.
- **Sol a 1.0 en Godot**, no al 2.6 del banco: con 2.6 el bicho sale lavado y no se
  parece a su propio horneado. (Blender hornea con un sol de 3.2, que por cómo
  normaliza cae cerca de 1.0 aquí — pero el criterio es el parecido con el horneado,
  no la conversión.)
- **Los pesos tienen que sumar 1, y se vigila por ARRIBA también.** Sumar de menos
  aplasta el vértice contra el origen del hueso; sumar de más lo mueve de más. El
  rig normaliza siempre — un guardián que solo mira el mínimo deja pasar la mitad
  de los casos, y así llevaba un 1,416 sin que nadie lo viera.
- **Alta necesita `glow_enabled`** o la emisión se recorta a 1.0 y se lee como
  «claro» en vez de «encendido». Y media necesita el **halo horneado** para tener el
  mismo carácter: sin él tiene el mismo brillo medio pero manchones planos reventados.

## Cómo se verifica

En `mex-orbit-client/pruebas/` hay tres escenas que son herramientas, no adornos.
**Se corren CON VENTANA, nunca con `--headless`**: headless monta el renderer
dummy, que no puede volcar texturas — la escena arranca, lista los huesos como si
todo fuera bien y luego escupe `Parameter "t" is null` y `save_png on a null
value` en bucle, sin salir nunca. El `--headless` vale para `--import`, no para
renderizar. Todas estas escenas abren su ventana un momento y salen solas.

| escena | para qué |
|---|---|
| `repro_orientacion.tscn` | renderiza el modelo a 0/90/180/270° de giro. **La orientación de un modelo nuevo se comprueba mirando cuatro PNG**, no razonando sobre permutaciones de ejes. |
| `repro_viewport.tscn` | monta **seis** viewports y vuelca el primero a 0,5 s y 9 s. Con uno solo el fallo del mundo compartido no aparece. |
| `repro_eje_hueso.tscn` | renderiza un hueso girado en X, Y y Z **más el reposo al lado**. **El eje de un gesto nuevo se elige mirando**, no deduciéndolo de la permutación de ejes. `-- --modelo=npcs/vorax.glb --hueso=brazo_1 --grados=35`, y con `--solo-eje=N` escribe `..._gNN.png` (nombre distinto: ojo al recoger la salida) |
| `ver_anclajes.tscn` | pinta los marcadores sobre el render **y mide las bocas en la silueta**. Para naves es la herramienta, no un extra: la malla no sabe distinguir una campana de la tubería que tiene al lado. |
| `medir_emision.tscn` | compone media a mano y la compara con alta, recortando a 1 en los dos lados. Guarda también la composición en PNG. |

**Una herramienta de verificación puede mentir, y estas ya lo hicieron.**
`repro_eje_hueso` prefijaba `npcs/` siempre, así que `--modelo=npcs/vorax.glb` daba
`assets/npcs/npcs/vorax.glb`: el modelo **no cargaba** y la escena seguía adelante
guardando **cuatro PNG negros diciendo «guardado»**. Se llegó a diagnosticar mal la
causa —se culpó al encuadre, que también estaba a constante— antes de mirar la
ruta. Ya aborta si el recurso no existe y mide el encuadre del modelo.

Antes de sacar una conclusión de un render, comprueba que hay algo dentro. **Un
render vacío que se anuncia como bueno es peor que un error**, porque se analiza
como si fuera un resultado.

Y `banco_3d.tscn` mide rendimiento — **ojo: sus cifras son N modelos en UN mundo con
UNA cámara, no la técnica de un viewport por entidad, que es más cara y sigue sin
medirse.**

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
que un bicho se quede congelado y nadie se entere.

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
4. **Mide el eje** con `repro_eje_hueso.tscn`, y **prueba la legibilidad con cada
   eje, no solo con el que creas bueno**. No hay eje universal: depende de cómo esté
   plantada la pieza. En el Vexor el 1 gira dentro del plano (`dy ≈ 0`, área
   creciente) y abre las pinzas; en el Vex el 1 casi no las mueve (0,5 px a 35°) y
   el bueno es el 2. Se llegó a descartar los cuernos del Vex por probar la
   legibilidad **con el eje que menos los movía** — la conclusión buena no era «esta
   pieza no se lee» sino «este gesto no se lee en este bicho».
5. **Renderiza los DOS extremos del recorrido** (`--ambos`, que posa el par en
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

Media **no se rehornea** si la pose de reposo no cambia: se queda con la parte
quieta, igual que ya hace con alas y cola.

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
   `ver_anclajes.tscn` cerró en un intento lo que tres rondas de tanteo sobre una
   nave en movimiento no habían cerrado.
7. **Dos ajustes distintos que dan la MISMA cifra hasta el último decimal no son
   un dial que no sirve: son un dial que no se está ejecutando.** Y la segunda vez
   que pasó, la causa no estaba en el script sino en el `cp` que recogía la
   salida: con `--solo-eje` la escena escribe `..._gNN.png`, y se estaba copiando
   tres veces el fichero de una corrida anterior. **Comprueba la marca de tiempo
   del archivo del que sacas el número.** Los diales del
   horno se definieron después de las líneas que los usan; el script petaba, el
   barrido mandaba la salida a `/dev/null` y el `cp` copiaba los PNG de la pasada
   anterior. Nunca escondas la salida de un paso que estás calibrando.
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
   "por si acaso" vive mejor en el historial de git que en el árbol de trabajo.
11. **Compara contra el horneado, no contra el banco.** El banco tiene sus propios
   valores y no es la referencia de aspecto.

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
