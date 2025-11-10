#!/usr/bin/env python3
# github_ollama_connector.py

import requests
import json
import os
import sys
import time

OLLAMA_API_URL = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
MODEL_NAME = os.environ.get("OLLAMA_MODEL", "phi3:mini")
OLLAMA_TIMEOUT = int(os.environ.get("OLLAMA_TIMEOUT", "180"))

def check_ollama_connection(max_retries=5, retry_delay=5):
    endpoint = f"{OLLAMA_API_URL}/api/tags"
    
    for attempt in range(max_retries):
        try:
            print(f"Connecting to Ollama... (Attempt {attempt + 1}/{max_retries})")
            response = requests.get(endpoint, timeout=10)
            
            if response.status_code == 200:
                print("✅ Connected to Ollama")
                return True
            else:
                print(f"Ollama response: {response.status_code}")
                
        except requests.exceptions.ConnectionError:
            print(f"Cannot connect to Ollama at {OLLAMA_API_URL}")
        except requests.exceptions.Timeout:
            print("Timeout connecting to Ollama")
        except Exception as e:
            print(f"Unexpected error: {e}")
        
        if attempt < max_retries - 1:
            print(f"Retrying in {retry_delay} seconds...")
            time.sleep(retry_delay)
    
    return False

def ensure_model_available():
    try:
        response = requests.get(f"{OLLAMA_API_URL}/api/tags", timeout=30)
        if response.status_code == 200:
            models_data = response.json()
            available_models = [model["name"] for model in models_data.get("models", [])]
            
            model_found = any(MODEL_NAME in model for model in available_models)
            
            if model_found:
                print(f"✅ Model '{MODEL_NAME}' found")
                return True
            else:
                print(f"Downloading model '{MODEL_NAME}'...")
                return pull_model()
        
        return False
        
    except Exception as e:
        print(f"Error checking models: {e}")
        return False

def pull_model():
    endpoint = f"{OLLAMA_API_URL}/api/pull"
    payload = {
        "name": MODEL_NAME,
        "stream": False
    }
    
    try:
        print(f"Downloading model '{MODEL_NAME}'... This may take several minutes.")
        response = requests.post(
            endpoint,
            headers={"Content-Type": "application/json"},
            data=json.dumps(payload),
            timeout=300
        )
        
        if response.status_code == 200:
            print(f"✅ Model '{MODEL_NAME}' downloaded successfully")
            return True
        else:
            print(f"Error downloading model: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"Error during model download: {e}")
        return False

def initialize_ollama():
    print("Initializing Ollama connection...")
    
    if not check_ollama_connection():
        print("Failed to connect to Ollama")
        return False
    
    if not ensure_model_available():
        print("Failed to ensure model availability")
        return False
    
    print("Ollama is ready!")
    return True

def generate_ollama_completion(prompt_text):
    endpoint = f"{OLLAMA_API_URL}/api/generate"
    
    payload = {
        "model": MODEL_NAME,
        "prompt": prompt_text,
        "stream": False,
        "options": {
            "temperature": 0.7,
            "top_p": 0.9,
        }
    }

    try:
        print(f"Generating response for: '{prompt_text[:50]}...'")
        response = requests.post(
            endpoint, 
            headers={"Content-Type": "application/json"}, 
            data=json.dumps(payload),
            timeout:OLLAMA_TIMEOUT
        )
        response.raise_for_status()
        
        data = response.json()
        
        return {
            "status": "success",
            "output": data.get("response", "No response found."),
            "model": data.get("model", MODEL_NAME),
            "total_duration": data.get("total_duration"),
            "prompt_eval_count": data.get("prompt_eval_count"),
            "eval_count": data.get("eval_count")
        }

    except requests.exceptions.RequestException as e:
        return {
            "status": "error",
            "message": f"Ollama connection failed: {e}",
            "output": None
        }

def process_github_event(event_data):
    # Intentar extraer el prompt de varios lugares: comentario, cuerpo de issue, título.
    prompt = event_data.get("comment", {}).get("body")
    if not prompt:
        prompt = event_data.get("issue", {}).get("body")
    if not prompt:
        prompt = event_data.get("pull_request", {}).get("body")
    if not prompt:
        prompt = event_data.get("issue", {}).get("title")
    
    if not prompt or len(prompt.strip()) < 10:
        return {
            "status": "error", 
            "message": "No valid prompt found in GitHub event."
        }

    print(f"Received GitHub prompt: '{prompt[:100]}...'")
    
    result = generate_ollama_completion(prompt)

    if result["status"] == "success":
        print(f"Response generated successfully ({result.get('eval_count', 0)} tokens)")
    else:
        print(f"Error generating response: {result.get('message')}")

    return result

def interactive_mode():
    print("\nInteractive Mode - Ollama Test")
    print("Type 'quit' or 'exit' to exit")
    print("-" * 50)
    
    while True:
        try:
            user_input = input("\nYou: ").strip()
            
            if user_input.lower() in ['quit', 'exit', 'salir']:
                break
                
            if not user_input:
                continue
                
            result = generate_ollama_completion(user_input)
            
            if result["status"] == "success":
                print(f"\n{MODEL_NAME}: {result['output']}")
            else:
                print(f"\nError: {result.get('message', 'Unknown error')}")
                
        except KeyboardInterrupt:
            print("\nGoodbye!")
            break
        except Exception as e:
            print(f"\nUnexpected error: {e}")

if __name__ == "__main__":
    if not initialize_ollama():
        print("Failed to initialize Ollama. Exiting...")
        sys.exit(1)
    
    if len(sys.argv) < 2:
        print(f"Usage: python {sys.argv[0]} \"Text for model\"")
        print("   or: cat event.json | python {sys.argv[0]} --event")
        print("   or: python {sys.argv[0]} --interactive")
        sys.exit(1)

    if sys.argv[1] == "--event":
        try:
            event_data = json.load(sys.stdin)
            final_result = process_github_event(event_data)
        except json.JSONDecodeError:
            final_result = {"status": "error", "message": "Invalid JSON input."}
    
    elif sys.argv[1] == "--interactive":
        interactive_mode()
        sys.exit(0)
        
    else:
        input_prompt = " ".join(sys.argv[1:])
        final_result = generate_ollama_completion(input_prompt)

    print("\n" + "="*50)
    print("OLLAMA RESULT")
    print("="*50)
    print(json.dumps(final_result, indent=2, ensure_ascii=False))
