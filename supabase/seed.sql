-- Reserva de espacios · datos iniciales (ejecutar una vez, después de schema.sql)
-- Después, todo se cambia desde la web (menú Administración).

-- Horas habituales (atajos al reservar), una lista por etapa
-- Si ya se ejecutó una versión anterior, las horas que había son las de ESO
update res_franjas set etapa = 'ESO · Bachillerato · CCFF' where etapa is null;

-- ESO, Bachillerato y CCFF: de 8:00 a 14:30, clases de 1 hora y recreo de 11:00 a 11:30
insert into res_franjas (etapa, nombre, inicio, fin, orden)
select 'ESO · Bachillerato · CCFF', * from (values
  ('1ª hora', time '08:00', time '09:00', 1),
  ('2ª hora', time '09:00', time '10:00', 2),
  ('3ª hora', time '10:00', time '11:00', 3),
  ('Recreo',  time '11:00', time '11:30', 4),
  ('4ª hora', time '11:30', time '12:30', 5),
  ('5ª hora', time '12:30', time '13:30', 6),
  ('6ª hora', time '13:30', time '14:30', 7)
) v where not exists (select 1 from res_franjas where etapa = 'ESO · Bachillerato · CCFF');

-- Infantil y Primaria: de 9:00 a 14:00, clases de 1 hora antes del recreo (12:00-12:30) y de 45 minutos después
insert into res_franjas (etapa, nombre, inicio, fin, orden)
select 'Infantil · Primaria', * from (values
  ('1ª hora', time '09:00', time '10:00', 1),
  ('2ª hora', time '10:00', time '11:00', 2),
  ('3ª hora', time '11:00', time '12:00', 3),
  ('Recreo',  time '12:00', time '12:30', 4),
  ('4ª hora', time '12:30', time '13:15', 5),
  ('5ª hora', time '13:15', time '14:00', 6)
) v where not exists (select 1 from res_franjas where etapa = 'Infantil · Primaria');

-- Espacios (los mismos que había en Bookings)
insert into res_espacios (nombre, descripcion, color, icono, orden) values
  ('Salón de Actos',      'Actos, charlas y reuniones grandes.',       '#009abb', 'escenario', 1),
  ('Biblioteca',          'Lectura, trabajo en grupo y reuniones.',    '#8a9400', 'libro',     2),
  ('Recibidor',           'Atención a familias y reuniones pequeñas.', '#ee712a', 'puerta',    3),
  ('Aula de Informática', 'Ordenadores fijos para un grupo completo.', '#007791', 'pantalla',  4),
  ('Laboratorio',         'Prácticas de ciencias.',                    '#6b7200', 'matraz',    5)
on conflict (nombre) do nothing;

-- Categorías de los espacios (los dispositivos van siempre en «Dispositivos»)
update res_espacios set categoria = 'Zonas comunes'   where categoria is null and nombre in ('Salón de Actos', 'Biblioteca', 'Recibidor');
update res_espacios set categoria = 'Aulas temáticas' where categoria is null and nombre in ('Aula de Informática', 'Laboratorio');

-- Dispositivos numerados (los números se pueden cambiar desde la web)
insert into res_espacios (nombre, tipo, grupo, numero, color, icono, orden)
select 'iPad ' || n, 'dispositivo', 'iPads', n, '#d35a15', 'tableta', 100 + n from generate_series(1, 15) n
on conflict (nombre) do nothing;
insert into res_espacios (nombre, tipo, grupo, numero, color, icono, orden)
select 'Portátil ' || n, 'dispositivo', 'Portátiles', n, '#475569', 'portatil', 200 + n from generate_series(1, 20) n
on conflict (nombre) do nothing;

-- Packs
insert into res_packs (grupo, nombre, espacios, orden)
select g, nombre, (select array_agg(id order by numero) from res_espacios where grupo = g and numero between a and b), o
from (values
  ('iPads', 'iPads 1-5', 1, 5, 1), ('iPads', 'iPads 6-10', 6, 10, 2), ('iPads', 'iPads 11-15', 11, 15, 3),
  ('Portátiles', 'Portátiles 1-10', 1, 10, 1), ('Portátiles', 'Portátiles 11-20', 11, 20, 2)
) v(g, nombre, a, b, o)
where not exists (select 1 from res_packs);

-- Cuentas de administración (después se gestionan desde la web)
insert into res_admin (email) values
  ('laura.ramos@salesianas.org'),
  ('silvia.alonso@salesianas.org'),
  ('rocio.cano@salesianas.org'),
  ('antonio.puntas@salesianas.org'),
  ('administracionnervion@salesianas.org'),
  ('mangeles.chavez@salesianas.org')
on conflict do nothing;
