// Smoke test completo para PoliMusic (classic ASP)
// Uso: node tools/smoke.js
const BASE = 'http://localhost:8080';

let cookieJar = '';
const results = [];
let passed = 0, failed = 0;

function log(name, ok, detail) {
    const status = ok ? 'PASS' : 'FAIL';
    if (ok) passed++; else failed++;
    results.push(`[${status}] ${name}${detail ? ' -> ' + detail : ''}`);
    console.log(`[${status}] ${name}${detail ? ' -> ' + String(detail).substring(0, 200) : ''}`);
}

function req(method, path, body, redirect) {
    return fetch(BASE + path, {
        method,
        headers: {
            'Cookie': cookieJar,
            ...(body ? { 'Content-Type': 'application/x-www-form-urlencoded' } : {})
        },
        body: body || undefined,
        redirect: redirect === false ? 'manual' : 'manual'
    }).then(async res => {
        const sc = res.headers.get('set-cookie');
        if (sc) {
            const aspsess = sc.match(/ASPSESSION[A-Z]+=[^;]+/);
            if (aspsess) {
                // reemplazar la cookie de sesion previa
                cookieJar = cookieJar.replace(/ASPSESSION[A-Z]+=[^;]+; ?/g, '');
                cookieJar += (cookieJar ? '; ' : '') + aspsess[0];
            }
        }
        const text = await res.text();
        return { status: res.status, location: res.headers.get('location'), text };
    });
}

const qs = o => Object.entries(o).map(([k, v]) => encodeURIComponent(k) + '=' + encodeURIComponent(v)).join('&');

