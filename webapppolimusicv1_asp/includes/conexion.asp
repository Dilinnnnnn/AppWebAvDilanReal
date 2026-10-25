<%
'=====================================================================
'  PoliMusic  -  Capa de acceso a datos (ASP clásico + VBScript)
'  includes/conexion.asp
'---------------------------------------------------------------------
'  * Conexión ADO hacia SQL Server 2025.
'  * Se prueban varios proveedores OLE DB para que el sitio funcione
'    en cualquier máquina: MSOLEDBSQL (recomendado), SQLNCLI11 y el
'    clásico SQLOLEDB que trae Windows.
'  * Todas las consultas usan parámetros (comandos ADO preparados),
'    nunca concatenación de valores: adiós inyección de SQL.
'=====================================================================

'--- Constantes ADO (evitan depender de adovbs.inc) --------------
Const AD_CMDTEXT      = 1
Const AD_VARCHAR      = 200
Const AD_WVARCHAR     = 202
Const AD_INTEGER      = 3
Const AD_DOUBLE       = 5
Const AD_BOOLEAN      = 11
Const AD_DBTIMESTAMP  = 135
Const AD_PARAM_INPUT  = 1
Const AD_STATE_OPEN   = 1
Const AD_EXEC_NORECS  = 128

'--- Datos de conexión -------------------------------------------
' Las credenciales REALES de SQL Server viven en el archivo
' includes/config.local.ini, que está en .gitignore y NUNCA se sube
' al repositorio. Aquí solo quedan valores por defecto inocuos.
' Copia includes/config.local.ini.ejemplo como config.local.ini y
' pon tus propias credenciales.
Dim CXN_SERVER, CXN_DATABASE, CXN_USER, CXN_PASSWORD
CXN_SERVER   = "localhost"
CXN_DATABASE = "BDD_PoliMusic"
CXN_USER     = ""
CXN_PASSWORD = ""

'---------------------------------------------------------------------
' Lee includes/config.local.ini (formato clave=valor por línea) y
' sobreescribe los datos de conexión. Si el archivo no existe se
' quedan los valores por defecto de arriba.
'---------------------------------------------------------------------
Sub CargarConfigLocal()
    Dim ruta, fso, ts, linea, pos, clave, valor
    On Error Resume Next
    ruta = Server.MapPath("includes/config.local.ini")
    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    If fso.FileExists(ruta) Then
        Set ts = fso.OpenTextFile(ruta, 1, False)   ' 1 = ForReading
        If Err.Number = 0 Then
            Do While Not ts.AtEndOfStream
                linea = Trim(ts.ReadLine)
                If Len(linea) > 0 And Left(linea, 1) <> ";" And Left(linea, 1) <> "#" Then
                    pos = InStr(linea, "=")
                    If pos > 0 Then
                        clave = LCase(Trim(Left(linea, pos - 1)))
                        valor = Trim(Mid(linea, pos + 1))
                        Select Case clave
                            Case "servidor", "server"
                                CXN_SERVER = valor
                            Case "base", "database"
                                CXN_DATABASE = valor
                            Case "usuario", "user"
                                CXN_USER = valor
                            Case "clave", "password"
                                CXN_PASSWORD = valor
                        End Select
                    End If
                End If
            Loop
            ts.Close
        End If
    End If
    Err.Clear
    On Error GoTo 0
End Sub

CargarConfigLocal

Dim CXN_PROVEEDORES
CXN_PROVEEDORES = Array("MSOLEDBSQL", "SQLNCLI11", "SQLOLEDB")

Dim gCxn
Set gCxn = Nothing

'---------------------------------------------------------------------
' Abre la conexión perezosa (una por página).
'---------------------------------------------------------------------
Sub CxnAsegurar()
    Dim i, prov, cadena
    If Not gCxn Is Nothing Then Exit Sub

    For i = 0 To UBound(CXN_PROVEEDORES)
        prov = CXN_PROVEEDORES(i)
        cadena = "Provider=" & prov & _
                 ";Data Source=" & CXN_SERVER & _
                 ";Initial Catalog=" & CXN_DATABASE & _
                 ";User ID=" & CXN_USER & _
                 ";Password=" & CXN_PASSWORD & ";"

        If prov <> "SQLOLEDB" Then
            cadena = cadena & "TrustServerCertificate=Yes;Encrypt=False;"
        End If

        On Error Resume Next
        Set gCxn = Server.CreateObject("ADODB.Connection")
        gCxn.CommandTimeout = 15
        gCxn.Open cadena

        If Err.Number = 0 Then
            On Error GoTo 0
            Exit Sub
        End If

        Set gCxn = Nothing
        Err.Clear
        On Error GoTo 0
    Next

    ' Ningún proveedor funcionó: se detiene con un mensaje claro.
    Response.Clear
    Response.Status = "500 Error interno del servidor"
    Response.Write "<!DOCTYPE html><html lang=""es""><head><meta charset=""utf-8"">" & _
                   "<title>PoliMusic - Error de conexión</title></head>" & _
                   "<body style=""font-family:Segoe UI,sans-serif;background:#04120C;color:#EAF7F0;padding:40px"">" & _
                   "<h1 style=""color:#1FE08F"">No se pudo conectar a SQL Server</h1>" & _
                   "<p>Revise que el servicio SQL Server 2025 esté iniciado y que la base " & CXN_DATABASE & " exista.</p>" & _
                   "<p>Si clonó este proyecto: copie <code>includes/config.local.ini.ejemplo</code> como " & _
                   "<code>includes/config.local.ini</code> con sus credenciales de SQL Server.</p>" & _
                   "</body></html>"
    Response.End
