# PoliMusic — Clon de Spotify en ASP clásico (VBScript)

Sitio web tipo Spotify construido con **ASP clásico + VBScript** (archivos `.asp`),
**SQL Server 2025** (base `BDD_PoliMusic`) y **HTML + CSS + JavaScript** puro en el
frente. El diseño es propio, en tonos verdes, inspirado en aplicaciones como Apple Music.

---

## 1. Requisitos

| Componente | Detalle |
|---|---|
| Windows + IIS | IIS 10 (Express también sirve para probar) |
| SQL Server | **SQL Server 2025** en `localhost` |
| Base de datos | `BDD_PoliMusic` |
| Acceso | credenciales de SQL Server en `includes/config.local.ini` (archivo local, no versionado) |
| ASP clásico | sin ASP.NET, sin C# — todo el servidor es `.asp` con VBScript |

---

## 2. Puesta en marcha

### Paso 1 — Crear la base de datos

Abre **SQL Server Management Studio** (o `sqlcmd`) y ejecuta, en este orden:

1. `BDD_PoliMusic.sql` — script original del modelo entidad-relación y datos.
2. `sql/00_drop.sql` — *(opcional)* borra y limpia la base si quedaron duplicados.
3. `sql/01_post_install.sql` — normaliza rutas de imágenes/canciones y agrega el
   usuario `Dilan.Real`.

### Paso 1b — Configurar las credenciales (importante)

Las credenciales de SQL Server **no están en el repositorio**. Copia el ejemplo
y pon las tuyas:

```
copy includes\config.local.ini.ejemplo includes\config.local.ini
```

Edita `includes/config.local.ini` con tu usuario y contraseña de SQL Server.
Ese archivo está en `.gitignore`: nunca se sube a GitHub.

### Paso 2 — Publicar el sitio

**Opción A — IIS local (recomendada), con un solo comando**

Abre PowerShell **como administrador** y ejecuta:

```powershell
powershell -ExecutionPolicy Bypass -File "D:\WebAvanzadas\repos\AppWebAvDilanReal\webapppolimusicv1_asp\tools\publicar_iis.ps1"
```

Ese script (`tools/publicar_iis.ps1`) se encarga de todo: habilita la
característica ASP de IIS si falta, da permisos de lectura a `IIS_IUSRS`,
crea la aplicación `/PoliMusic` bajo *Default Web Site* (si el puerto 80 no
se puede usar, crea un sitio dedicado en el puerto 8081), activa
*Send Errors To Browser* y comprueba que la página responde. Al terminar
muestra la URL para abrir.

Para revertirlo: `appcmd delete app "Default Web Site/PoliMusic"`
(o `appcmd delete site PoliMusic` si usó el puerto 8081).

**Opción A manual — IIS local paso a paso**

1. Copia la carpeta `webapppolimusicv1_asp` a `C:\inetpub\wwwroot\PoliMusic`
   (o publícala como aplicación independiente).
2. En el Administrador de IIS, crea un **grupo de aplicaciones** con
   .NET CLR = *Sin código administrado* y canalización *Integrada o Clásica*.
3. Abre `http://localhost/PoliMusic/login.asp` (o el puerto que hayas asignado).

**Opción B — IIS Express (para probar rápido)**

```bat
"C:\Program Files\IIS Express\iisexpress.exe" /site:WebSite1 /apppool:Clr4IntegratedAppPool
```

El archivo `tools/iisexpress_conf.js` deja `WebSite1` apuntando a esta carpeta
(sirve para restaurar la configuración si hace falta).

### Paso 3 — Entrar

| Cuenta | Contraseña | Rol | Qué puede hacer |
|---|---|---|---|
| `userAdmin` | `12345678` | **Administrador** | CRUD completo de canciones |
| `userNormal` | `12345678` | Normal | Solo escuchar y explorar |
| `Dilan.Real` | `12345678` | Normal | Solo escuchar y explorar |
| `username1` | *(hash SHA-1)* | Normal | Solo escuchar y explorar |

