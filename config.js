// ─── Configuración de la Reserva de espacios ──────────────────────────────────
// Proyecto de Supabase «Acceso Microsoft 365» (el mismo del Control de baños).
// Si supabaseUrl se deja vacío, la web funciona en MODO PRUEBA: guarda los datos solo en el navegador.
window.APP_CONFIG = {
  supabaseUrl: "https://hblayjaknhfxieqbzrlq.supabase.co",
  supabaseAnonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhibGF5amFrbmhmeGllcWJ6cmxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyMjg0ODEsImV4cCI6MjEwNjgwNDQ4MX0.K2iWyQAt9upNBXUhdZuV-Nle9fkCMYgQ6jTBBO0MluE",

  dominio: "salesianas.org",  // solo pueden entrar cuentas de este dominio
  antelacionDias: 60,         // el profesorado puede reservar hasta estos días por delante (administración, sin límite)
};
