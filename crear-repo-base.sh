#!/usr/bin/env bash
# ============================================================================
# crear-repo-base.sh
# Genera el repo base "openspec-todolist-base" para el tutorial de OpenSpec.
#
# Uso:      bash crear-repo-base.sh [carpeta-destino]
# Requiere: bun (>= 1.1) y git instalados.
# Windows:  ejecutar en Git Bash o WSL.
# ============================================================================
set -euo pipefail

DESTINO="${1:-openspec-todolist-base}"

# ---------- Verificaciones ----------
command -v bun >/dev/null 2>&1 || { echo "ERROR: bun no está instalado (https://bun.sh)"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "ERROR: git no está instalado"; exit 1; }
[ -e "$DESTINO" ] && { echo "ERROR: la carpeta '$DESTINO' ya existe"; exit 1; }

echo "==> Creando estructura en $DESTINO/"
mkdir -p "$DESTINO"/{app/src/components,server,.claude/skills,openspec}
cd "$DESTINO"

# ============================================================================
# Raíz del proyecto
# ============================================================================
cat > package.json << 'EOF'
{
  "name": "openspec-todolist-base",
  "private": true,
  "scripts": {
    "dev": "concurrently -n server,app -c blue,green \"bun run dev:server\" \"bun run dev:app\"",
    "dev:server": "bun --watch server/index.ts",
    "dev:app": "cd app && bunx vite"
  },
  "workspaces": ["app"],
  "devDependencies": {
    "concurrently": "^9.1.0"
  }
}
EOF

cat > .gitignore << 'EOF'
node_modules/
dist/
server/db.sqlite*
.claude/.archive-pendiente
.DS_Store
EOF

cat > README.md << 'EOF'
# openspec-todolist-base

Repo base del tutorial **OpenSpec en acción: un TodoList paso a paso**.

## Arranque

```bash
bun install
bun dev        # API en :3001 + app en http://localhost:5173
```

La app arranca vacía a propósito: toda la funcionalidad se construye
siguiendo el tutorial, con ciclos de OpenSpec (`/opsx:propose` → revisar →
`/opsx:apply` → probar → `/opsx:archive`).

Los comandos `/opsx:*` y los skills ya vienen incluidos en `.claude/`:
abre Claude Code (CLI o app de escritorio) sobre esta carpeta y escribe `/opsx`.
EOF

# ============================================================================
# server/ — Bun + bun:sqlite
# ============================================================================
cat > server/index.ts << 'EOF'
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
EOF

# ============================================================================
# app/ — React + Vite
# ============================================================================
cat > app/package.json << 'EOF'
{
  "name": "app",
  "private": true,
  "type": "module",
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.3.4",
    "vite": "^6.0.0"
  }
}
EOF

cat > app/vite.config.js << 'EOF'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      // Todas las llamadas del frontend a /api/* van al servidor Bun.
      "/api": "http://localhost:3001",
    },
  },
});
EOF

cat > app/index.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>TodoList</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

cat > app/src/main.jsx << 'EOF'
import React from "react";
import { createRoot } from "react-dom/client";
import App from "./App.jsx";
import "./styles.css";

createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

cat > app/src/App.jsx << 'EOF'
import { useEffect, useState } from "react";

export default function App() {
  const [api, setApi] = useState("conectando…");

  useEffect(() => {
    fetch("/api/health")
      .then((r) => r.json())
      .then(() => setApi("conectada ✓"))
      .catch(() => setApi("sin conexión ✗"));
  }, []);

  return (
    <main className="pantalla-base">
      <h1>TodoList</h1>
      <p>
        Repo base listo. Aquí no hay funcionalidad todavía: se construye paso a
        paso con OpenSpec.
      </p>
      <p className="estado-api">API {api}</p>
    </main>
  );
}
EOF

cat > app/src/styles.css << 'EOF'
* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: system-ui, sans-serif;
  background: #f5f6f8;
  color: #1d2733;
  min-height: 100vh;
  display: grid;
  place-items: center;
}

