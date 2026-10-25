// Apunta el sitio WebSite1 de IIS Express a la carpeta del proyecto.
// (Se usa ruta con barras invertidas: IIS Express normaliza a "/" y el
//  sistema de archivos del entorno no resuelve rutas mixtas.)
const fs = require("fs");
const cfg = "C:/Users/elias/Documents/IISExpress/config/applicationHost.config";
const destino = "D:\\WebAvanzadas\\repos\\AppWebAvDilanReal\\webapppolimusicv1_asp";

let t = fs.readFileSync(cfg, "utf8");
const antes = t;

t = t.replace(
  /<virtualDirectory path="\/" physicalPath="[^"]*" \/>/,
  '<virtualDirectory path="/" physicalPath="' + destino + '" />'
);

if (t === antes) {
  console.log("NO SE ENCONTRÓ el patrón a reemplazar");
} else {
  fs.writeFileSync(cfg, t, "utf8");
  console.log("config actualizada");
}
console.log(t.match(/<site name="WebSite1"[\s\S]{0,320}?\/>/)[0]);
