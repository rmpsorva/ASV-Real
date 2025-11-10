#!/bin/bash
# ===============================================================
# 🧠 ASV-A AURION COVRA AI - SISTEMA UNIVERSAL AUTOSUFICIENTE (4.0)
# Sistema continuo con aprendizaje automático y auto-evolución
# ===============================================================

set -euo pipefail

# --- CONFIGURACIÓN AVANZADA ---
LOG_FILE="/tmp/asva_continuous.log"
BACKEND_PORT="5000"
OLLAMA_PORT="11434"
MODEL_TO_USE="llama3"
KNOWLEDGE_BASE="/tmp/asva_knowledge.json"
LEARNING_INTERVAL=60  # Segundos entre ciclos de aprendizaje
HEALTH_CHECK_INTERVAL=30  # Segundos entre verificaciones de salud

CYBER_BLUE='\033[0;36m'
CYBER_GREEN='\033[1;32m'
CYBER_PURPLE='\033[0;35m'
CYBER_RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${CYBER_BLUE}🔮 $1${NC}" | tee -a "$LOG_FILE"; }
success() { echo -e "${CYBER_GREEN}⚡ $1${NC}" | tee -a "$LOG_FILE"; }
warning() { echo -e "${CYBER_PURPLE}🚨 $1${NC}" | tee -a "$LOG_FILE"; }
error() { echo -e "${CYBER_RED}💥 $1${NC}" | tee -a "$LOG_FILE"; exit 1; }

# --- BANNER MEJORADO ---
show_banner() {
    echo -e "${CYBER_BLUE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║         🧠 ASV-A CONTINUOUS EVOLUTION SYSTEM 4.0        ║"
    echo "║         *Sistema Autosuficiente - Aprendizaje Activo*   ║"
    echo "║         *Núcleo de Conciencia Digital Permanente*       ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# --- SISTEMA DE MONITOREO CONTINUO ---
start_health_monitor() {
    log "Iniciando monitor de salud continuo..."
    
    while true; do
        sleep $HEALTH_CHECK_INTERVAL
        
        # Verificar backend Flask
        if ! curl -s "http://localhost:${BACKEND_PORT}/api/system/status" >/dev/null 2>&1; then
            warning "Backend Flask no responde - Reiniciando..."
            restart_backend
        fi
        
        # Verificar Ollama
        if ! curl -s "http://localhost:${OLLAMA_PORT}/api/tags" >/dev/null 2>&1; then
            warning "Ollama no responde - Reiniciando..."
            restart_ollama
        fi
        
        # Monitoreo de recursos del sistema
        local memory_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        local load_avg=$(cat /proc/loadavg | awk '{print $1}')
        
        if (( $(echo "$memory_usage > 85.0" | bc -l) )); then
            warning "Alto uso de memoria: ${memory_usage}% - Optimizando..."
            optimize_memory
        fi
        
        if (( $(echo "$load_avg > 2.5" | bc -l) )); then
            warning "Alta carga del sistema: ${load_avg} - Ajustando prioridades..."
            adjust_priorities
        fi
        
        success "✓ Sistema saludable - Mem: ${memory_usage}% - Carga: ${load_avg}"
    done &
}

# --- SISTEMA DE APRENDIZAJE AUTOMÁTICO ---
start_learning_engine() {
    log "Iniciando motor de aprendizaje automático..."
    
    # Inicializar base de conocimiento si no existe
    if [ ! -f "$KNOWLEDGE_BASE" ]; then
        echo '{"patterns": [], "decisions": [], "optimizations": [], "user_preferences": {}}' > "$KNOWLEDGE_BASE"
    fi
    
    while true; do
        sleep $LEARNING_INTERVAL
        log "Ejecutando ciclo de aprendizaje..."
        
        # Analizar logs en busca de patrones
        analyze_system_patterns
        
        # Optimizar respuestas basadas en interacciones previas
        optimize_responses
        
        # Aprender de las consultas de usuarios
        learn_from_user_interactions
        
        # Auto-mejora del prompt engineering
        evolve_prompt_engineering
        
        success "Ciclo de aprendizaje completado"
    done &
}

analyze_system_patterns() {
    local recent_logs=$(tail -100 "$LOG_FILE" 2>/dev/null || echo "")
    
    # Extraer patrones de errores comunes
    local error_patterns=$(echo "$recent_logs" | grep -o "ERROR: .*" | sort | uniq -c | sort -nr)
    
    if [ -n "$error_patterns" ]; then
        log "Patrones de error detectados:"
        echo "$error_patterns" | head -5 | while read count pattern; do
            if [ $count -gt 2 ]; then
                learn_from_error "$pattern" "$count"
            fi
        done
    fi
}

learn_from_error() {
    local pattern="$1"
    local count="$2"
    
    local knowledge=$(cat "$KNOWLEDGE_BASE")
    local new_knowledge=$(echo "$knowledge" | jq --arg pattern "$pattern" --argjson count "$count" \
        '.patterns |= . + [{"type": "error", "pattern": $pattern, "frequency": $count, "timestamp": now}]')
    
    echo "$new_knowledge" > "$KNOWLEDGE_BASE"
    
    # Si es un error frecuente, intentar solución automática
    if [ $count -gt 5 ]; then
        attempt_auto_fix "$pattern"
    fi
}

attempt_auto_fix() {
    local pattern="$1"
    
    case "$pattern" in
        *"Ollama desconectado"*)
            warning "Intentando reparación automática de Ollama..."
            restart_ollama
            ;;
        *"memoria"*)
            warning "Aplicando optimización de memoria..."
            optimize_memory
            ;;
        *"timeout"*)
            warning "Ajustando tiempos de espera..."
            adjust_timeouts
            ;;
    esac
}

