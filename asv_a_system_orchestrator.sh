#!/bin/bash
# ===============================================================
# 🌐 ASV-A SYSTEM ORCHESTRATOR 
# FUNCIÓN: Inicia y detiene los backends de Ollama y Flask.
# ===============================================================

set -euo pipefail

# --- CONFIGURACIÓN ---
OLLAMA_PORT="11434"
FLASK_PORT="5000"
FLASK_PID_FILE="/tmp/asva_flask.pid"
OLLAMA_PID_FILE="/tmp/asva_ollama.pid"
LOG_FILE="/tmp/asva_launch.log"
FLASK_FILE="backend/asva_flask_backend.py" 

# --- COLORES ---
CYBER_BLUE='\033[0;36m'
CYBER_GREEN='\033[1;32m' 
CYBER_ORANGE='\033[0;33m'
CYBER_RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${CYBER_BLUE}🔮 $1${NC}" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "${CYBER_GREEN}⚡ $1${NC}" | tee -a "$LOG_FILE"; }
log_warn()  { echo -e "${CYBER_ORANGE}⚠️  $1${NC}" | tee -a "$LOG_FILE"; }
log_err()   { echo -e "${CYBER_RED}💥 $1${NC}" | tee -a "$LOG_FILE"; exit 1; }

# --- VERIFICACIÓN DE DEPENDENCIAS ---
check_dependencies() {
    log_info "Verificando dependencias..."
    
    if ! command -v python3 >/dev/null 2>&1; then
        log_err "Python3 no encontrado"
    fi
    if ! command -v pip3 >/dev/null 2>&1; then
        log_err "pip3 no encontrado"
    fi
    if ! command -v ollama >/dev/null 2>&1; then
        log_err "Ollama no encontrado. Ejecuta primero: ./full_asv_deployment.sh"
    fi
    
    log_ok "Dependencias verificadas"
}

# --- GESTIÓN DE OLLAMA ---
wait_ollama_ready() {
    log_info "Esperando que Ollama esté listo..."
    for i in {1..30}; do
        if curl -s "http://localhost:${OLLAMA_PORT}/api/tags" >/dev/null 2>&1; then
            log_ok "Ollama listo en puerto $OLLAMA_PORT"
            return 0
        fi
        sleep 2
    done
    log_err "Timeout: Ollama no respondió después de 60 segundos"
}

start_ollama() {
    log_info "Iniciando servidor Ollama..."
    
    if [ -f "$OLLAMA_PID_FILE" ] && ps -p "$(cat "$OLLAMA_PID_FILE")" >/dev/null 2>&1; then
        local pid=$(cat "$OLLAMA_PID_FILE")
        log_ok "Ollama ya ejecutándose (PID: $pid)"
        return 0
    fi
    
    pkill -f "ollama serve" 2>/dev/null || true
    sleep 1
    
    nohup ollama serve >> "$LOG_FILE" 2>&1 &
    local ollama_pid=$!
    echo "$ollama_pid" > "$OLLAMA_PID_FILE"
    
    log_ok "Ollama iniciado (PID: $ollama_pid)"
    wait_ollama_ready
}

stop_ollama() {
    log_info "Deteniendo Ollama..."
    if [ -f "$OLLAMA_PID_FILE" ]; then
        local pid=$(cat "$OLLAMA_PID_FILE")
        kill "$pid" 2>/dev/null || true
        rm -f "$OLLA_PID_FILE"
        log_ok "Ollama detenido"
    else
        log_warn "Ollama no estaba ejecutándose"
    fi
}

# --- GESTIÓN DE FLASK ---
install_flask_dependencies() {
    log_info "Instalando dependencias de Flask..."
    
    if ! python3 -c "import flask" 2>/dev/null; then
        pip3 install flask flask-cors requests >> "$LOG_FILE" 2>&1 || log_err "Fallo en la instalación de Flask/CORS/Requests"
        log_ok "Dependencias de Flask instaladas"
    else
        log_ok "Flask ya instalado"
    fi
}