.pantalla-base { text-align: center; padding: 2rem; }
.pantalla-base h1 { font-size: 2.4rem; margin-bottom: 0.5rem; }
.pantalla-base p { color: #5a6b80; max-width: 32rem; }
.estado-api { margin-top: 1rem; font-family: monospace; font-size: 0.85rem; }
EOF

# ============================================================================
# .claude/skills/ — convenciones que la IA lee al construir
# ============================================================================
mkdir -p .claude/skills/{convenciones-react,convenciones-api,convenciones-sqlite}

cat > .claude/skills/convenciones-react/SKILL.md << 'EOF'
---
name: convenciones-react
description: Convenciones de frontend para este proyecto. Consultar SIEMPRE antes de crear o modificar componentes React, estilos o cualquier código en app/.
---

# Convenciones de React en este proyecto

- Componentes de función con hooks. Un componente por archivo, en `app/src/components/`.
- Sin librerías de UI externas (nada de MUI, Chakra, Tailwind, etc.). Estilos en `app/src/styles.css` con clases en español y kebab-case (ej. `barra-lateral`).
- Estado local con `useState`/`useEffect`. No introducir gestores de estado (Redux, Zustand) — la app es pequeña a propósito.
- Llamadas a la API con `fetch` a rutas relativas `/api/...` (el proxy de Vite las enruta al servidor Bun).
- Todo texto visible al usuario, en español. Confirmaciones destructivas con `window.confirm` es aceptable.
- Mantener `App.jsx` como orquestador: composición de componentes, no lógica de negocio extensa.
EOF

cat > .claude/skills/convenciones-api/SKILL.md << 'EOF'
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
EOF

cat > .claude/skills/convenciones-sqlite/SKILL.md << 'EOF'
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
EOF

# ============================================================================
# OpenSpec: init no-interactivo para Claude Code + constitución del proyecto
# ============================================================================
echo "==> Inicializando OpenSpec (comandos /opsx:* + skills para Claude Code)"
bunx --yes @fission-ai/openspec@latest init --tools claude

echo "==> Escribiendo la constitución del proyecto (openspec/project.md)"
cat > openspec/project.md << 'EOF'
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
EOF

# ============================================================================
# Hooks de Claude Code: automatización git del ciclo OpenSpec
# ============================================================================
# Determinísticos (no dependen de que el modelo obedezca):
#   - /opsx:propose → crea y activa una rama propose/<id>-<timestamp>
#   - /opsx:archive → al terminar, git add -A + commit con el id del cambio
mkdir -p .claude/hooks

cat > .claude/hooks/rama-propose.sh << 'EOF'
#!/usr/bin/env bash
# Hook UserPromptSubmit: crea una rama por cada /opsx:propose.
# Recibe JSON por stdin; usa bun (prerrequisito del proyecto) para parsearlo.
set -euo pipefail

PROMPT=$(bun -e 'const d=await new Response(Bun.stdin.stream()).text();try{process.stdout.write(JSON.parse(d).prompt??"")}catch{}' 2>/dev/null || true)

case "$PROMPT" in
  /opsx:propose*)
    # El id del cambio es la palabra siguiente al comando (solo primera línea).
    ID=$(printf '%s' "$PROMPT" | head -n1 | awk '{print $2}' | tr -cd 'a-zA-Z0-9._-')
    [ -z "$ID" ] && ID="cambio"
    RAMA="propose/${ID}-$(date +%Y%m%d-%H%M%S)"
    if git checkout -b "$RAMA" >/dev/null 2>&1; then
      # Lo que se imprime aquí se inyecta como contexto para Claude.
      echo "Rama git creada y activa para este cambio: $RAMA. Trabaja sobre ella; no crees otra."
    fi
    ;;
esac
exit 0
EOF

cat > .claude/hooks/marcar-archive.sh << 'EOF'
#!/usr/bin/env bash
# Hook UserPromptSubmit: marca que se pidió /opsx:archive para que el hook
# de Stop haga el commit al terminar (aquí el archive aún no movió archivos).
set -euo pipefail

PROMPT=$(bun -e 'const d=await new Response(Bun.stdin.stream()).text();try{process.stdout.write(JSON.parse(d).prompt??"")}catch{}' 2>/dev/null || true)

case "$PROMPT" in
  /opsx:archive*)
    # Id del cambio: argumento del comando o, si no viene, derivado de la rama.
    ID=$(printf '%s' "$PROMPT" | head -n1 | awk '{print $2}' | tr -cd 'a-zA-Z0-9._-')
    if [ -z "$ID" ]; then
      RAMA=$(git branch --show-current 2>/dev/null || true)
      case "$RAMA" in
        propose/*) ID=$(printf '%s' "$RAMA" | sed -E 's|^propose/||; s|-[0-9]{8}-[0-9]{6}$||');;
      esac
    fi
    [ -z "$ID" ] && ID="cambio"
    printf '%s' "$ID" > .claude/.archive-pendiente
    echo "Hook configurado: al terminar este archive se hará commit automático del cambio '$ID'. No hagas commits manuales."
    ;;
esac
exit 0
EOF

cat > .claude/hooks/commit-archive.sh << 'EOF'
#!/usr/bin/env bash
# Hook Stop: si hay un archive marcado como pendiente y ya se completó,
# hace git add -A + commit con mensaje relacionado al cambio.
set -euo pipefail

MARCA=.claude/.archive-pendiente
[ -f "$MARCA" ] || exit 0

ID=$(cat "$MARCA")

# ¿El archive realmente terminó? El cambio ya no debe estar activo.
if [ -d "openspec/changes/$ID" ]; then
  # Sigue activo: el archive no terminó en este turno; se mantiene la marca.
  exit 0
fi

rm -f "$MARCA"
git add -A
if ! git diff --cached --quiet; then
  RAMA=$(git branch --show-current 2>/dev/null || echo "?")
  git commit -q -m "Cambio '$ID' completado y archivado (rama $RAMA)"
fi
exit 0
EOF

chmod +x .claude/hooks/*.sh

cat > .claude/settings.json << 'EOF'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/rama-propose.sh" },
          { "type": "command", "command": "bash .claude/hooks/marcar-archive.sh" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/commit-archive.sh" }
        ]
      }
    ]
  }
}
EOF

# ============================================================================
# Dependencias + commit inicial
# ============================================================================
# git no versiona carpetas vacías: .gitkeep asegura que la estructura llegue
# completa al estudiante al clonar.
touch openspec/specs/.gitkeep openspec/changes/archive/.gitkeep app/src/components/.gitkeep

echo "==> Instalando dependencias"
bun install

echo "==> Creando commit inicial"
git init -q
git add -A
git commit -q -m "Repo base: React + Vite, Bun + SQLite, skills y OpenSpec inicializado"

echo ""
echo "============================================================"
echo "  Repo base creado en: $DESTINO/"
echo ""
echo "  Probar:   cd $DESTINO && bun dev"
echo "            → API en :3001, app en http://localhost:5173"
echo ""
echo "  Verificar comandos: abrir Claude Code en la carpeta"
echo "            y escribir /opsx (deben aparecer propose, apply…)"
echo ""
echo "  Publicar: crear repo vacío en GitHub y hacer push."
echo "============================================================"