<%@Language=VBScript%>
<% Option Explicit %>
<!--#include file="includes/comun.asp"-->
<%
'=====================================================================
'  default.asp  -  Punto de entrada de la aplicación
'=====================================================================
SesionIniciarTemporizador()

If UsuarioLogueado() Then
    Response.Redirect "songs.asp"
Else
    Response.Redirect "login.asp"
End If
%>
