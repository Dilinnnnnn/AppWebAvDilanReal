<%
'=====================================================================
'  PoliMusic  -  includes/sesion.asp   (se carga desde comun.asp)
'---------------------------------------------------------------------
'  Control de acceso: obliga a iniciar sesión en todas las páginas
'  privadas y expone los roles (0 = usuario normal, 1 = administrador)
'  definidos en TBL_CATALOG (COD_CATALOG_PARENT = 1).
'=====================================================================

Const SESION_TIEMPO_VIDA = 60   ' minutos

Sub SesionIniciarTemporizador()
    Session.Timeout = SESION_TIEMPO_VIDA
    Session.CodePage = 65001
End Sub

Sub SesionRequerir()
    If Not UsuarioLogueado() Then
        Dim destino
        destino = Request.ServerVariables("SCRIPT_NAME")
        If Len(Request.ServerVariables("QUERY_STRING")) > 0 Then
            destino = destino & "?" & Request.ServerVariables("QUERY_STRING")
        End If
        Response.Redirect "login.asp?volver=" & Server.URLEncode(destino)
    End If
End Sub

Function UsuarioLogueado()
    Dim v
    v = Session("PM_USUARIO_ID")
    UsuarioLogueado = (IsNumeric(v) And CLng(v) > 0)
End Function

'--- Nombre que se muestra en el saludo de bienvenida -------------
Function SesionNombre()
    Dim n
    n = Session("PM_USUARIO_NOMBRE")
    If Len(n) = 0 Then n = "invitado"
    SesionNombre = n
End Function

Function SesionCorreo()
    SesionCorreo = Session("PM_USUARIO_CORREO")
End Function

Function SesionFoto()
    Dim f
    f = Session("PM_USUARIO_FOTO")
    If Len(f) = 0 Then f = "~/UserImages/default.jpg"
    SesionFoto = AssetUrl(f)
End Function

'--- Roles ---------------------------------------------------------
Function UsuarioEsAdmin()
    UsuarioEsAdmin = (CLng(Session("PM_USUARIO_ROL")) = 1)
End Function

Function SesionRolTexto()
    If UsuarioEsAdmin() Then
        SesionRolTexto = "Administrador"
    Else
        SesionRolTexto = "Usuario"
    End If
End Function

Sub SesionCerrar()
    Session.Abandon()
End Sub
%>
