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
