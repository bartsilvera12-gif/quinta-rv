-- =========================================================================
-- Casa Quinta RV — schema `quintarv` para Supabase
--
-- Pegá TODO esto en el SQL Editor y dale Run. Es idempotente: podés
-- correrlo las veces que quieras sin romper nada ni perder datos.
--
-- Modelo: la quinta se alquila POR TURNO (día / noche), no por noche
-- de alojamiento. Por eso cada reserva es (fecha + turno).
-- =========================================================================

-- ----- 1) Schema propio -------------------------------------------------

create schema if not exists quintarv;
grant usage on schema quintarv to anon, authenticated, service_role;
alter default privileges in schema quintarv
  grant select, insert, update, delete on tables to anon, authenticated, service_role;

-- ----- 2) Tablas --------------------------------------------------------

-- Configuración del sitio. Una sola fila (id = 1). El panel la edita.
create table if not exists quintarv.config (
  id int primary key default 1,
  price_full_day      bigint  not null default 900000,
  price_full_night    bigint  not null default 1100000,
  price_couple_day    bigint  not null default 450000,
  price_couple_night  bigint  not null default 550000,
  price_extra_person  bigint  not null default 50000,
  included_full       int     not null default 15,
  max_full            int     not null default 25,
  included_couple     int     not null default 2,
  max_couple          int     not null default 2,
  deposit_pct         int     not null default 30,
  hold_minutes        int     not null default 30,
  day_time            text    not null default '10:00 - 18:00',
  night_time          text    not null default '19:00 - 03:00',
  alias               text    not null default 'quintarv.py',
  whatsapp            text    not null default '595981123456',
  promo_couple        boolean not null default true,
  constraint config_singleton check (id = 1)
);
insert into quintarv.config (id) values (1) on conflict do nothing;

-- Reservas. Una fila = un turno de un día.
create table if not exists quintarv.reservations (
  code text primary key,
  name text not null,
  phone text not null,
  date date not null,
  modality text not null default 'full' check (modality in ('full','couple')),
  shift text not null check (shift in ('day','night')),
  people int not null default 1,
  total bigint not null default 0,
  deposit bigint,
  status text not null default 'PENDIENTE'
    check (status in ('PENDIENTE','CONFIRMADA','RECHAZADA','VENCIDA')),
  source text not null default 'web' check (source in ('web','manual')),
  created_at timestamptz not null default now()
);
create index if not exists reservations_date_idx   on quintarv.reservations (date);
create index if not exists reservations_status_idx on quintarv.reservations (status);

-- Un turno ocupado no se puede volver a tomar. Las rechazadas y vencidas
-- liberan el turno, por eso el índice es parcial.
create unique index if not exists reservations_slot_taken_idx
  on quintarv.reservations (date, shift)
  where status in ('PENDIENTE','CONFIRMADA');

-- Turnos bloqueados a mano desde el panel (mantenimiento, uso propio, etc.)
create table if not exists quintarv.blocked_slots (
  date date not null,
  shift text not null check (shift in ('day','night')),
  reason text,
  created_at timestamptz not null default now(),
  primary key (date, shift)
);

-- Galería. `path` es la key dentro del bucket 'quintarv-photos'.
create table if not exists quintarv.gallery (
  id uuid primary key default gen_random_uuid(),
  path text not null,
  category text not null default 'Piscina'
    check (category in ('Piscina','Exterior','Interior','Habitación','Quincho','Noche')),
  sort_order int not null default 0,
  title text,
  created_at timestamptz not null default now()
);
create index if not exists gallery_order_idx on quintarv.gallery (sort_order);

-- Admins autorizados a entrar al panel.
create table if not exists quintarv.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  created_at timestamptz not null default now()
);

grant select, insert, update, delete on all tables in schema quintarv
  to anon, authenticated;

-- ----- 3) Quién es admin ------------------------------------------------
-- Solo admin@quintarv.com entra al panel. Se valida por email (no por uuid)
-- para que no importe si creás el usuario antes o después de este script.

create or replace function quintarv.is_admin() returns boolean
language sql stable security definer set search_path = quintarv, public, auth as $fn$
  select exists (
    select 1 from auth.users u
    where u.id = auth.uid()
      and (
        lower(u.email) = 'admin@quintarv.com'
        or exists (select 1 from quintarv.admins a where a.user_id = u.id)
      )
  );
$fn$;
grant execute on function quintarv.is_admin() to anon, authenticated;

-- ----- 4) RLS -----------------------------------------------------------

alter table quintarv.config        enable row level security;
alter table quintarv.reservations  enable row level security;
alter table quintarv.blocked_slots enable row level security;
alter table quintarv.gallery       enable row level security;
alter table quintarv.admins        enable row level security;

