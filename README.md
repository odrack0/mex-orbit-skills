# mex-orbit-skills

Las **skills y comandos** de Claude Code para MexOrbit. Es conocimiento del
proyecto —la cadena de assets 3D, el sistema de diseño de UI, cómo se lanza el
cliente— y hasta ahora vivía **solo en una máquina**, sin versionar: tres
documentos que nadie echaría de menos hasta perderlos.

| ruta | qué es |
|---|---|
| `skills/mexorbit-asset-3d/` | la cadena de un asset 3D, de Meshy al juego, con todas las trampas medidas |
| `skills/mexorbit-ui/` | el sistema de diseño N: invocarla antes de tocar cualquier interfaz |
| `commands/godot.md` | `/godot` — levanta el entorno y lanza el cliente |

## Cómo lo encuentra Claude Code

Claude Code busca las skills en **`.claude/skills/`** del proyecto, no aquí. Para
que este repo sea la fuente y siga funcionando el descubrimiento, `.claude/skills`
y `.claude/commands` son **junctions** que apuntan a las carpetas de este repo.

Así hay **una sola copia real**, versionada, y editar la skill desde donde sea
—el editor, Claude, un `git pull`— toca el mismo archivo.

## En una máquina nueva

```bash
git clone git@github.com:odrack0/mex-orbit-skills.git
```

Y desde `C:\Source\MexOrbit`, con el repo ya clonado en `mex-orbit-v1`:

```
powershell -File mex-orbit-v1\mex-orbit-skills\enlazar.ps1
```

El guion **no borra nada sin avisar**: si `.claude\skills` ya existe con archivos
de verdad, se para y lo dice, en vez de sustituirlos por un enlace y llevarse por
delante trabajo sin commit.

## Por qué junctions y no copias

Una copia por sitio es una copia que se queda atrás. Ya estaba pasando: `godot.md`
existía en el proyecto **y** en `~/.claude/commands/`, idénticos de milagro. Es la
misma lección que el recorte del croma, que vivió duplicado en dos scripts hasta
que uno se quedó con el despill viejo.

Los junctions de Windows (`mklink /J`) **no necesitan permisos de administrador**,
al contrario que los enlaces simbólicos.
