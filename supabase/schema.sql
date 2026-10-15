-- Reserva de espacios · estructura de la base de datos (Supabase / PostgreSQL)
-- Ejecutar una vez en Supabase → SQL Editor. Después, ejecutar seed.sql.
-- Puede ir en el mismo proyecto de Supabase que el Control de baños: todas las tablas
-- empiezan por res_ y la administración de reservas es independiente.

-- Si se llegó a ejecutar la primera versión (reservas por tramos fijos), se sustituye
do $$ begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'res_reservas' and column_name = 'franja_id') then
    drop table if exists res_reservas, res_bloqueos, res_espacios cascade;
  end if;
end $$;

-- ── Horas habituales: solo son atajos para rellenar las horas al reservar ───
create table if not exists res_franjas (
  id      serial primary key,
  etapa   text,                          -- "ESO · Bachillerato · CCFF", "Infantil · Primaria"
  nombre  text not null,                 -- "1ª hora", "Recreo"…
  inicio  time not null,
  fin     time not null check (fin > inicio),
  orden   int  not null default 0,
  activo  boolean not null default true
);

alter table res_franjas add column if not exists etapa text;  -- por si la tabla ya existía

-- ── Espacios y dispositivos (cada iPad o portátil es un recurso) ───────────
create table if not exists res_espacios (
  id          serial primary key,
  nombre      text not null unique,                 -- "Salón de Actos", "iPad 7"
  descripcion text,
  tipo        text not null default 'espacio' check (tipo in ('espacio', 'dispositivo')),
  categoria   text,                                 -- espacios: "Zonas comunes", "Aulas temáticas"
  grupo       text,                                 -- dispositivos: "iPads", "Portátiles"
  numero      int,                                  -- dispositivos: su número dentro del grupo
  color       text not null default '#009abb',
  icono       text not null default 'sala',
  dias        int[] not null default '{1,2,3,4,5}', -- 1 = lunes … 7 = domingo
  apertura    time not null default '08:00',        -- horas entre las que se puede reservar
  cierre      time not null default '14:30' check (cierre > apertura),
  activo      boolean not null default true,
  orden       int  not null default 0,
  check ((tipo = 'dispositivo') = (grupo is not null))
);

alter table res_espacios add column if not exists categoria text;  -- por si la tabla ya existía

-- ── Packs: grupos de dispositivos que se reservan juntos ────────────────────
create table if not exists res_packs (
  id        serial primary key,
  grupo     text not null,
  nombre    text not null,                          -- "iPads 1-5"
  espacios  int[] not null,
  orden     int not null default 0
);

-- ── Bloqueos: usos fijos o días sin reservas (lo gestiona administración) ───
-- Puntual: fecha = el día.  Semanal: dia_semana (1-7) entre desde y hasta.
-- inicio/fin null = todo el día.  Sin espacio_id ni grupo = todo.
create table if not exists res_bloqueos (
  id          serial primary key,
  espacio_id  int references res_espacios(id) on delete cascade,
  grupo       text,
  fecha       date,
  dia_semana  int check (dia_semana between 1 and 7),
  desde       date,
  hasta       date,
  inicio      time,
  fin         time,
  motivo      text,                               -- opcional
  persona     text,                               -- opcional: quién lo usa
  creado      timestamptz not null default now(),
  check ((fecha is not null) <> (dia_semana is not null)),
  check ((inicio is null) = (fin is null) and (fin is null or fin > inicio))
);

-- Por si la tabla ya existía: el motivo pasa a ser opcional y se añade la persona
alter table res_bloqueos alter column motivo drop not null;
alter table res_bloqueos add column if not exists persona text;

-- ── Reservas ────────────────────────────────────────────────────────────────
create table if not exists res_reservas (
  id              bigserial primary key,
  espacio_id      int  not null references res_espacios(id) on delete cascade,
  fecha           date not null,
  inicio          time not null,
  fin             time not null check (fin > inicio),
  motivo          text,                                            -- grupo, actividad…
  lote            uuid,                                            -- reservas hechas de una vez
  profesor_email  text not null default lower(auth.jwt() ->> 'email'),
  profesor_nombre text,
  creado_por      text not null default lower(auth.jwt() ->> 'email'),
  creado          timestamptz not null default now()
);
create index if not exists res_reservas_fecha_idx on res_reservas (fecha, espacio_id);
create index if not exists res_reservas_prof_idx on res_reservas (profesor_email, fecha);
create index if not exists res_reservas_lote_idx on res_reservas (lote);

-- Red de seguridad: un mismo recurso nunca puede tener dos reservas que se solapen
create extension if not exists btree_gist with schema extensions;
do $$ begin
  alter table res_reservas add constraint res_sin_solape
    exclude using gist (espacio_id with =, tsrange(fecha + inicio, fecha + fin) with &&);
exception when duplicate_object or duplicate_table then null;
  when others then raise notice 'No se pudo crear res_sin_solape (%): basta con la comprobación de res_comprobar()', sqlerrm;
end $$;

-- ── Administración de reservas ──────────────────────────────────────────────
create table if not exists res_admin (
  email  text primary key,
  creado timestamptz not null default now()
);

create or replace function es_profesorado() returns boolean
language sql stable as $$
  select coalesce(lower(auth.jwt() ->> 'email') like '%@salesianas.org', false)
$$;

create or replace function es_admin_reservas() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from res_admin where lower(email) = lower(auth.jwt() ->> 'email'))
$$;