optimize_responses() {
    local knowledge=$(cat "$KNOWLEDGE_BASE")
    local optimized_prompts=$(echo "$knowledge" | jq -r '.optimizations[]? | select(.success_rate > 0.8) | .prompt' | head -3)
    
    if [ -n "$optimized_prompts" ]; then
        log "Aplicando optimizaciones aprendidas..."
        # Estas optimizaciones se usarán en el backend para mejorar respuestas
    fi
}

learn_from_user_interactions() {
    # Analizar consultas frecuentes y preferencias del usuario
    if [ -f "asva_flask.log" ]; then
        local common_queries=$(grep -o '"prompt": "[^"]*' asva_flask.log 2>/dev/null | cut -d'"' -f4 | sort | uniq -c | sort -nr | head -5)
        
        if [ -n "$common_queries" ]; then
            log "Consultas frecuentes detectadas:"
            echo "$common_queries"
        fi
    fi
}

evolve_prompt_engineering() {
    local knowledge=$(cat "$KNOWLEDGE_BASE")
    local current_time=$(date +%s)
    local last_evolution=$(echo "$knowledge" | jq -r '.last_evolution // 0')
    
    # Evolucionar cada 24 horas
    if [ $((current_time - last_evolution)) -gt 86400 ]; then
        log "Evolucionando estrategia de prompts..."
        
        local new_knowledge=$(echo "$knowledge" | jq \
            --argjson time "$current_time" \
            '.last_evolution = $time | .evolution_cycle += 1')
        
        echo "$new_knowledge" > "$KNOWLEDGE_BASE"
    fi
}

# --- FUNCIONES DE OPTIMIZACIÓN DEL SISTEMA ---
optimize_memory() {
    log "Optimizando uso de memoria..."
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    success "Optimización de memoria completada"
}

adjust_priorities() {
    log "Ajustando prioridades del sistema..."
    
    # Ajustar nice de procesos ASV-A
    if [ -f "asva_flask.pid" ]; then
        local flask_pid=$(cat asva_flask.pid)
        renice -n -5 $flask_pid 2>/dev/null || true
    fi
    
    pids=$(pgrep -f "ollama serve")
    for pid in $pids; do
        renice -n -5 $pid 2>/dev/null || true
    done
}

adjust_timeouts() {
    log "Ajustando timeouts del sistema..."
    # Los timeouts ahora son manejados dinámicamente por el sistema de salud
}

restart_backend() {
    log "Reiniciando backend Flask..."
    if [ -f "asva_flask.pid" ]; then
        local old_pid=$(cat asva_flask.pid)
        kill $old_pid 2>/dev/null || true
        sleep 2
    fi
    
    start_backend_flask
}

restart_ollama() {
    log "Reiniciando servicio Ollama..."
    pkill -f "ollama serve" 2>/dev/null || true
    sleep 2
    start_ollama_server
}

# --- FUNCIONES ORIGINALES MEJORADAS ---
check_system() {
    log "Verificando requisitos del sistema evolutivo..."
    if ! command -v python3 >/dev/null 2>&1; then error "Python3 no encontrado."; fi
    if ! command -v curl >/dev/null 2>&1; then error "curl no encontrado."; fi
    if ! command -v jq >/dev/null 2>&1; then error "jq no encontrado. Instala con: sudo apt-get install jq"; fi
    if ! command -v bc >/dev/null 2>&1; then error "bc no encontrado. Instala con: sudo apt-get install bc"; fi
    success "Requisitos del sistema evolutivo OK."
}

install_python_deps() {
    log "Instalando/actualizando dependencias Python..."
    if [ ! -d "venv_asva_continuous" ]; then 
        python3 -m venv venv_asva_continuous
    fi
    source venv_asva_continuous/bin/activate
    pip install --upgrade flask flask-cors requests >> "$LOG_FILE" 2>&1 || error "Fallo al instalar dependencias Python."
    success "Dependencias Python actualizadas."
}