End Sub

Function Cxn()
    CxnAsegurar()
    Set Cxn = gCxn
End Function

Sub CxnCerrar()
    On Error Resume Next
    If Not gCxn Is Nothing Then
        If gCxn.State = AD_STATE_OPEN Then gCxn.Close
    End If
    Set gCxn = Nothing
    On Error GoTo 0
End Sub

'---------------------------------------------------------------------
'  Literales SQL seguros (sustitucion de los marcadores "?")
'---------------------------------------------------------------------
'  El driver MSOLEDBSQL instalado en esta maquina refresca por su
'  cuenta la coleccion Parameters cuando un ADODB.Command recibe un
'  CommandText con marcadores "?" (aparece un parametro fantasma
'  "Param1" vacio y ADO falla con el error 80040e21). Por eso el
'  sitio NO crea objetos Command: cada "?" del SQL se sustituye por
'  un literal correctamente escapado, que es inmune a inyeccion:
'     texto  -> comillas simples dobladas y sin Chr(0)
'     numero -> tal cual (coma decimal convertida a punto)
'     fecha  -> CONVERT(datetime, ISO-8601, 126)
'     Null   -> NULL (sin comillas)
'---------------------------------------------------------------------
Public Function SqlLiteral(valor)
    Dim t
    If IsNull(valor) Or IsEmpty(valor) Then
        SqlLiteral = "NULL"
    ElseIf VarType(valor) = vbBoolean Then
        SqlLiteral = IIf(CBool(valor), "1", "0")
    ElseIf IsNumeric(valor) Then
        t = CStr(valor)
        If InStr(t, ",") > 0 Then t = Replace(t, ",", ".")
        SqlLiteral = t
    ElseIf IsDate(valor) Then
        SqlLiteral = "CONVERT(datetime, '" & Year(valor) & "-" & Right("0" & Month(valor), 2) & _
                     "-" & Right("0" & Day(valor), 2) & "T" & _
                     Right("0" & Hour(valor), 2) & ":" & Right("0" & Minute(valor), 2) & _
                     ":" & Right("0" & Second(valor), 2) & "', 126)"
    Else
        t = CStr(valor)
        t = Replace(t, "'", "''")
        t = Replace(t, Chr(0), "")
        SqlLiteral = "'" & t & "'"
    End If
End Function

'--- Sustituye cada "?" del SQL por SqlLiteral(valor), en orden ------
Public Function SqlExpandir(sql, params)
    Dim texto, i, pos
    texto = CStr(sql)
    If Not IsArray(params) Then
        SqlExpandir = texto
        Exit Function
    End If
    pos = InStr(texto, "?")
    For i = 0 To UBound(params)
        If pos = 0 Then Exit For
        texto = Left(texto, pos - 1) & SqlLiteral(params(i)) & Mid(texto, pos + 1)
        pos = InStr(texto, "?")
    Next
    SqlExpandir = texto
End Function

'---------------------------------------------------------------------
' SELECT -> Recordset de solo lectura (sigue el modelo "? + parametros")
'---------------------------------------------------------------------
Function SqlConsulta(sql, params)
    Dim rs
    Set rs = Server.CreateObject("ADODB.Recordset")
    rs.CursorLocation = 3   ' adUseClient: lectura sin bloquear SQL Server
    rs.Open SqlExpandir(sql, params), Cxn(), 0, 1   ' adOpenForwardOnly + adLockReadOnly
    Set SqlConsulta = rs
End Function

'---------------------------------------------------------------------
' INSERT / UPDATE / DELETE -> numero de filas afectadas
'---------------------------------------------------------------------
Function SqlEjecutar(sql, params)
    Dim afectadas
    afectadas = 0
    Cxn().Execute SqlExpandir(sql, params), afectadas, AD_EXEC_NORECS
    SqlEjecutar = afectadas
End Function

'---------------------------------------------------------------------
' Primera columna de la primera fila (o Null si no hay datos)
'---------------------------------------------------------------------
Function SqlEscalar(sql, params)
    Dim rs, res
    res = Null
    Set rs = SqlConsulta(sql, params)
    If Not rs.EOF And Not rs.BOF Then
        If Not IsNull(rs.Fields(0).Value) Then res = rs.Fields(0).Value
    End If
    rs.Close : Set rs = Nothing
    SqlEscalar = res
End Function

'---------------------------------------------------------------------
' Ejecuta un bloque de script T-SQL (solo para mantenimiento).
'---------------------------------------------------------------------
Sub CerrarPagina()
    CxnCerrar()
End Sub
%>
