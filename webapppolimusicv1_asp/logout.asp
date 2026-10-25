<%@Language=VBScript%>
<% Option Explicit %>
<!--#include file="includes/comun.asp"-->
<%
'=====================================================================
'  logout.asp  -  Cierre de sesión
'---------------------------------------------------------------------
'  Destruye las variables de sesión y regresa al inicio de sesión.
'=====================================================================

SesionIniciarTemporizador()
SesionCerrar()
Response.Redirect "login.asp?msg=salida"
%>
