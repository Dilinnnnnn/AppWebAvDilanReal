'use strict';
//=====================================================================
//  capturas_practica.js  -  Capturas de la practica (PoliMusic)
//---------------------------------------------------------------------
//  Abre Edge headless, inicia sesion con cada usuario y guarda:
//    captura_practica_usuario.png  ->  Dilan.Real  (nombre.apellido)
//    captura_practica_admin.png    ->  userAdmin   (rol ADMIN con CRUD)
//  Requisito: el sitio levantado en http://localhost:8080
//  Uso:  node tools/capturas_practica.js
//=====================================================================

const { spawn } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const EDGE_CANDIDATOS = [
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe'
];
const EDGE = EDGE_CANDIDATOS.find(p => fs.existsSync(p));
if (!EDGE) { console.error('No se encontro msedge.exe'); process.exit(1); }

const PUERTO_CDP = 9222;
const BASE = 'http://localhost:8080';
const RAIZ = path.join(__dirname, '..');
const PERFIL = path.join(os.tmpdir(), 'pm-cdp-perfil-' + Date.now());
fs.mkdirSync(PERFIL, { recursive: true });

const espera = ms => new Promise(r => setTimeout(r, ms));

async function jsonHttp(url, intentos) {
  for (let i = 0; i < intentos; i++) {
    try {
      const r = await fetch(url);
      if (r.ok) return await r.json();
    } catch (e) { /* reintentar */ }
    await espera(500);
  }
  throw new Error('No responde ' + url);
}

function conectarCDP(wsUrl) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(wsUrl);
    const pendientes = new Map();
    let siguiente = 1;
    ws.addEventListener('message', ev => {
      const msg = JSON.parse(ev.data);
      if (msg.id && pendientes.has(msg.id)) {
        const p = pendientes.get(msg.id);
        pendientes.delete(msg.id);
        if (msg.error) p.reject(new Error(msg.error.message)); else p.resolve(msg.result);
      }
    });
    ws.addEventListener('open', () => resolve({
      enviar(method, params) {
        return new Promise((res, rej) => {
          const id = siguiente++;
          pendientes.set(id, { resolve: res, reject: rej });
          ws.send(JSON.stringify({ id, method, params: params || {} }));
        });
      }
    }));
    ws.addEventListener('error', () => reject(new Error('WebSocket CDP error')));
  });
}

async function esperarPagina(cdp, expresion, timeoutMs) {
  const limite = Date.now() + (timeoutMs || 15000);
  while (Date.now() < limite) {
    const r = await cdp.enviar('Runtime.evaluate', { expression: expresion, returnByValue: true });
    if (r.result && r.result.value) return true;
    await espera(350);
  }
  return false;
}

async function capturar(cdp, usuario, clave, archivo, opciones) {
  opciones = opciones || {};
  console.log('-> Entrando como ' + usuario + ' ...');
  await cdp.enviar('Page.navigate', { url: BASE + '/login.asp' });
  await espera(1200);

  const relleno = await cdp.enviar('Runtime.evaluate', {
    expression: `(function(){
      var u = document.getElementById('usuario');
      var c = document.getElementById('clave');
      if (!u || !c) return 'sin-formulario';
      u.value = ${JSON.stringify(usuario)};
      c.value = ${JSON.stringify(clave)};
      u.dispatchEvent(new Event('input', {bubbles:true}));
      c.dispatchEvent(new Event('input', {bubbles:true}));
      document.getElementById('btnEntrar').click();
      return 'ok';
    })()`,
    returnByValue: true
  });
  if (!relleno.result || relleno.result.value !== 'ok') {
    throw new Error('No se encontro el formulario de login');
  }

  const ok = await esperarPagina(cdp, "document.location.pathname.indexOf('songs.asp') >= 0", 20000);
  if (!ok) throw new Error('No se pudo iniciar sesion como ' + usuario);
  await espera(2500);   // que carguen imagenes, estilos y reproductor

  if (opciones.scroll) {
    await cdp.enviar('Runtime.evaluate', { expression: 'window.scrollTo(0, ' + opciones.scroll + ')' });
    await espera(900);
  }

  const shot = await cdp.enviar('Page.captureScreenshot', {
    format: 'png',
    captureBeyondViewport: !!opciones.completa
  });
  fs.writeFileSync(path.join(RAIZ, archivo), Buffer.from(shot.data, 'base64'));
  console.log('   Guardada: ' + archivo);

  await cdp.enviar('Page.navigate', { url: BASE + '/logout.asp' });
  await espera(1200);
}

async function main() {
  const args = [
    '--headless=new',
    '--remote-debugging-port=' + PUERTO_CDP,
    '--user-data-dir=' + PERFIL,
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-extensions',
    '--disable-gpu',
    '--window-size=1600,1000',
    '--host-resolver-rules=MAP localhost 127.0.0.1:8080',
    'about:blank'
  ];
  console.log('Lanzando Edge headless...');
  const proc = spawn(EDGE, args, { detached: true, stdio: 'ignore' });
  try {
    const objetivos = await jsonHttp('http://127.0.0.1:' + PUERTO_CDP + '/json/list', 40);
    const pagina = objetivos.find(t => t.type === 'page');
    if (!pagina) throw new Error('CDP no devolvio target de pagina');
    const cdp = await conectarCDP(pagina.webSocketDebuggerUrl);
    await cdp.enviar('Page.enable');
    await cdp.enviar('Runtime.enable');

    // 1) Usuario normal: nombre.apellido visible en el mensaje de bienvenida
    await capturar(cdp, 'Dilan.Real', '12345678', 'captura_practica_usuario.png', { scroll: 0 });
    // 2) Rol admin: ve el CRUD completo de canciones
    await capturar(cdp, 'userAdmin', '12345678', 'captura_practica_admin.png', { scroll: 260 });
    console.log('Listo, las dos capturas estan guardadas.');
  } finally {
    try { process.kill(-proc.pid); } catch (e) { try { proc.kill(); } catch (e2) {} }
    try { fs.rmSync(PERFIL, { recursive: true, force: true }); } catch (e) {}
  }
}

main().catch(e => { console.error('ERROR: ' + e.message); process.exit(1); });