(async () => {
    // ---------- 1. Paginas publicas / login ----------
    try {
        let r = await req('GET', '/login.asp');
        log('login.asp responde 200', r.status === 200, 'HTTP ' + r.status);
        log('login.asp muestra formulario', /<form/i.test(r.text) && /name="usuario"/i.test(r.text));
        log('login.asp tiene cuentas demo', /userAdmin/i.test(r.text) && /userNormal/i.test(r.text));
    } catch (e) { log('login.asp', false, e.message); }

    // sin sesion, songs.asp debe redirigir a login
    try {
        let r = await req('GET', '/songs.asp');
        log('songs.asp sin sesion redirige a login', r.status === 302 || r.status === 301, 'HTTP ' + r.status + ' ' + (r.location || ''));
    } catch (e) { log('songs.asp sin sesion', false, e.message); }

    // ---------- 2. Login admin ----------
    try {
        let r = await req('POST', '/login.asp', qs({ usuario: 'userAdmin', clave: '12345678', volver: '' }));
        log('POST login.asp OK', r.status === 200 || r.status === 302, 'HTTP ' + r.status + ' ' + (r.location || ''));
    } catch (e) { log('POST login.asp', false, e.message); }

    // ---------- 3. default.asp ----------
    try {
        let r = await req('GET', '/default.asp');
        log('default.asp redirige a songs', (r.status === 302) && /songs\.asp/i.test(r.location || ''), 'HTTP ' + r.status + ' ' + (r.location || ''));
    } catch (e) { log('default.asp', false, e.message); }

    // ---------- 4. songs.asp (Song List) ----------
    try {
        let r = await req('GET', '/songs.asp');
        log('songs.asp responde 200', r.status === 200, 'HTTP ' + r.status);
        const tieneSongList = /Song\s*List/i.test(r.text);
        log('songs.asp contiene "Song List"', tieneSongList);
        const m = r.text.match(/Bienvenido,\s*<\/?[^>]*>?\s*([^<,]+)/i);
        log('songs.asp muestra bienvenida con usuario', /Bienvenido/i.test(r.text), r.text.match(/Bienvenido[^<]*<?[^>]*>?([^<]{0,40})/i)?.[1]);
        log('songs.asp muestra rol admin', /admin/i.test(r.text));
        const filas = (r.text.match(/class="fila-cancion/g) || []).length;
        log('songs.asp lista canciones', filas >= 5, filas + ' filas');
        log('songs.asp tiene boton Nueva cancion (admin)', /Nueva\s*canci/i.test(r.text));
        log('songs.asp tiene reproductor audio', /<audio[^>]+id="audio"/i.test(r.text));
        const duraciones = (r.text.match(/\d+:\d{2}/g) || []).length;
        log('songs.asp calcula duraciones', duraciones >= 5, duraciones + ' duraciones');
    } catch (e) { log('songs.asp', false, e.message); }

    // ---------- 5. Play count ----------
    try {
        let r = await req('GET', '/play_count.asp?id=1');
        let json = null;
        try { json = JSON.parse(r.text); } catch (e) { }
        log('play_count.asp devuelve JSON', !!(json && json.ok === true), r.text.substring(0, 120));
    } catch (e) { log('play_count.asp', false, e.message); }

    // ---------- 6. CRUD admin ----------
    let nuevoId = null;
    try {
        // formulario
        let r = await req('GET', '/song_form.asp');
        log('song_form.asp responde 200 (admin)', r.status === 200, 'HTTP ' + r.status);
        log('song_form.asp tiene campos', /name="nombre"/i.test(r.text) && /name="ruta"/i.test(r.text));

        // crear
        const nombre = 'Prueba Humo ' + Date.now().toString().slice(-5);
        r = await req('POST', '/song_save.asp', qs({ nombre: nombre, ruta: '~/SongFiles/bensound-scifi.mp3', album: '1', artista: '1', plays: '0', id: '' }));
        log('song_save.asp crea cancion', r.status === 302 || r.status === 200, 'HTTP ' + r.status + ' ' + (r.location || ''));

        // verificar que aparece en songs.asp
        r = await req('GET', '/songs.asp');
        log('cancion nueva aparece en listado', r.text.indexOf(nombre) > -1, nombre);

        // obtener id de la cancion creada
        const mm = r.text.match(new RegExp('data-id="(\\d+)"[^>]*data-titulo="[^"]*' + nombre.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i')) ||
            r.text.match(new RegExp(nombre.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '[\\s\\S]{0,400}?data-id="(\\d+)"', 'i'));
        if (mm) nuevoId = mm[1];
        log('id de cancion nueva obtenido', !!nuevoId, nuevoId);

        // editar (cambiar nombre)
        if (nuevoId) {
            const nombre2 = nombre + ' Edit';
            r = await req('POST', '/song_save.asp', qs({ nombre: nombre2, ruta: '~/SongFiles/bensound-scifi.mp3', album: '1', artista: '1', plays: '0', id: nuevoId }));
            log('song_save.asp edita cancion', r.status === 302 || r.status === 200, 'HTTP ' + r.status);
            r = await req('GET', '/songs.asp');
            log('cancion editada aparece', r.text.indexOf(nombre2) > -1);
        }
    } catch (e) { log('CRUD admin', false, e.message); }

    // ---------- 7. Eliminar cancion de prueba ----------
    try {
        if (nuevoId) {
            // flujo real: confirmacion por GET y POST a song_delete.asp?id=N
            let conf = await req('GET', '/song_delete.asp?id=' + nuevoId);
            log('pantalla de confirmacion muestra la cancion', conf.status === 200 && /confirmar/i.test(conf.text) && /Sí, eliminar/i.test(conf.text));
            let r = await req('POST', '/song_delete.asp?id=' + nuevoId, qs({ confirmar: '1' }));
            log('song_delete.asp elimina', r.status === 302 || r.status === 200, 'HTTP ' + r.status);
            r = await req('GET', '/songs.asp');
            // se comprueba sobre las filas (data-titulo), no sobre el aviso flash
            log('cancion eliminada ya no aparece como fila', r.text.indexOf('data-titulo="Prueba Humo') === -1);
            const filasFinal = (r.text.match(/class="fila-cancion pista"/g) || []).length;
            log('el listado queda con las 5 canciones originales', filasFinal === 5, filasFinal + ' filas');
        }
    } catch (e) { log('song_delete.asp', false, e.message); }

    // ---------- 8. Catalogo ----------
    for (const p of ['albums.asp', 'artists.asp', 'playlists.asp', 'album_detail.asp?id=1', 'playlist_detail.asp?id=1']) {
        try {
            let r = await req('GET', '/' + p);
            log(p + ' responde 200', r.status === 200, 'HTTP ' + r.status + (r.status !== 200 ? ' :: ' + r.text.replace(/\s+/g, ' ').substring(0, 150) : ''));
        } catch (e) { log(p, false, e.message); }
    }

    // ---------- 9. Assets ----------
    for (const a of ['/assets/css/styles.css', '/assets/js/app.js', '/assets/img/favicon.svg', '/SongFiles/bensound-adventure.mp3', '/AlbumImages/album1.png', '/ArtistImages/artist1.jpg']) {
        try {
            let r = await req('GET', a);
            log('asset ' + a, r.status === 200, 'HTTP ' + r.status);
        } catch (e) { log('asset ' + a, false, e.message); }
    }

    // ---------- 10. Logout ----------
    try {
        let r = await req('GET', '/logout.asp');
        log('logout.asp redirige a login', r.status === 302 && /login/i.test(r.location || ''), 'HTTP ' + r.status + ' ' + (r.location || ''));
        r = await req('GET', '/songs.asp');
        log('tras logout songs.asp pide login', r.status === 302, 'HTTP ' + r.status);
    } catch (e) { log('logout', false, e.message); }

    // ---------- 11. Usuario normal (no admin) ----------
    try {
        await req('GET', '/logout.asp');
        let r = await req('POST', '/login.asp', qs({ usuario: 'userNormal', clave: '12345678', volver: '' }));
        r = await req('GET', '/songs.asp');
        log('usuario normal ve songs.asp', r.status === 200 && /Bienvenido/i.test(r.text));
        log('usuario normal NO ve boton Nueva cancion', !/Nueva\s*canci/i.test(r.text));
        r = await req('GET', '/song_form.asp');
        log('usuario normal bloqueado en song_form.asp', r.status === 302 || /acceso|denegad|permiso/i.test(r.text), 'HTTP ' + r.status);
    } catch (e) { log('rol normal', false, e.message); }

    console.log('\n===== RESUMEN: ' + passed + ' PASS / ' + failed + ' FAIL =====');
    process.exit(failed > 0 ? 1 : 0);
})();
