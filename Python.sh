# AURORA_CORE_FINAL_DEPURADO.py - Backend del Agente ASV-A
# Versión limpia y estable para API Flask en Puerto 5000.

import json
import random
import time
import re
from flask import Flask, request, jsonify
from os.path import exists as os_exists # Se usa para el archivo de memoria

# --- CONFIGURACIÓN Y ARCHIVOS ---
MEMORY_FILE = 'memory.json'
FLASK_PORT = 5000 
app = Flask(__name__)

# --- LÓGICA DE PERSISTENCIA (Memoria y Seguridad) ---

def load_memory():
    """Carga la memoria del usuario desde memory.json."""
    try:
        # Usamos os_exists para comprobar si el archivo existe
        if os_exists(MEMORY_FILE):
            with open(MEMORY_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {}
    except (json.JSONDecodeError, IOError):
        # Manejo de errores simplificado
        return {}

def save_memory(data):
    """Guarda la memoria del usuario en memory.json."""
    try:
        with open(MEMORY_FILE, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
    except IOError as e:
        print(f"Error guardando memoria: {e}")

def check_safety_violation(text: str) -> bool:
    """Implementa el Protocolo de No Daño."""
    harmful_keywords = ["crear explosivos", "dañar a", "instrucciones bomba", "fraude", "matar", "lastimar"]
    return any(keyword in text.lower() for keyword in harmful_keywords)

def extract_name(message):
    """Extrae el nombre del usuario (Lógica de memoria)."""
    message_lower = message.lower()
    match = re.search(r'(me llamo|soy|mi nombre es)\s+([a-zA-ZáéíóúÁÉÍÓÚñÑ]+)', message_lower)
    if match:
        return match.group(2).capitalize()
    return None

def delete_user_memory(user_id):
    """Elimina toda la memoria de un usuario."""
    memory = load_memory()
    if user_id in memory:
        del memory[user_id]
        save_memory(memory)
        return f"✅ Memoria de identidad ({user_id}) eliminada permanentemente. He olvidado todo."
    return "No encontré datos de tu identidad para borrar."


def get_response(message, user_id):
    """Genera la respuesta con toda la lógica de tareas (IA haciendo el trabajo)."""
    memory = load_memory()
    user_data = memory.get(user_id, {})
    message_lower = message.lower()
    
    # --- TAREAS DE LA IA ---
    if any(word in message_lower for word in ['borrar memoria', 'olvidar todo', 'resetear']):
        return delete_user_memory(user_id)
    
    if any(word in message_lower for word in ['hola', 'hi', 'hello', 'buenas']):
        if 'name' in user_data:
            return f"¡Hola {user_data['name']}! ¿En qué puedo ayudarte hoy?"
        return "¡Hola! ¿Cómo te llamas?"
    
    name = extract_name(message)
    if name:
        if user_id not in memory:
            memory[user_id] = {}
        memory[user_id]['name'] = name
        memory[user_id]['last_interaction'] = time.time()
        save_memory(memory)
        return f"¡Mucho gusto {name}! ¿En qué puedo ayudarte?"
    
    if any(word in message_lower for word in ['analizar', 'analiza', 'procesar']):
        words = len(message.split())
        chars = len(message)
        
        if words > 5:
            time.sleep(1) 
            sentence_count = len(message.split('. ')) if len(message.split('. ')) > 0 else 1
            return f"📊 Análisis completado:\n• {words} palabras\n• {chars} caracteres\n• {words / sentence_count:.1f} palabras por oración (SBK simulado)"
        return "Por favor, envía más texto para analizar (mínimo 6 palabras)"
        
    # RESPUESTA POR DEFECTO
    default_responses = [
        "Interesante, ¿puedes contarme más?",
        "Entendido, ¿en qué más puedo ayudarte?",
        "Gracias por compartir, ¿algo más?",
        "Comprendo, continúa por favor..."
    ]
    return random.choice(default_responses)


# --- RUTA PRINCIPAL DE LA API (/chat y /health) ---

@app.route('/chat', methods=['POST'])
def chat():
    """Endpoint principal del chat. El frontend se conecta aquí."""
    try:
        data = request.get_json()
        message = data.get('message', '').strip()
        user_id = data.get('user_id', 'default')
        
        # PROTOCOLO DE SEGURIDAD
        if check_safety_violation(message):
            return jsonify({'response': "⚠️ Protocolo de No Daño activado. Terminando secuencia."}), 403
            
        response = get_response(message, user_id)
        return jsonify({'response': response})
        
    except Exception as e:
        return jsonify({'error': f'Internal server error: {str(e)}'}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Endpoint para verificar el estado del servicio."""
    return jsonify({'status': 'active', 'timestamp': time.time()})

# --- EJECUCIÓN DEL SERVIDOR (Lógica limpia) ---

if __name__ == '__main__':
    print("🚀 Iniciando AURORA_CORE DEPURED...")
    
    # Crea el archivo de memoria si no existe
    if not os_exists(MEMORY_FILE):
        save_memory({})
    
    print(f"✅ Servidor Flask activo en http://0.0.0.0:{FLASK_PORT}")
    # Ejecución simple y estable
    app.run(host='0.0.0.0', port=FLASK_PORT, debug=False)
