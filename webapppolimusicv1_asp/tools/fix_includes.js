// Reemplaza los includes de pagina (ui.asp / sesion.asp / layout.asp)
// por el cargador unico includes/comun.asp.
const fs = require('fs');
const path = require('path');

const root = 'D:\\WebAvanzadas\\repos\\AppWebAvDilanReal\\webapppolimusicv1_asp';
const archivos = fs.readdirSync(root).filter(f => f.toLowerCase().endsWith('.asp'));

for (const f of archivos) {
    const full = path.join(root, f);
    let txt = fs.readFileSync(full, 'utf8');
    if (/includes\/comun\.asp/.test(txt)) { console.log('skip ' + f + ' (ya usa comun.asp)'); continue; }

    const antes = txt;
    // bloque ui.asp + layout.asp  ->  comun.asp
    txt = txt.replace(
        /<!--#include file="includes\/ui\.asp"-->\s*[\r\n]+\s*<!--#include file="includes\/layout\.asp"-->/gi,
        '<!--#include file="includes/comun.asp"-->');
    // include suelto de sesion.asp -> comun.asp
    txt = txt.replace(/<!--#include file="includes\/sesion\.asp"-->/gi, '<!--#include file="includes/comun.asp"-->');
    // include suelto de ui.asp -> comun.asp
    txt = txt.replace(/<!--#include file="includes\/ui\.asp"-->/gi, '<!--#include file="includes/comun.asp"-->');

    if (txt !== antes) {
        fs.writeFileSync(full, txt, 'utf8');
        console.log('MOD  ' + f);
    } else {
        console.log('skip ' + f);
    }
}
// informe de includes restantes
console.log('\n--- includes restantes ---');
for (const f of archivos) {
    const txt = fs.readFileSync(path.join(root, f), 'utf8');
    const incs = txt.match(/<!--#include[^>]*-->/gi) || [];
    if (incs.length) console.log(f + ': ' + incs.join('  '));
}
for (const f of ['conexion.asp', 'sesion.asp', 'ui.asp', 'layout.asp', 'comun.asp']) {
    const p = path.join(root, 'includes', f);
    if (!fs.existsSync(p)) continue;
    const txt = fs.readFileSync(p, 'utf8');
    const incs = txt.match(/<!--#include[^>]*-->/gi) || [];
    console.log('includes/' + f + ': ' + (incs.length ? incs.join('  ') : '(ninguno)'));
}
