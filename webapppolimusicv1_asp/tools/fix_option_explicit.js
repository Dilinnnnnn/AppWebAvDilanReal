// Reestructura los .asp: mueve "Option Explicit" al inicio (antes de los includes),
// porque en ASP clasico todas las secciones <% %> se fusionan en un solo script y
// Option Explicit debe ser la PRIMERA instruccion.
const fs = require('fs');
const path = require('path');

const root = 'D:\\WebAvanzadas\\repos\\AppWebAvDilanReal\\webapppolimusicv1_asp';
const archivos = fs.readdirSync(root).filter(f => f.toLowerCase().endsWith('.asp'));

for (const f of archivos) {
    const full = path.join(root, f);
    let txt = fs.readFileSync(full, 'utf8');
    if (!/^Option\s+Explicit/m.test(txt) && !/<%\s*Option\s+Explicit\s*%>/.test(txt)) continue;

    const antes = txt;

    // 1) Quita cualquier "Option Explicit" suelto dentro de los bloques <% %>
    txt = txt.replace(/^[ \t]*Option\s+Explicit[ \t]*\r?\n/m, '');

    // 2) Inserta el bloque <% Option Explicit %> justo despues de la directiva @Language
    if (!/<%\s*Option\s+Explicit\s*%>/.test(txt)) {
        if (/<%@\s*Language\s*=\s*VBScript\s*%>/.test(txt)) {
            txt = txt.replace(/(<%@\s*Language\s*=\s*VBScript\s*%>[ \t]*\r?\n)/, '$1<% Option Explicit %>\n');
        } else {
            // sin directiva: lo pone tras el BOM
            txt = txt.replace(/^\uFEFF/, '\uFEFF<% Option Explicit %>\n');
        }
    }

    if (txt !== antes) {
        fs.writeFileSync(full, txt, 'utf8');
        console.log('MOD  ' + f);
    } else {
        console.log('skip ' + f);
    }
}
