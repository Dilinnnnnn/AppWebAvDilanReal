<%@Language=VBScript%>
<% Option Explicit %>
<!--#include file="includes/comun.asp"-->
<%
'=====================================================================
'  playlist_detail.asp  -  Canciones de una lista (TBL_PLAYLIST_SONG)
'=====================================================================
SesionRequerir()

Dim idLista, rs, titulo, portada, propietario, tipo, creada
idLista = Request.QueryString("id") & ""
If Not EsEntero(idLista) Then idLista = "0"
idLista = CLng(idLista)

Set rs = SqlConsulta("SELECT p.ID_PLAYLIST, p.TITLE, p.CREATION_DATE, p.TYPE, p.PHOTO, u.USERNAME " & _
                     "FROM TBL_PLAYLIST p JOIN TBL_USER u ON u.ID_USER = p.ID_USER " & _
                     "WHERE p.ID_PLAYLIST = ?", Array(idLista))
If rs.EOF Then
    rs.Close : Set rs = Nothing
    FijarFlash "Lista no encontrada", "La lista que buscas no existe.", "error"
    Response.Redirect "playlists.asp"
End If
titulo     = Txt(rs.Fields("TITLE").Value)
Creada     = FechaCorta(rs.Fields("CREATION_DATE").Value)
tipo       = CLng(rs.Fields("TYPE").Value)
portada    = AssetUrl(Txt(rs.Fields("PHOTO").Value))
propietario = Txt(rs.Fields("USERNAME").Value)
rs.Close : Set rs = Nothing

Set rs = SqlConsulta( _
    "SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, ISNULL(s.PLAYS,0) AS PLAYS, " & _
    "       (SELECT TOP 1 a.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST t " & _
    "          JOIN TBL_ALBUM a ON a.ID_ALBUM = t.ID_ALBUM WHERE t.ID_SONG = s.ID_SONG) AS PORTADA " & _
    "FROM TBL_PLAYLIST_SONG ps " & _
    "JOIN TBL_SONG s ON s.ID_SONG = ps.ID_SONG " & _
    "WHERE ps.ID_PLAYLIST = ? ORDER BY s.ID_SONG", Array(idLista))

Cabecera titulo, "playlists"
%>

<section class="hero">
  <div class="hero__portada">
    <img src="<%= portada %>" alt="Portada de la lista" width="220" height="220" loading="lazy">
  </div>
  <div class="hero__texto">
    <p class="hero__eyebrow"><a class="enlace-simple" href="<%= Url("playlists.asp") %>">Listas</a> · <%= H(propietario) %> · <%= H(creada) %></p>
    <h1 class="hero__titulo"><%= H(titulo) %></h1>
    <p class="hero__sub">Canciones guardadas en esta lista (relación TBL_PLAYLIST_SONG).</p>
    <p class="hero__bienvenida">
      <span class="hero__saludo">Bienvenido,</span>
      <strong><%= H(SesionNombre()) %></strong>
      <span class="chip chip--<%= IIf(UsuarioEsAdmin(), "admin", "usuario") %>"><%= H(SesionRolTexto()) %></span>
      <span class="chip <%= IIf(tipo = 1, "chip--privada", "chip--publica") %>"><%= IIf(tipo = 1, "Privada", "Pública") %></span>
    </p>
  </div>
</section>

<section class="panel">
  <div class="panel__cabecera">
    <div>
      <h2 class="panel__titulo">Canciones de la lista</h2>
      <p class="panel__sub">Reproduce directamente desde aquí o añade cualquier canción a la cola.</p>
    </div>
  </div>

  <div class="tabla-envoltorio">
    <table class="tabla-canciones">
      <thead>
        <tr>
          <th class="col-indice" scope="col">#</th>
          <th scope="col">Título</th>
          <th scope="col" class="col-oculta-movil">Reproducciones</th>
        </tr>
      </thead>
      <tbody>
      <%
        Dim i, src
        i = 0
        Do While Not rs.EOF
            i = i + 1
            src = AssetUrl(Txt(rs.Fields("SONG_PATH").Value))
      %>
        <tr class="fila-cancion pista"
            data-id="<%= rs.Fields("ID_SONG").Value %>"
            data-src="<%= H(src) %>"
            data-titulo="<%= H(Txt(rs.Fields("SONG_NAME").Value)) %>"
            data-artista="<%= H(titulo) %>"
            data-album="<%= H(titulo) %>"
            data-portada="<%= H(portada) %>"
            data-plays="<%= CLng(rs.Fields("PLAYS").Value) %>">
          <td class="col-indice">
            <span class="fila-cancion__numero"><%= i %></span>
            <button type="button" class="fila-cancion__play js-play" aria-label="Reproducir" title="Reproducir">
              <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
            </button>
            <span class="fila-cancion__ecualizador" aria-hidden="true"><i></i><i></i><i></i></span>
          </td>
          <td><span class="fila-cancion__titulo"><%= H(Txt(rs.Fields("SONG_NAME").Value)) %></span></td>
          <td class="col-oculta-movil"><span class="contador-plays" id="plays<%= rs.Fields("ID_SONG").Value %>"><%= CLng(rs.Fields("PLAYS").Value) %></span></td>
        </tr>
      <%
            rs.MoveNext
        Loop
        rs.Close : Set rs = Nothing
        If i = 0 Then
      %>
        <tr><td colspan="3"><div class="vacio"><p>Esta lista todavía no tiene canciones.</p></div></td></tr>
      <% End If %>
      </tbody>
    </table>
  </div>
</section>

<%
Pie()
%>
