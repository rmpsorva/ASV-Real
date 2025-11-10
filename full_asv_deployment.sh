#!/bin/bash
# ===============================================================
# 🌐 FULL ASV-A COGNITIVE DEPLOYMENT SCRIPT
# Version 1.0 - Crea toda la arquitectura (Bash, Python, HTML/CSS/JS)
# en un solo archivo ejecutable.
# ===============================================================

set -euo pipefail

# --- CONFIGURACIÓN GLOBAL ---
DEFAULT_MODEL="phi3:mini"
PORT="11434"
LOG_FILE="/tmp/asva_ollama.log"
PID_FILE="/tmp/asva_ollama.pid"
FLASK_PORT="5000"

export OLLAMA_HOST="http://localhost:${PORT}"
export OLLAMA_MODEL="${OLLAMA_MODEL:-$DEFAULT_MODEL}"
export OLLAMA_TIMEOUT="${OLLAMA_TIMEOUT:-120}"
export FLASK_PORT="${FLASK_PORT}" # Exportar puerto de Flask

# --- COLORES ASV-A ---
CYBER_BLUE='\033[0;36m'
CYBER_GREEN='\033[1;32m' 
CYBER_ORANGE='\033[0;33m'
CYBER_RED='\033[0;31m'
NC='\033[0m'

asva_info()  { echo -e "${CYBER_BLUE}🔮 $1${NC}"; }
asva_ok()    { echo -e "${CYBER_GREEN}⚡ $1${NC}"; }
asva_warn()  { echo -e "${CYBER_ORANGE}⚠️  $1${NC}"; }
asva_err()   { echo -e "${CYBER_RED}💥 $1${NC}" >&2; exit 1; }

# --- FUNCIONES DE GESTIÓN (IDÉNTICAS AL GESTOR PERFECTO) ---

