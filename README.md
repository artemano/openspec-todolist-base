# Repo base para **OpenSpec en Acción**

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
