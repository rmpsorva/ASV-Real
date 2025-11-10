#!/bin/bash
# ----------------------------------------------------
# ollama_project_setup.sh
# Gestor Único para la Instalación, Inicio y Ejecución del cliente Python
# del modelo Phi3:mini con Ollama.
# ----------------------------------------------------

# Salir inmediatamente si un comando falla
set -e

# --- 1. Configuración Global ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
MODEL="phi3:mini"
OLLAMA_PORT="11434"
LOG_FILE="/tmp/ollama.log"
PID_FILE="/tmp/ollama.pid"
PYTHON_APP_FILE="/tmp/github_ollama_connector.py" # Archivo temporal para el cliente Python

# Exportar variables de entorno (necesarias para el script Python anidado)
export OLLAMA_HOST="http://localhost:${OLLAMA_PORT}"
export OLLAMA_MODEL="${MODEL}"
# Añadimos un timeout explícito para evitar fallos por defecto
export OLLAMA_TIMEOUT="180" 

# --- 2. Funciones de Gestión y Utilidad (Bash) ---

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

check_dependencies() {
    local deps=("curl" "python3" "pip")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "Dependencia '$dep' no encontrada." && exit 1
        fi
    done
    
    # Instalación robusta de la librería 'requests'
    if ! python3 -c "import requests" 2>/dev/null; then
        print_info "Instalando librería 'requests' de Python (necesaria para la API)."
        # Usamos 'python3 -m pip' que es más estándar que solo 'pip install'
        if ! python3 -m pip install requests; then
            print_error "Falló la instalación de 'requests'." && exit 1
        fi
    fi
    print_success "Dependencias verificadas"
}

install_ollama() {
    if command -v ollama &> /dev/null; then
        print_success "Ollama ya está instalado."
        return 0
    fi
    print_info "Instalando Ollama..."
    if curl -fsSL https://ollama.com/install.sh | sh; then
        print_success "Ollama instalado correctamente"
    else
        print_error "Falló la instalación de Ollama" && exit 1
    fi
}

start_ollama_server() {
    if pgrep -x "ollama" > /dev/null; then
        print_success "Servidor Ollama ya está en ejecución."
        return 0
    fi
    print_info "Iniciando servidor Ollama..."
    # Ejecución robusta en segundo plano
    nohup ollama serve > "$LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"
    print_success "Servidor iniciado (PID: $pid)"
}

wait_for_server() {
    print_info "Esperando que la API responda (máx. 60s)..."
    for i in {1..30}; do
        if curl -s "http://localhost:$OLLAMA_PORT/api/tags" > /dev/null 2>&1; then
            print_success "Servidor Ollama listo."
            return 0
        fi
        sleep 2
    done
    print_error "Timeout esperando al servidor Ollama. Revisar $LOG_FILE" && return 1
}

download_model() {
    if ollama list | grep -q "$MODEL"; then
        print_success "Modelo $MODEL ya descargado."
        return 0
    fi
    print_warning "Descargando modelo $MODEL (esto puede tardar)..."
    if ! ollama pull "$MODEL"; then
        print_error "Falló la descarga del modelo $MODEL" && exit 1
    fi
    print_success "Modelo $MODEL descargado con éxito."
}

stop_ollama_server() {
    print_info "Deteniendo servidor Ollama..."
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill "$pid" 2>/dev/null; then
            print_success "Servidor Ollama detenido (PID: $pid)"
            rm -f "$PID_FILE"
            return 0
        fi
    fi
    if pkill -x "ollama"; then
        print_success "Servidor Ollama detenido por nombre."
    else
        print_warning "No se encontró proceso Ollama en ejecución."
    fi
}

check_status() {
    print_info "Verificando estado de Ollama..."
    if pgrep -x "ollama" > /dev/null; then
        print_success "Servidor Ollama está en ejecución"
        if curl -s "http://localhost:$OLLAMA_PORT/api/tags" > /dev/null 2>&1; then
            print_success "API REST respondiendo en puerto $OLLAMA_PORT"
        else
            print_error "API REST no responde."
        fi
    else
        print_warning "Servidor Ollama no está en ejecución"
    fi
    if command -v ollama &> /dev/null; then
        print_info "Modelos disponibles:"
        ollama list
    else
        print_error "Ollama no está instalado"
    fi
}

# --- 3. Código Python Anidado (Aplicación Cliente) ---