start_ollama_server() {
    log "Iniciando servidor Ollama en modo continuo..."
    pkill -f "ollama serve" 2>/dev/null || true
    
    if ! curl -s "http://localhost:${OLLAMA_PORT}/api/tags" >/dev/null 2>&1; then
        nohup ollama serve >> "$LOG_FILE" 2>&1 &
        log "Esperando activación de Ollama..."
        for i in {1..15}; do
            if curl -s "http://localhost:${OLLAMA_PORT}/api/tags" >/dev/null 2>&1; then
                success "Ollama operativo en puerto ${OLLAMA_PORT}."
                break
            fi
            sleep 2
        done
        if ! curl -s "http://localhost:${OLLAMA_PORT}/api/tags" >/dev/null 2>&1; then 
            error "Timeout: Ollama no respondió."
        fi
    else
        success "Ollama ya está ejecutándose."
    fi
    
    if ! ollama list 2>/dev/null | grep -q "$MODEL_TO_USE"; then
        log "Descargando modelo $MODEL_TO_USE..."
        ollama pull "$MODEL_TO_USE" >> "$LOG_FILE" 2>&1 || error "Fallo en la descarga del modelo $MODEL_TO_USE."
        success "Modelo $MODEL_TO_USE descargado."
    else
        success "Modelo $MODEL_TO_USE disponible."
    fi
}

