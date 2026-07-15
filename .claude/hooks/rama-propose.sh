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
