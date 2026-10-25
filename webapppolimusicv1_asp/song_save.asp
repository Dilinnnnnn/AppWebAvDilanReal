<%@Language=VBScript%>
<% Option Explicit %>
<!--#include file="includes/comun.asp"-->
<%
'=====================================================================
'  song_save.asp  -  Guarda altas y modificaciones de canciones
'---------------------------------------------------------------------
'  Recibe el POST del formulario, valida y ejecuta INSERT/UPDATE
'  con parámetros. También mantiene las tablas puente TBL_TRACKLIST
'  (álbum) y TBL_PLAYER (artista) del modelo entidad-relación.
'=====================================================================
SesionRequerir()

If Not UsuarioEsAdmin() Then
    FijarFlash "Acceso restringido", "Solo el administrador puede modificar el catálogo.", "error"
    Response.Redirect "songs.asp"
End If

If Request.ServerVariables("REQUEST_METHOD") <> "POST" Then
    Response.Redirect "songs.asp"
End If

Dim idCancion, nombre, ruta, plays, idAlbum, idArtista
Dim errores : errores = ""

idCancion = Request.Form("id") & ""
If Not EsEntero(idCancion) Then idCancion = "0"
idCancion = CLng(idCancion)

nombre = Trim(Request.Form("nombre") & "")
ruta   = Trim(Request.Form("ruta") & "")
plays  = Request.Form("plays") & ""
If Not EsEntero(plays) Or CLng(plays) < 0 Then plays = "0"

idAlbum = Request.Form("album") & ""
If Not EsEntero(idAlbum) Or CLng(idAlbum) < 0 Then idAlbum = "0"

idArtista = Request.Form("artista") & ""
If Not EsEntero(idArtista) Or CLng(idArtista) < 0 Then idArtista = "0"

'--- Validaciones -------------------------------------------------
If Len(nombre) = 0 Then
    errores = errores & "<li>El nombre de la canción es obligatorio.</li>"
ElseIf Len(nombre) > 50 Then
    errores = errores & "<li>El nombre no puede superar los 50 caracteres.</li>"
End If

If Len(ruta) = 0 Then
    errores = errores & "<li>La ruta del archivo MP3 es obligatoria.</li>"
ElseIf Len(ruta) > 255 Then
    errores = errores & "<li>La ruta no puede superar los 255 caracteres.</li>"
ElseIf LCase(Right(ruta, 4)) <> ".mp3" Then
    errores = errores & "<li>La ruta debe apuntar a un archivo .mp3.</li>"
End If

If Len(errores) > 0 Then
    FijarFlash "No se pudo guardar", "Revisa los campos marcados del formulario.", "error"
    Response.Redirect IIf(idCancion > 0, "song_form.asp?id=" & idCancion, "song_form.asp")
End If

'--- Evita duplicados por nombre (la BD no tiene índice único) ----
Dim repetida
repetida = SqlEscalar("SELECT TOP 1 ID_SONG FROM TBL_SONG WHERE SONG_NAME = ? AND ID_SONG <> ?", Array(nombre, idCancion))
If Not IsNull(repetida) Then
    FijarFlash "Nombre duplicado", "Ya existe una canción llamada """ & nombre & """ en el catálogo.", "error"
    Response.Redirect IIf(idCancion > 0, "song_form.asp?id=" & idCancion, "song_form.asp")
End If

Dim idFinal
If idCancion > 0 Then
    '--- UPDATE ---------------------------------------------------
    SqlEjecutar "UPDATE TBL_SONG SET SONG_NAME = ?, SONG_PATH = ?, PLAYS = ? WHERE ID_SONG = ?", _
                Array(nombre, ruta, CLng(plays), idCancion)
    idFinal = idCancion
Else
    '--- INSERT ---------------------------------------------------
    SqlEjecutar "INSERT INTO TBL_SONG (SONG_NAME, SONG_PATH, PLAYS) VALUES (?, ?, ?)", _
                Array(nombre, ruta, CLng(plays))
    idFinal = CLng(SqlEscalar("SELECT TOP 1 ID_SONG FROM TBL_SONG WHERE SONG_NAME = ? ORDER BY ID_SONG DESC", Array(nombre)))
End If

'--- Relaciones del modelo E-R (se reconstruyen desde cero) ------
If idFinal > 0 Then
    SqlEjecutar "DELETE FROM TBL_TRACKLIST WHERE ID_SONG = ?", Array(idFinal)
    SqlEjecutar "DELETE FROM TBL_PLAYER WHERE ID_SONG = ?", Array(idFinal)
    If CLng(idAlbum) > 0 Then
        SqlEjecutar "INSERT INTO TBL_TRACKLIST (ID_ALBUM, ID_SONG) VALUES (?, ?)", Array(CLng(idAlbum), idFinal)
    End If
    If CLng(idArtista) > 0 Then
        SqlEjecutar "INSERT INTO TBL_PLAYER (ID_SONG, ID_ARTIST) VALUES (?, ?)", Array(idFinal, CLng(idArtista))
    End If
End If

If idCancion > 0 Then
    FijarFlash "Canción actualizada", "Los cambios de """ & nombre & """ se guardaron correctamente.", "ok"
Else
    FijarFlash "Canción creada", """" & nombre & """" & " se agregó al listado de canciones.", "ok"
End If

Response.Redirect "songs.asp"
%>
