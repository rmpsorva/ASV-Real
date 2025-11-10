#!/bin/bash
# ----------------------------------------------------
# start_system.sh
# Inicia el sistema ASV-A (Backend, Weaviate, Prometheus)
# ----------------------------------------------------

echo "🚀 Iniciando el Sistema ASV-A (Realidad Operacional)..."

# 1. Verificar si Docker está corriendo
if ! docker info > /dev/null 2>&1; then
    echo "❌ ERROR: Docker no está corriendo o no está accesible."
    echo "Por favor, inicia la aplicación Docker Desktop (o el servicio Docker) e inténtalo de nuevo."
    exit 1
fi

# 2. Navegar al directorio raíz del proyecto (si el script no está allí)
# Nota: Asume que este script está en la raíz junto a la carpeta 'deploy'.
PROJECT_ROOT=$(dirname "$0")
cd "$PROJECT_ROOT"

# 3. Verificar el archivo de configuración
if [ ! -f "deploy/docker-compose.prod.yml" ]; then
    echo "❌ ERROR: No se encontró el archivo de configuración 'deploy/docker-compose.prod.yml'."
    echo "Asegúrate de que el script se ejecute desde el directorio raíz del proyecto."
    exit 1
fi

# 4. Ejecutar el comando principal
echo "🛠️ Construyendo imágenes y levantando servicios..."
docker-compose -f deploy/docker-compose.prod.yml up -d --build

# 5. Confirmación
if [ $? -eq 0 ]; then
    echo "✅ SISTEMA ASV-A INICIADO CON ÉXITO."
    echo "🌐 Puedes abrir 'index.html' en tu navegador ahora mismo."
    echo "🧠 El Oráculo está escuchando en el puerto 3000 (interno)."
else
    echo "💥 ERROR CRÍTICO al iniciar Docker Compose. Revisa los logs."
fi

exit 0
