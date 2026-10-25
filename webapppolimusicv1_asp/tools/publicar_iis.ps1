#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Publica PoliMusic (ASP clasico / VBScript) en el IIS local, copiando
  el codigo a C:\inetpub\wwwroot\PoliMusic como pide la practica.
.DESCRIPTION
  Que hace este script, paso a paso:
    1. Comprueba que exista la carpeta del proyecto y appcmd.exe (IIS).
    2. Habilita la caracteristica "ASP" de IIS si no esta instalada.
    3. COPIA el codigo a C:\inetpub\wwwroot\PoliMusic (robocopy /E).
    4. Da permisos de LECTURA a IIS_IUSRS sobre la carpeta copiada.
    5. Crea la aplicacion /PoliMusic bajo "Default Web Site"
       apuntando a C:\inetpub\wwwroot\PoliMusic.
       Si ahi no se puede servir (sitio detenido o puerto 80 ocupado),
       crea un sitio dedicado llamado PoliMusic en el puerto 8081.
    6. Activa "Send Errors To Browser" para ver errores de VBScript
       en el navegador mientras se depura.
    7. Hace una peticion de prueba y muestra la URL final.
.NOTES
  Como ejecutarlo (PowerShell como ADMINISTRADOR):
    powershell -ExecutionPolicy Bypass -File "D:\WebAvanzadas\repos\AppWebAvDilanReal\webapppolimusicv1_asp\tools\publicar_iis.ps1"
  Para revertirlo (borra la aplicacion /PoliMusic):
    "%windir%\system32\inetsrv\appcmd.exe" delete app "Default Web Site/PoliMusic"
  Para revertirlo (borra el sitio dedicado del puerto 8081):
    "%windir%\system32\inetsrv\appcmd.exe" delete site PoliMusic
#>

$ErrorActionPreference = "Stop"

$Origen  = "D:\WebAvanzadas\repos\AppWebAvDilanReal\webapppolimusicv1_asp"
$Destino = "C:\inetpub\wwwroot\PoliMusic"
$Alias   = "PoliMusic"
$Sitio   = "Default Web Site"
$PuertoAlt = 8081
$AppCmd  = Join-Path $env:windir "system32\inetsrv\appcmd.exe"

function Escribir-Paso($texto) {
    Write-Host ""
    Write-Host "==> $texto" -ForegroundColor Green
}

# --- 0) Comprobaciones basicas -------------------------------------------
if (-not (Test-Path $Origen)) {
    throw "No se encuentra la carpeta del proyecto: $Origen"
}
if (-not (Test-Path $AppCmd)) {
    throw "No se encuentra appcmd.exe (IIS no esta instalado?): $AppCmd"
}

# --- 1) Caracteristica ASP clasico de IIS --------------------------------
Escribir-Paso "Comprobando la caracteristica ASP clasico de IIS..."
$aspHabilitadoAhora = $false
$asp = $null
try { $asp = Get-WindowsOptionalFeature -Online -FeatureName IIS-ASP } catch { $asp = $null }
if ($asp -and $asp.State -ne "Enabled") {
    Write-Host "   ASP clasico NO estaba instalado; habilitando (puede tardar un minuto)..."
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASP -All -NoRestart | Out-Null
    $aspHabilitadoAhora = $true
    Write-Host "   Caracteristica IIS-ASP habilitada."
} else {
    Write-Host "   ASP clasico ya estaba habilitado (o no se pudo comprobar)."
}

# --- 2) Copiar el codigo a C:\inetpub\wwwroot\PoliMusic -------------------
Escribir-Paso "Copiando el codigo a $Destino ..."
& robocopy $Origen $Destino /E /NFL /NDL /NJH /NJS /NP | Out-Null
# robocopy: codigos 0 a 7 = exito (son banderas de lo copiado)
if ($LASTEXITCODE -ge 8) {
    throw "robocopy devolvio el codigo $LASTEXITCODE (copia fallida)"
}
if (-not (Test-Path (Join-Path $Destino "songs.asp"))) {
    throw "La copia no contiene songs.asp; algo salio mal."
}
Write-Host "   Codigo copiado ($((Get-ChildItem $Destino -Recurse -File).Count) archivos)."