server_running() {
    [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" >/dev/null 2>&1
}

install_ollama() {
    if command -v ollama >/dev/null 2>&1; then
        asva_ok "Ollama ya instalado."
        return 0
    fi
    asva_info "Instalando Ollama Cognitive Engine..."
    if curl -fsSL https://ollama.com/install.sh | sh >>"$LOG_FILE" 2>&1; then
        asva_ok "✅ Motor cognitivo instalado"
        return 0
    else
        asva_err "Fallo en instalación cognitiva"
    fi
}

start_server() {
    if server_running; then
        local pid=$(cat "$PID_FILE")
        asva_ok "Servidor Ollama activo (PID $pid)"
        return 0
    fi
    asva_info "Iniciando motor cognitivo ASV-A..."
    nohup ollama serve >>"$LOG_FILE" 2>&1 &
    local pid=$!
    echo "$pid" > "$PID_FILE"
    
    for i in {1..15}; do
        if ps -p "$pid" >/dev/null 2>&1 && curl -s "http://localhost:${PORT}/api/tags" >/dev/null 2>&1; then
            asva_ok "Motor cognitivo operativo (PID $pid)"
            return 0
        fi
        sleep 2
    done
    asva_err "Timeout en arranque cognitivo"
}

pull_model() {
    local model="${1:-$OLLAMA_MODEL}"
    asva_info "Descargando modelo cognitivo: $model"
    ollama pull "$model" 2>&1 | tee -a "$LOG_FILE" || asva_err "Fallo en descarga cognitiva"
    asva_ok "Modelo cognitivo '$model' cargado"
}

stop_server() {
    if ! server_running; then
        asva_warn "Motor cognitivo ya detenido."
        return 0
    fi
    local pid=$(cat "$PID_FILE")
    asva_info "Deteniendo motor cognitivo (PID $pid)..."
    kill "$pid" >/dev/null 2>&1 || true
    sleep 1
    rm -f "$PID_FILE"
    asva_ok "Motor cognitivo detenido correctamente."
}

# --- FUNCIONES DE ARQUITECTURA (Crea y Lanza todos los archivos) ---

create_architecture() {
    asva_info "Creando estructura de proyecto y archivos..."
    
    # Crea directorios
    mkdir -p frontend backend || asva_err "No se pudo crear la estructura de directorios."
    
    # 1. ARCHIVO DE BACKEND (PYTHON/FLASK)
    cat > backend/asva_flask_backend.py <<PYCODE
import os
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS
# La librería requests y flask-cors deben estar instaladas (instaladas abajo en Bash)

app = Flask(__name__)
CORS(app) 

OLLAMA_API = os.getenv("OLLAMA_HOST")
MODEL_NAME = os.getenv("OLLAMA_MODEL")
PORT = int(os.getenv("FLASK_PORT", 5000))
TIMEOUT = int(os.getenv("OLLAMA_TIMEOUT", 120))

@app.route("/api/query", methods=["POST"])
def ollama_generate():
    try:
        prompt = request.json.get("prompt", "")
        if not prompt:
            return jsonify({"error": "No se recibió un prompt válido."}), 400
            
        payload = {"model": MODEL_NAME, "prompt": prompt, "stream": False}
        
        r = requests.post(f"{OLLAMA_API}/api/generate", json=payload, timeout=TIMEOUT)
        r.raise_for_status()
        
        return jsonify(r.json()), 200
        
    except requests.exceptions.RequestException as e:
        return jsonify({"error": f"Fallo de conexión a Ollama (Código 503): {str(e)}"}), 503
    except Exception as e:
        return jsonify({"error": f"Error interno del servidor Flask: {str(e)}"}), 500

if __name__ == "__main__":
    print(f"✅ Servidor backend ASV-A activo en puerto {PORT}")
    app.run(host="0.0.0.0", port=PORT)
PYCODE

    # 2. ARCHIVO DE FRONTEND (JAVASCRIPT)
    cat > frontend/app.js <<JSCODE
// app.js - Lógica de conexión para la interfaz ASV-A
class AurionAI {
    constructor() {
        // La URL de Flask (puerto 5000) es nuestro único punto de contacto
        this.API_ENDPOINT = "http://localhost:${FLASK_PORT}/api/query"; 
        this.isGenerating = false;
        document.addEventListener('DOMContentLoaded', () => this.init());
    }

    init() {
        console.log('🤖 ASV-A AURION COVRA AI Inicializado. Escuchando Flask en :${FLASK_PORT}');
        this.bindEvents();
    }

    bindEvents() {
        const sendBtn = document.getElementById('send-button');
        const input = document.getElementById('user-input');
        const clearBtn = document.getElementById('clear-chat');

        if (sendBtn) sendBtn.addEventListener('click', () => this.handleSend());
        if (clearBtn) clearBtn.addEventListener('click', () => this.clearChat());
        if (input) input.addEventListener('keypress', (e) => {
            if (e.key === 'Enter' && !this.isGenerating) this.handleSend();
        });
    }

    async handleSend() {
        const input = document.getElementById('user-input');
        const message = input ? input.value.trim() : '';

        if (!message || this.isGenerating) return;

        if (input) input.value = '';
        this.addMessageToChat('user', message);
        
        this.showTypingIndicator();
        this.isGenerating = true;
        this.updateSendButton(true);

        try {
            const response = await this.generateAIResponse(message);
            this.addMessageToChat('assistant', response);
        } catch (error) {
            this.addMessageToChat('error', this.formatError(error));
        } finally {
            this.removeTypingIndicator();
            this.isGenerating = false;
            this.updateSendButton(false);
        }
    }

    async generateAIResponse(prompt) {
        const response = await fetch(this.API_ENDPOINT, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ prompt: prompt })
        });

        const data = await response.json();
        
        if (!response.ok) {
            // El error viene del servidor Flask o de un fallo de conexión
            throw new Error(data.error || 'Fallo de red o del backend.');
        }

        return data.response ? data.response.trim() : 'Error: Respuesta vacía del modelo.';
    }

    addMessageToChat(role, content) {
        const chatContainer = document.getElementById('chat-container');
        if (!chatContainer) return;

        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${role}-message`;
        messageDiv.innerHTML = `<div class="message-content">${this.formatMessage(content)}</div>`;

        chatContainer.appendChild(messageDiv);
        chatContainer.scrollTop = chatContainer.scrollHeight; // Scroll
    }

    formatMessage(content) {
        if (!content) return '';
        return content.replace(/\n/g, '<br>');
    }

    formatError(error) {
        const message = error.message || 'Error desconocido';
        if (message.includes('Failed to fetch') || message.includes('Fallo de conexión')) {
            return "🔌 Error de Conexión: Asegúrate de que el servidor Flask esté corriendo en puerto 5000.";
        }
        return `💥 Error: ${message}`;
    }

    showTypingIndicator() {
        this.removeTypingIndicator();
        const chatContainer = document.getElementById('chat-container');
        const typingDiv = document.createElement('div');
        typingDiv.id = 'typing-indicator';
        typingDiv.className = 'message assistant-message typing';
        typingDiv.innerHTML = '<div class="message-content"><div class="typing-dots"><span></span><span></span><span></span></div></div>';
        chatContainer.appendChild(typingDiv);
    }
    
    removeTypingIndicator() {
        const typingIndicator = document.getElementById('typing-indicator');
        if (typingIndicator) typingIndicator.remove();
    }
    
    updateSendButton(disabled) {
        const sendBtn = document.getElementById('send-button');
        if (sendBtn) sendBtn.disabled = disabled;
    }
    
    clearChat() {
        const chatContainer = document.getElementById('chat-container');
        if (chatContainer) chatContainer.innerHTML = '';
    }
}
window.aurionAI = new AurionAI();
JSCODE
    
    # 3. ARCHIVO DE FRONTEND (HTML)
    cat > frontend/index.html <<HTMLCODE
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🧠 ASV-A AURION COVRA AI - Cognitive Operating System</title>
    
    <script src="https://cdn.ethers.io/lib/ethers-5.2.umd.min.js"></script> 
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700&family=Share+Tech+Mono&display=swap" rel="stylesheet">
    
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="system-container">
        <div class="header-display">
            <h1 class="header-title">ASV-A AURION COVRA AI - Cognitive Operating System</h1>
            <p class="header-subtitle">Oráculo de Realidad Web3 | <span class="active-status">SISTEMA COGNITIVO ACTIVO</span></p>
        </div>

        <div class="main-grid">
            <div class="panel center-panel">
                <div class="avatar-display">
                    <div class="avatar-face" id="avatarFace"></div>
                    <div class="avatar-text">ORÁCULO ASV-A</div>
                </div>
                
                <div class="interaction-zone">
                    <div id="status-indicator" class="notification-area status info">Cargando módulos...</div>
                    <div class="query-input-group">
                        <input type="text" id="user-input" class="query-input" placeholder="Escribe tu consulta..." required>
                        <button id="send-button" class="action-button primary-button">SEND</button>
                    </div>
                </div>
            </div>
            </div>

        <div class="panel cosmic-log-panel">
            <h3 class="section-title">LOG CÓSMICO (CONVERSACIÓN)</h3>
            <div id="chat-container" class="log-display">
                </div>
            <button id="clear-chat" class="action-button secondary-button" style="margin-top: 10px;">LIMPIAR LOG</button>
        </div>
    </div>

    <script src="frontend/app.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</body>
</html>
HTMLCODE

    # 4. ARCHIVO DE FRONTEND (CSS - El estilo que logramos)
    cat > frontend/style.css <<CSSCODE
/* ===== ESTILOS COGNITIVOS ASV-A AURION: CHAT Y CYBERPUNK ===== */
.query-input {
    background: rgba(0, 10, 20, 0.95);
    border: 1px solid #00f0ff;
    color: #00f0ff;
}
.message {
    margin: 8px 0;
    padding: 10px 14px;
    border-radius: 10px;
    max-width: 85%;
}
.user-message {
    background: rgba(0, 150, 255, 0.2); 
    color: #66f0ff;
    margin-left: auto;
    border-color: #00f0ff;
}
.assistant-message {
    background: rgba(0, 255, 136, 0.1); 
    color: #00ff88;
    margin-right: auto;
    border-color: #00ff88;
}
.error-message {
    background: rgba(255, 68, 68, 0.15);
    color: #ff4444;
    border-color: #ff4444;
}
.typing-dots {
    display: flex;
    gap: 6px;
}
.typing-dots span {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: #00ff88;
    animation: bounce 1s ease-in-out infinite both;
}
@keyframes bounce { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-4px); } }
/* Añade aquí más de tus estilos personalizados */
CSSCODE
    
    asva_ok "Estructura de archivos creada con éxito."
}

# --- FUNCIÓN PRINCIPAL DE DESPLIEGUE ---
full_deployment() {
    # 1. Crear todos los archivos
    create_architecture
    
    # 2. Instalar dependencias necesarias
    asva_info "Instalando dependencias de Python (Flask, CORS, Requests)..."
    pip install flask flask-cors requests || asva_err "Fallo al instalar dependencias de Python."
    asva_ok "Dependencias instaladas."

    # 3. Lanzamiento de Ollama (IA Backend)
    install_ollama
    start_server
    pull_model "$OLLAMA_MODEL"
    wait_ready

    # 4. Instrucciones finales para el usuario
    asva_ok "🎉 DEPLIEGUE COMPLETO!"
    echo "--------------------------------------------------------"
    echo "EL SISTEMA ASV-A ESTÁ LISTO."
    echo "🌐 Ollama está ACTIVO en http://localhost:$PORT"
    echo "--------------------------------------------------------"
    echo "👉 PASO 1: Abra una NUEVA terminal en Codespaces."
    echo "👉 PASO 2: Ejecute el servidor web FLASK (el puente):"
    echo "   python3 backend/asva_flask_backend.py"
    echo "👉 PASO 3: Abra la vista previa de frontend/index.html en su navegador."
    echo "--------------------------------------------------------"
}

# --- EJECUCIÓN DEL DEPLOYMENT ---
full_deployment