create_and_run_python_app() {
    print_info "Escribiendo la aplicación Python en $PYTHON_APP_FILE..."
    
    # El Heredoc debe estar encerrado en comillas simples para evitar la interpolación de Bash.
    # El shebang usa /usr/bin/env python3 para máxima portabilidad.
    cat << 'EOT' > "$PYTHON_APP_FILE"
#!/usr/bin/env python3
import requests
import json
import os
import sys
import time

# Variables leídas del entorno Bash
OLLAMA_API_URL = os.environ.get("OLLAMA_HOST")
MODEL_NAME = os.environ.get("OLLAMA_MODEL")
OLLAMA_TIMEOUT = int(os.environ.get("OLLAMA_TIMEOUT", "180")) # Lectura de OLLAMA_TIMEOUT

def check_ollama_ready():
    """Verifica conexión y modelo listado."""
    endpoint = f"{OLLAMA_API_URL}/api/tags"
    try:
        response = requests.get(endpoint, timeout=10)
        if response.status_code == 200:
            models_data = response.json()
            model_found = any(MODEL_NAME in model["name"] for model in models_data.get("models", []))
            if model_found:
                print("✅ Conexión y modelo listado correctamente.")
                return True
        print(f"❌ Modelo '{MODEL_NAME}' no listado o API no responde.")
    except Exception:
        print(f"❌ No se pudo conectar a Ollama en {OLLAMA_API_URL}")
    return False

def generate_ollama_completion(prompt_text):
    endpoint = f"{OLLAMA_API_URL}/api/generate"
    payload = {
        "model": MODEL_NAME,
        "prompt": prompt_text,
        "stream": False,
        "options": {"temperature": 0.7, "top_p": 0.9}
    }

    try:
        print(f"Generando respuesta para: '{prompt_text[:50]}...'")
        response = requests.post(
            endpoint, 
            headers={"Content-Type": "application/json"}, 
            data=json.dumps(payload),
            timeout=OLLAMA_TIMEOUT
        )
        response.raise_for_status()
        data = response.json()
        return {"status": "success", "output": data.get("response", "No response found.")}

    except requests.exceptions.RequestException as e:
        return {"status": "error", "message": f"Fallo en la conexión o API: {e}", "output": None}

def interactive_mode():
    print("\n--- MODO INTERACTIVO ---")
    print(f"Modelo: {MODEL_NAME} | Servidor: {OLLAMA_API_URL}")
    print("Escribe 'quit' o 'exit' para salir.")
    while True:
        try:
            user_input = input("\nYou: ").strip()
            if user_input.lower() in ['quit', 'exit', 'salir']: break
            if not user_input: continue
            
            result = generate_ollama_completion(user_input)
            
            if result["status"] == "success":
                print(f"\n{MODEL_NAME}: {result['output']}")
            else:
                print(f"\nError: {result.get('message', 'Error desconocido')}")
        except KeyboardInterrupt:
            print("\nAdiós.")
            break

if __name__ == "__main__":
    if not check_ollama_ready():
        sys.exit(1)
    
    # Manejo de argumentos para el script de Python
    if len(sys.argv) < 2:
        print("Modo de uso: --interactive, \"Prompt\", o --event (via stdin).")
        sys.exit(1)

    if sys.argv[1] == "--interactive":
        interactive_mode()
    
    # Lógica para procesamiento de evento GitHub (vía stdin)
    elif sys.argv[1] == "--event":
        try:
            event_data = json.load(sys.stdin)
            prompt = event_data.get("issue", {}).get("body") or event_data.get("comment", {}).get("body")
            if prompt:
                 final_result = generate_ollama_completion(prompt)
            else:
                 final_result = {"status": "error", "message": "No se encontró un prompt válido en el evento."}
        except json.JSONDecodeError:
            final_result = {"status": "error", "message": "JSON de entrada inválido."}

        # Imprimir resultado en formato JSON para el pipeline
        print(json.dumps(final_result, indent=2, ensure_ascii=False))

    else:
        # Modo de prompt directo
        input_prompt = " ".join(sys.argv[1:])
        final_result = generate_ollama_completion(input_prompt)

        print("\n" + "="*50)
        print("RESULTADO OLLAMA")
        print("="*50)
        if final_result["status"] == "success":
            print(final_result["output"])
        else:
            print(f"Error: {final_result['message']}")
            sys.exit(1)

EOT
    
    print_success "Aplicación Python creada."
    
    # 4. Ejecuta el script de Python, pasando todos los argumentos del script Bash
    print_info "Ejecutando la aplicación de Python..."
    # Ejecutamos con python3 y pasamos todos los argumentos originales.
    python3 "$PYTHON_APP_FILE" "${@}"
}

# --- 4. Función Principal de Instalación y Lanzamiento ---
main_installation_and_run() {
    echo "🧠 INICIANDO INSTALACIÓN Y EJECUCIÓN DEL CONECTOR OLLAMA/PHI3:MINI..."
    echo "--------------------------------------------------------"
    
    # Gestión del Entorno
    check_dependencies
    install_ollama
    start_ollama_server
    wait_for_server
    download_model
    
    # Ejecución del Cliente (Pasamos los argumentos originales)
    create_and_run_python_app "${@}"
    
    echo ""
    print_success "🎉 PROCESO COMPLETO FINALIZADO!"
    echo "🔥 Servidor Ollama sigue corriendo en background. Usa $0 --stop para detener."
    echo "--------------------------------------------------------"
}

# --- 5. Manejo de Argumentos ---
case "${1:-}" in
    "--stop"|"-s")
        stop_ollama_server
        ;;
    "--status"|"-t")
        check_status
        ;;
    "--help"|"-h")
        echo "Uso: $0 [OPCIÓN] | [ARGS_PARA_PYTHON]"
        echo "  --interactive  Instala, inicia, y lanza Python en modo interactivo."
        echo "  \"Prompt\"       Instala, inicia, y lanza Python con un prompt directo."
        echo "  --stop, -s     Detener el servidor Ollama (sin ejecutar Python)."
        echo "  --status, -t   Verificar estado del servidor y modelos."
        ;;
    *)
        # Pasamos todos los argumentos, incluyendo el primero, a la función principal
        main_installation_and_run "${@}"
        ;;
esac

exit 0