# --- 3) Permisos de lectura para IIS -------------------------------------
Escribir-Paso "Dando permisos de lectura a IIS_IUSRS sobre $Destino ..."
& icacls $Destino /grant "IIS_IUSRS:(OI)(CI)(RX)" /T | Out-Null
if ($LASTEXITCODE -ne 0) { throw "icacls devolvio el codigo $LASTEXITCODE" }
Write-Host "   Permisos concedidos."

# --- 4) Intento A: aplicacion /PoliMusic bajo Default Web Site ------------
Escribir-Paso "Creando la aplicacion /$Alias bajo '$Sitio'..."
& $AppCmd delete app "$Sitio/$Alias" | Out-Null   # por si ya existia (se ignora el error)
& $AppCmd add app /site.name:$Sitio /path:/$Alias /physicalPath:$Destino | Out-Null
$addOk = ($LASTEXITCODE -eq 0)

function Probar-Url($u) {
    try {
        $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 15
        return ($r.StatusCode -eq 200)
    } catch {
        return $false
    }
}

$url = $null
$rutaConfig = $null
$sirve = $false
if ($addOk) {
    # Aseguramos que el sitio este arrancado por si estaba detenido.
    & $AppCmd start site $Sitio | Out-Null
    $url = "http://localhost/$Alias/login.asp"
    $rutaConfig = "$Sitio/$Alias"
    Start-Sleep -Seconds 2
    $sirve = Probar-Url $url
    if (-not $sirve) {
        Write-Host "   El sitio no responde en http://localhost/$Alias/ ..." -ForegroundColor Yellow
        & $AppCmd start site $Sitio | Out-Null
        Start-Sleep -Seconds 2
        $sirve = Probar-Url $url
    }
}

# --- 5) Intento B (respaldo): sitio dedicado en el puerto 8081 ------------
if (-not $sirve) {
    if ($addOk) {
        Write-Host "   Revirtiendo la aplicacion y creando sitio dedicado..." -ForegroundColor Yellow
        & $AppCmd delete app "$Sitio/$Alias" | Out-Null
    }
    Escribir-Paso "Creando sitio dedicado 'PoliMusic' en el puerto $PuertoAlt..."
    & $AppCmd delete site PoliMusic | Out-Null   # por si ya existia
    & $AppCmd add site /name:PoliMusic /bindings:"http/*:$PuertoAlt`:" /physicalPath:$Destino | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo crear el sitio en el puerto $PuertoAlt. Revisa si el puerto esta ocupado."
    }
    & $AppCmd start site PoliMusic | Out-Null
    $url = "http://localhost:$PuertoAlt/login.asp"
    $rutaConfig = "PoliMusic"
    Start-Sleep -Seconds 2
    $sirve = Probar-Url $url
}

# --- 6) Ver errores de VBScript en el navegador ---------------------------
Escribir-Paso "Activando 'Send Errors To Browser' para poder depurar..."
& $AppCmd set config $rutaConfig -section:system.webServer/asp /scriptErrorSentToBrowser:true /commit:apphost | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   AVISO: no se pudo activar automaticamente (no es grave)." -ForegroundColor Yellow
    Write-Host "   Puedes hacerlo a mano en el Administrador de IIS: ASP ->" -ForegroundColor Yellow
    Write-Host "   Propiedades de depuracion -> 'Send Errors To Browser' = True." -ForegroundColor Yellow
} else {
    Write-Host "   Activado."
}

# --- 7) Resultado final ----------------------------------------------------
if (-not $sirve) {
    Write-Host ""
    Write-Host "AVISO: la pagina no respondio a la prueba automatica." -ForegroundColor Red
    Write-Host "Abre la URL manualmente en el navegador:  $url" -ForegroundColor Red
    if ($aspHabilitadoAhora) {
        Write-Host "Si da error 404, ejecuta una vez 'iisreset' en esta ventana." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "================================================================"
    Write-Host " PoliMusic publicado. Abrelo en tu navegador:"
    Write-Host "   $url"
    Write-Host ""
    Write-Host " Usuario: userAdmin    Contrasena: 12345678"
    Write-Host " (usuario normal: userNormal / 12345678)"
    Write-Host "================================================================"
    if ($aspHabilitadoAhora) {
        Write-Host ""
        Write-Host "NOTA: se habilito ASP en este momento. Si alguna pagina da" -ForegroundColor Yellow
        Write-Host "error 404, ejecuta una vez 'iisreset' en esta ventana." -ForegroundColor Yellow
    }
}
