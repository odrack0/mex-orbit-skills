# Enlaza .claude\skills y .claude\commands de MexOrbit a este repo.
#
# Junctions y no copias: una copia por sitio es una copia que se queda atras.
# `mklink /J` no necesita permisos de administrador, al contrario que los enlaces
# simbolicos, y por eso se usa este y no `New-Item -ItemType SymbolicLink`.
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$raiz = (Resolve-Path (Join-Path $repo '..\..')).Path      # C:\Source\MexOrbit
$claude = Join-Path $raiz '.claude'

foreach ($par in @(@('skills', 'skills'), @('commands', 'commands'))) {
    $destino = Join-Path $claude $par[0]
    $origen = Join-Path $repo $par[1]

    if (Test-Path $destino) {
        $item = Get-Item $destino -Force
        if ($item.LinkType -eq 'Junction') {
            Write-Host "$($par[0]): ya enlazado" -ForegroundColor DarkGray
            continue
        }
        # NO se borra a ciegas. Si ahi hay archivos de verdad puede haber trabajo
        # sin commit, y un enlace que los sustituye se los lleva por delante sin
        # que nadie lo note hasta que hace falta.
        $sueltos = Get-ChildItem $destino -Recurse -File -ErrorAction SilentlyContinue
        if ($sueltos) {
            Write-Host "$($par[0]): ya existe con $($sueltos.Count) archivo(s) reales." -ForegroundColor Yellow
            Write-Host "  Comprueba que estan en el repo y borra la carpeta a mano:" -ForegroundColor Yellow
            Write-Host "    $destino" -ForegroundColor Yellow
            continue
        }
        Remove-Item $destino -Force -Recurse
    }
    New-Item -ItemType Directory -Force -Path $claude | Out-Null
    cmd /c mklink /J "$destino" "$origen" | Out-Null
    Write-Host "$($par[0]): enlazado -> $origen" -ForegroundColor Green
}
