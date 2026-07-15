#!/usr/bin/env bash
# ============================================================================
# actualizar-repo-base.sh
# Aplica actualizaciones incrementales a un repo base YA creado y commiteado.
# Se ejecuta DESDE la raíz del repo:  bash actualizar-repo-base.sh
#
# Esta versión agrega:
#   - Hook UserPromptSubmit: rama git automática (propose/<id>-<timestamp>)
#     en cada /opsx:propose.
#   - Registro del hook en .claude/settings.json (merge no destructivo:
#     respeta hooks/config existentes y es idempotente).
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

# ============================================================================
# 1. Hook: rama git automática en cada /opsx:propose
# ============================================================================
mkdir -p .claude/hooks

HOOK=.claude/hooks/rama-propose.sh
cat > "$HOOK.nuevo" << 'EOF'
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

if [ ! -f "$HOOK" ] || ! cmp -s "$HOOK.nuevo" "$HOOK"; then
  mv "$HOOK.nuevo" "$HOOK"
  chmod +x "$HOOK"
  echo "==> Hook actualizado: $HOOK"
  CAMBIOS=1
else
  rm "$HOOK.nuevo"
  echo "==> Hook ya al día: $HOOK"
fi

# ============================================================================
# 2. Registrar el hook en .claude/settings.json (merge, no sobrescritura)
# ============================================================================
SETTINGS=.claude/settings.json
export SETTINGS
RESULTADO=$(bun -e '
const fs = require("fs");
const ruta = process.env.SETTINGS;
const comando = "bash .claude/hooks/rama-propose.sh";

let cfg = {};
if (fs.existsSync(ruta)) {
  try { cfg = JSON.parse(fs.readFileSync(ruta, "utf8")); }
  catch { console.log("ERROR: settings.json existe pero no es JSON válido; corrígelo a mano"); process.exit(1); }
}

cfg.hooks ??= {};
cfg.hooks.UserPromptSubmit ??= [];

const yaExiste = cfg.hooks.UserPromptSubmit.some(grupo =>
  (grupo.hooks ?? []).some(h => h.command === comando)
);

if (yaExiste) {
  console.log("sin-cambios");
} else {
  cfg.hooks.UserPromptSubmit.push({ hooks: [{ type: "command", command: comando }] });
  fs.writeFileSync(ruta, JSON.stringify(cfg, null, 2) + "\n");
  console.log("actualizado");
}
')

case "$RESULTADO" in
  actualizado)  echo "==> Hook registrado en $SETTINGS"; CAMBIOS=1;;
  sin-cambios)  echo "==> $SETTINGS ya tenía el hook registrado";;
  *)            echo "$RESULTADO"; exit 1;;
esac

# ============================================================================
# Commit de la actualización
# ============================================================================
if [ "$CAMBIOS" -eq 1 ]; then
  git add .claude/hooks/rama-propose.sh "$SETTINGS"
  git commit -q -m "Hook: rama git automática (propose/<id>-<timestamp>) en cada /opsx:propose"
  echo ""
  echo "==> Commit creado. Si el repo ya está en GitHub: git push"
else
  echo ""
  echo "==> Nada que actualizar: el repo ya está al día."
fi

echo ""
echo "Prueba rápida del hook (sin Claude Code):"
echo "  printf '%s' '{\"prompt\":\"/opsx:propose prueba\"}' | bash .claude/hooks/rama-propose.sh"
echo "  git branch   # debe aparecer propose/prueba-<timestamp>"
