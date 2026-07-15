---
name: convenciones-sqlite
description: Convenciones de base de datos para este proyecto. Consultar SIEMPRE antes de crear tablas o escribir consultas SQL.
---

# Convenciones de SQLite en este proyecto

- Motor: `bun:sqlite`, archivo único `server/db.sqlite` (ya inicializado en `server/index.ts`). No usar ORMs.
- Esquema por código: `db.exec("CREATE TABLE IF NOT EXISTS ...")` al arrancar el servidor, junto a la conexión.
- Tablas en inglés y plural (`projects`, `tasks`, `people`); columnas en snake_case.
- Toda tabla lleva: `id INTEGER PRIMARY KEY AUTOINCREMENT` y `created_at TEXT NOT NULL DEFAULT (datetime('now'))`.
- Relaciones con claves foráneas explícitas y regla de borrado según la spec del cambio (CASCADE o SET NULL — nunca decidirlo sin spec).
- Consultas con parámetros preparados (`db.query("... WHERE id = ?").get(id)`), nunca interpolar strings.
