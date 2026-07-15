import { Database } from "bun:sqlite";
import { join } from "path";

// Base de datos local: un solo archivo, cero configuración.
const db = new Database(join(import.meta.dir, "db.sqlite"), { create: true });
db.exec("PRAGMA journal_mode = WAL;");

// Las tablas se crean aquí con CREATE TABLE IF NOT EXISTS a medida que
// los cambios de OpenSpec las vayan necesitando. El repo base no trae ninguna.

const server = Bun.serve({
  port: 3001,
  fetch(req) {
    const url = new URL(req.url);

    if (url.pathname === "/api/health") {
      return Response.json({ ok: true, fecha: new Date().toISOString() });
    }

    // Los endpoints /api/* de la aplicación se agregan aquí vía OpenSpec.

    return Response.json({ error: "No encontrado" }, { status: 404 });
  },
});

console.log(`API escuchando en http://localhost:${server.port}`);
export { db };