En `login.asp` hay botones de **cuentas de demostración** que rellenan el formulario.

---

## 3. Estructura del proyecto

```
webapppolimusicv1_asp/
├── login.asp            Inicio de sesión (valida contra TBL_USER y guarda la sesión)
├── logout.asp           Cierra la sesión
├── default.asp          Redirige a Song List o al login
├── songs.asp            ★ LISTADO DE CANCIONES (Song List) + bienvenida + CRUD admin
├── song_form.asp        Formulario de alta / edición (solo admin)
├── song_save.asp        Guarda el alta/edición y las relaciones del modelo E-R
├── song_delete.asp      Baja con pantalla de confirmación (solo admin)
├── play_count.asp       Contador de reproducciones (lo llama el reproductor por AJAX)
├── albums.asp           Catálogo de álbumes
├── album_detail.asp     Canciones de un álbum
├── artists.asp          Catálogo de artistas
├── playlist_detail.asp / playlists.asp
├── includes/
│   ├── comun.asp        CARGADOR ÚNICO: incluye los 4 módulos una sola vez
│   ├── conexion.asp     Conexión ADO a SQL Server + consultas seguras
│   ├── sesion.asp       Sesión, roles y control de acceso
│   ├── ui.asp           Utilidades (HTML escape, rutas de assets, duración MP3)
│   └── layout.asp       Estructura visual común + barra de reproducción
├── assets/
│   ├── css/styles.css   Sistema de diseño propio (verde, tema claro/oscuro)
│   ├── js/app.js        Reproductor: cola, aleatorio, repetir, favoritos, atajos
│   ├── js/login.js      Cuentas demo
│   └── img/             Favicon y placeholders
├── SongFiles/           Los 5 MP3
├── AlbumImages/         Carátulas de álbumes
├── ArtistImages/        Fotos de artistas
├── PlaylistImages/      Carátulas de listas
├── UserImages/          Avatares de usuario
├── sql/                 Scripts de mantenimiento de la base
└── tools/               Utilidades de desarrollo (ver sección 6)
```

---

## 4. Cómo funciona

### 4.1 Sesión y roles

`login.asp` valida usuario/contraseña contra `TBL_USER` y guarda en sesión:
`PM_USUARIO_ID`, `PM_USUARIO_NOMBRE`, `PM_USUARIO_CORREO`, `PM_USUARIO_FOTO`,
`PM_USUARIO_ROL`. El rol sale de `TBL_USER.USER_TYPE` (`1` = administrador,
`0` = normal), igual que `TBL_CATALOG`.

- `SesionRequerir()` obliga a iniciar sesión: sin sesión, cualquier página privada
  redirige a `login.asp?volver=...`.
- `UsuarioEsAdmin()` protege `song_form.asp`, `song_save.asp` y `song_delete.asp`:
  un usuario normal que entre a mano recibe un aviso y vuelve al listado.

### 4.2 Página de canciones (Song List)

`songs.asp` muestra el texto **"Song List"** junto al saludo
**«Bienvenido, userAdmin»** con el rol en un chip, y una tabla con:
`# · Título · Artista · Álbum · Reproducciones · Duración · Acciones`.
La duración real se calcula leyendo la cabecera MPEG del archivo (bitrate y
frecuencia de muestreo), y las canciones se reproducen desde el reproductor fijo
de la parte inferior (cola, anterior/siguiente, aleatorio, repetir, volumen y
favoritos).

El CRUD (solo admin) aparece como iconos en la columna *Acciones*:

| Icono | Acción |
|---|---|
| `+` | Añadir la canción a la cola |
| ✎ | Editar → `song_form.asp?id=…` |
| ⤓ | Descargar el MP3 |
| 🗑 | Eliminar → `song_delete.asp?id=…` (confirmación) |

