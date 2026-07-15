---
name: convenciones-api
description: Convenciones del backend para este proyecto. Consultar SIEMPRE antes de crear o modificar endpoints en server/.
---

# Convenciones de la API en este proyecto

- Todo el backend vive en `server/index.ts` (Bun.serve, puerto 3001). Si crece, dividir en módulos dentro de `server/` importados desde `index.ts`.
- Endpoints REST JSON bajo `/api/<recurso>` en plural e inglés: `/api/projects`, `/api/tasks`, `/api/people`.
- Verbos: GET (listar/leer), POST (crear), PATCH (modificar parcial), DELETE (eliminar).
- Respuestas de error: `Response.json({ error: "mensaje en español" }, { status: NNN })` con el status HTTP correcto (400 validación, 404 no existe).
- Validar entrada en el servidor aunque la UI ya valide (nombre obligatorio, etc.).
- No agregar frameworks HTTP (Express, Hono, etc.): `Bun.serve` con un router simple es suficiente.
