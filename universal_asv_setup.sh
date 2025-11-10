#!/bin/bash
# ==========================================================
# 🌐 universal_asv_setup.sh - GESTOR COMPLETO Y UNIFICADO
# Instala Ollama, inicia el servidor, configura el backend/frontend Flask/Node.js.
# ==========================================================

set -e

# --- CONFIGURACIÓN GLOBAL ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
OLLAMA_PORT="11434"
LOG_FILE="/tmp/ollama.log"
PID_FILE="/tmp/ollama.pid"

# Variables de entorno universales (se usan en el código Python/Node.js)
export OLLAMA_HOST="http://localhost:${OLLAMA_PORT}"
export FRONTEND_ORIGIN=${FRONTEND_ORIGIN:-"http://localhost:3000"}
export PORT=${PORT:-5000}
export MODE=${MODE:-dev}
export MODEL_NAME=${MODEL_NAME:-"phi3:mini"} # Cambiado a phi3:mini para ser consistente con el proyecto anterior

# --- UTILIDADES DE IMPRESIÓN ---
print_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }

# ====================================================
# A. GESTIÓN DE OLLAMA (CÓDIGO ORIGINAL MEJORADO)
# ====================================================

install_ollama() {
    if command -v ollama >/dev/null 2>&1; then
        print_success "Ollama ya está instalado."
        return
    fi
    print_info "Instalando Ollama..."
    if curl -fsSL https://ollama.com/install.sh | sh; then
        print_success "Ollama instalado correctamente."
    else
        print_error "Falló la instalación de Ollama."
        exit 1
    fi
}

start_ollama_server() {
    if pgrep -x "ollama" >/dev/null 2>&1; then
        print_success "Servidor Ollama ya está en ejecución."
        return
    fi
    print_info "Iniciando servidor Ollama..."
    nohup ollama serve >"$LOG_FILE" 2>&1 &
    echo $! >"$PID_FILE"
    sleep 2
    print_success "Servidor iniciado (PID: $(cat "$PID_FILE"))"
}

wait_for_server() {
    print_info "Esperando que la API responda..."
    for i in {1..30}; do
        if curl -s "http://localhost:${OLLAMA_PORT}/api/tags" >/dev/null 2>&1; then
            print_success "Servidor Ollama listo."
            return
        fi
        sleep 2
    done
    print_error "Timeout esperando al servidor Ollama."
    exit 1
}

download_model() {
    # Usamos el MODEL_NAME de la variable de entorno, que es phi3:mini por defecto
    if ollama list | grep -q "$MODEL_NAME"; then
        print_success "Modelo $MODEL_NAME ya descargado."
        return
    fi
    print_info "Descargando modelo $MODEL_NAME (puede tardar)..."
    if ollama pull "$MODEL_NAME"; then
        print_success "Modelo $MODEL_NAME descargado con éxito."
    else
        print_error "Error al descargar el modelo $MODEL_NAME."
        exit 1
    fi
}

# --- Control de argumentos (funcionalidad de --stop y --status) ---
control_ollama() {
    case "$1" in
        --stop|-s)
            if [ -f "$PID_FILE" ]; then
                kill "$(cat "$PID_FILE")" 2>/dev/null && rm -f "$PID_FILE"
                print_success "Servidor Ollama detenido."
            else
                print_info "No hay servidor Ollama ejecutándose (no se encontró PID)."
            fi
            exit 0
            ;;
        --status|-t)
            if pgrep -x "ollama" >/dev/null 2>&1; then
                print_success "Servidor Ollama en ejecución."
            else
                print_error "Servidor Ollama no está activo."
            fi
            exit 0
            ;;
    esac
}

# ====================================================
# B. CONFIGURACIÓN DE LA ARQUITECTURA (CÓDIGO NUEVO)
# ====================================================

setup_architecture() {
    echo "🚀 Iniciando configuración de la arquitectura ASV-REAL..."
    
    # --- ARCHIVOS NECESARIOS ---
    mkdir -p frontend backend
    
    # =========================
    # 🧠 BACKEND - Python Flask
    # =========================
    print_info "Creando backend/github_ollama_connector.py (Flask)..."
    cat > backend/github_ollama_connector.py <<'PYCODE'
#!/usr/bin/env python3
import os, json, requests
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
# Permitir CORS para que el frontend pueda conectarse
CORS(app) 

# Leer variables de entorno
OLLAMA_API = os.getenv("OLLAMA_HOST", "http://localhost:11434")
MODEL = os.getenv("MODEL_NAME", "llama2")
TIMEOUT = int(os.getenv("OLLAMA_TIMEOUT", 180)) # Usar TIMEOUT desde env

@app.route("/api", methods=["POST"])
def ollama_generate():
    try:
        data = request.json
        prompt = data.get("prompt", "")
        
        # Validar la conexión del frontend
        if not prompt:
            return jsonify({"error": "No se recibió un prompt válido."}), 400
            
        payload = {
            "model": data.get("model", MODEL), # Permite que el frontend especifique el modelo
            "prompt": prompt,
            "stream": False
        }
        
        # Llamada a la API de Ollama
        r = requests.post(f"{OLLAMA_API}/api/generate", json=payload, timeout=TIMEOUT)
        r.raise_for_status() # Lanza HTTPError si el código no es 2xx
        
        # Devolver la respuesta de Ollama
        return jsonify(r.json()), 200
        
    except requests.exceptions.Timeout:
        return jsonify({"error": "Timeout al conectar con Ollama. El modelo está tardando."}), 504
    except requests.exceptions.RequestException as e:
        return jsonify({"error": f"Fallo en la conexión al backend de Ollama: {e}"}), 503
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    print(f"✅ Servidor backend ASV-REAL (Flask) iniciado en puerto {os.getenv('PORT',5000)}")
    # La aplicación se ejecuta en 0.0.0.0 para ser accesible en Codespaces
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)))
PYCODE
    print_success "Backend Flask creado."

    # --- Proxy Node.js (se omite para no duplicar funcionalidad, se recomienda usar Flask) ---
    # Si fuera necesario, el código Node.js iría aquí.

    # =========================
    # 💻 FRONTEND - HTML + JS
    # =========================
    print_info "Creando frontend/index.html..."
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
    #respuesta { margin-top: 20px; padding: 10px; border: 1px solid #00ff99; text-align: left; white-space: pre-wrap; }
  </style>
