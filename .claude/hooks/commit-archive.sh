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
