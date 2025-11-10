#!/bin/bash
# ===============================================================
# 🌐 ASV-A AUTONOMOUS DEPLOYMENT - Despliegue Autónomo Completo
# Version 3.0 - Lanza TODO automáticamente: Ollama + Flask + Frontend
# ===============================================================

set -euo pipefail

# --- CONFIGURACIÓN GLOBAL ---
DEFAULT_MODEL="phi3:mini"
OLLAMA_PORT="11434"
FLASK_PORT="5000"
LOG_FILE="/tmp/asva_autonomous.log"
OLLAMA_PID_FILE="/tmp/asva_ollama.pid"
FLASK_PID_FILE="/tmp/asva_flask.pid"

export OLLAMA_HOST="http://localhost:${OLLAMA_PORT}"
export OLLAMA_MODEL="${OLLAMA_MODEL:-$DEFAULT_MODEL}"
export FLASK_ENV="production"

# --- COLORES ASV-A ---
CYBER_BLUE='\033[0;36m'
CYBER_GREEN='\033[1;32m' 
CYBER_ORANGE='\033[0;33m'
CYBER_RED='\033[0;31m'
NC='\033[0m'

asva_info()  { echo -e "${CYBER_BLUE}🔮 $1${NC}" | tee -a "$LOG_FILE"; }
asva_ok()    { echo -e "${CYBER_GREEN}⚡ $1${NC}" | tee -a "$LOG_FILE"; }
asva_warn()  { echo -e "${CYBER_ORANGE}⚠️  $1${NC}" | tee -a "$LOG_FILE"; }
asva_err()   { echo -e "${CYBER_RED}💥 $1${NC}" | tee -a "$LOG_FILE"; exit 1; }

# --- VERIFICACIÓN DE PROCESOS ---
process_running() {
    local pid_file="$1"
    local process_name="$2"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" >/dev/null 2>&1; then
            return 0
        else
            rm -f "$pid_file"
        fi
    fi
    
    # Verificar por nombre también
    if pgrep -f "$process_name" >/dev/null; then
        return 0
    fi
    return 1
}

# --- INSTALACIÓN AUTÓNOMA DE OLLAMA ---
install_ollama_autonomous() {
    if command -v ollama >/dev/null 2>&1; then
        asva_ok "Ollama ya instalado: $(ollama --version 2>/dev/null || echo 'unknown')"
        return 0
    fi
    
    asva_info "Instalando Ollama automáticamente..."
    if curl -fsSL https://ollama.com/install.sh | sh >> "$LOG_FILE" 2>&1; then
        asva_ok "✅ Ollama instalado correctamente"
        
        # Esperar a que el comando esté disponible
        for i in {1..10}; do
            if command -v ollama >/dev/null 2>&1; then
                break
            fi
            sleep 1
        done
        return 0
    else
        asva_err "Fallo en la instalación automática de Ollama"
    fi
}

# --- SERVICIO OLLAMA AUTÓNOMO ---
start_ollama_autonomous() {
    if process_running "$OLLAMA_PID_FILE" "ollama serve"; then
        local pid=$(cat "$OLLAMA_PID_FILE" 2>/dev/null || pgrep -f "ollama serve")
        asva_ok "Ollama ya ejecutándose (PID: $pid)"
        return 0
    fi
    
    asva_info "Iniciando servidor Ollama..."
    
    # Detener cualquier instancia previa
    pkill -f "ollama serve" 2>/dev/null || true
    sleep 2
    
    # Iniciar nuevo servidor
    nohup ollama serve >> "$LOG_FILE" 2>&1 &
    local ollama_pid=$!
    echo "$ollama_pid" > "$OLLAMA_PID_FILE"
    
    # Esperar a que esté listo
    asva_info "Esperando que Ollama esté listo..."
    for i in {1..30}; do
        if curl -s "http://localhost:${OLLAMA_PORT}/api/tags" >/dev/null 2>&1; then
            asva_ok "✅ Ollama operativo en puerto $OLLAMA_PORT (PID: $ollama_pid)"
            return 0
        fi
        sleep 2
    done
    
    asva_err "Timeout: Ollama no respondió después de 60 segundos"
}