drop policy if exists "config public read"         on quintarv.config;
drop policy if exists "config admin update"        on quintarv.config;
drop policy if exists "reservations public read"   on quintarv.reservations;
drop policy if exists "reservations public insert" on quintarv.reservations;
drop policy if exists "reservations admin update"  on quintarv.reservations;
drop policy if exists "reservations admin delete"  on quintarv.reservations;
drop policy if exists "blocked_slots public read"  on quintarv.blocked_slots;
drop policy if exists "blocked_slots admin write"  on quintarv.blocked_slots;
drop policy if exists "gallery public read"        on quintarv.gallery;
drop policy if exists "gallery admin write"        on quintarv.gallery;
drop policy if exists "admins self read"           on quintarv.admins;

-- Lectura pública: el sitio necesita precios, fotos y qué turnos están libres.
create policy "config public read"
  on quintarv.config for select using (true);
create policy "reservations public read"
  on quintarv.reservations for select using (true);
create policy "blocked_slots public read"
  on quintarv.blocked_slots for select using (true);
create policy "gallery public read"
  on quintarv.gallery for select using (true);

-- Cualquiera puede pedir una reserva desde el sitio, pero solo como PENDIENTE.
create policy "reservations public insert"
  on quintarv.reservations for insert
  with check (status = 'PENDIENTE');

-- Todo lo demás es solo del admin.
create policy "reservations admin update"
  on quintarv.reservations for update to authenticated
  using (quintarv.is_admin()) with check (quintarv.is_admin());
create policy "reservations admin delete"
  on quintarv.reservations for delete to authenticated
  using (quintarv.is_admin());
create policy "blocked_slots admin write"
  on quintarv.blocked_slots for all to authenticated
  using (quintarv.is_admin()) with check (quintarv.is_admin());
create policy "config admin update"
  on quintarv.config for update to authenticated
  using (quintarv.is_admin()) with check (quintarv.is_admin());
create policy "gallery admin write"
  on quintarv.gallery for all to authenticated
  using (quintarv.is_admin()) with check (quintarv.is_admin());
create policy "admins self read"
  on quintarv.admins for select to authenticated
  using (auth.uid() = user_id);

-- ----- 5) Bucket de fotos ----------------------------------------------

insert into storage.buckets (id, name, public)
values ('quintarv-photos', 'quintarv-photos', true)
on conflict (id) do nothing;

drop policy if exists "quintarv photos public read"  on storage.objects;
drop policy if exists "quintarv photos admin write"  on storage.objects;
drop policy if exists "quintarv photos admin update" on storage.objects;
drop policy if exists "quintarv photos admin delete" on storage.objects;

create policy "quintarv photos public read"
  on storage.objects for select
  using (bucket_id = 'quintarv-photos');
create policy "quintarv photos admin write"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'quintarv-photos' and quintarv.is_admin());
create policy "quintarv photos admin update"
  on storage.objects for update to authenticated
  using (bucket_id = 'quintarv-photos' and quintarv.is_admin());
create policy "quintarv photos admin delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'quintarv-photos' and quintarv.is_admin());

-- ----- 6) Dejar registrado al admin ------------------------------------
-- Si el usuario admin@quintarv.com ya existe, lo anota en la tabla.
-- Si todavía no lo creaste, no pasa nada: is_admin() lo reconoce igual
-- por el email apenas lo crees.

insert into quintarv.admins (user_id, email)
select id, email from auth.users where lower(email) = 'admin@quintarv.com'
on conflict (user_id) do nothing;

-- ----- 7) Chequeo final -------------------------------------------------

select 'tablas' as que, string_agg(tablename, ', ' order by tablename) as valor
from pg_tables where schemaname = 'quintarv'
union all
select 'admin cargado', coalesce(string_agg(email, ', '), 'todavia no - crea el usuario en Authentication')
from quintarv.admins;

-- =========================================================================
-- DESPUES DE CORRER ESTO FALTAN 2 COSAS EN EL DASHBOARD:
--
-- 1) Crear el usuario del panel:
--    Authentication -> Users -> Add user
--      Email:    admin@quintarv.com
--      Password: la que elijas
--      Auto Confirm User: si  (importante, si no, no puede entrar)
--
-- 2) Exponer el schema en la API:
--    Settings -> API -> Exposed schemas -> agregar `quintarv`
--
--    (Supabase self-hosted: en el .env / docker-compose poner
--     PGRST_DB_SCHEMAS=public,quintarv,storage,graphql_public
--     y despues `docker compose restart rest`)
--
-- Sin el paso 2 el panel no va a poder leer ni escribir nada.
-- =========================================================================
