#!/usr/bin/env bash
# ============================================================================
# actualizar-repo-base.sh
# Aplica actualizaciones incrementales a un repo base YA creado y commiteado.
# Se ejecuta DESDE la raíz del repo:  bash actualizar-repo-base.sh
#
# Actualizaciones incluidas (idempotentes, no destructivas):
#   1. Hook /opsx:propose  → crea rama propose/<id>-<timestamp>
#   2. Hook /opsx:archive  → al terminar el archive, git add -A + commit
#      con mensaje relacionado al cambio de la rama.
#
# Requiere: bun y git.
# ============================================================================
set -euo pipefail

# ---------- Verificaciones ----------
command -v bun >/dev/null 2>&1 || { echo "ERROR: bun no está instalado"; exit 1; }
git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "ERROR: ejecuta este script desde dentro del repo"; exit 1; }
[ "$(git rev-parse --show-toplevel)" = "$(pwd)" ] || { echo "ERROR: ejecútalo desde la RAÍZ del repo: $(git rev-parse --show-toplevel)"; exit 1; }
[ -d openspec ] || { echo "ERROR: no veo la carpeta openspec/ — ¿es este el repo del tutorial?"; exit 1; }

CAMBIOS=0
mkdir -p .claude/hooks

# Escribe un hook solo si es nuevo o cambió (mantiene idempotencia).
instalar_hook() { # $1=ruta destino  (contenido por stdin)
  local destino="$1"
  cat > "$destino.nuevo"
  if [ ! -f "$destino" ] || ! cmp -s "$destino.nuevo" "$destino"; then
    mv "$destino.nuevo" "$destino"
    chmod +x "$destino"
    echo "==> Hook actualizado: $destino"
    CAMBIOS=1
  else
    rm "$destino.nuevo"
    echo "==> Hook ya al día: $destino"
  fi
}

# ============================================================================
# 1. Hook (UserPromptSubmit): rama git automática en cada /opsx:propose
# ============================================================================
instalar_hook .claude/hooks/rama-propose.sh << 'EOF'
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

# ============================================================================
# 2. Hook (UserPromptSubmit): marcar que hay un /opsx:archive en curso
# ============================================================================
# El commit no puede hacerse al recibir el prompt (el archive aún no movió
# los archivos): aquí solo se deja una marca con el id del cambio, y el
# hook de Stop (paso 3) hace el commit cuando Claude termina.
instalar_hook .claude/hooks/marcar-archive.sh << 'EOF'
#!/usr/bin/env bash
# Hook UserPromptSubmit: marca que se pidió /opsx:archive para que el hook
# de Stop haga el commit al terminar.
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

# ============================================================================
# 3. Hook (Stop): commit automático cuando el archive terminó
# ============================================================================
instalar_hook .claude/hooks/commit-archive.sh << 'EOF'
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

# ============================================================================
# 4. .gitignore: la marca temporal no se versiona
# ============================================================================
if ! grep -qxF '.claude/.archive-pendiente' .gitignore 2>/dev/null; then
  echo '.claude/.archive-pendiente' >> .gitignore
  echo "==> .gitignore: agregado .claude/.archive-pendiente"
  CAMBIOS=1
else
  echo "==> .gitignore ya al día"
fi

# ============================================================================
# 5. Registrar los hooks en .claude/settings.json (merge, no sobrescritura)
# ============================================================================
SETTINGS=.claude/settings.json
export SETTINGS
RESULTADO=$(bun -e '
const fs = require("fs");
const ruta = process.env.SETTINGS;

// evento → comandos que deben estar registrados
const requeridos = {
  UserPromptSubmit: [
    "bash .claude/hooks/rama-propose.sh",
    "bash .claude/hooks/marcar-archive.sh",
  ],
  Stop: [
    "bash .claude/hooks/commit-archive.sh",
  ],
};

let cfg = {};
if (fs.existsSync(ruta)) {
  try { cfg = JSON.parse(fs.readFileSync(ruta, "utf8")); }
  catch { console.log("ERROR: settings.json existe pero no es JSON válido; corrígelo a mano"); process.exit(1); }
}

cfg.hooks ??= {};
let agregados = 0;

for (const [evento, comandos] of Object.entries(requeridos)) {
  cfg.hooks[evento] ??= [];
  for (const comando of comandos) {
    const existe = cfg.hooks[evento].some(grupo =>
      (grupo.hooks ?? []).some(h => h.command === comando)
    );
    if (!existe) {
      cfg.hooks[evento].push({ hooks: [{ type: "command", command: comando }] });
      agregados++;
    }
  }
}

if (agregados > 0) {
  fs.writeFileSync(ruta, JSON.stringify(cfg, null, 2) + "\n");
  console.log("actualizado:" + agregados);
} else {
  console.log("sin-cambios");
}
')

case "$RESULTADO" in
  actualizado:*) echo "==> Hooks registrados en $SETTINGS (${RESULTADO#actualizado:} nuevos)"; CAMBIOS=1;;
  sin-cambios)   echo "==> $SETTINGS ya tenía todos los hooks registrados";;
  *)             echo "$RESULTADO"; exit 1;;
esac

# ============================================================================
# Commit de la actualización
# ============================================================================
if [ "$CAMBIOS" -eq 1 ]; then
  git add .claude/hooks .claude/settings.json .gitignore
  git commit -q -m "Hooks: rama automática en propose y commit automático al archivar"
  echo ""
  echo "==> Commit creado. Si el repo ya está en GitHub: git push"
else
  echo ""
  echo "==> Nada que actualizar: el repo ya está al día."
fi

echo ""
echo "Prueba rápida sin Claude Code (desde la raíz del repo):"
echo "  printf '%s' '{\"prompt\":\"/opsx:propose prueba\"}' | bash .claude/hooks/rama-propose.sh"
echo "  touch archivo-de-prueba && printf '%s' '{\"prompt\":\"/opsx:archive prueba\"}' | bash .claude/hooks/marcar-archive.sh"
echo "  echo '{}' | bash .claude/hooks/commit-archive.sh && git log -1 --oneline"