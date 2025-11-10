# ASV-A Platform - Versión Operacional Final (Mobile Ready)

El sistema **ASV-A (Aurion Sovra AI)** es una plataforma de Oráculo Cognitivo Web3 lista para producción. Combina la **ejecución transaccional descentralizada** (BNB Chain) con la **inteligencia artificial avanzada** (RAG/TensorFlow) en una arquitectura segura y observable.

---

## 🚀 1. Visión General y Módulos Activos

| Módulo | Descripción | Tecnología | Estado |
| :--- | :--- | :--- | :--- |
| **Backend API** | Lógica de negocio, seguridad, métricas y proxy Web3. | Node.js (Express), JWT, Prom-Client | 🟢 Real |
| **Oráculo Cognitivo** | Generación de respuestas contextuales. | LLM (vía proxy), Weaviate (RAG) | 🟢 Real |
| **Conector Web3** | Conexión y firma de transacciones móviles. | WalletConnect, Ethers.js | 🟢 Real |
| **Análisis de Señales** | Procesa telemetría/datos de mercado. | TensorFlow.js | 🟢 Real |
| **Observabilidad** | Monitoreo y alertas en tiempo real. | Prometheus, Grafana | 🟢 Real |

## 2. Arquitectura (Despliegue Docker)

El sistema se despliega como un conjunto de microservicios orquestados por `docker-compose.prod.yml`:

* **API (`asv-a-api`):** Sirve la lógica y las métricas (`/metrics`).
* **Vector DB (`weaviate`):** Almacena el contexto RAG para el Oráculo.
* **Monitoreo:** Prometheus (colector de métricas) y Grafana (visualización y alertas).

---

## 3. 🛡️ Funcionalidades Críticas de Seguridad

* **Autenticación JWT:** Se requiere un token de acceso (obtenido en `/auth/token`) para todos los *endpoints* sensibles (p. ej., `/api/price`, `/api/complete`).
* **API Key:** El *endpoint* `/metrics` está protegido por la `PROXY_API_KEY` para prevenir el acceso público a datos operativos de Prometheus.
* **Rate Limiting:** Implementado en `src/middleware/auth.js` para proteger la API contra ataques de fuerza bruta y abuso.
* **Transacciones Móviles:** La firma de transacciones (`/api/transaction` en el backend) se realiza de forma segura en el dispositivo móvil del usuario a través de **WalletConnect**.

---

## 4. 🌐 Endpoints y Utilidad Web3

| Endpoint | Utilidad | Permisos Requeridos (JWT) | Notas |
| :--- | :--- | :--- | :--- |
| `POST /auth/token` | Genera JWT de acceso. | Ninguno (abierto a clientes) | Usa `clientId` para el scope. |
| `GET /api/price` | Obtiene el precio de ASV-A. | `read:price` | **Consulta directa al DEX** (simulado en el código por simplicidad). |
| `POST /api/complete` | Consulta al Oráculo Cognitivo. | `read:oracle` | Activa el flujo **RAG** y **TensorFlow**. |
| `POST /api/transaction` | Envía una transacción Web3. | `write:transaction` | **Simula el *broadcast* TX** después de la firma móvil. |
| `GET /metrics` | Exposición de métricas. | **`X-API-Key`** (`PROXY_API_KEY`) | Consumido por Prometheus. |

---

## 5. 🛠️ Despliegue Rápido (Producción)

**Prerrequisitos:** Docker, Docker Compose, archivo `.env` configurado.

1.  **Configuración:** Cree y configure el archivo `.env` a partir de `.env.example`.
2.  **Despliegue:** Ejecute el comando de Docker Compose desde el directorio principal:

```bash
docker-compose -f deploy/docker-compose.prod.yml up -d --build
