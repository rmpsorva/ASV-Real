#!/usr/bin/env bash
# ==========================================================
# 🌐 ASV-REAL UNIVERSAL SETUP
# Funciona en: Codespaces / Local / Docker / GitHub Pages
# Autor: MindLoop AI Future
# ==========================================================

echo "🚀 Iniciando configuración del sistema ASV-REAL..."

# --- VARIABLES GLOBALES ---
export OLLAMA_HOST=${OLLAMA_HOST:-"http://localhost:11434"}
export FRONTEND_ORIGIN=${FRONTEND_ORIGIN:-"http://localhost:3000"}
export PORT=${PORT:-5000}
export MODE=${MODE:-dev}
export MODEL_NAME=${MODEL_NAME:-"llama2"}

# --- ARCHIVOS NECESARIOS ---
mkdir -p frontend backend

# =========================
# 🧠 BACKEND - Python Ollama
# =========================
cat > backend/github_ollama_connector.py <<'PYCODE'
#!/usr/bin/env python3
import os, json, time, requests
from flask import Flask, request, jsonify
app = Flask(__name__)

OLLAMA_API = os.getenv("OLLAMA_HOST", "http://localhost:11434")
MODEL = os.getenv("MODEL_NAME", "llama2")

@app.route("/api", methods=["POST"])
def ollama_generate():
    try:
        prompt = request.json.get("prompt", "")
        payload = {"model": MODEL, "prompt": prompt}
        r = requests.post(f"{OLLAMA_API}/api/generate", json=payload)
        return jsonify(r.json())
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    print(f"✅ Servidor backend ASV-REAL iniciado en puerto {os.getenv('PORT',5000)}")
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)))
PYCODE

# =========================
# 🌐 PROXY (Node.js Express)
# =========================
cat > backend/proxy_server.js <<'JSCODE'
import express from "express";
import cors from "cors";
import fetch from "node-fetch";

const app = express();
const PORT = process.env.PORT || 5000;
const OLLAMA_API = process.env.OLLAMA_HOST || "http://localhost:11434";

app.use(cors());
app.use(express.json());

app.post("/api", async (req, res) => {
  try {
    const response = await fetch(`${OLLAMA_API}/api/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(req.body),
    });
    const data = await response.json();
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => console.log(`✅ Proxy activo en puerto ${PORT}`));
JSCODE

# =========================
# 💻 FRONTEND - HTML + JS
# =========================
cat > frontend/index.html <<'HTMLCODE'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ASV-A Platform 💡 - Real AI</title>
  <style>
    body { font-family: Arial, sans-serif; background: #101820; color: #fff; text-align: center; }
    textarea { width: 90%; height: 100px; margin-top: 20px; font-size: 16px; }
    button { background: #00ff99; color: #000; border: none; padding: 10px 20px; margin-top: 10px; cursor: pointer; }
    #respuesta { margin-top: 20px; font-size: 18px; }
  </style>
</head>
<body>
  <h1>ASV-A 🤖 Real Cognitive System</h1>
  <textarea id="prompt" placeholder="Escribe tu pregunta..."></textarea><br>
  <button onclick="enviarPrompt()">Enviar</button>
  <div id="respuesta"></div>
  <script>
    const API_URL = (window.location.hostname.includes('github.io'))
      ? 'https://asv-proxy.vercel.app/api'
      : 'http://localhost:5000/api';

    async function enviarPrompt() {
      const prompt = document.getElementById('prompt').value;
      document.getElementById('respuesta').innerText = '⏳ Generando...';
      const res = await fetch(API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model: 'llama2', prompt })
      });
      const data = await res.json();
      document.getElementById('respuesta').innerText = data.response || JSON.stringify(data);
    }
  </script>
</body>
</html>
HTMLCODE

# =========================
# 🐋 DOCKER COMPOSE (opcional)
# =========================
cat > docker-compose.yml <<'YAML'
version: "3.9"
services:
  backend:
    build: .
    environment:
      - OLLAMA_HOST=http://ollama:11434
      - PORT=5000
    ports:
      - "5000:5000"
    depends_on:
      - ollama
  ollama:
    image: ollama/ollama
    ports:
      - "11434:11434"
  frontend:
    image: nginx:alpine
    ports:
      - "3000:80"
    volumes:
      - ./frontend:/usr/share/nginx/html
YAML

# =========================
# 🚀 ARRANQUE AUTOMÁTICO
# =========================
echo "📦 Instalando dependencias..."
pip install flask requests --quiet
npm install express node-fetch cors --prefix backend --silent

echo "✅ Configuración lista."
echo ""
echo "=== MODOS DE EJECUCIÓN ==="
echo "1️⃣ Backend Python:     python3 backend/github_ollama_connector.py"
echo "2️⃣ Proxy Node.js:      node backend/proxy_server.js"
echo "3️⃣ Frontend local:     abrir frontend/index.html"
echo "4️⃣ Docker completo:    docker compose up"
echo ""
echo "🧠 Conectado a modelo: $MODEL_NAME en $OLLAMA_HOST"
