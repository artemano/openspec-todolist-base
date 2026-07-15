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
