<%@Language=VBScript%>
<% Option Explicit %>
<!--#include file="includes/comun.asp"-->
<%
'=====================================================================
'  play_count.asp  -  Contador de reproducciones (llamado por AJAX)
'---------------------------------------------------------------------
'  Suma 1 a TBL_SONG.PLAYS cada vez que el usuario reproduce una
'  canción y devuelve el nuevo valor en formato JSON.
'=====================================================================
SesionRequerir()

Response.ContentType = "application/json"
Response.CodePage    = 65001
Response.Charset     = "UTF-8"

Dim idCancion, plays
idCancion = Request.QueryString("id") & Request.Form("id") & ""
If Not EsEntero(idCancion) Then
    Response.Write "{""ok"":false,""error"":""identificador invalido""}"
    Response.End
End If

Dim existe
existe = SqlEscalar("SELECT TOP 1 ID_SONG FROM TBL_SONG WHERE ID_SONG = ?", Array(CLng(idCancion)))
If IsNull(existe) Then
    Response.Write "{""ok"":false,""error"":""la cancion no existe""}"
    Response.End
End If

SqlEjecutar "UPDATE TBL_SONG SET PLAYS = ISNULL(PLAYS,0) + 1 WHERE ID_SONG = ?", Array(CLng(idCancion))
plays = SqlEscalar("SELECT PLAYS FROM TBL_SONG WHERE ID_SONG = ?", Array(CLng(idCancion)))

Response.Write "{""ok"":true,""id"":" & CLng(idCancion) & ",""plays"":" & CStr(plays) & "}"
CerrarPagina()
%>
