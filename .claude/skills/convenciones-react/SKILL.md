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
