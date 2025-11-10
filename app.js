// app.js - Lógica Principal para la Interfaz ASV-A

// =============================================================================
// 🚀 CONFIGURACIÓN Y ESTADO REAL
// =============================================================================

// --- CONFIGURACIÓN DE BACKEND ---
const API_BASE_URL = 'http://localhost:3000/api'; // Asegúrate de que este puerto sea el correcto de tu backend
const AUTH_URL = 'http://localhost:3000/auth/token';
const WALLET_CONNECT_RPC = { 56: "https://bsc-dataseed.binance.org/" }; // BNB Smart Chain Mainnet
const ASV_A_TOKEN_ADDRESS = "0x2682FA44105a60F2016FAa8909eA82d3d427bfFc"; // Contrato de ejemplo ASV-A
const TREASURY_ADDRESS = "0x4989e248039E69A7115842d0571C4003E9991234"; // Dirección del tesoro para pagos

// ABI mínimo para tokens ERC20 (balanceOf, transfer, decimals)
const ERC20_ABI = [
    "function transfer(address to, uint amount) returns (bool)",
    "function balanceOf(address owner) view returns (uint256)",
    "function decimals() view returns (uint8)"
];

// --- ESTADO LOCAL ---
let providerWC, web3Provider, signer, account;
let asvDecimals = 18; // Valor por defecto, se actualizará al obtener el balance
let currentJWT = null; // Token JWT para autenticar llamadas al backend

// Referencias a elementos del DOM
const el = (id) => document.getElementById(id);

// Gráficos (Chart.js)
let latencyChart, ragHitsChart;

// =============================================================================
// 🔗 CONECTIVIDAD WEB3 (WALLETCÓNNECT)
// =============================================================================

async function connectWallet() {
    el('walletStatus').textContent = 'CONECTANDO...';
    el('walletStatus').style.color = 'var(--color-tertiary)';
    el('avatarFace').style.backgroundImage = 'linear-gradient(to right, var(--color-tertiary), var(--color-primary))'; // Efecto de carga
    el('avatarFace').style.animation = 'spin 1s linear infinite'; // Animación de carga

    try {
        const WalletConnectProvider = window.WalletConnectProvider.default;
        providerWC = new WalletConnectProvider({
            rpc: WALLET_CONNECT_RPC,
            chainId: 56,
            qrcode: true, 
            bridge: "https://bridge.walletconnect.org"
        });

        logCosmicEvent("🌐 Solicitando conexión a WalletConnect. Revisa tu dispositivo móvil/desktop.");
        showNotification('info', 'Conexión Wallet', 'Revisa tu Wallet Móvil/Desktop para aprobar la conexión.');
        
        await providerWC.enable();

        web3Provider = new ethers.providers.Web3Provider(providerWC);
        signer = web3Provider.getSigner();
        account = await signer.getAddress();

        // Obtener un token JWT para las llamadas al backend
        currentJWT = await getJWTToken('mobile-app'); 

        await updateWalletUI(true);
        
        providerWC.on("disconnect", (code, reason) => {
            updateWalletUI(false);
            logCosmicEvent(`❌ Sesión desconectada. Razón: ${reason || 'Usuario desconectado'}`, 'var(--color-tertiary)');
            showNotification('error', 'Wallet Desconectada', 'Tu sesión de WalletConnect ha finalizado.');
        });
        providerWC.on("accountsChanged", (accounts) => {
            account = accounts[0];
            updateWalletUI(true); // Re-renderizar UI
            logCosmicEvent(`👤 Cuenta cambiada a: ${shortenAddress(account)}`);
        });

    } catch (error) {
        const msg = error.message.includes("User closed modal") ? "Conexión cancelada por el usuario." : `Error: ${error.message}`;
        logCosmicEvent(`❌ Fallo en conexión WC: ${msg}`, 'var(--color-tertiary)');
        showNotification('error', 'Error de Conexión', msg);
        updateWalletUI(false);
    } finally {
        el('avatarFace').style.animation = 'none'; // Quitar animación de carga
    }
}