Al reproducir, el JavaScript llama a `play_count.asp?id=…`, que suma 1 a
`TBL_SONG.PLAYS` y devuelve el nuevo valor en JSON.

### 4.3 Consultas a SQL Server

`includes/conexion.asp` abre la conexión probando varios proveedores
(OLE DB Driver, SQLNCLI11 y SQLOLEDB) para que funcione en cualquier equipo.
Todas las consultas usan marcadores `?` y se sustituyen por **literales
escapados** (`comillas dobladas`, `NULL`, fechas ISO-8601), lo que evita la
inyección de SQL sin depender de la colección `Parameters` de ADO.

> Nota técnica: el driver MSOLEDBSQL de esta máquina refresca automáticamente los
> parámetros de un `ADODB.Command` al asignar un `CommandText` con `?`, lo que
> provocaba el error `80040e21`. Por eso el sitio expande los literales en
> `includes/conexion.asp` (`SqlLiteral` / `SqlExpandir`).

### 4.4 Detalles de ASP clásico

- Un único `<%@Language=VBScript%>` y `Option Explicit` **al principio** de cada
  página (los `#include` se funden en un solo script, así que `Option Explicit`
  debe ir antes que cualquier include).
- Todas las páginas incluyen **solo** `includes/comun.asp`: si un mismo archivo se
  incluye dos veces, sus `Const`/`Dim` se duplican y el compilador falla con
  *«Nombre redefinido» (800a0411)*.
- Los `.asp` se guardan con **BOM UTF-8** para que IIS escriba bien los acentos.
- `<%-- ... --%>` **no** existe en ASP clásico: para comentar código se usa `'`
  dentro de un bloque `<% %>`.

---

## 5. Modelo entidad-relación usado

`TBL_CATALOG`, `TBL_SONG`, `TBL_ALBUM`, `TBL_TRACKLIST` (canción ↔ álbum),
`TBL_ARTIST`, `TBL_PLAYER` (canción ↔ artista), `TBL_USER`, `TBL_PLAYLIST`,
`TBL_PLAYLIST_SONG` (lista ↔ canción). Las páginas de álbumes, artistas y listas
muestran las canciones relacionadas a través de esas tablas puente.

---

## 6. Herramientas (`tools/`)

| Script | Para qué sirve |
|---|---|
| `smoke.js` | Prueba automática de **42 comprobaciones** (login, sesión, listado, CRUD, contador, roles, assets). Ejecutar con el sitio levantado: `node tools/smoke.js` |
| `fix_bom.js` | Asegura el BOM UTF-8 en todos los `.asp` |
| `fix_includes.js` | Convierte los includes de página al cargador único |
| `fix_option_explicit.js` | Mueve `Option Explicit` al inicio de cada página |
| `gen_mp3.js` | Regenera los MP3 a partir del original (recorte de frames MPEG) |
| `gen_images.py` | Regenera carátulas y fotos de artista |
| `iisexpress_conf.js` | Apunta el sitio `WebSite1` de IIS Express a esta carpeta |
| `publicar_iis.ps1` | Publica el sitio en el IIS local (aplicación `/PoliMusic`). Ejecutar en PowerShell **como administrador** |

---

## 7. Solución de problemas

| Síntoma | Causa / solución |
|---|---|
| 800a0411 «Nombre redefinido» | Un include se carga dos veces → usar solo `includes/comun.asp` |
| 800a0400 en `Option Explicit` | Debe ir antes de los `#include` |
| ASP 0174 en `Server.MapPath` | Rutas con `//` — `Url()` ya quita el slash inicial |
| Las duraciones salen `0:00` | Revisar `Mp3DuracionSeg` en `includes/ui.asp` |
| No conecta a SQL Server | Servicio detenido, contraseña de `sa` o proveedor OLE DB ausente |
| 80040e21 al consultar | Driver que refresca parámetros — ver nota 4.3 |

---

*Proyecto académico — Programación Web Avanzada. ASP clásico + VBScript + SQL Server 2025.*
