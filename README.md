# Casa Quinta RV

Sitio de reservas por turno (día / noche) de Casa Quinta RV — Yukyry, Luque.
Es 100% estático: HTML + dos scripts, sin build. El panel de administración
vive en `/admin`, dentro del mismo archivo.

## Publicar en Vercel

1. Entrar a [vercel.com/new](https://vercel.com/new) e importar este repo.
2. Framework Preset: **Other**. Sin build command, sin output directory.
3. Deploy.

El `vercel.json` ya tiene el rewrite para que `/admin` no dé 404.

## Base de datos (Supabase)

Antes del primer uso del panel, correr [`supabase-schema.sql`](supabase-schema.sql)
en el SQL Editor. Crea el schema `quintarv` con las tablas, las políticas RLS
y el bucket de fotos. Es idempotente.

Después quedan dos pasos en el dashboard:

1. **Authentication → Users → Add user**: `admin@quintarv.com`, con la
   contraseña que elijas y **Auto Confirm User** tildado.
2. **Settings → API → Exposed schemas**: agregar `quintarv`.
   (Self-hosted: `PGRST_DB_SCHEMAS=public,quintarv,storage,graphql_public`
   y reiniciar PostgREST.)

Sin el paso 2 el panel muestra el aviso «Invalid schema: quintarv».

La URL y la anon key están en el `<helmet>` de `index.html`, arriba de todo.

## El panel

`/admin` — entra solo `admin@quintarv.com`.

| Pestaña | Qué hace |
| --- | --- |
| Reservas | Las que entran por el sitio llegan como PENDIENTE. Confirmar o rechazar. Al confirmar, el turno queda ocupado en el calendario público. |
| Calendario | Dos turnos por día (D / N). Se bloquean y liberan tocándolos. Abajo, el formulario para cargar reservas de WhatsApp o teléfono. |
| Galería | Subir, recategorizar, reordenar y borrar fotos. Apenas hay una foto en la base, el sitio deja de usar las del diseño y muestra estas. |
| Configuración | Precios por turno, capacidad, horarios, seña, alias y WhatsApp. Se guardan solos al terminar de escribir. |

### Estados de un turno

| Estado | Color |
| --- | --- |
| Disponible | blanco |
| Pendiente | crema |
| Reservado / confirmado | rojo |
| Bloqueado | casi negro |
| Ya pasó | gris claro |

Dos personas no pueden tomar el mismo turno: hay un índice único sobre
(fecha, turno) para las reservas pendientes y confirmadas, así que la
segunda confirmación falla y el sitio manda a elegir otra fecha.

## Archivos

| Archivo | Para qué sirve |
| --- | --- |
| `Casa Quinta RV.dc.html` | El archivo que editás en la app. Fuente de verdad. |
| `index.html` | Copia del anterior. Es lo que Vercel publica. |
| `support.js` / `image-slot.js` | Runtime de la página y componente de fotos. |
| `image-slots.state.json` | Fotos cargadas a mano (copia sin punto: Vercel no sirve archivos que empiezan con `.`). |
| `sync.ps1` | Copia el `.dc.html` y el sidecar a los archivos que se publican. |

## Actualizar

Después de editar `Casa Quinta RV.dc.html`:

```powershell
.\sync.ps1
git add -A
git commit -m "actualiza sitio"
git push
```

Vercel redeploya solo con cada push.
