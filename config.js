// ─── Configuración de la Reserva de espacios ──────────────────────────────────
// Si supabaseUrl está vacío, la web funciona en MODO PRUEBA: guarda los datos solo
// en este navegador, con los espacios y tramos de ejemplo de más abajo.
// Para usarla de verdad, copia aquí la Project URL y la clave anon del proyecto de Supabase
// (puede ser el mismo del Control de baños: ya tiene configurado el acceso con Microsoft 365).
window.APP_CONFIG = {
  supabaseUrl: "",
  supabaseAnonKey: "",
  // Proyecto del Control de baños. Para pasar a modo real, borra las dos líneas de arriba y quita las // de estas dos
  // (antes hay que ejecutar supabase/schema.sql y supabase/seed.sql: ver README).
  // supabaseUrl: "https://hblayjaknhfxieqbzrlq.supabase.co",
  // supabaseAnonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhibGF5amFrbmhmeGllcWJ6cmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyMjg0ODEsImV4cCI6MjEwNjgwNDQ4MX0.K2iWyQAt9upNBXUhdZuV-Nle9fkCMYgQ6jTBBO0MluE",

  dominio: "salesianas.org",  // solo pueden entrar cuentas de este dominio
  antelacionDias: 60,         // el profesorado puede reservar hasta estos días por delante (administración, sin límite)
};