start_flask() {
    log_info "Iniciando servidor Flask..."
    
    if [ -f "$FLASK_PID_FILE" ] && ps -p "$(cat "$FLASK_PID_FILE")" >/dev/null 2>&1; then
        local pid=$(cat "$FLASK_PID_FILE")
        log_ok "Flask ya ejecutándose (PID: $pid)"
        return 0
    fi
    
    if [ ! -f "$FLASK_FILE" ]; then
        log_err "Archivo $FLASK_FILE no encontrado. Ejecuta primero: ./full_asv_deployment.sh"
    fi
    
    nohup python3 "$FLASK_FILE" >> "$LOG_FILE" 2>&1 &
    local flask_pid=$!
    echo "$flask_pid" > "$FLASK_PID_FILE"
    
    sleep 3
    if ps -p "$flask_pid" >/dev/null 2>&1; then
        log_ok "Flask iniciado (PID: $flask_pid) en puerto $FLASK_PORT"
    else
        log_err "Fallo al iniciar Flask. Revisa: $LOG_FILE"
    fi
}

stop_flask() {
    log_info "Deteniendo Flask..."
    
    if [ -f "$FLASK_PID_FILE" ]; then
        local pid=$(cat "$FLASK_PID_FILE")
        kill "$pid" 2>/dev/null || true
        rm -f "$FLASK_PID_FILE"
        log_ok "Flask detenido"
    else
        log_warn "Flask no estaba ejecutándose"
    fi
}

# --- VERIFICACIÓN DE SERVICIOS ---
check_services() {
    log_info "Verificando estado de servicios..."
    
    if curl -s "http://localhost:${OLLAMA_PORT}/api/tags" >/dev/null 2>&1; then
        log_ok "🟢 Ollama: ACTIVO"
    else
        log_warn "🔴 Ollama: INACTIVO"
    fi
    
    if curl -s "http://localhost:${FLASK_PORT}" >/dev/null 2>&1; then
        log_ok "🟢 Flask: ACTIVO"
    else
        log_warn "🔴 Flask: INACTIVO"
    fi
}

# --- FUNCIÓN PRINCIPAL DE INICIO ---
start_system() {
    log_info "=========================================================="
    log_info "🚀 INICIANDO ORQUESTADOR WEB COGNITIVO ASV-A"
    log_info "=========================================================="
    
    echo "=== ASV-A ORCHESTRATOR LAUNCH $(date) ===" > "$LOG_FILE"
    
    check_dependencies
    install_flask_dependencies
    
    start_ollama
    start_flask
    
    check_services
    
    log_info "=========================================================="
    log_ok "¡SISTEMA COMPLETAMENTE ACTIVO! 🎉"
    log_info "=========================================================="
    log_info "🌐 OLLAMA API: http://localhost:$OLLAMA_PORT"
    log_info "🔗 FLASK API:  http://localhost:$FLASK_PORT"
    log_info "📁 INTERFAZ:   Abre 'frontend/index.html' en tu navegador"
    log_info ""
    log_info "🛑 Para detener: $0 stop"
    log_info "=========================================================="
}

# --- FUNCIÓN DE PARADA ---
stop_system() {
    log_info "=========================================================="
    log_info "🛑 DETENIENDO SISTEMA ASV-A"
    log_info "=========================================================="
    
    stop_flask
    stop_ollama
    
    log_ok "Sistema completamente detenido"
}

# --- FUNCIÓN DE ESTADO ---
show_status() {
    log_info "=========================================================="
    log_info "📊 ESTADO DEL SISTEMA ASV-A"
    log_info "=========================================================="
    
    check_services
    
    if [ -f "$OLLAMA_PID_FILE" ]; then
        log_info "Ollama PID: $(cat "$OLLAMA_PID_FILE")"
    fi
    if [ -f "$FLASK_PID_FILE" ]; then
        log_info "Flask PID:  $(cat "$FLASK_PID_FILE")"
    fi
    
    log_info "=========================================================="
}

# --- AYUDA ---
show_help() {
    echo -e "${CYBER_BLUE}"
    echo "🚀 ASV-A SYSTEM ORCHESTRATOR"
    echo -e "${NC}"
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos:"
    echo "  start     - Inicia Ollama y Flask (por defecto)"
    echo "  stop      - Detiene todos los servicios"
    echo "  status    - Muestra estado del sistema"
    echo "  restart   - Reinicia todos los servicios"
    echo "  help      - Muestra esta ayuda"
    echo ""
    echo "Nota: Asegúrate de ejecutar ./full_asv_deployment.sh primero para crear archivos"
}

# --- MAIN ---
main() {
    local command="${1:-start}"
    
    case "$command" in
        start|"")
            start_system
            ;;
        stop)
            stop_system
            ;;
        status)
            show_status
            ;;
        restart)
            stop_system
            sleep 2
            start_system
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_err "Comando desconocido: $command. Usa: $0 help"
            ;;
    esac
}

# Ejecutar función principal
main "$@"