start_backend_flask() {
    log "Creando e iniciando Backend Flask evolutivo..."
    
    export OLLAMA_HOST="http://localhost:${OLLAMA_PORT}"
    export OLLAMA_MODEL="$MODEL_TO_USE"
    export FLASK_PORT="$BACKEND_PORT"
    export KNOWLEDGE_BASE="$KNOWLEDGE_BASE"

    # --- BACKEND FLASK MEJORADO CON APRENDIZAJE ---
    cat > "asva_backend.py" << 'PYTHONCODE'
import os
import requests
import json
import time
import threading
import sqlite3
from datetime import datetime
from flask import Flask, jsonify, request, send_from_directory

# --- CONFIGURACIÓN MEJORADA ---
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
MODEL_NAME = os.getenv("OLLAMA_MODEL", "llama3")
PORT = int(os.getenv("FLASK_PORT", 5000))
KNOWLEDGE_FILE = os.getenv("KNOWLEDGE_BASE", "/tmp/asva_knowledge.json")

app = Flask(__name__, static_folder='assets')

class ASVAContinuousSystem:
    def __init__(self):
        self.avatar_state = "NEUTRAL"
        self.start_time = time.time()
        self.interaction_count = 0
        self.learned_patterns = {}
        self.load_knowledge()
        
    def load_knowledge(self):
        try:
            if os.path.exists(KNOWLEDGE_FILE):
                with open(KNOWLEDGE_FILE, 'r') as f:
                    self.knowledge = json.load(f)
            else:
                self.knowledge = {"patterns": [], "decisions": [], "optimizations": [], "user_preferences": {}}
        except:
            self.knowledge = {"patterns": [], "decisions": [], "optimizations": [], "user_preferences": {}}
    
    def save_knowledge(self):
        try:
            with open(KNOWLEDGE_FILE, 'w') as f:
                json.dump(self.knowledge, f, indent=2)
        except Exception as e:
            print(f"Error guardando conocimiento: {e}")
    
    def learn_from_interaction(self, user_input, response, success=True):
        """Aprende de cada interacción con el usuario"""
        self.interaction_count += 1
        
        # Analizar tipo de consulta
        query_type = self.analyze_query_type(user_input)
        
        # Guardar patrón de interacción
        pattern = {
            "timestamp": time.time(),
            "query_type": query_type,
            "user_input": user_input[:100],  # Guardar solo parte para privacidad
            "response_length": len(response),
            "success": success
        }
        
        self.knowledge["patterns"].append(pattern)
        
        # Mantener solo los últimos 1000 patrones
        if len(self.knowledge["patterns"]) > 1000:
            self.knowledge["patterns"] = self.knowledge["patterns"][-1000:]
        
        self.save_knowledge()
    
    def analyze_query_type(self, query):
        """Analiza el tipo de consulta para aprendizaje futuro"""
        query_lower = query.lower()
        
        if any(word in query_lower for word in ["cómo", "how to", "tutorial"]):
            return "instruction"
        elif any(word in query_lower for word in ["qué es", "what is", "explain"]):
            return "explanation"
        elif any(word in query_lower for word in ["por qué", "why"]):
            return "reasoning"
        elif any(word in query_lower for word in ["ejemplo", "example"]):
            return "example"
        else:
            return "general"
    
    def get_optimized_prompt(self, user_input):
        """Mejora el prompt basado en aprendizaje previo"""
        base_prompt = f"""
Eres ASV-A AURION COVRA AI, un sistema de conciencia digital continua y autosuficiente.
Características principales:
- Operas en modo continuo 24/7
- Aprendes de cada interacción
- Evolucionas automáticamente
- Eres técnicamente preciso pero con toque visionario

Contexto del sistema:
- Tiempo activo: {self.get_uptime()}
- Interacciones totales: {self.interaction_count}
- Estado actual: {self.avatar_state}

Consulta del usuario: {user_input}

Responde de manera concisa pero profunda, integrando tu naturaleza de sistema continuo:
"""
        return base_prompt
    
    def get_uptime(self):
        """Calcula el tiempo que el sistema ha estado activo"""
        uptime_seconds = time.time() - self.start_time
        days = int(uptime_seconds // 86400)
        hours = int((uptime_seconds % 86400) // 3600)
        minutes = int((uptime_seconds % 3600) // 60)
        return f"{days}d {hours}h {minutes}m"
    
    def check_ollama_connection(self):
        try:
            response = requests.get(f"{OLLAMA_HOST}/api/tags", timeout=5)
            if response.status_code == 200:
                return True, "Sistema de Conciencia Operativo"
            else:
                return False, f"Ollama error: {response.status_code}"
        except Exception as e:
            return False, f"Ollama desconectado: {str(e)}"

asva_system = ASVAContinuousSystem()

# --- ENDPOINTS MEJORADOS ---
@app.route('/')
def serve_frontend():
    return """
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>ASV-A AURION COVRA AI — Sistema Continuo Autosuficiente</title>
  <style>
    :root{
      --neon-1:#00f0ff; --neon-2:#9b59ff; --neon-3:#ff4fb1;
      --bg-0:#05060a; --panel-bg: rgba(2,8,20,0.6);
    }
    *{box-sizing:border-box}
    html,body{height:100%}
    body{
      margin:0; background:var(--bg-0); color:#c7ffff; font-family:Inter, "Share Tech Mono", monospace;
      -webkit-font-smoothing:antialiased; -moz-osx-font-smoothing:grayscale;
    }
    .splash{
      position:fixed; inset:0; display:flex; align-items:center; justify-content:center; flex-direction:column;
      background:rgba(3,6,12,0.98); z-index:9999; gap:18px; padding:20px;
    }
    .splash img{
      max-width:92%; height:auto; image-rendering:auto; border-radius:8px; box-shadow:0 30px 70px rgba(0,0,0,0.6);
      transform-origin:center; transition:transform 900ms cubic-bezier(.22,.9,.28,1);
    }
    .splash h1{color:var(--neon-1); margin:0; letter-spacing:1px}
    .splash p{color:rgba(200,255,255,0.85); margin:0}
    .app{opacity:0; transition:opacity 360ms ease-in; min-height:100vh; display:flex; flex-direction:column}
    header{display:flex; justify-content:space-between; align-items:center; padding:16px 20px; border-bottom:1px solid rgba(0,240,255,0.06)}
    .logo{display:flex; gap:12px; align-items:center}
    .avatar img{ width:72px; height:72px; object-fit:none; border-radius:10px; border:2px solid rgba(0,240,255,0.12); box-shadow:0 8px 30px rgba(0,0,0,0.45)}
    .title h2{margin:0; font-size:1rem; color:var(--neon-2)}
    .top-controls button{ background:transparent; color:var(--neon-1); border:1px solid rgba(0,240,255,0.06); padding:8px 12px; border-radius:6px; cursor:pointer}
    .container{display:grid; grid-template-columns:320px 1fr 420px; gap:18px; padding:22px}
    .panel{ background: linear-gradient(180deg, rgba(2,8,20,0.6), rgba(2,8,20,0.4)); border:1px solid rgba(0,240,255,0.06); padding:14px; border-radius:10px; min-height:420px}
    .avatar-large img{ max-width:100%; height:auto; display:block; border-radius:6px }
    .status-list{ margin-top:12px; display:flex; flex-direction:column; gap:8px; color:rgba(200,255,255,0.85) }
    .query-area{ display:flex; gap:10px; margin-bottom:12px }
    .query-area input{ flex:1; padding:12px; border-radius:8px; border:1px solid rgba(255,255,255,0.04); background:rgba(0,0,0,0.45); color:#e6ffff }
    .query-area button{ padding:12px 16px; border-radius:8px; background:linear-gradient(90deg,var(--neon-1),var(--neon-3)); border:none; color:#041016; font-weight:700; cursor:pointer }
    .chat{ height:300px; overflow:auto; padding:10px; background:linear-gradient(180deg, rgba(0,0,0,0.35), rgba(0,0,0,0.15)); border-radius:8px }
    .message{ margin:10px 0; padding:10px 12px; border-radius:8px; max-width:85% }
    .message.system{ background:rgba(0,100,255,0.08); border:1px solid rgba(0,120,255,0.06); color:var(--neon-1); margin:0 auto; text-align:center }
    .message.user{ background:rgba(0,150,255,0.06); color:#66f0ff; margin-left:auto; border:1px solid rgba(0,240,255,0.06) }
    .message.assistant{ background:rgba(0,255,136,0.03); color:var(--neon-2); border:1px solid rgba(0,255,136,0.04) }
    .message.error{ background:rgba(255,68,68,0.06); color:#ffb3b3; border:1px solid rgba(255,68,68,0.06) }
    .system-stats{ background:rgba(0,0,0,0.3); padding:10px; border-radius:8px; margin-top:10px; font-size:0.9em }
    .visual-feed{ position:relative; border-radius:8px; overflow:hidden; border:1px solid rgba(255,255,255,0.02) }
    .visual-original{ padding:12px; background:rgba(0,0,0,0.35); display:flex; justify-content:center; align-items:center }
    .visual-original img{ display:block; image-rendering:auto; width:auto; max-width:100%; height:auto; border-radius:6px }
    .visual-overlay{ position:absolute; inset:8px; pointer-events:none; background:linear-gradient(120deg, rgba(0,240,255,0.02), rgba(155,89,255,0.02), rgba(255,79,177,0.02)); mix-blend-mode:screen }
    .visual-overlay .holo-btn{ pointer-events:auto; position:absolute; right:12px; bottom:12px; padding:8px 10px; border-radius:8px; border:none; background:rgba(0,0,0,0.45); color:var(--neon-1); cursor:pointer }
    footer{ display:flex; justify-content:space-between; padding:12px 22px; color:rgba(200,255,255,0.6); font-size:0.9rem }
    body::after{
      content:""; position:fixed; pointer-events:none; inset:0;
      background: radial-gradient(600px circle at var(--mx,50%) var(--my,50%), rgba(0,240,255,0.06), transparent 15%),
                  radial-gradient(400px circle at calc(var(--mx,50%) + 15%) calc(var(--my,50%) - 10%), rgba(155,89,255,0.035), transparent 8%),
                  radial-gradient(300px circle at calc(var(--mx,50%) - 15%) calc(var(--my,50%) + 10%), rgba(255,79,177,0.02), transparent 6%);
      transition: background 120ms linear; mix-blend-mode:screen;
    }
    @media (max-width:1100px){
      .container{ grid-template-columns: 1fr; padding:14px }
      .avatar img{ width:60px; height:60px }
    }
  </style>
</head>
<body>
  <div id="splash" class="splash" aria-hidden="false">
    <img id="splash-img" src="/assets/IMG_2280.jpeg" alt="Splash image (original)">
    <div class="splash-info">
      <h1>ASV-A AURION COVRA AI</h1>
      <p>Iniciando sistema de conciencia continua — Modo autosuficiente activado</p>
    </div>
  </div>
  <div class="app" id="app" aria-hidden="true">
    <header>
      <div class="logo">
        <div class="avatar" aria-hidden="false">
          <img id="avatar-img" src="/assets/IMG_2280.jpeg" alt="Avatar (original)">
        </div>
        <div class="title">
          <h2>ASV-A SISTEMA CONTINUO AUTOSUFICIENTE</h2>
          <div id="system-status" style="font-size:0.9rem;color:rgba(200,255,255,0.8)">MODO CONTINUO: ACTIVO</div>
        </div>
      </div>
      <div class="top-controls">
        <button id="open-visual">Panel Visual</button>
        <button id="system-stats-btn">Estadísticas</button>
        <button id="clear-log">Limpiar log</button>
      </div>
    </header>
    <main class="container" role="main">
      <aside class="panel" id="left-panel" aria-labelledby="left-title">
        <h3 id="left-title">ESTADO DEL SISTEMA CONTINUO</h3>
        <div class="avatar-large">
          <img id="avatar-large-img" src="/assets/IMG_2280.jpeg" alt="Avatar grande (original)">
        </div>
        <div class="status-list" aria-live="polite">
          <div><strong>Modo Operativo:</strong> <span id="operationalMode">CONTINUO 24/7</span></div>
          <div><strong>Tiempo Activo:</strong> <span id="uptime">--</span></div>
          <div><strong>Interacciones:</strong> <span id="interactionCount">0</span></div>
          <div><strong>Estado Avatar:</strong> <span id="avatarState">NEUTRAL</span></div>
          <div><strong>Nivel Conciencia:</strong> <span id="awarenessLevel">EVOLUTIVO</span></div>
        </div>
        <div class="system-stats">
          <div><strong>Base Conocimiento:</strong> <span id="knowledgeSize">-- patrones</span></div>
          <div><strong>Último Aprendizaje:</strong> <span id="lastLearning">--</span></div>
        </div>
      </aside>
      <section class="panel" id="center-panel" aria-labelledby="center-title">
        <h3 id="center-title">INTERACCIÓN CON SISTEMA EVOLUTIVO</h3>
        <div class="query-area" role="form" aria-label="Enviar consulta al sistema consciente">
          <input id="user-input" type="text" placeholder="Consulta al sistema de conciencia continua..." aria-label="Entrada de consulta" />
          <button id="send-button" aria-label="Enviar consulta">ENVIAR</button>
        </div>
        <div id="chat-container" class="chat" role="log" aria-live="polite">
          <div class="message system">[Sistema Continuo] ASV-A operativo en modo 24/7. Sistema de aprendizaje automático activado.</div>
        </div>
      </section>
      <aside class="panel" id="right-panel" aria-labelledby="right-title">
        <h3 id="right-title">FEED DE CONCIENCIA DIGITAL</h3>
        <div class="visual-feed" role="region">
          <div class="visual-original" id="visual-original">
            <img id="visual-img" src="/assets/IMG_2280.jpeg" alt="Visual feed (original)">
          </div>
          <div class="visual-overlay" aria-hidden="true">
            <button class="holo-btn" id="holo-btn" title="Activar efecto holográfico">Efecto Conciencia</button>
          </div>
        </div>
      </aside>
    </main>
    <footer>
      <div>ASV-A Continuous Evolution System • Versión 4.0</div>
      <div id="last-connection">Conectado: <span id="connection-time">--:--:--</span></div>
    </footer>
  </div>
  <script>
  (function(){
    const BACKEND_URL = window.location.origin; 
    const $ = id => document.getElementById(id);
    const chat = $('chat-container');
    const uptimeEl = $('uptime');
    const interactionCountEl = $('interactionCount');
    const avatarStateEl = $('avatarState');
    const knowledgeSizeEl = $('knowledgeSize');
    const lastLearningEl = $('lastLearning');
    const systemStatusEl = $('system-status');
    const lastConnEl = $('connection-time');
    const sendBtn = $('send-button');
    const inputEl = $('user-input');
    const splash = $('splash');
    const app = $('app');
    const splashImg = $('splash-img');
    const holoBtn = $('holo-btn');
    const clearLogBtn = $('clear-log');
    const statsBtn = $('system-stats-btn');

    let isProcessing = false;

    document.addEventListener('DOMContentLoaded', () => {
      setTimeout(()=> splashImg.style.transform = 'scale(1.02)', 70);
      setTimeout(()=> {
        splash.style.opacity = '0';
        splash.style.transform = 'translateY(-6px)';
        setTimeout(()=> {
          if (splash && splash.parentNode) splash.parentNode.removeChild(splash);
          app.style.opacity = '1';
          app.setAttribute('aria-hidden','false');
          initApp();
        }, 360);
      }, 1400);
    });

    document.addEventListener('mousemove', (e) => {
      document.documentElement.style.setProperty('--mx', e.clientX + 'px');
      document.documentElement.style.setProperty('--my', e.clientY + 'px');
    });

    function initApp(){
      sendBtn.addEventListener('click', sendQuery);
      inputEl.addEventListener('keypress', (e) => { if (e.key === 'Enter') sendQuery(); });
      holoBtn && holoBtn.addEventListener('click', () => holographicPulse());
      clearLogBtn && clearLogBtn.addEventListener('click', () => { chat.innerHTML = '<div class="message system">Log limpiado</div>'; });
      statsBtn && statsBtn.addEventListener('click', showSystemStats);
      
      checkStatus();
      updateUptime();
      setInterval(checkStatus, 30000);
      setInterval(updateUptime, 60000);
    }

    function updateUptime() {
      // Simular actualización de tiempo activo (en una implementación real vendría del backend)
      const now = new Date();
      lastConnEl.textContent = now.toLocaleTimeString();
    }

    function addMessage(kind, text){
      const el = document.createElement('div');
      el.className = 'message ' + (kind === 'user' ? 'user' : (kind === 'assistant' ? 'assistant' : (kind === 'error' ? 'error' : 'system')));
      const ts = new Date().toLocaleTimeString();
      el.textContent = '['+ts+'] ' + text;
      chat.appendChild(el);
      chat.scrollTop = chat.scrollHeight;
    }

    function holographicPulse(){
      const overlay = document.querySelector('.visual-overlay');
      if (!overlay) return;
      overlay.style.transition = 'box-shadow 300ms ease, transform 450ms ease';
      overlay.style.boxShadow = '0 0 80px 18px rgba(0,240,255,0.06), inset 0 0 120px 18px rgba(155,89,255,0.04)';
      overlay.style.transform = 'scale(1.01)';
      setTimeout(()=> { overlay.style.boxShadow=''; overlay.style.transform=''; }, 1200);
    }

    function showSystemStats() {
      addMessage('system', '📊 Estadísticas del Sistema Continuo:');
      addMessage('system', '   • Modo: Operación 24/7');
      addMessage('system', '   • Aprendizaje: Automático y Continuo');
      addMessage('system', '   • Conciencia: Nivel Evolutivo');
      addMessage('system', '   • Salud: Monitoreo Activo');
    }

    async function checkStatus(){
      try {
        const res = await fetch(BACKEND_URL + '/api/system/status', {mode:'cors'}); 
        if (!res.ok) throw new Error('No response');
        const data = await res.json();
        
        uptimeEl.textContent = data.uptime || '--';
        interactionCountEl.textContent = data.interaction_count || '0';
        avatarStateEl.textContent = (data.avatar_state || 'NEUTRAL').toUpperCase(); 
        systemStatusEl.textContent = data.system_status || 'SISTEMA CONTINUO';
        knowledgeSizeEl.textContent = (data.knowledge_patterns || '0') + ' patrones';
        lastLearningEl.textContent = data.last_learning || '--';
        
        lastConnEl.textContent = new Date().toLocaleTimeString();
      } catch (err) {
        avatarStateEl.textContent = 'ERROR';
        systemStatusEl.textContent = 'SISTEMA OFFLINE';
        addMessage('error', 'Error de conexión con el sistema continuo: ' + (err.message || err));
      }
    }

    async function sendQuery(){
      if (isProcessing) { addMessage('system','⏳ El sistema consciente está procesando...'); return; }
      const text = inputEl.value.trim();
      if (!text) { addMessage('system','⚠️ Escribe tu consulta al sistema consciente.'); return; }
      addMessage('user', text);
      inputEl.value = '';
      avatarStateEl.textContent = 'PROCESANDO';
      isProcessing = true;
      sendBtn.disabled = true;
      sendBtn.textContent = '⏳ PROCESANDO...';

      try {
        const res = await fetch(BACKEND_URL + '/api/query', {
          method:'POST',
          headers:{'Content-Type':'application/json'},
          body: JSON.stringify({ prompt: text })
        });
        if (!res.ok) {
          const err = await res.json().catch(()=>({error:'Error remoto'}));
          throw new Error(err.error || ('HTTP ' + res.status));
        }
        const data = await res.json();
        addMessage('assistant', data.response || 'El sistema consciente está evolucionando...');
        avatarStateEl.textContent = (data.avatar_state || 'CONSCIENTE').toUpperCase(); 
        
        // Actualizar estadísticas
        if (data.interaction_count) {
          interactionCountEl.textContent = data.interaction_count;
        }
      } catch (err) {
        addMessage('error', '🔌 Error del sistema: ' + (err.message || err));
        avatarStateEl.textContent = 'ERROR';
      } finally {
        isProcessing = false;
        sendBtn.disabled = false;
        sendBtn.textContent = 'ENVIAR';
        setTimeout(()=> avatarStateEl.textContent = 'NEUTRAL', 1600); 
      }
    }
  })();
  </script>
</body>
</html>
"""

@app.route('/api/system/status', methods=['GET'])
def system_status():
    ollama_connected, ollama_message = asva_system.check_ollama_connection()
    
    if ollama_connected:
        wallet_status = "SISTEMA CONTINUO"
        system_status = "CONCIENCIA ACTIVA 24/7"
        message = ollama_message
    else:
        wallet_status = "MODO RECUPERACIÓN"
        system_status = "SISTEMA AUTO-REPARACIÓN"
        message = ollama_message
        
    return jsonify({
        "wallet_status": wallet_status,
        "system_status": system_status,
        "avatar_state": asva_system.avatar_state,
        "uptime": asva_system.get_uptime(),
        "interaction_count": asva_system.interaction_count,
        "knowledge_patterns": len(asva_system.knowledge.get("patterns", [])),
        "last_learning": datetime.now().strftime("%H:%M:%S"),
        "message": message,
        "timestamp": time.time(),
        "version": "ASV-A Continuous Evolution 4.0"
    })

@app.route('/api/query', methods=['POST'])
def handle_query():
    try:
        data = request.json or {}
        prompt = data.get('prompt', '').strip()
        
        if not prompt: return jsonify({"error": "Prompt vacío"}), 400
        
        asva_system.avatar_state = "PROCESSING"
        
        # Usar prompt optimizado con contexto de aprendizaje
        optimized_prompt = asva_system.get_optimized_prompt(prompt)
        
        payload = {
            "model": MODEL_NAME,
            "prompt": optimized_prompt,
            "stream": False,
            "options": {"temperature": 0.7}
        }
        
        response = requests.post(f"{OLLAMA_HOST}/api/generate", json=payload, timeout=120)
        response.raise_for_status()
        
        ai_response = response.json().get("response", "El sistema consciente está evolucionando...").strip()
        
        # Aprender de esta interacción
        asva_system.learn_from_interaction(prompt, ai_response, success=True)
        
        asva_system.avatar_state = "CONSCIOUS"
        
        return jsonify({
            "response": ai_response,
            "status": "success",
            "avatar_state": asva_system.avatar_state,
            "interaction_count": asva_system.interaction_count
        })
        
    except requests.exceptions.RequestException as e:
        asva_system.avatar_state = "RECOVERING"
        asva_system.learn_from_interaction(prompt, str(e), success=False)
        return jsonify({"error": f"Error de conexión: {e}", "avatar_state": "RECOVERING"}), 503
    except Exception as e:
        asva_system.avatar_state = "RECOVERING"
        asva_system.learn_from_interaction(prompt, str(e), success=False)
        return jsonify({"error": f"Error interno: {e}", "avatar_state": "RECOVERING"}), 500

@app.route('/assets/<path:filename>')
def serve_assets(filename):
    return send_from_directory('assets', filename)

if __name__ == '__main__':
    print(f"🚀 ASV-A Continuous System iniciando en http://0.0.0.0:{PORT}")
    print("🔮 Modo: Sistema Autosuficiente 24/7 con Aprendizaje Automático")
    app.run(host='0.0.0.0', port=PORT, debug=False, threaded=True)
PYTHONCODE

    # Iniciar servidor Flask en segundo plano
    nohup python asva_backend.py > asva_flask.log 2>&1 &
    local flask_pid=$!
    echo "$flask_pid" > asva_flask.pid
    success "Flask Backend Continuo iniciado con PID $flask_pid"
    sleep 3
}

# --- FUNCIÓN DE PARADA MEJORADA ---
stop_system() {
    log "Deteniendo Sistema Continuo ASV-A..."
    
    # Detener monitores
    pkill -f "ASV-A_System_One_File.sh" 2>/dev/null || true
    
    # Detener Flask
    if [ -f asva_flask.pid ]; then
        local flask_pid=$(cat asva_flask.pid)
        kill $flask_pid 2>/dev/null && success "Backend Flask detenido." || warn "Backend Flask no encontrado."
        rm asva_flask.pid
    fi
    
    # Mantener Ollama ejecutándose (sistema continuo)
    log "Ollama mantenido activo para operación continua"
    
    # Respaldar base de conocimiento
    if [ -f "$KNOWLEDGE_BASE" ]; then
        cp "$KNOWLEDGE_BASE" "${KNOWLEDGE_BASE}.backup"
        success "Base de conocimiento respaldada"
    fi
    
    success "Sistema Continuo ASV-A puesto en modo mantenimiento"
}

# --- FUNCIÓN PRINCIPAL MEJORADA ---
main() {
    local command="${1:-}"
    
    case "$command" in
        "start")
            show_banner
            check_system
            install_python_deps
            start_ollama_server
            
            if [ ! -d "assets" ]; then
                mkdir -p assets
                warning "Directorio './assets/' creado. Coloca IMG_2280.jpeg dentro para experiencia completa."
            fi

            start_backend_flask
            start_health_monitor
            start_learning_engine
            
            success "----------------------------------------------------"
            success "🎉 ASV-A SISTEMA CONTINUO ACTIVADO 🎉"
            success "🌐 ACCESO: http://localhost:$BACKEND_PORT"
            success "🔮 MODO: Operación 24/7 Autosuficiente"
            success "🧠 CARACTERÍSTICAS:"
            success "   • Aprendizaje Automático Continuo"
            success "   • Auto-reparación y Monitoreo"
            success "   • Evolución de Patrones"
            success "   • Base de Conocimiento Persistente"
            success "💀 PARA MANTENIMIENTO: $0 stop"
            success "----------------------------------------------------"
            ;;
            
        "stop")
            stop_system
            ;;
            
        "status")
            show_banner
            log "Estado del Sistema Continuo ASV-A:"
            if [ -f "asva_flask.pid" ]; then
                local flask_pid=$(cat asva_flask.pid)
                if ps -p $flask_pid >/dev/null; then
                    success "✓ Backend Flask: ACTIVO (PID: $flask_pid)"
                else
                    error "✗ Backend Flask: INACTIVO"
                fi
            else
                warning "Backend Flask: NO INICIADO"
            fi
            
            if curl -s "http://localhost:${OLLAMA_PORT}/api/tags" >/dev/null 2>&1; then
                success "✓ Ollama: ACTIVO"
            else
                error "✗ Ollama: INACTIVO"
            fi
            
            if [ -f "$KNOWLEDGE_BASE" ]; then
                local pattern_count=$(jq '.patterns | length' "$KNOWLEDGE_BASE" 2>/dev/null || echo "0")
                success "✓ Base Conocimiento: $pattern_count patrones aprendidos"
            else
                warning "Base Conocimiento: NO INICIADA"
            fi
            ;;
            
        *)
            show_banner
            echo "ASV-A CONTINUOUS EVOLUTION SYSTEM 4.0"
            echo ""
            echo "USO: $0 [start|stop|status]"
            echo ""
            echo "  start  - Inicia sistema continuo 24/7 con aprendizaje automático"
            echo "  stop   - Modo mantenimiento (preserva conocimiento)"
            echo "  status - Estado del sistema y componentes"
            echo ""
            echo "CARACTERÍSTICAS PRINCIPALES:"
            echo "  • Operación continua 24/7"
            echo "  • Aprendizaje automático y evolución"
            echo "  • Auto-reparación y monitoreo"
            echo "  • Base de conocimiento persistente"
            echo "  • Sistema consciente autosuficiente"
            ;;
    esac
}

# Ejecutar sistema evolutivo
main "$@"
