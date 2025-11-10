#!/usr/bin/env bash
# ==============================================================
# ASV-A_Universal_Cognitive_System.sh
# Single-file bootstrapper / Orquestador todo-en-uno
# Crea backend (Flask), frontend (HTML/CSS/JS), instala dependencias,
# y lanza servicios mínimos. Bilingüe: Español / English.
# ==============================================================

set -euo pipefail

# ---------- CONFIG ----------
PROJECT_DIR="${PWD}/ASV-A-AURION-COVRA-AI"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"
FLASK_FILE="$BACKEND_DIR/asva_flask_backend.py"
INDEX_FILE="$FRONTEND_DIR/index.html"
APP_JS="$FRONTEND_DIR/app.js"
STYLE_CSS="$FRONTEND_DIR/style.css"

# Ports and files
FLASK_PORT="${FLASK_PORT:-5000}"
FRONTEND_PORT="${FRONTEND_PORT:-8000}"   # static file server (simple)
FLASK_PID_FILE="/tmp/asva_flask.pid"
FRONTEND_PID_FILE="/tmp/asva_frontend.pid"
LOG_FILE="/tmp/asva_universal.log"

OLLAMA_CMD="$(command -v ollama || true)"  # may be empty if not installed

# Colors
GREEN='\033[1;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

log()    { echo -e "${CYAN}🔮 $*${NC}" | tee -a "$LOG_FILE"; }
logok()  { echo -e "${GREEN}✅ $*${NC}" | tee -a "$LOG_FILE"; }
logerr() { echo -e "${RED}✖ $*${NC}" | tee -a "$LOG_FILE"; }

# ---------- HELP / AYUDA ----------
show_help() {
cat <<'EOF'
ASV-A Universal Cognitive System - Single-file orchestrator
Uso / Usage:
  ./ASV-A_Universal_Cognitive_System.sh start   # Crea archivos, instala deps y arranca servicios
  ./ASV-A_Universal_Cognitive_System.sh stop    # Detiene servicios y limpia PIDs
  ./ASV-A_Universal_Cognitive_System.sh status  # Muestra estado
  ./ASV-A_Universal_Cognitive_System.sh help    # Esta ayuda

Nota:
 - En Windows usar WSL o Git Bash. / On Windows use WSL or Git Bash.
 - Ollama: si lo tienes instalado, el script intentará detectar su presencia.
EOF
}

# ---------- CREATE FILES ----------
create_structure() {
    log "Creando estructura de proyecto / Creating project structure..."
    mkdir -p "$BACKEND_DIR" "$FRONTEND_DIR"
}

