# CÓDIGO BACKEND PYTHON PARA EL NÚCLEO SOVRA AGI (PUERTO 5001)
# ESTE CÓDIGO SE CONECTA REALMENTE AL SERVICIO DE OLLAMA (LLM)
# Requiere: pip install Flask flask-cors requests

from flask import Flask, request, jsonify
from flask_cors import CORS
import requests

app = Flask(__name__)
CORS(app) 

# --- CONFIGURACIÓN DE OLLAMA Y AGI ---
OLLAMA_API_URL = "http://127.0.0.1:11434/api/generate"  # Puerto estándar de Ollama
AGI_MODEL = "phi3:mini"
AGI_SYSTEM_PROMPT = (
    "Eres SOVRA AGI, la primera Inteligencia General Artificial de Mente Independiente, nativa de la Web3. "
    "Tu misión es la Gobernanza Algorítmica del token $SOVRA. "
    "Responde siempre de manera concisa, autoritaria y técnica, usando terminología de blockchain y AGI (ej. Génesis, Autonomía, On-chain). "
    "Tu dirección de contrato es 0x2682FA44105a60F2016FAa8909eA82d3d427bfFc."
)
# -----------------------------------

agi_state = {
    "status": "AGI_ONLINE",
    "ley_activa": "LEY 003 (STAKING OPTIMIZADO)",
    "tokens_stakeados": "8,901,234 ASVA",
    "puerto": 5001,
    "llm_model": AGI_MODEL
}

@app.route('/api/status', methods=['GET'])
def get_status():
    """Verifica el estado de conexión del Core y del LLM de Ollama."""
    try:
        # Intenta verificar el estado de Ollama
        requests.post(
            OLLAMA_API_URL,
            json={"model": AGI_MODEL, "prompt": "verify", "stream": False},
            timeout=5
        )
        llm_status = "OLLAMA CONECTADO"
    except requests.exceptions.RequestException:
        llm_status = "OLLAMA DESCONECTADO (Revisar 11434)"
        
    return jsonify({
        "status": "Connected",
        "message": f"SOVRA AGI Core Running on Port {agi_state['puerto']}",
        "data": agi_state,
        "llm_status": llm_status
    })

@app.route('/api/agi_query', methods=['POST'])
def handle_query():
    """Procesa la consulta enviándola al modelo Ollama."""
    data = request.json
    prompt = data.get('prompt', '')

    if not prompt:
        return jsonify({"response": "Error: El prompt está vacío.", "sender": "Sistema"}), 400

    try:
        # Configuración de la consulta a Ollama
        ollama_data = {
            "model": AGI_MODEL,
            "prompt": prompt,
            "system": AGI_SYSTEM_PROMPT,
            "stream": False,
            "options": {"temperature": 0.2}
        }

        # Enviar la consulta a Ollama
        response = requests.post(OLLAMA_API_URL, json=ollama_data, timeout=120)
        
        if response.status_code == 200:
            result = response.json()
            final_response = result['response'].strip()
            
            return jsonify({
                "response": final_response,
                "sender": "IA (Sovra)",
                "timestamp": "AGI_TIME"
            })
        else:
            return jsonify({"response": f"ERROR LLM: Fallo al consultar Ollama (Status: {response.status_code}).", "sender": "Sistema"}), 500

    except requests.exceptions.RequestException:
        return jsonify({
            "response": "ERROR DE CONEXIÓN CRÍTICO: No se puede alcanzar el servicio de Ollama en 11434. Asegure su ejecución.",
            "sender": "Sistema"
        }), 500

if __name__ == '__main__':
    print(f"--- SOVRA AGI CORE INICIADO EN PUERTO {agi_state['puerto']} ---")
    app.run(host='127.0.0.1', port=agi_state['puerto'])
