# TodoList — Contexto del proyecto

## Propósito

Aplicación TodoList didáctica para aprender Spec-Driven Development con
OpenSpec. Los estudiantes construyen toda la funcionalidad mediante ciclos
propose → revisar → apply → probar → archive, sin escribir código a mano.

## Stack (no negociable)

- **Frontend:** React 18 + Vite en `app/`. Componentes de función simples,
  sin librerías de UI externas. Estilos en `app/src/styles.css`.
- **Backend:** Bun con `Bun.serve` en `server/index.ts`, puerto 3001.
- **Base de datos:** `bun:sqlite`, un único archivo `server/db.sqlite`.
  Sin ORMs.
- **API:** endpoints REST JSON bajo `/api/*`. El frontend usa rutas
  relativas (`/api/...`) a través del proxy de Vite.
- No agregar dependencias nuevas salvo que la spec del cambio lo justifique
  explícitamente.

## Convenciones (ver detalle en .claude/skills/)

- Todo texto visible al usuario: **en español**.
- Tablas en inglés/plural, columnas snake_case, `id` autoincremental y
  `created_at` en toda tabla. Esquema con `CREATE TABLE IF NOT EXISTS`.
- Errores de API como `{ "error": "mensaje" }` con status HTTP correcto.
- Componentes React en `app/src/components/`, uno por archivo.

## Cómo trabajar en este repo

- Cambios pequeños y enfocados: una capacidad por cambio de OpenSpec.
- Las specs son la fuente de verdad: si algo cambia de opinión, se actualiza
  la spec primero y luego se re-aplica.
- Antes de archivar, la funcionalidad debe estar probada manualmente en el
  navegador.