async function updateWalletUI(isConnected) {
    if (isConnected) {
        el('walletStatus').textContent = 'CONECTADO';
        el('walletStatus').style.color = 'var(--color-secondary)';
        el('connectWalletBtn').textContent = `CONECTADO: ${shortenAddress(account)}`;
        el('connectWalletBtn').disabled = true;
        el('sendTxBtn').disabled = false;
        el('avatarFace').style.backgroundImage = 'linear-gradient(to right, var(--color-primary), var(--color-secondary))';
        el('avatarFace').style.animation = 'avatar-gradient-shift 4s infinite linear, avatar-pulse 2s infinite alternate';

        await fetchASVBalance();
        await requestTokenPrice();
        logCosmicEvent(`✅ Wallet conectada: ${shortenAddress(account)}`);
        showNotification('success', 'Wallet Conectada', `Bienvenido, ${shortenAddress(account)}.`);
    } else {
        el('walletStatus').textContent = 'DESCONECTADO';
        el('walletStatus').style.color = 'var(--color-tertiary)';
        el('connectWalletBtn').textContent = 'CONECTAR';
        el('connectWalletBtn').disabled = false;
        el('sendTxBtn').disabled = true;
        el('asvBalance').textContent = '0.0000 ASV-A';
        el('asvPrice').textContent = '$0.00000000';
        el('avatarFace').style.backgroundImage = 'linear-gradient(to right, var(--color-text-dim), var(--color-background-dark))';
        el('avatarFace').style.animation = 'none'; // Detener animación
        el('avatarFace').style.boxShadow = 'none'; // Quitar brillo

        account = null;
        currentJWT = null;
    }
}

async function fetchASVBalance() {
    if (!account) return;
    try {
        const tokenContract = new ethers.Contract(ASV_A_TOKEN_ADDRESS, ERC20_ABI, web3Provider); // Usar web3Provider para leer
        const balanceBN = await tokenContract.balanceOf(account);
        const decimals = await tokenContract.decimals();
        asvDecimals = decimals;
        
        const balanceFormatted = ethers.utils.formatUnits(balanceBN, decimals);
        el('asvBalance').textContent = `${parseFloat(balanceFormatted).toFixed(4)} ASV-A`;
        logCosmicEvent(`💰 Saldo ASV-A de ${shortenAddress(account)}: ${parseFloat(balanceFormatted).toFixed(4)}`);
    } catch (e) {
        logCosmicEvent(`⚠️ Error al leer el saldo ASV-A: ${e.message.substring(0, 50)}...`, 'var(--color-tertiary)');
        el('asvBalance').textContent = 'ERROR';
    }
}

// =============================================================================
// 💰 UTILIDAD WEB3 (PAGO DE SERVICIO)
// =============================================================================

async function sendASVATransaction() {
    if (!signer || !account) { showNotification('error', 'Fallo TX', 'Wallet no conectada'); return; }

    const amountStr = el('txAmount').value;
    const recipient = el('txRecipient').value;

    if (!amountStr || isNaN(amountStr) || parseFloat(amountStr) <= 0) {
         showNotification('error', 'Monto Inválido', 'Introduce una cantidad válida.'); return;
    }
    if (!ethers.utils.isAddress(recipient)) {
        showNotification('error', 'Dirección Inválida', 'La dirección del destinatario no es válida.'); return;
    }

    el('lastTxStatus').textContent = 'FIRMANDO...';
    el('lastTxStatus').style.color = 'var(--color-tertiary)';
    
    try {
        const tokenContract = new ethers.Contract(ASV_A_TOKEN_ADDRESS, ERC20_ABI, signer); // Usar signer para escribir
        const amount = ethers.utils.parseUnits(amountStr, asvDecimals);
        
        logCosmicEvent(`📤 Solicitando firma para transferir ${amountStr} ASV-A a ${shortenAddress(recipient)}...`);
        showNotification('info', 'Revisa tu Wallet', 'Confirma la transacción en tu dispositivo.');

        const tx = await tokenContract.transfer(recipient, amount, { gasLimit: 100000 });

        logCosmicEvent(`✅ TX enviada. Hash: ${shortenAddress(tx.hash, 8)}`);
        el('lastTxStatus').textContent = 'CONFIRMANDO';
        el('lastTxHash').textContent = shortenAddress(tx.hash);
        showNotification('info', 'Transacción Enviada', `Hash: ${shortenAddress(tx.hash, 8)}`);

        const receipt = await tx.wait(); // Esperar confirmación
        
        logCosmicEvent(`🎉 TX CONFIRMADA. Bloque: ${receipt.blockNumber}.`, 'var(--color-secondary)');
        showNotification('success', 'Pago Confirmado', `Servicio activado. Hash: ${shortenAddress(tx.hash, 8)}`);
        
        el('lastTxStatus').textContent = 'COMPLETADO';
        el('lastTxStatus').style.color = 'var(--color-secondary)';
        
        await fetchASVBalance(); // Actualizar saldo después de TX

    } catch (error) {
        const msg = error.code === 4001 ? "Usuario rechazó la firma." : `Error: ${error.message.substring(0, 80)}...`;
        logCosmicEvent(`❌ FALLO TX: ${msg}`, 'var(--color-tertiary)');
        showNotification('error', 'Fallo de Transacción', msg);
        el('lastTxStatus').textContent = 'ERROR';
        el('lastTxStatus').style.color = 'var(--color-tertiary)';
    }
}