</head>
<body>
  <h1>ASV-A 🤖 Real Cognitive System</h1>
  <textarea id="prompt" placeholder="Escribe tu pregunta..."></textarea><br>
  <button id="sendBtn" onclick="enviarPrompt()">Enviar</button>
  <div id="respuesta">Esperando Oráculo...</div>
  <script>
    // Usa el puerto 5000 donde corre el backend Flask. 
    const API_URL = 'http://localhost:5000/api';
    const MODEL = 'phi3:mini'; // Usa el modelo descargado por el script Bash

    async function enviarPrompt() {
      const prompt = document.getElementById('prompt').value;
      const btn = document.getElementById('sendBtn');
      if (!prompt) return;

      document.getElementById('respuesta').innerText = '⏳ Generando...';
      btn.disabled = true;

      try {
        const res = await fetch(API_URL, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ model: MODEL, prompt })
        });

        if (!res.ok) {
          const errorData = await res.json();
          throw new Error(`Error: ${errorData.error || res.statusText}`);
        }
        
        const data = await res.json();
        
        // Muestra la respuesta principal del LLM
        document.getElementById('respuesta').innerText = data.response || "Error: Respuesta vacía del modelo.";
        
      } catch (e) {
        document.getElementById('respuesta').innerText = `❌ ERROR DE CONEXIÓN: ${e.message}. Asegúrate que Flask esté corriendo en puerto 5000.`;
      } finally {
        btn.disabled = false;
      }
    }
  </script>
</body>
</html>
HTMLCODE
    print_success "Frontend HTML/JS creado."

    # =========================
    # 🐋 DOCKER COMPOSE (opcional)
    # =========================
    print_info "Creando docker-compose.yml..."
    cat > docker-compose.yml <<'YAML'
version: "3.9"
services:
  backend:
    build: .
    context: .
    command: python3 backend/github_ollama_connector.py
    environment:
      - OLLAMA_HOST=http://ollama:11434
      - PORT=5000
      - MODEL_NAME=phi3:mini
    ports:
      - "5000:5000"
    depends_on:
      - ollama
    # Instalar Flask y requests dentro del contenedor
    volumes:
      - ./backend:/app/backend
    working_dir: /app
  
  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama # Persistencia de modelos
  
  frontend:
    image: nginx:alpine
    ports:
      - "3000:80"
    volumes:
      - ./frontend:/usr/share/nginx/html
      
volumes:
  ollama_data:
YAML
    print_success "Docker Compose creado."
}

# ====================================================
# C. EJECUCIÓN DEL SETUP
# ====================================================

# 1. Controlar Ollama si se usa --stop o --status
control_ollama "$1"

# 2. Instalación de dependencias externas (requeridas para Flask)
install_dependencies() {
    print_info "📦 Instalando dependencias externas (Python/Node)..."
    # flask y requests para el backend Python
    pip install flask requests flask-cors --quiet
    
    # Se omiten las dependencias de Node.js Express ya que el backend Flask es la opción principal.
    # Si se quisiera usar Node.js: npm install express node-fetch cors --prefix backend --silent
    print_success "Dependencias instaladas."
}

# --- FUNCIÓN PRINCIPAL DE LANZAMIENTO ---
main_launch() {
    # 1. Configuración de la IA
    install_ollama
    start_ollama_server
    wait_for_server
    download_model
    
    # 2. Configuración de la Arquitectura
    setup_architecture
    install_dependencies
    
    # 3. Lanzamiento de la Aplicación
    echo ""
    print_success "🎉 CONFIGURACIÓN COMPLETA - INICIANDO SISTEMA ASV-REAL!"
    echo "--------------------------------------------------------"
    echo "🚀 INSTRUCCIONES DE LANZAMIENTO:"
    echo "1️⃣ Lanzar Frontend (Visualización):  Abrir frontend/index.html en Codespaces Preview."
    echo "2️⃣ Lanzar Backend (Servicio Flask):  python3 backend/github_ollama_connector.py"
    echo "3️⃣ Lanzar Todo (Docker):           docker compose up"
    echo ""
    echo "🌐 El frontend intentará conectarse a http://localhost:5000/api"
    echo "--------------------------------------------------------"
}

# Ejecutar el lanzamiento
main_launch

exit 0
