// Asegura que todos los .asp tengan BOM UTF-8 (IIS decodifica el archivo
// y escribe los bytes tal cual; sin BOM los acentos salen corruptos).
// Idempotente: no anade BOM si ya existe.
const fs = require('fs');
const path = require('path');

const root = 'D:\\WebAvanzadas\\repos\\AppWebAvDilanReal\\webapppolimusicv1_asp';
function walk(dir, out) {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
        const p = path.join(dir, e.name);
        if (e.isDirectory()) walk(p, out);
        else if (p.toLowerCase().endsWith('.asp')) out.push(p);
    }
    return out;
}
const archivos = walk(root, []);
let cambiados = 0;
for (const f of archivos) {
    const buf = fs.readFileSync(f);
    if (buf[0] === 0xEF && buf[1] === 0xBB && buf[2] === 0xBF) continue;
    fs.writeFileSync(f, Buffer.concat([Buffer.from([0xEF, 0xBB, 0xBF]), buf]));
    console.log('BOM  ' + path.relative(root, f));
    cambiados++;
}
console.log((cambiados ? cambiados + ' archivos actualizados' : 'todos ya tenian BOM') + ' (' + archivos.length + ' archivos .asp)');