// =============================================================================
// 🧠 FUNCIONES COGNITIVAS (CONECTANDO AL BACKEND REAL)
// =============================================================================

async function getJWTToken(clientId = 'web-dashboard') {
    if (currentJWT) return currentJWT; // Reutilizar si ya tenemos uno

    try {
        const response = await fetch(AUTH_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ clientId: clientId })
        });
        if (!response.ok) throw new Error(`Error al obtener JWT: ${response.status}`);
        const data = await response.json();
        currentJWT = data.access_token;
        logCosmicEvent(`🔑 JWT obtenido para cliente: ${clientId.toUpperCase()}`);
        return currentJWT;
    } catch (error) {
        logCosmicEvent(`❌ Error fatal al obtener JWT: ${error.message}`, 'var(--color-tertiary)');
        showNotification('error', 'Error de Autenticación', 'No se pudo obtener el token de acceso.');
        throw error; // Propagar el error
    }
}

async function requestTokenPrice() {
    el('asvPrice').textContent = 'Buscando...';
    
    try {
        const jwtToken = await getJWTToken(); // Asegurar JWT
        const response = await fetch(`${API_BASE_URL}/price?contract=${ASV_A_TOKEN_ADDRESS}`, {
            headers: { 'Authorization': `Bearer ${jwtToken}` }
        });

        if (!response.ok) throw new Error(`API Status ${response.status}`);

        const data = await response.json();
        
        el('asvPrice').textContent = `$${data.price_usd.toFixed(8)} USD`;
        logCosmicEvent(`💰 PRECIO DEX: $${data.price_usd.toFixed(8)} USD (${data.source})`);

    } catch (error) {
        el('asvPrice').textContent = 'FALLO API';
        logCosmicEvent(`❌ Error en /api/price: ${error.message}`, 'var(--color-tertiary)');
    }
}