# --- DESCARGAR MODELO AUTÓNOMO ---
download_model_autonomous() {
    local model="${1:-$OLLAMA_MODEL}"
    
    asva_info "Verificando modelo $model..."
    
    # Verificar si el modelo ya existe
    if ollama list 2>/dev/null | grep -q "$model"; then
        asva_ok "Modelo $model ya está descargado"
        return 0
    fi
    
    asva_info "Descargando modelo $model (esto puede tomar varios minutos)..."
    
    if ollama pull "$model" >> "$LOG_FILE" 2>&1; then
        asva_ok "✅ Modelo $model descargado correctamente"
        return 0
    else
        asva_err "Fallo en la descarga del modelo $model"
    fi
}

# --- BACKEND FLASK AUTÓNOMO ---
create_flask_backend() {
    asva_info "Creando backend Flask autónomo..."
    
    cat > asva_flask_backend.py << 'PYTHONCODE'
import os
import requests
import json
import time
from flask import Flask, request, jsonify
from flask_cors import CORS
import threading
import sys

app = Flask(__name__)
CORS(app)

OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
MODEL_NAME = os.getenv("OLLAMA_MODEL", "phi3:mini")
PORT = int(os.getenv("FLASK_PORT", 5000))

class OllamaManager:
    def __init__(self):
        self.base_url = OLLAMA_HOST
        
    def is_ready(self):
        """Verificar si Ollama está listo"""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=5)
            return response.status_code == 200
        except:
            return False
            
    def generate_response(self, prompt):
        """Generar respuesta usando Ollama"""
        try:
            payload = {
                "model": MODEL_NAME,
                "prompt": prompt,
                "stream": False,
                "options": {
                    "temperature": 0.7,
                    "top_p": 0.9,
                    "top_k": 40
                }
            }
            
            response = requests.post(
                f"{self.base_url}/api/generate",
                json=payload,
                timeout=120
            )
            response.raise_for_status()
            
            result = response.json()
            return result.get("response", "Error: No response from AI")
            
        except requests.exceptions.RequestException as e:
            return f"Error de conexión con Ollama: {str(e)}"
        except Exception as e:
            return f"Error interno: {str(e)}"

# Instancia global del manager
ollama_manager = OllamaManager()

@app.route('/')
def home():
    return jsonify({
        "status": "ASV-A Cognitive System Online",
        "ollama_ready": ollama_manager.is_ready(),
        "model": MODEL_NAME,
        "timestamp": time.time()
    })

@app.route('/api/health')
def health_check():
    """Endpoint de verificación de salud"""
    ollama_status = ollama_manager.is_ready()
    return jsonify({
        "flask": "running",
        "ollama": "ready" if ollama_status else "not_ready",
        "model": MODEL_NAME,
        "port": PORT
    })

@app.route('/api/query', methods=['POST'])
def handle_query():
    """Manejar consultas del frontend"""
    try:
        data = request.get_json()
        prompt = data.get('prompt', '').strip()
        
        if not prompt:
            return jsonify({"error": "Prompt vacío"}), 400
            
        # Verificar que Ollama esté listo
        if not ollama_manager.is_ready():
            return jsonify({"error": "Ollama no está disponible"}), 503
            
        # Generar respuesta
        response_text = ollama_manager.generate_response(prompt)
        
        return jsonify({
            "response": response_text,
            "model": MODEL_NAME,
            "success": True
        })
        
    except Exception as e:
        return jsonify({"error": f"Error procesando consulta: {str(e)}"}), 500

@app.route('/api/models')
def list_models():
    """Listar modelos disponibles"""
    try:
        response = requests.get(f"{OLLAMA_HOST}/api/tags", timeout=10)
        if response.status_code == 200:
            return jsonify(response.json())
        else:
            return jsonify({"error": "No se pudieron obtener los modelos"}), 500
    except Exception as e:
        return jsonify({"error": str(e)}), 503

def start_flask_server():
    """Iniciar servidor Flask"""
    print(f"🚀 ASV-A Flask Backend iniciando en puerto {PORT}...")
    print(f"🔗 Ollama: {OLLAMA_HOST}")
    print(f"🤖 Modelo: {MODEL_NAME}")
    print(f"🌐 Health check: http://localhost:{PORT}/api/health")
    
    # Configurar para producción
    app.run(
        host='0.0.0.0',
        port=PORT,
        debug=False,
        threaded=True
    )

if __name__ == '__main__':
    start_flask_server()
PYTHONCODE

    asva_ok "Backend Flask creado correctamente"
}

