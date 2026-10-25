<%@Language=VBScript%>
<% Option Explicit %>
<!--#include file="includes/comun.asp"-->
<%
'=====================================================================
'  login.asp  -  Inicio de sesión
'---------------------------------------------------------------------
'  Valida usuario y contraseña contra TBL_USER (SQL Server 2025),
'  guarda los datos en variables de sesión y entra a Song List.
'  Los roles (0 = usuario normal, 1 = administrador) vienen de
'  TBL_CATALOG y se respetan en todas las páginas.
'=====================================================================

SesionIniciarTemporizador()

Dim usuario, clave, mensaje, campoUsuario
usuario = Trim(Request.Form("usuario") & "")
clave   = Trim(Request.Form("clave") & "")
mensaje = ""

' Si ya hay sesión abierta, se entra directamente.
If UsuarioLogueado() Then
    Response.Redirect "songs.asp"

ElseIf Len(usuario) > 0 Then
    Dim rs, filas
    Set rs = SqlConsulta("SELECT ID_USER, USERNAME, EMAIL, USER_PHOTO, USER_TYPE " & _
                         "FROM TBL_USER WHERE USERNAME = ? AND PASSWORD = ?", Array(usuario, clave))
    If Not rs.EOF Then
        Session("PM_USUARIO_ID")     = CLng(rs.Fields("ID_USER").Value)
        Session("PM_USUARIO_NOMBRE") = rs.Fields("USERNAME").Value
        Session("PM_USUARIO_CORREO") = rs.Fields("EMAIL").Value
        Session("PM_USUARIO_FOTO")   = rs.Fields("USER_PHOTO").Value
        Session("PM_USUARIO_ROL")    = CLng(rs.Fields("USER_TYPE").Value)
        rs.Close : Set rs = Nothing
        FijarFlash "Bienvenido a PoliMusic", "Sesión iniciada correctamente", "ok"
        Dim volver
        volver = Request.QueryString("volver") & ""
        ' Solo se aceptan rutas relativas dentro de la propia aplicación.
        If Len(volver) > 0 And InStr(volver, "://") = 0 _
           And InStr(LCase(volver), "login.asp") = 0 And InStr(LCase(volver), "logout.asp") = 0 Then
            Response.Redirect volver
        End If
        Response.Redirect "songs.asp"
    Else
        rs.Close : Set rs = Nothing
        mensaje = "Usuario o contraseña incorrectos. Verifica tus datos e inténtalo de nuevo."
    End If
End If
%>
<!DOCTYPE html>
<html lang="es" data-tema="oscuro">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Iniciar sesión · PoliMusic</title>
<link rel="icon" href="assets/img/favicon.svg" type="image/svg+xml">
<link rel="stylesheet" href="assets/css/styles.css">
</head>
<body class="pagina-login">
<div class="login">
  <section class="login__marca">
    <div class="login__logo" aria-hidden="true">
      <svg viewBox="0 0 24 24" width="34" height="34" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
        <path d="M9 18V6l10-2v12"/><circle cx="6.5" cy="18" r="2.5"/><circle cx="16.5" cy="16" r="2.5"/>
      </svg>
    </div>
    <h1 class="login__titulo">Poli<span>Music</span></h1>
    <p class="login__sub">Tu música, tus listas y tus artistas en un solo lugar. Construido con ASP clásico, VBScript y SQL Server 2025.</p>
    <ul class="login__puntos">
      <li><span class="punto punto--verde"></span> Dos roles: usuario normal y administrador</li>
      <li><span class="punto punto--verde"></span> Solo el administrador administra las canciones</li>
      <li><span class="punto punto--verde"></span> Reproductor integrado con cola y control de plays</li>
    </ul>
  </section>

  <section class="login__panel">
    <h2 class="login__bienvenida">Iniciar sesión</h2>
    <p class="login__ayuda">Ingresa con tu cuenta para escuchar el catálogo de PoliMusic.</p>

    <% If Len(mensaje) > 0 Then %>
    <div class="alerta alerta--error" role="alert">
      <strong>No pudimos iniciar sesión</strong>
      <span><%= H(mensaje) %></span>
    </div>
    <% End If %>

    <form method="post" action="login.asp" class="formulario" id="formLogin" novalidate>
      <div class="campo">
        <label for="usuario">Usuario</label>
        <div class="campo__caja">
          <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
          <input type="text" id="usuario" name="usuario" value="<%= H(Request.Form("usuario")) %>" placeholder="userAdmin" autocomplete="username" required>
        </div>
      </div>
      <div class="campo">
        <label for="clave">Contraseña</label>
        <div class="campo__caja">
          <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>
          <input type="password" id="clave" name="clave" placeholder="••••••••" autocomplete="current-password" required>
        </div>
      </div>
      <button type="submit" class="boton boton--principal boton--ancho" id="btnEntrar">Entrar</button>
    </form>

    <div class="login__cuentas">
      <p class="login__cuentas-titulo">Cuentas de demostración</p>
      <div class="cuentas">
        <button type="button" class="cuenta" data-usuario="userAdmin" data-clave="12345678">
          <span class="cuenta__rol cuenta__rol--admin">Admin</span>
          <strong>userAdmin</strong>
          <span>CRUD completo de canciones</span>
        </button>
        <button type="button" class="cuenta" data-usuario="userNormal" data-clave="12345678">
          <span class="cuenta__rol cuenta__rol--usuario">Normal</span>
          <strong>userNormal</strong>
          <span>Solo escuchar y explorar</span>
        </button>
      </div>
    </div>
  </section>
</div>

<script src="assets/js/login.js" defer></script>
</body>
</html>