async function handleUserQuery() {
    const query = el('oracleQueryInput').value.trim();
    if (query === "") return;

    el('avatarFace').style.animation = 'avatar-pulse 0.5s infinite alternate'; // Animación más rápida
    el('oracleResponse').innerHTML = '<p><span class="loader"></span> Procesando consulta cognitiva...</p>';
    const startTime = Date.now();
    
    try {
        const jwtToken = await getJWTToken(); // Asegurar JWT
        const response = await fetch(`${API_BASE_URL}/complete`, {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${jwtToken}`
            },
            body: JSON.stringify({ prompt: query, model: 'gpt-4o-mini', inputSignal: generateRandomSignal() })
        });

        if (!response.ok) throw new Error(`API Status ${response.status}`);
        
        const data = await response.json();
        const latency = Date.now() - startTime;

        el('oracleResponse').innerHTML = `<p><strong>ASV-A:</strong> ${data.cognitive_result}</p>`;
        el('avatarFace').style.animation = 'avatar-gradient-shift 4s infinite linear, avatar-pulse 2s infinite alternate';
        
        // Actualizar gráficos
        updateChart(latencyChart, latency, 'Latencia (ms)');
        // Asumiendo que `data.context_used` es un boolean, o que la respuesta incluye un score de RAG
        updateChart(ragHitsChart, data.context_used ? 100 : 0, 'RAG Hit Rate (%)'); 
        
        logCosmicEvent(`🧠 ORÁCULO: Consulta procesada en ${latency}ms. Contexto: ${data.context_used ? 'HIT' : 'MISS'}.`);
        showNotification('info', 'Respuesta Oráculo', data.cognitive_result.substring(0, 100) + '...');
        
    } catch (error) {
        el('oracleResponse').innerHTML = `<p>❌ Error en el Oráculo: ${error.message}</p>`;
        el('avatarFace').style.animation = 'avatar-pulse 1s infinite alternate'; // Indicar error con pulso
        logCosmicEvent(`❌ Error en el Oráculo: ${error.message}`, 'var(--color-tertiary)');
        showNotification('error', 'Error Oráculo', 'Fallo al procesar la consulta cognitiva.');
    } finally {
        el('oracleQueryInput').value = '';
    }
}

// =============================================================================
// 📊 GRÁFICOS Y UTILIDADES VISUALES (Chart.js)
// =============================================================================

function initializeCharts() {
    const commonChartOptions = {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 500 },
        scales: {
            x: {
                type: 'time',
                time: { unit: 'second' },
                display: false,
                grid: { display: false }
            },
            y: {
                beginAtZero: true,
                grid: { color: 'rgba(0, 229, 255, 0.1)' },
                ticks: { color: 'var(--color-text-dim)' }
            }
        },
        plugins: {
            legend: { display: false },
            tooltip: { enabled: true }
        }
    };

    latencyChart = new Chart(el('latencyChart').getContext('2d'), {
        type: 'line',
        data: {
            datasets: [{
                label: 'Latencia (ms)',
                borderColor: 'var(--color-primary)',
                backgroundColor: 'rgba(0, 229, 255, 0.2)',
                borderWidth: 2,
                pointRadius: 3,
                data: []
            }]
        },
        options: commonChartOptions
    });

    ragHitsChart = new Chart(el('ragHitsChart').getContext('2d'), {
        type: 'bar',
        data: {
            labels: ['RAG Hit Rate'],
            datasets: [{
                label: 'Porcentaje',
                backgroundColor: 'var(--color-secondary)',
                borderColor: 'var(--color-secondary)',
                borderWidth: 1,
                data: [0]
            }]
        },
        options: {
            ...commonChartOptions,
            scales: {
                x: { display: true, ticks: { color: 'var(--color-text-dim)' }, grid: { display: false } },
                y: { beginAtZero: true, max: 100, ticks: { color: 'var(--color-text-dim)' }, grid: { color: 'rgba(0, 255, 192, 0.1)' } }
            }
        }
    });
}

function updateChart(chart, value, label) {
    if (chart.options.type === 'line') {
        chart.data.datasets[0].data.push({ x: Date.now(), y: value });
        if (chart.data.datasets[0].data.length > 20) { // Mostrar los últimos 20 puntos
            chart.data.datasets[0].data.shift();
        }
    } else if (chart.options.type === 'bar') {
        chart.data.datasets[0].data[0] = value;
    }
    chart.update();
}

// =============================================================================
// 🛠️ UTILIDADES Y LOGGING
// =============================================================================

function logCosmicEvent(message, color = 'var(--color-primary)') {
    const logElement = el('cosmicLog');
    const now = new Date();
    const timeString = now.toTimeString().split(' ')[0]; // HH:MM:SS
    
    const span = document.createElement('span');
    span.style.color = color;
    span.textContent = `\n[${timeString}] ${message}`;

    logElement.appendChild(span);
    logElement.scrollTop = logElement.scrollHeight; // Scroll automático
}

function showNotification(type, title, message) {
    const notificationArea = el('notificationArea');
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `<strong>${title}:</strong> ${message}`;
    
    notificationArea.appendChild(notification);

    setTimeout(() => {
        notification.style.opacity = '0';
        notification.style.transform = 'translateX(100%)';
        notification.addEventListener('transitionend', () => notification.remove());
    }, 6000); // Duración de la notificación
}

function shortenAddress(address, chars = 6) {
     if (!address) return 'N/A';
     const start = address.substring(0, chars + 2); 
     const end = address.substring(address.length - chars); 
     return `${start}...${end}`;
}

function generateRandomSignal() {
    // Genera un array de 4 valores para simular una señal de entrada para TensorFlow
    return Array.from({ length: 4 }, () => Math.floor(Math.random() * 100));
}

// =============================================================================
// 🏁 INICIALIZACIÓN
// =============================================================================

window.onload = () => {
    logCosmicEvent("🟢 SISTEMA ASV-A INICIADO. Preparando módulos...");
    initializeCharts();

    // Event Listeners
    el('connectWalletBtn').addEventListener('click', connectWallet);
    el('sendTxBtn').addEventListener('click', sendASVATransaction);
    el('sendQueryBtn').addEventListener('click', handleUserQuery);
    el('oracleQueryInput').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') handleUserQuery();
    });

    // Cargar el JWT inicial para operar con el backend si no hay wallet conectada
    getJWTToken().catch(err => console.error("Fallo inicial de JWT:", err));

    // Refrescar el precio cada 30 segundos
    setInterval(requestTokenPrice, 30000); 
    requestTokenPrice(); // Primera carga de precio
};
