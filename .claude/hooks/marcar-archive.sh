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