-- ── Comprobaciones al reservar (no se pueden saltar desde la web) ───────────
create or replace function res_comprobar() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  e res_espacios; otra res_reservas; dow int;
  admin boolean := es_admin_reservas();
  ahora timestamp := now() at time zone 'Europe/Madrid';
  cuando text := to_char(new.fecha, 'DD/MM/YYYY') || ' de ' || to_char(new.inicio, 'HH24:MI') || ' a ' || to_char(new.fin, 'HH24:MI');
begin
  -- Solo administración puede reservar en nombre de otra persona o modificar reservas
  if not admin then
    if tg_op = 'UPDATE' then raise exception 'Solo administración puede modificar reservas'; end if;
    new.profesor_email := lower(auth.jwt() ->> 'email');
  end if;
  new.profesor_email := lower(new.profesor_email);

  -- Dos reservas a la vez del mismo recurso y día se comprueban una detrás de otra
  perform pg_advisory_xact_lock(new.espacio_id, new.fecha - date '2000-01-01');

  select * into e from res_espacios where id = new.espacio_id;
  dow := extract(isodow from new.fecha);

  if not admin then
    if not e.activo then raise exception '% no se puede reservar ahora mismo', e.nombre; end if;
    if new.fecha + new.fin <= ahora then raise exception 'No se puede reservar en el pasado (% · %)', e.nombre, cuando; end if;
    if not (dow = any (e.dias)) then raise exception '% no se reserva ese día de la semana', e.nombre; end if;
    if new.inicio < e.apertura or new.fin > e.cierre then
      raise exception '% solo se reserva de % a %', e.nombre, to_char(e.apertura, 'HH24:MI'), to_char(e.cierre, 'HH24:MI');
    end if;
  end if;

  if exists (select 1 from res_bloqueos b
             where (b.espacio_id = new.espacio_id or b.grupo = e.grupo or (b.espacio_id is null and b.grupo is null))
               and (b.inicio is null or (b.inicio < new.fin and b.fin > new.inicio))
               and (b.fecha = new.fecha
                    or (b.dia_semana = dow and (b.desde is null or new.fecha >= b.desde) and (b.hasta is null or new.fecha <= b.hasta)))) then
    raise exception '% no está disponible el %: está bloqueado', e.nombre, cuando;
  end if;

  select * into otra from res_reservas r
    where r.espacio_id = new.espacio_id and r.fecha = new.fecha and r.id is distinct from new.id
      and r.inicio < new.fin and r.fin > new.inicio
    limit 1;
  if found then
    raise exception '% ya está reservado el % de % a % (%)', e.nombre, to_char(new.fecha, 'DD/MM/YYYY'),
      to_char(otra.inicio, 'HH24:MI'), to_char(otra.fin, 'HH24:MI'), coalesce(otra.profesor_nombre, otra.profesor_email);
  end if;
  return new;
end $$;

drop trigger if exists res_reservas_comprobar on res_reservas;
create trigger res_reservas_comprobar before insert or update on res_reservas
  for each row execute function res_comprobar();

-- ── Seguridad: solo profesorado con cuenta @salesianas.org ──────────────────
alter table res_franjas  enable row level security;
alter table res_espacios enable row level security;
alter table res_packs    enable row level security;
alter table res_bloqueos enable row level security;
alter table res_reservas enable row level security;
alter table res_admin    enable row level security;

do $$ declare t text; begin
  foreach t in array array['res_franjas', 'res_espacios', 'res_packs', 'res_bloqueos'] loop
    execute format('drop policy if exists "leer" on %I', t);
    execute format('drop policy if exists "gestionar" on %I', t);
    execute format('create policy "leer" on %I for select to authenticated using (es_profesorado())', t);
    execute format('create policy "gestionar" on %I for all to authenticated using (es_admin_reservas()) with check (es_admin_reservas())', t);
  end loop;
end $$;

-- Todo el profesorado ve qué está ocupado y por quién
drop policy if exists "leer reservas"   on res_reservas;
drop policy if exists "crear reserva"   on res_reservas;
drop policy if exists "editar reserva"  on res_reservas;
drop policy if exists "anular reserva"  on res_reservas;
create policy "leer reservas"  on res_reservas for select to authenticated using (es_profesorado());
create policy "crear reserva"  on res_reservas for insert to authenticated
  with check (es_profesorado() and (es_admin_reservas() or profesor_email = lower(auth.jwt() ->> 'email')));
create policy "editar reserva" on res_reservas for update to authenticated
  using (es_admin_reservas()) with check (es_admin_reservas());
create policy "anular reserva" on res_reservas for delete to authenticated
  using (es_admin_reservas() or profesor_email = lower(auth.jwt() ->> 'email'));

-- Administración ve la lista completa, añade cuentas del colegio y quita a otras (no a sí misma)
drop policy if exists "ver administradores"  on res_admin;
drop policy if exists "nuevo administrador"  on res_admin;
drop policy if exists "quitar administrador" on res_admin;
create policy "ver administradores" on res_admin for select to authenticated
  using (es_admin_reservas() or lower(email) = lower(auth.jwt() ->> 'email'));
create policy "nuevo administrador" on res_admin for insert to authenticated
  with check (es_admin_reservas() and lower(email) like '%@salesianas.org');
create policy "quitar administrador" on res_admin for delete to authenticated
  using (es_admin_reservas() and lower(email) <> lower(auth.jwt() ->> 'email'));