create_backend() {
    log "Escribiendo backend Flask / Writing Flask backend..."
    cat > "$FLASK_FILE" <<PY
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ASV-A Flask Backend (bilingual comments)
Receives frontend prompt and forwards to Ollama (if available).
If Ollama is not present, returns a mocked response for local testing.
"""
import os, requests, json
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

OLLAMA_API = os.getenv("OLLAMA_HOST", "http://localhost:11434")
MODEL_NAME = os.getenv("OLLAMA_MODEL", "phi3:mini")
TIMEOUT = int(os.getenv("OLLAMA_TIMEOUT", "30"))

@app.route("/api/query", methods=["POST"])
def ollama_generate():
    data = request.json or {}
    prompt = data.get("prompt", "")
    if not prompt:
        return jsonify({"error": "No se recibió un prompt válido / Invalid prompt."}), 400

    # If Ollama available, forward; otherwise return a local mock response
    try:
        # Try to call Ollama
        resp = requests.post(f"{OLLAMA_API}/api/generate", json={
            "model": data.get("model", MODEL_NAME),
            "prompt": prompt,
            "stream": False
        }, timeout=TIMEOUT)
        resp.raise_for_status()
        return jsonify(resp.json()), 200
    except requests.exceptions.RequestException as e:
        # Fallback mock reply for local dev
        mock = {
            "response": f"[MOCK RESPONSE] ASV-A (local): He recibido tu prompt: {prompt}",
            "meta": {"note": "Ollama no disponible, respuesta simulada / Ollama not available, mock response"}
        }
        return jsonify(mock), 200

@app.route("/api/ping", methods=["GET"])
def ping():
    return jsonify({"status": "ok", "service": "ASV-A Flask backend"}), 200

if __name__ == "__main__":
    port = int(os.getenv("FLASK_PORT", "5000"))
    print(f"ASV-A Flask backend running on port {port}")
    app.run(host="0.0.0.0", port=port)
PY
    chmod +x "$FLASK_FILE"
    logok "Backend creado: $FLASK_FILE"
}

create_frontend() {
    log "Escribiendo frontend (HTML/JS/CSS) / Writing frontend files..."

    cat > "$INDEX_FILE" <<'HTML'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>ASV-A AURION COVRA AI — Cognitive Operating System</title>
  <link href="style.css" rel="stylesheet">
  <script>window.ASVA_FLASK_ENDPOINT = "http://localhost:5000/api/query";</script>
</head>
<body>
  <div class="system-container">
    <header>
      <h1>ASV-A AURION COVRA AI</h1>
      <p class="subtitle">Oráculo de Realidad Web3 — Cognitive Operating System</p>
    </header>

    <main class="main-grid">
      <section class="left-panel">
        <h3>Estado / Status</h3>
        <div>POWER: <span id="power">ONLINE</span></div>
        <div>WALLET: <span id="walletStatus">DESCONECTADO / DISCONNECTED</span></div>
        <div>SALDO ASV-A: <span id="asvBalance">0.0000 ASV-A</span></div>
      </section>

      <section class="center-panel">
        <div class="avatar">
          <div class="avatar-face"><div class="holo"></div></div>
          <div class="avatar-title">ORÁCULO ASV-A</div>
          <p class="avatar-sub">"SOY CAPAZ DE HABLAR, COMPRENDER Y AYUDAR" / "I CAN SPEAK, UNDERSTAND & HELP"</p>
        </div>

        <div class="chat-area">
          <div id="chat-container" class="chat-container">
            <div class="assistant-message">[00:00:00] 🟢 SISTEMA ASV-A INICIADO. Esperando comandos...</div>
          </div>
          <div class="input-row">
            <input id="user-input" placeholder="Escribe tu consulta..." />
            <button id="send-button">SEND</button>
          </div>
        </div>
      </section>

      <section class="right-panel">
        <h3>UTILIDADES WEB3</h3>
        <div>PAGO DE SERVICIO (simulado)</div>
        <input id="txAmount" placeholder="Cantidad ASV-A" type="number" />
        <button id="sendTxBtn" disabled>FIRMAR Y PAGAR (simulado)</button>
      </section>
    </main>

    <footer>
      <small>ASV-A — Local Dev Mode. / Modo desarrollo local.</small>
    </footer>
  </div>

  <script src="app.js"></script>
</body>
</html>
HTML

    cat > "$APP_JS" <<'JS'
// app.js - Minimal logic to talk to Flask backend (bilingual messages)
class AurionAI {
  constructor() {
    this.API = window.ASVA_FLASK_ENDPOINT || "http://localhost:5000/api/query";
    this.init();
  }
  init() {
    document.getElementById('send-button').addEventListener('click', () => this.send());
    document.getElementById('user-input').addEventListener('keypress', (e) => {
      if (e.key === 'Enter') this.send();
    });
    console.log("ASV-A Frontend initialized. / Frontend inicializado.");
  }
  appendMsg(role, text) {
    const c = document.getElementById('chat-container');
    const d = document.createElement('div');
    d.className = (role === 'user') ? 'user-message' : 'assistant-message';
    d.innerHTML = text.replace(/\n/g,'<br>');
    c.appendChild(d);
    c.scrollTop = c.scrollHeight;
  }
  async send() {
    const el = document.getElementById('user-input');
    const prompt = (el.value || "").trim();
    if (!prompt) return;
    el.value = '';
    this.appendMsg('user', prompt);
    this.appendMsg('assistant', '... generando respuesta / generating response ...');
    try {
      const res = await fetch(this.API, {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({prompt: prompt})
      });
      const data = await res.json();
      // If Ollama returned structured result try to extract a response field, otherwise show JSON
      let text = "";
      if (data.response) text = data.response;
      else if (data.output && Array.isArray(data.output) && data.output.length) text = JSON.stringify(data.output);
      else text = JSON.stringify(data);
      // remove last "generating" placeholder
      const c = document.getElementById('chat-container');
      const last = c.lastElementChild;
      if (last && last.textContent.includes('generando')) last.remove();
      this.appendMsg('assistant', text);
    } catch (e) {
      this.appendMsg('assistant', '🔌 Error de conexión / Connection error: ' + String(e));
    }
  }
}
window.aurionAI = new AurionAI();
JS

    cat > "$STYLE_CSS" <<'CSS'
:root {
  --bg: #0a0a1f;
  --accent: #00E5FF;
  --accent2: #00FFC0;
  --text: #e0ffff;
}
body{font-family:monospace;background:radial-gradient(circle,#1a1a3a,#0a0a1f);color:var(--text);margin:0;padding:20px}
.system-container{max-width:1100px;margin:0 auto;border:1px solid rgba(0,229,255,0.08);padding:18px;border-radius:10px;box-shadow:0 0 40px rgba(0,229,255,0.06)}
header h1{font-family:Orbitron,monospace;color:var(--accent);margin:0}
.main-grid{display:grid;grid-template-columns:1fr 1.4fr 1fr;gap:18px;margin-top:16px}
.panel-like{background:rgba(10,10,30,0.8);padding:12px;border-radius:8px}
.left-panel,.right-panel{background:rgba(5,5,15,0.7);padding:12px;border-radius:8px}
.center-panel{background:rgba(2,2,8,0.5);padding:12px;border-radius:8px;display:flex;flex-direction:column;align-items:center}
.avatar-face{width:140px;height:140px;border-radius:50%;border:3px solid rgba(0,255,192,0.15);display:flex;align-items:center;justify-content:center;margin:12px}
.holo{width:70%;height:70%;border-radius:50%;background:radial-gradient(circle,#00E5FF,#002233);animation:spin 6s linear infinite}
@keyframes spin{from{transform:rotate(0)}to{transform:rotate(360deg)}}
.chat-container{background:rgba(0,0,0,0.6);padding:12px;border-radius:8px;width:100%;max-height:300px;overflow:auto}
.input-row{display:flex;gap:8px;margin-top:8px}
input#user-input{flex:1;padding:8px;border-radius:6px;border:1px solid rgba(0,229,255,0.12);background:transparent;color:var(--text)}
button{padding:8px 12px;border-radius:6px;border:0;background:var(--accent);color:#001}
.user-message{align-self:flex-end;background:rgba(0,150,255,0.12);padding:8px;border-radius:6px;margin:6px 0}
.assistant-message{align-self:flex-start;background:rgba(0,255,136,0.06);padding:8px;border-radius:6px;margin:6px 0;color:var(--accent2)}
@media(max-width:900px){.main-grid{grid-template-columns:1fr}}
CSS

    logok "Frontend creado en: $FRONTEND_DIR"
}

# ---------- DEPENDENCIES ----------
install_deps() {
    # Try create venv and install Flask, flask-cors, requests
    log "Verificando python3 / Checking python3..."
    if ! command -v python3 >/dev/null 2>&1; then
        logerr "python3 no encontrado. Instala Python 3.9+ / python3 not found. Install Python 3.9+"
        exit 1
    fi

    # Create venv inside project (isolated)
    if [ ! -d "$PROJECT_DIR/.venv" ]; then
        log "Creando virtualenv / Creating venv..."
        python3 -m venv "$PROJECT_DIR/.venv"
    fi
    # Activate and pip install
    # shellcheck disable=SC1090
    source "$PROJECT_DIR/.venv/bin/activate"
    pip install --upgrade pip >/dev/null
    pip install flask flask-cors requests >/dev/null
    deactivate
    logok "Dependencias Python instaladas / Python dependencies installed"
}

# ---------- START / STOP SERVICES ----------
start_flask() {
    if [ -f "$FLASK_PID_FILE" ] && ps -p "$(cat "$FLASK_PID_FILE")" >/dev/null 2>&1; then
        log "Flask ya está corriendo / Flask already running"
        return
    fi
    log "Iniciando Flask backend en puerto $FLASK_PORT / Starting Flask backend..."
    source "$PROJECT_DIR/.venv/bin/activate"
    (cd "$BACKEND_DIR" && FLASK_PORT="$FLASK_PORT" FLASK_APP="$FLASK_FILE" python3 "$FLASK_FILE" > /tmp/asva_flask.out 2>&1 & echo $! > "$FLASK_PID_FILE")
    sleep 1
    if ps -p "$(cat "$FLASK_PID_FILE")" >/dev/null 2>&1; then
        logok "Flask iniciado (PID $(cat $FLASK_PID_FILE))"
    else
        logerr "Error al iniciar Flask. Revisa /tmp/asva_flask.out"
    fi
    deactivate || true
}

start_frontend_server() {
    # Simple static server: use Python http.server on FRONTEND_PORT
    if [ -f "$FRONTEND_PID_FILE" ] && ps -p "$(cat "$FRONTEND_PID_FILE")" >/dev/null 2>&1; then
        log "Servidor frontal ya está corriendo / Frontend server already running"
        return
    fi
    log "Iniciando servidor estático en puerto $FRONTEND_PORT / Starting static server..."
    (cd "$FRONTEND_DIR" && python3 -m http.server "$FRONTEND_PORT" > /tmp/asva_frontend.out 2>&1 & echo $! > "$FRONTEND_PID_FILE")
    sleep 1
    if ps -p "$(cat "$FRONTEND_PID_FILE")" >/dev/null 2>&1; then
        logok "Frontend servido en http://localhost:$FRONTEND_PORT (PID $(cat $FRONTEND_PID_FILE))"
    else
        logerr "No se pudo iniciar el servidor estático. Revisa /tmp/asva_frontend.out"
    fi
}

start_ollama_info() {
    if [ -n "$OLLAMA_CMD" ]; then
        logok "Detectado Ollama en el sistema: $OLLAMA_CMD"
        log "Nota: Este script NO intenta instalar Ollama automaticamente. / This script does NOT auto-install Ollama."
        log "Si quieres que el orquestador arranque Ollama, instala Ollama y ajusta el script. / To auto-start Ollama, install it and modify the orchestrator."
    else
        log "Ollama no detectado. Las llamadas a /api/generate usarán mock si Ollama no está disponible."
    fi
}

stop_all() {
    log "Deteniendo servicios / Stopping services..."
    if [ -f "$FLASK_PID_FILE" ]; then
        PID="$(cat "$FLASK_PID_FILE")"
        if ps -p "$PID" >/dev/null 2>&1; then
            kill "$PID" && logok "Flask detenido (PID $PID)"
        fi
        rm -f "$FLASK_PID_FILE"
    fi
    if [ -f "$FRONTEND_PID_FILE" ]; then
        PID="$(cat "$FRONTEND_PID_FILE")"
        if ps -p "$PID" >/dev/null 2>&1; then
            kill "$PID" && logok "Frontend server detenido (PID $PID)"
        fi
        rm -f "$FRONTEND_PID_FILE"
    fi
    logok "Servicios detenidos / Services stopped."
}

status() {
    echo "---- ASV-A Status ----"
    if [ -f "$FLASK_PID_FILE" ] && ps -p "$(cat "$FLASK_PID_FILE")" >/dev/null 2>&1; then
        echo "Flask: running (PID $(cat "$FLASK_PID_FILE"))"
    else
        echo "Flask: stopped"
    fi
    if [ -f "$FRONTEND_PID_FILE" ] && ps -p "$(cat "$FRONTEND_PID_FILE")" >/dev/null 2>&1; then
        echo "Frontend server: running (PID $(cat "$FRONTEND_PID_FILE")) - http://localhost:$FRONTEND_PORT"
    else
        echo "Frontend server: stopped"
    fi
    if [ -n "$OLLAMA_CMD" ]; then
        echo "Ollama: detected at $OLLAMA_CMD (not auto-started)"
    else
        echo "Ollama: not detected"
    fi
    echo "Project dir: $PROJECT_DIR"
    echo "Log: $LOG_FILE"
}

# ---------- MAIN ----------
COMMAND="${1:-start}"

case "$COMMAND" in
    start)
        log "Iniciando / Starting ASV-A Universal System..."
        create_structure
        create_backend
        create_frontend
        install_deps
        start_ollama_info
        start_flask
        start_frontend_server
        logok "LISTO: Frontend -> http://localhost:$FRONTEND_PORT  |  Backend -> http://localhost:$FLASK_PORT/api/query"
        log "Abre el navegador y visita la URL / Open your browser and go to the URL above."
        ;;
    stop)
        stop_all
        ;;
    status)
        status
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo "Comando inválido / Invalid command: $COMMAND"
        show_help
        exit 1
        ;; te
esac
