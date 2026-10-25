<%@Language=VBScript%>
<% Option Explicit %>
<!--#include file="includes/comun.asp"-->
<%
'=====================================================================
'  song_delete.asp  -  Baja de canciones (SOLO ADMIN)
'---------------------------------------------------------------------
'  GET  -> pantalla de confirmación con las relaciones de la canción
'          (álbumes y listas de reproducción) que se eliminarán.
'  POST -> borrado en cascada del registro y de sus tablas puente.
'=====================================================================
SesionRequerir()

If Not UsuarioEsAdmin() Then
    FijarFlash "Acceso restringida", "Solo el administrador puede eliminar canciones.", "error"
    Response.Redirect "songs.asp"
End If

Dim idCancion, nombre, ruta, portada, artista, album
Dim enAlbums, enListas, rs, regreso
' El id puede venir por QueryString (confirmacion) o por formulario.
idCancion = Request.QueryString("id") & ""
If Len(idCancion) = 0 Then idCancion = Request.Form("id") & ""
If Not EsEntero(idCancion) Then idCancion = "0"
idCancion = CLng(idCancion)

'---------------------------------------------------------------------
'  Acción: borrar
'---------------------------------------------------------------------
If Request.Form("confirmar") = "1" And idCancion > 0 Then
    Dim borradas, fallo, nombreBorrado
    Set rs = SqlConsulta("SELECT SONG_NAME FROM TBL_SONG WHERE ID_SONG = ?", Array(idCancion))
    If Not rs.EOF Then nombreBorrado = Txt(rs.Fields("SONG_NAME").Value)
    rs.Close : Set rs = Nothing
    If Len(nombreBorrado) = 0 Then nombreBorrado = "la canción"

    borradas = 0 : fallo = False
    On Error Resume Next
    borradas = borradas + SqlEjecutar("DELETE FROM TBL_PLAYLIST_SONG WHERE ID_SONG = ?", Array(idCancion))
    borradas = borradas + SqlEjecutar("DELETE FROM TBL_TRACKLIST    WHERE ID_SONG = ?", Array(idCancion))
    borradas = borradas + SqlEjecutar("DELETE FROM TBL_PLAYER       WHERE ID_SONG = ?", Array(idCancion))
    borradas = borradas + SqlEjecutar("DELETE FROM TBL_SONG         WHERE ID_SONG = ?", Array(idCancion))
    If Err.Number <> 0 Then fallo = True : Err.Clear
    On Error GoTo 0

    If fallo Then
        FijarFlash "No se pudo eliminar", "La canción sigue referenciada por otros datos.", "error"
    Else
        FijarFlash "Canción eliminada", "Se quitó """ & nombreBorrado & """ del catálogo junto con sus " & CStr(borradas) & " referencias.", "ok"
    End If
    Response.Redirect "songs.asp"
End If

'---------------------------------------------------------------------
'  Datos para la pantalla de confirmación
'---------------------------------------------------------------------
Set rs = SqlConsulta("SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, " & _
                     "       (SELECT TOP 1 a.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST t " & _
                     "          JOIN TBL_ALBUM a ON a.ID_ALBUM = t.ID_ALBUM WHERE t.ID_SONG = s.ID_SONG) AS PORTADA " & _
                     "FROM TBL_SONG s WHERE ID_SONG = ?", Array(idCancion))

If rs.EOF Then
    rs.Close : Set rs = Nothing
    FijarFlash "Canción no encontrada", "El registro que intentas eliminar ya no existe.", "error"
    Response.Redirect "songs.asp"
End If

nombre  = Txt(rs.Fields("SONG_NAME").Value)
ruta    = Txt(rs.Fields("SONG_PATH").Value)
portada = AssetUrl(Txt(rs.Fields("PORTADA").Value))
rs.Close : Set rs = Nothing

artista = Txt(SqlEscalar("SELECT TOP 1 a.ARTIST_NAME + ' ' + ISNULL(a.ARTIST_LASTNAME,'') " & _
                         "FROM TBL_PLAYER p JOIN TBL_ARTIST a ON a.ID_ARTIST = p.ID_ARTIST " & _
                         "WHERE p.ID_SONG = ?", Array(idCancion)))
album   = Txt(SqlEscalar("SELECT TOP 1 al.TITLE_ALBUM FROM TBL_TRACKLIST t " & _
                         "JOIN TBL_ALBUM al ON al.ID_ALBUM = t.ID_ALBUM " & _
                         "WHERE t.ID_SONG = ?", Array(idCancion)))
If Len(album) = 0 Then album = "Sin álbum"
If Len(artista) = 0 Then artista = "Artista desconocido"

Set rs = SqlConsulta("SELECT al.TITLE_ALBUM FROM TBL_TRACKLIST t " & _
                     "JOIN TBL_ALBUM al ON al.ID_ALBUM = t.ID_ALBUM WHERE t.ID_SONG = ?", Array(idCancion))
If Not rs.EOF Then
    Do While Not rs.EOF
        enAlbums = enAlbums & "<li>" & H(Txt(rs.Fields("TITLE_ALBUM").Value)) & "</li>"
        rs.MoveNext
    Loop
End If
rs.Close : Set rs = Nothing

Set rs = SqlConsulta("SELECT p.TITLE FROM TBL_PLAYLIST_SONG ps " & _
                     "JOIN TBL_PLAYLIST p ON p.ID_PLAYLIST = ps.ID_PLAYLIST " & _
                     "WHERE ps.ID_SONG = ?", Array(idCancion))
If Not rs.EOF Then
    Do While Not rs.EOF
        enListas = enListas & "<li>" & H(Txt(rs.Fields("TITLE").Value)) & "</li>"
        rs.MoveNext
    Loop
End If
rs.Close : Set rs = Nothing

Cabecera "Eliminar canción", "canciones"
%>

<section class="panel panel--centrado">
  <div class="confirmacion">
    <div class="confirmacion__icono" aria-hidden="true">
      <svg viewBox="0 0 24 24" width="30" height="30" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="M6 6l1 14h10l1-14"/><path d="M10 11v6M14 11v6"/></svg>
    </div>
    <h2 class="confirmacion__titulo">¿Eliminar esta canción?</h2>
    <p class="confirmacion__texto">Esta acción no se puede deshacer. Se borrará el registro de <strong>TBL_SONG</strong> y sus relaciones del modelo entidad-relación.</p>

    <div class="confirmacion__ficha">
      <img src="<%= portada %>" alt="" width="72" height="72">
      <div>
        <strong><%= H(nombre) %></strong>
        <span><%= H(artista) %> · <%= H(album) %></span>
        <code><%= H(ruta) %></code>
      </div>
    </div>

    <% If Len(enAlbums) > 0 Or Len(enListas) > 0 Then %>
    <div class="confirmacion__relaciones">
      <p class="confirmacion__relaciones-titulo">También se quitarán las referencias en:</p>
      <% If Len(enAlbums) > 0 Then %>
      <div class="confirmacion__grupo">
        <p>Álbumes (TBL_TRACKLIST)</p>
        <ul><%= enAlbums %></ul>
      </div>
      <% End If %>
      <% If Len(enListas) > 0 Then %>
      <div class="confirmacion__grupo">
        <p>Listas de reproducción (TBL_PLAYLIST_SONG)</p>
        <ul><%= enListas %></ul>
      </div>
      <% End If %>
    </div>
    <% End If %>

    <form method="post" action="song_delete.asp?id=<%= idCancion %>" class="confirmacion__acciones">
      <input type="hidden" name="confirmar" value="1">
      <button type="submit" class="boton boton--peligro">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="M6 6l1 14h10l1-14"/></svg>
        Sí, eliminar definitivamente
      </button>
      <a class="boton boton--fantasma" href="<%= Url("songs.asp") %>">Cancelar y volver al Song List</a>
    </form>
  </div>
</section>

<%
Pie()
%>
