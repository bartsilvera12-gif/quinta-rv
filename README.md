# Quinta RV — landing

Landing estática de **Casa Quinta RV** (quinta con piscina y quincho en Yukyry, Luque).
Sin build ni dependencias: es HTML + dos scripts, listo para publicar en Vercel.

## Archivos

| Archivo | Para qué sirve |
| --- | --- |
| `index.html` | La página que se publica. Es una copia de `Quinta RV v2.dc.html`. |
| `Quinta RV v2.dc.html` | El archivo que editás en la app. Fuente de verdad. |
| `support.js` | Runtime que renderiza la página. |
| `image-slot.js` | Componente de las fotos. |
| `image-slots.state.json` | Las fotos cargadas (copia sin punto del sidecar, porque Vercel no sirve archivos que empiezan con `.`). |
| `sync.ps1` | Copia el `.dc.html` y el sidecar a `index.html` / `image-slots.state.json`. |

## Publicar en Vercel

1. En [vercel.com/new](https://vercel.com/new) importá este repo.
2. Framework preset: **Other**. Sin build command, sin output directory.
3. Deploy.

## Actualizar la página

Después de editar `Quinta RV v2.dc.html` (o de cambiar fotos):

```powershell
.\sync.ps1
git add -A
git commit -m "actualiza landing"
git push
```

Vercel redeploya solo con cada push.
