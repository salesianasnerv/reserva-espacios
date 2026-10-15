# Reserva de espacios

Web para que el profesorado reserve los espacios y dispositivos del colegio, en lugar de las páginas de Microsoft Bookings. Se entra con la cuenta de Microsoft 365 del colegio.

- **Reservar**, en tres pasos:
  1. **¿Cuándo?** Eliges el día y escribes la hora de inicio y de fin que quieras, o eliges una hora de la plantilla horaria de clases (1ª hora, recreo…) como atajo. Puedes añadir varios días u horarios y repetirlo cada semana hasta una fecha.
  2. **¿Qué?** Marcas a la vez todos los espacios y dispositivos que necesites. Cada iPad (1–15) y cada portátil (1–20) se reserva por separado, o de golpe con un pack («iPads 1-5») o con «Todos los libres». Lo ocupado aparece en gris, con quién lo tiene.
  3. **¿Para qué?** Grupo o actividad. Se hacen todas las reservas de una vez (espacios × horarios).
- **Ocupación**: la otra forma de reservar (se llega también desde el aviso de arriba de «Reservar»). La línea de tiempo de un día con todos los espacios. iPads y portátiles aparecen agrupados («5/15» ocupados) y se despliegan para ver cada uno. Al pulsar un hueco libre empieza una reserva ya rellena; al pulsar una reserva se ve de quién es.
- **Mis reservas**: tus próximas reservas, agrupadas como las hiciste, con el botón para anularlas (una, todo el grupo o también las de otros días).
- **Administración** (solo las cuentas autorizadas):
  - **Todas las reservas**: listado con filtros (fechas, espacio o dispositivo, profesor/a) y descarga para Excel. Desde aquí, y desde Ocupación, se puede mover, cambiar de hora o anular cualquier reserva.
  - **Espacios y dispositivos**: añadir, editar o desactivar espacios. En los dispositivos se puede cambiar el número o el nombre de cada uno, desactivarlos si están rotos, añadir más, crear o editar packs y crear tipos nuevos (cámaras, proyectores…). Para cada cosa se eligen los días y las horas entre las que se puede reservar.
  - **Plantilla horaria de clases**: los atajos de horario que se ofrecen al reservar.
  - **Bloqueos y usos fijos**: clases fijas cada semana (p. ej. Informática los lunes de 9:00 a 10:00), festivos, actos… para un espacio, un dispositivo, un tipo entero o todo. Se crean de dos formas: **horas sueltas** (un día, varios días seguidos o un hueco cada semana) u **horario semanal** (una rejilla días × horas de la plantilla horaria de clases donde se marcan varias horas a la vez; las seguidas se guardan juntas). Cada bloqueo lleva motivo y persona, los dos opcionales, y se puede editar o quitar desde la lista o pulsándolo en la rejilla.
  - **Cuentas de administración**: dar o quitar este acceso. Al empezar son laura.ramos, silvia.alonso, rocio.cano, antonio.puntas, administracionnervion y mangeles.chavez (@salesianas.org).

## Probarla ahora (modo prueba)

Con `supabaseUrl` vacío en `config.js`, la web funciona sin servidor y guarda los datos solo en tu navegador. Súbela a Vercel tal cual, o ábrela con un servidor local, y pulsa «Generar reservas de ejemplo».

## Ponerla en marcha (reutiliza el Supabase del Control de baños)

Las tablas de esta web empiezan por `res_` y no tocan las del Control de baños. La administración de reservas también es independiente. Como ese proyecto ya tiene configurado el acceso con Microsoft 365, **no hace falta pedir nada a informática**.

1. **Base de datos.** En https://supabase.com, abre el proyecto del Control de baños → *SQL Editor*. Pega y ejecuta `supabase/schema.sql` y, después, `supabase/seed.sql`. Así se crean los 5 espacios, los 15 iPads y los 20 portátiles numerados, los packs, la plantilla horaria de clases y las cuentas de administración. Si llegaste a ejecutar la primera versión, `schema.sql` la sustituye solo.
2. **Publicar.** Sube esta carpeta a un repositorio nuevo de GitHub (por ejemplo, `reserva-espacios`). En https://vercel.com → *Add New → Project*, impórtalo. *Framework Preset*: **Other**, sin comando de compilación. Anota la dirección que te dé (por ejemplo, `https://reserva-espacios.vercel.app`).
3. **Permitir la vuelta tras el login.** En Supabase → *Authentication → URL Configuration → Redirect URLs*, añade `https://reserva-espacios.vercel.app/**` (con tu dirección). **No cambies la *Site URL***, porque es la del Control de baños.
4. **Pasar a modo real.** En `config.js`, borra las dos líneas vacías de `supabaseUrl` y `supabaseAnonKey`, quita las `//` de las dos de debajo y súbelo a GitHub. Vercel la publica sola en un minuto.
5. Entra con tu cuenta. Las cuentas de administración son las de `seed.sql`; las demás se añaden desde *Administración → Cuentas de administración*.
6. Si la dirección final no es `reserva-espacios.vercel.app`, cámbiala en las etiquetas `og:` de `index.html` (sirven para la vista previa al compartir el enlace).

## Antes de dejar Bookings

- Revisa en *Administración → Espacios y dispositivos* las horas y días de cada cosa, y pon a cada iPad y portátil su número definitivo (pulsando sobre él).
- Mete como **bloqueos semanales** las clases fijas en Informática, el Laboratorio, etc.
- Pasa a mano las reservas futuras que ya estén en Bookings (desde *Reservar*, escribiendo el correo del profesor/a en «A nombre de»).
- Cambia los enlaces de https://claustro.nervion.salesianas.org/enlaces/reserva por el de esta web, y añádela a https://claustro-utilidades.vercel.app/.

## Seguridad

- Solo pueden entrar cuentas **@salesianas.org** (reglas RLS en `supabase/schema.sql`).
- La base de datos comprueba cada reserva aunque alguien intente saltarse la web: que no sea en el pasado, que esté dentro del horario y los días de ese espacio o dispositivo, que no esté bloqueado y que no se solape con otra reserva. Dos personas no pueden reservar a la vez lo mismo a horas que se pisen.
- Cada reserva queda a nombre de quien la hace. Solo esa persona o administración la puede anular, y solo administración la puede mover.
- El límite de antelación (`antelacionDias` en `config.js`, 60 días) lo aplica la web.
