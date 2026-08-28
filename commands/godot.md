---
description: Levanta el entorno de dev (MySQL, api, game server) y lanza el cliente Godot
argument-hint: "[autotest | servicios | detener]"
allowed-tools: PowerShell, Read
---

Lanza el cliente de MexOrbit corriendo el script del repo:

```
powershell -File C:\Source\MexOrbit\mex-orbit-v1\mex-orbit-client\tools\dev-run.ps1
```

Según el argumento `$ARGUMENTS`, agrega el modificador correspondiente al comando:

- (sin argumento) → lanza el cliente con ventana, arrancando antes lo que falte.
- `autotest` → agrega `-Autotest`: corre el autotest headless del loop completo con captura. Al terminar, **lee la captura** (`C:/Tools/autotest.png`) con Read y comenta el resultado.
- `servicios` → agrega `-SoloServicios`: deja MySQL, api y game server listos sin abrir el cliente.
- `detener` → agrega `-Detener`: apaga cliente, api y game server (el MySQL de dev se queda).

El script es idempotente: comprueba cada puerto (3307 MySQL, 5100 api, 5200 game server) y solo arranca lo que esté caído.

Después de ejecutarlo, informa en una línea qué quedó corriendo. Si algún servicio falló al arrancar, revisa su salida y repórtalo en vez de asumir que está bien.

**Ojo con las cuentas** (una sesión por cuenta): el cliente con ventana entra con las credenciales de `dev_login.cfg` (odrack) y el autotest usa TestBot — no corras el autotest mientras el usuario juega con TestBot.
