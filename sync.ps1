# Prepara los archivos que Vercel publica a partir de la version que editas
# en la app (Casa Quinta RV.dc.html + su sidecar de imagenes).
# Uso:  .\sync.ps1     y despues:  git add -A; git commit -m "update"; git push
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
Copy-Item (Join-Path $root "Casa Quinta RV.dc.html") (Join-Path $root "index.html") -Force
Copy-Item (Join-Path $root ".image-slots.state.json") (Join-Path $root "image-slots.state.json") -Force
Write-Host "Listo: index.html e image-slots.state.json actualizados."
