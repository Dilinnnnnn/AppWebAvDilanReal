<%
'=====================================================================
'  PoliMusic  -  includes/ui.asp   (se carga desde comun.asp)
'---------------------------------------------------------------------
'  Utilidades de presentación: escapado de HTML, resolución de rutas
'  de assets ("~/SongFiles/x.mp3" -> "/PoliMusic/SongFiles/x.mp3"),
'  reformateo de fechas, duraciones, etc.
'=====================================================================

Dim gBaseVirtual

'---------------------------------------------------------------------
' Ruta virtual de la aplicación (funciona como sitio raíz o como
' directorio virtual dentro de otro sitio).
'---------------------------------------------------------------------
Function BaseVirtual()
    Dim script
    If Len(gBaseVirtual) > 0 Then
        BaseVirtual = gBaseVirtual
        Exit Function
    End If
    script = Request.ServerVariables("SCRIPT_NAME")     ' /PoliMusic/songs.asp
    If Len(script) = 0 Then
        gBaseVirtual = ""
    Else
        gBaseVirtual = Left(script, InStrRev(script, "/"))  ' /PoliMusic/  (o "/" si es sitio raíz)
    End If
    BaseVirtual = gBaseVirtual
End Function

'--- Une la base virtual con cualquier ruta de la aplicación ------
' La base siempre termina en "/", así que se quita el slash inicial
' de la ruta recibida para no generar "//" (IIS rechaza esas rutas
' en Server.MapPath con "caracteres de la ruta no válidos").
Function Url(relativa)
    Dim r
    r = CStr(relativa)
    If Left(r, 1) = "/" Then r = Mid(r, 2)
    Url = BaseVirtual() & r
End Function

'---------------------------------------------------------------------
' Convierte una ruta tipo "~/SongFiles/x.mp3" (como se guarda en la
' base) en una URL del navegador. Si el archivo no existe en disco se
' devuelve la imagen de respaldo para no mostrar enlaces rojos.
'---------------------------------------------------------------------
Public Function AssetUrl(ruta)
    Dim limpia, virtual, fisica, ext, respaldo
    limpia = CStr(ruta)
    If Len(limpia) = 0 Then limpia = "~/UserImages/default.jpg"
    ' quita "~/" y cualquier slash inicial
    limpia = Replace(limpia, "~/", "")
    limpia = Replace(limpia, "~", "")
    If Len(limpia) = 0 Then limpia = "UserImages/default.jpg"
    If Left(limpia, 1) <> "/" Then limpia = "/" & limpia

    virtual = Url(limpia)

    ' verificación física (no rompe si FSO no está disponible)
    On Error Resume Next
    fisica = Server.MapPath(virtual)
    If Err.Number = 0 Then
        Dim fso
        Set fso = Server.CreateObject("Scripting.FileSystemObject")
        If Not fso.FileExists(fisica) Then
            ext = LCase(Mid(limpia, InStrRev(limpia, ".") + 1))
            If ext = "mp3" Then
                respaldo = Url("/SongFiles/bensound-adventure.mp3")
            Else
                respaldo = Url("/assets/img/placeholder.svg")
            End If
            AssetUrl = respaldo
            On Error GoTo 0
            Exit Function
        End If
    End If
    On Error GoTo 0
    AssetUrl = virtual
End Function

'--- ¿Es un número entero válido? ---------------------------------
Public Function EsEntero(valor)
    Dim t
    t = Trim(CStr(valor))
    If Len(t) = 0 Then
        EsEntero = False
    ElseIf Not IsNumeric(t) Then
        EsEntero = False
    Else
        EsEntero = (CLng(CDbl(t)) = CDbl(t))
    End If
End Function

