<%
'=====================================================================
'  PoliMusic  -  includes/comun.asp   (CARGADOR UNICO)
'---------------------------------------------------------------------
'  TODAS las paginas incluyen unicamente este archivo:
'
'      <!--#include file="includes/comun.asp"-->
'
'  Classic ASP expande las directivas #include como TEXTO PLANO: la
'  misma pagina se compila como un solo script VBScript. Si un mismo
'  archivo se incluye dos veces (por ejemplo ui.asp -> sesion.asp y
'  layout.asp -> ui.asp), sus declaraciones se duplican y el
'  compilador aborta con "Nombre redefinido" (800a0411).
'  Por eso cada modulo se carga una sola vez y en orden de
'  dependencia: datos -> sesion -> utilidades -> estructura.
'=====================================================================
%>
<!--#include file="conexion.asp"-->
<!--#include file="sesion.asp"-->
<!--#include file="ui.asp"-->
<!--#include file="layout.asp"-->
