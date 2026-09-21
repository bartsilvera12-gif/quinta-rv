-- =========================================================================
-- Carga en la galería las 12 fotos que ya vienen publicadas con el sitio.
-- Pegalo en el SQL Editor y dale Run.
--
-- No sube nada al bucket: las fotos ya están en el repo (carpeta uploads/),
-- así que las filas apuntan directo a esos archivos. Desde el panel podés
-- reordenarlas, cambiarles la categoría o borrarlas igual que cualquier otra.
--
-- Es idempotente: si ya cargaste una foto con el mismo path, no se duplica.
-- =========================================================================

insert into quintarv.gallery (path, category, title, sort_order)
select v.path, v.category, v.title, v.sort_order
from (values
  ('uploads/quintarv/quinta-rv (13).webp',      'Piscina',    'Piscina con cascada',          1),
  ('uploads/quintarv/quinta-rv (2) (1).webp',   'Piscina',    'Piscina al atardecer',         2),
  ('uploads/quintarv/quinta-rv (15).webp',      'Piscina',    'Piscina y sombrillas',         3),
  ('uploads/quintarv/quinta-rv (8).webp',       'Piscina',    'Piscina de día',               4),
  ('uploads/quintarv/quinta-rv (11).webp',      'Piscina',    'Piscina y hamaca paraguaya',   5),
  ('uploads/quintarv/quinta-rv (14).webp',      'Quincho',    'Quincho frente a la piscina',  6),
  ('uploads/quintarv/quinta-rv (3) (1).webp',   'Quincho',    'Hamaca y estar del quincho',   7),
  ('uploads/quintarv/quinta-rv (9).webp',       'Quincho',    'Salón del quincho',            8),
  ('uploads/quintarv/quinta-rv (1).webp',       'Exterior',   'Parque y galería',             9),
  ('uploads/quintarv/quinta-rv (10).webp',      'Habitación', 'Habitación climatizada',      10),
  ('uploads/quintarv/quinta-rv (6).webp',       'Interior',   'Baño completo',               11),
  ('uploads/quintarv/quinta-rv (7).webp',       'Noche',      'El predio de noche',          12)
) as v(path, category, title, sort_order)
where not exists (
  select 1 from quintarv.gallery g where g.path = v.path
);

-- Cómo quedó:
select sort_order, category, title from quintarv.gallery order by sort_order;

-- =========================================================================
-- Para volver a empezar de cero (borra SOLO estas 12, no las que subas vos):
--   delete from quintarv.gallery where path like 'uploads/quintarv/%';
-- =========================================================================