# --- FRONTEND AUTÓNOMO ---
create_frontend_autonomous() {
    asva_info "Creando frontend autónomo..."
    
    # Crear directorio frontend
    mkdir -p frontend
    
    # HTML principal
    cat > frontend/index.html << 'HTMLCODE'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🧠 ASV-A AURION COVRA AI - Sistema Autónomo</title>
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700&family=Share+Tech+Mono&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="system-container">
        <div class="header-display">
            <h1 class="header-title">ASV-A AURION COVRA AI - Sistema Autónomo</h1>
            <p class="header-subtitle">Oráculo Cognitivo | <span id="system-status" class="status-active">INICIANDO...</span></p>
        </div>

        <div class="main-interface">
            <div class="chat-container">
                <div id="chat-messages" class="messages-area">
                    <div class="message system-message">
                        <div class="message-content">
                            🔮 ASV-A AURION COGNITIVE SYSTEM INICIADO<br>
                            Conectando con motor de IA...
                        </div>
                    </div>
                </div>
                
                <div class="input-area">
                    <input type="text" id="user-input" placeholder="Escribe tu consulta al oráculo..." disabled>
                    <button id="send-button" class="cyber-button" disabled>ENVIAR</button>
                </div>
                
                <div class="status-area">
                    <div id="connection-status" class="status-item">
                        <span class="status-label">CONEXIÓN:</span>
                        <span id="status-indicator" class="status-offline">🔴 OFFLINE</span>
                    </div>
                    <div class="status-item">
                        <span class="status-label">MODELO:</span>
                        <span id="model-indicator" class="status-model">cargando...</span>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="app.js"></script>
</body>
</html>
HTMLCODE

    # CSS mejorado
    cat > frontend/style.css << 'CSSCODE'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    background: linear-gradient(135deg, #0a0a0a 0%, #1a1a2e 50%, #16213e 100%);
    color: #00f0ff;
    font-family: 'Share Tech Mono', monospace;
    min-height: 100vh;
    overflow-x: hidden;
}

.system-container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

.header-display {
    text-align: center;
    margin-bottom: 30px;
    padding: 20px;
    background: rgba(0, 240, 255, 0.1);
    border: 1px solid #00f0ff;
    border-radius: 10px;
    box-shadow: 0 0 20px rgba(0, 240, 255, 0.3);
}

.header-title {
    font-family: 'Orbitron', sans-serif;
    font-size: 2.5em;
    margin-bottom: 10px;
    background: linear-gradient(45deg, #00f0ff, #00ff88);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    text-shadow: 0 0 10px rgba(0, 240, 255, 0.5);
}

.header-subtitle {
    font-size: 1.2em;
    opacity: 0.9;
}

.status-active {
    color: #00ff88;
    text-shadow: 0 0 10px #00ff88;
}

.main-interface {
    display: flex;
    justify-content: center;
}

.chat-container {
    width: 100%;
    max-width: 800px;
    background: rgba(0, 20, 40, 0.8);
    border: 1px solid #00f0ff;
    border-radius: 15px;
    padding: 20px;
    box-shadow: 0 0 30px rgba(0, 240, 255, 0.2);
}

.messages-area {
    height: 400px;
    overflow-y: auto;
    margin-bottom: 20px;
    padding: 15px;
    background: rgba(0, 10, 20, 0.9);
    border: 1px solid #00ff88;
    border-radius: 10px;
}

.message {
    margin: 15px 0;
    padding: 12px 16px;
    border-radius: 10px;
    max-width: 85%;
    animation: messageAppear 0.3s ease-out;
}

@keyframes messageAppear {
    from {
        opacity: 0;
        transform: translateY(10px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

.system-message {
    background: rgba(0, 100, 255, 0.2);
    border: 1px solid #0066ff;
    margin: 0 auto;
    text-align: center;
}

.user-message {
    background: rgba(0, 240, 255, 0.2);
    border: 1px solid #00f0ff;
    margin-left: auto;
    margin-right: 0;
}

.assistant-message {
    background: rgba(0, 255, 136, 0.2);
    border: 1px solid #00ff88;
    margin-right: auto;
    margin-left: 0;
}

.error-message {
    background: rgba(255, 50, 50, 0.2);
    border: 1px solid #ff3232;
    margin: 0 auto;
}

.message-content {
    line-height: 1.5;
}

.typing-indicator {
    display: flex;
    align-items: center;
    color: #00ff88;
}

.typing-dots {
    display: flex;
    gap: 4px;
    margin-left: 10px;
}

.typing-dots span {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: #00ff88;
    animation: bounce 1.4s ease-in-out infinite both;
}

.typing-dots span:nth-child(1) { animation-delay: -0.32s; }
.typing-dots span:nth-child(2) { animation-delay: -0.16s; }

@keyframes bounce {
    0%, 80%, 100% {
        transform: scale(0.8);
        opacity: 0.5;
    }
    40% {
        transform: scale(1);
        opacity: 1;
    }
}

.input-area {
    display: flex;
    gap: 10px;
    margin-bottom: 15px;
}

#user-input {
    flex: 1;
    padding: 12px 15px;
    background: rgba(0, 10, 20, 0.9);
    border: 1px solid #00f0ff;
    border-radius: 8px;
    color: #00f0ff;
    font-family: 'Share Tech Mono', monospace;
    font-size: 14px;
}

#user-input:focus {
    outline: none;
    box-shadow: 0 0 10px rgba(0, 240, 255, 0.5);
    border-color: #00ff88;
}

.cyber-button {
    padding: 12px 25px;
    background: linear-gradient(45deg, #00f0ff, #00ff88);
    border: none;
    border-radius: 8px;
    color: #0a0a0a;
    font-family: 'Orbitron', sans-serif;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
}

.cyber-button:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(0, 240, 255, 0.4);
}

.cyber-button:disabled {
    background: #666;
    cursor: not-allowed;
    transform: none;
}

.status-area {
    display: flex;
    justify-content: space-between;
    padding: 10px;
    background: rgba(0, 15, 30, 0.8);
    border-radius: 8px;
    border: 1px solid #00f0ff;
}

.status-item {
    display: flex;
    align-items: center;
    gap: 8px;
}

.status-label {
    font-weight: bold;
    color: #00f0ff;
}

.status-online {
    color: #00ff88;
    text-shadow: 0 0 5px #00ff88;
}

.status-offline {
    color: #ff4444;
}

.status-model {
    color: #ffaa00;
}

/* Scrollbar personalizado */
.messages-area::-webkit-scrollbar {
    width: 8px;
}

.messages-area::-webkit-scrollbar-track {
    background: rgba(0, 20, 40, 0.8);
}

.messages-area::-webkit-scrollbar-thumb {
    background: #00f0ff;
    border-radius: 4px;
}

.messages-area::-webkit-scrollbar-thumb:hover {
    background: #00ff88;
}
CSSCODE

    # JavaScript autónomo mejorado
    cat > frontend/app.js << 'JSCODE'
// ASV-A Autonomous Frontend - Conexión automática completa
class ASVAAutonomousSystem {
    constructor() {
        this.flaskUrl = `http://localhost:5000`;
        this.isConnected = false;
        this.isGenerating = false;
        this.retryCount = 0;
        this.maxRetries = 10;
        
        this.initializeSystem();
    }

    async initializeSystem() {
        this.updateStatus('🟡 CONECTANDO SISTEMA...', 'connecting');
        this.disableInput(true);
        
        // Iniciar monitoreo de conexión
        this.startConnectionMonitor();
        
        // Intentar conexión inicial
        await this.attemptConnection();
        
        // Configurar event listeners
        this.setupEventListeners();
    }

    setupEventListeners() {
        const sendButton = document.getElementById('send-button');
        const userInput = document.getElementById('user-input');

        sendButton.addEventListener('click', () => this.handleUserMessage());
        userInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter' && !this.isGenerating) {
                this.handleUserMessage();
            }
        });
    }

    async startConnectionMonitor() {
        // Verificar conexión cada 5 segundos
        setInterval(async () => {
            if (!this.isConnected) {
                await this.checkConnection();
            }
        }, 5000);
    }

    async attemptConnection() {
        while (this.retryCount < this.maxRetries && !this.isConnected) {
            this.retryCount++;
            this.updateStatus(`🟡 INTENTANDO CONEXIÓN ${this.retryCount}/${this.maxRetries}...`, 'connecting');
            
            const success = await this.checkConnection();
            if (success) break;
            
            // Esperar entre intentos (con backoff exponencial)
            await new Promise(resolve => 
                setTimeout(resolve, Math.min(1000 * Math.pow(1.5, this.retryCount), 10000))
            );
        }

        if (!this.isConnected) {
            this.updateStatus('🔴 CONEXIÓN FALLIDA - Verifica los servidores', 'error');
        }
    }

    async checkConnection() {
        try {
            const response = await fetch(`${this.flaskUrl}/api/health`, {
                method: 'GET',
                timeout: 5000
            });
            
            if (response.ok) {
                const data = await response.json();
                this.handleSuccessfulConnection(data);
                return true;
            }
        } catch (error) {
            console.log('Error de conexión:', error);
        }
        
        this.isConnected = false;
        return false;
    }

    handleSuccessfulConnection(healthData) {
        this.isConnected = true;
        this.retryCount = 0;
        
        const ollamaStatus = healthData.ollama === 'ready' ? '🟢 CONECTADO' : '🟡 OLLAMA PENDIENTE';
        this.updateStatus(`${ollamaStatus} | Modelo: ${healthData.model}`, 'connected');
        
        this.disableInput(false);
        this.addSystemMessage('✅ SISTEMA CONECTADO - Oráculo listo para consultas');
        
        // Actualizar indicador de modelo
        document.getElementById('model-indicator').textContent = healthData.model;
    }

    updateStatus(message, type) {
        const statusElement = document.getElementById('status-indicator');
        const systemStatus = document.getElementById('system-status');
        
        if (statusElement) {
            statusElement.textContent = message;
            statusElement.className = `status-${type}`;
        }
        
        if (systemStatus) {
            systemStatus.textContent = message;
            systemStatus.className = `status-${type}`;
        }
        
        // Actualizar título de la página con estado
        document.title = `ASV-A AI | ${message}`;
    }

    disableInput(disabled) {
        document.getElementById('user-input').disabled = disabled;
        document.getElementById('send-button').disabled = disabled;
        
        if (!disabled) {
            document.getElementById('user-input').placeholder = 'Escribe tu consulta al oráculo...';
            document.getElementById('user-input').focus();
        } else {
            document.getElementById('user-input').placeholder = 'Conectando con el sistema...';
        }
    }

    async handleUserMessage() {
        if (!this.isConnected || this.isGenerating) return;

        const userInput = document.getElementById('user-input');
        const message = userInput.value.trim();

        if (!message) return;

        // Limpiar input y agregar mensaje
        userInput.value = '';
        this.addUserMessage(message);
        this.showTypingIndicator();

        this.isGenerating = true;
        this.disableInput(true);

        try {
            const response = await this.sendToBackend(message);
            this.removeTypingIndicator();
            this.addAssistantMessage(response);
        } catch (error) {
            this.removeTypingIndicator();
            this.addErrorMessage(`Error: ${error.message}`);
            // Reintentar conexión si falla
            this.isConnected = false;
            await this.attemptConnection();
        } finally {
            this.isGenerating = false;
            if (this.isConnected) {
                this.disableInput(false);
            }
        }
    }

    async sendToBackend(prompt) {
        const response = await fetch(`${this.flaskUrl}/api/query`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ prompt })
        });

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.error || `HTTP ${response.status}`);
        }

        const data = await response.json();
        return data.response || 'No response from AI';
    }

    addSystemMessage(content) {
        this.addMessage('system', content);
    }

    addUserMessage(content) {
        this.addMessage('user', content);
    }

    addAssistantMessage(content) {
        this.addMessage('assistant', content);
    }

    addErrorMessage(content) {
        this.addMessage('error', content);
    }

    addMessage(type, content) {
        const messagesArea = document.getElementById('chat-messages');
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${type}-message`;
        
        messageDiv.innerHTML = `
            <div class="message-content">${this.formatMessage(content)}</div>
        `;

        messagesArea.appendChild(messageDiv);
        messagesArea.scrollTop = messagesArea.scrollHeight;
    }

    showTypingIndicator() {
        const messagesArea = document.getElementById('chat-messages');
        const typingDiv = document.createElement('div');
        typingDiv.id = 'typing-indicator';
        typingDiv.className = 'message assistant-message typing-indicator';
        
        typingDiv.innerHTML = `
            <div class="message-content">
                ASV-A procesando...
                <div class="typing-dots">
                    <span></span>
                    <span></span>
                    <span></span>
                </div>
            </div>
        `;

        messagesArea.appendChild(typingDiv);
        messagesArea.scrollTop = messagesArea.scrollHeight;
    }

    removeTypingIndicator() {
        const typingIndicator = document.getElementById('typing-indicator');
        if (typingIndicator) {
            typingIndicator.remove();
        }
    }

    formatMessage(content) {
        return content.replace(/\n/g, '<br>');
    }
}

// Inicializar el sistema cuando se carga la página
document.addEventListener('DOMContentLoaded', () => {
    window.asvaSystem = new ASVAAutonomousSystem();
});

// Polyfill para timeout en fetch
if (!