'--- Duración real de un MP3 (CBR) leyendo la cabecera del primer
'    frame y estimando sobre el tamaño total del archivo -------------
Public Function Mp3DuracionSeg(rutaFisica)
    Dim stm, datos, tamano, off, i, b, encontrado
    Dim b1, b2, b3, b4, ver, brIdx, srIdx, bitrate, sr, spf, largo
    ' Tablas MPEG Audio Layer III
    Dim BR1, BR2, SR1, SR2
    BR1 = Array(0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0)
    BR2 = Array(0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0)
    SR1 = Array(44100, 48000, 32000)
    SR2 = Array(22050, 24000, 16000)
    Mp3DuracionSeg = 0

    On Error Resume Next
    Set stm = Server.CreateObject("ADODB.Stream")
    stm.Type = 1                 ' adTypeBinary
    stm.Open
    stm.LoadFromFile rutaFisica
    stm.Position = 0                 ' LoadFromFile deja el puntero al final
    datos = stm.Read()
    stm.Close
    Set stm = Nothing
    If Err.Number <> 0 Then
        Err.Clear
        On Error GoTo 0
        Exit Function
    End If
    On Error GoTo 0

    tamano = LenB(datos)
    If tamano < 64 Then Exit Function

    ' cabecera ID3v2 -> se salta
    off = 1
    If AscB(MidB(datos, 1, 1)) = 73 And AscB(MidB(datos, 2, 1)) = 68 And AscB(MidB(datos, 3, 1)) = 51 Then
        off = 11 + ((AscB(MidB(datos, 7, 1)) And 127) * 2097152) _
                  + ((AscB(MidB(datos, 8, 1)) And 127) * 16384) _
                  + ((AscB(MidB(datos, 9, 1)) And 127) * 128) _
                  + (AscB(MidB(datos, 10, 1)) And 127)
    End If

    ' busca el primer frame válido
    encontrado = False
    For i = off To 65535
        If i + 3 > tamano Then Exit For
        b1 = AscB(MidB(datos, i, 1)) And 255
        b2 = AscB(MidB(datos, i + 1, 1)) And 255
        If b1 = 255 And (b2 And 224) = 224 Then
            b3 = AscB(MidB(datos, i + 2, 1)) And 255
            ver   = CLng(Int(b2 / 8)) And 3
            brIdx = CLng(Int(b3 / 16)) And 15
            srIdx = CLng(Int(b3 / 4)) And 3
            If (ver = 3 Or ver = 2) And brIdx > 0 And brIdx < 15 And srIdx < 3 Then
                encontrado = True
                Exit For
            End If
        End If
    Next
    If Not encontrado Then Exit Function

    If ver = 3 Then
        bitrate = BR1(brIdx) * 1000
        sr = SR1(srIdx)
    Else
        bitrate = BR2(brIdx) * 1000
        sr = SR2(srIdx)
    End If

    If bitrate = 0 Then Exit Function
    ' bytes * 8 bits/byte / bits por segundo = segundos (CBR)
    Mp3DuracionSeg = Int((tamano * 8) / bitrate)
End Function

'--- mm:ss --------------------------------------------------------
Public Function FormatoReloj(seg)
    Dim s, m
    If Not IsNumeric(seg) Or seg <= 0 Then
        FormatoReloj = "-"
    Else
        s = Int(seg) Mod 60
        m = Int(Int(seg) / 60)
        FormatoReloj = m & ":" & Right("0" & s, 2)
    End If
End Function

'--- Convierte un valor de BD en texto seguro (Null -> "") --------
Public Function Txt(valor)
    If IsNull(valor) Or IsEmpty(valor) Then
        Txt = ""
    Else
        Txt = CStr(valor)
    End If
End Function

'--- Escapado de HTML --------------------------------------------
Public Function H(texto)    If IsNull(texto) Or IsEmpty(texto) Then
        H = ""
    Else
        H = Server.HTMLEncode(CStr(texto))
    End If
End Function

Public Function HA(texto)
    HA = Server.URLEncode(CStr(texto))
End Function

'--- Formato corto de fecha --------------------------------------
Public Function FechaCorta(valor)
    If Not IsDate(valor) Then
        FechaCorta = "-"
    Else
        FechaCorta = Year(CDate(valor)) & "-" & _
                     Right("0" & Month(CDate(valor)), 2) & "-" & _
                     Right("0" & Day(CDate(valor)), 2)
    End If
End Function

'--- Iniciales para avatares de texto -----------------------------
Public Function Iniciales(nombre)
    Dim partes, i, salida
    If Len(CStr(nombre)) = 0 Then
        Iniciales = "PM"
        Exit Function
    End If
    partes = Split(CStr(nombre), " ")
    salida = ""
    For i = 0 To UBound(partes)
        If Len(Trim(partes(i))) > 0 Then
            salida = salida & UCase(Left(Trim(partes(i)), 1))
            If Len(salida) >= 2 Then Exit For
        End If
    Next
    If Len(salida) = 0 Then salida = "PM"
    Iniciales = salida
End Function

'--- Mensaje "flash" entre páginas (crear/editar/borrar) --------
Sub FijarFlash(titulo, detalle, tipo)
    Session("PM_FLASH_TITULO") = titulo
    Session("PM_FLASH_DETALLE") = detalle
    Session("PM_FLASH_TIPO") = tipo
End Sub

Function LeerFlash()
    Dim t, d, k, out
    t = Session("PM_FLASH_TITULO")
    d = Session("PM_FLASH_DETALLE")
    k = Session("PM_FLASH_TIPO")
    If Len(t) = 0 Then
        LeerFlash = ""
    Else
        out = "<div class=""toast toast--" & H(k) & """ role=""status"" aria-live=""polite"">" & _
              "<span class=""toast__icon"" aria-hidden=""true"">" & IIf(k = "error", "!", "✓") & "</span>" & _
              "<span class=""toast__body""><strong>" & H(t) & "</strong>" & _
              IIf(Len(d) > 0, "<span>" & H(d) & "</span>", "") & "</span>" & _
              "<button type=""button"" class=""toast__close"" aria-label=""Cerrar"">×</button></div>"
        LeerFlash = out
    End If
    Session("PM_FLASH_TITULO")  = Empty
    Session("PM_FLASH_DETALLE") = Empty
    Session("PM_FLASH_TIPO")    = Empty
End Function

'--- IIf no existe en VBScript ------------------------------------
Public Function IIf(condicion, verdadero, falso)
    If condicion Then IIf = verdadero Else IIf = falso
End Function
%>
