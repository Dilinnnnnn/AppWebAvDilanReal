<%@Language=VBScript%>
<% Option Explicit %>
<!--#include file="includes/comun.asp"-->
<%
'=====================================================================
'  album_detail.asp  -  Canciones de un álbum (TBL_ALBUM/TBL_TRACKLIST)
'=====================================================================
SesionRequerir()

Dim idAlbum, rs, titulo, portada, anio
idAlbum = Request.QueryString("id") & ""
If Not EsEntero(idAlbum) Then idAlbum = "0"
idAlbum = CLng(idAlbum)

Set rs = SqlConsulta("SELECT TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH FROM TBL_ALBUM WHERE ID_ALBUM = ?", Array(idAlbum))
If rs.EOF Then
    rs.Close : Set rs = Nothing
    FijarFlash "Álbum no encontrado", "El álbum que buscas no existe.", "error"
    Response.Redirect "albums.asp"
End If
titulo  = Txt(rs.Fields("TITLE_ALBUM").Value)
anio    = Txt(rs.Fields("RELEASE_YEAR").Value)
portada = AssetUrl(Txt(rs.Fields("ALBUM_IMAGE_PATH").Value))
rs.Close : Set rs = Nothing

Set rs = SqlConsulta( _
    "SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, ISNULL(s.PLAYS,0) AS PLAYS, " & _
    "       ISNULL(a.ARTIST_NAME + ' ' + a.ARTIST_LASTNAME,'Artista desconocido') AS ARTISTA " & _
    "FROM TBL_TRACKLIST t " & _
    "JOIN TBL_SONG s  ON s.ID_SONG  = t.ID_SONG " & _
    "LEFT JOIN TBL_PLAYER p  ON p.ID_SONG = s.ID_SONG " & _
    "LEFT JOIN TBL_ARTIST a  ON a.ID_ARTIST = p.ID_ARTIST " & _
    "WHERE t.ID_ALBUM = ? ORDER BY s.ID_SONG", Array(idAlbum))

Cabecera titulo, "albumes"
%>

<section class="hero">
  <div class="hero__portada">
    <img src="<%= portada %>" alt="Portada de <%= H(titulo) %>" width="220" height="220" loading="lazy">
  </div>
  <div class="hero__texto">
    <p class="hero__eyebrow"><a class="enlace-simple" href="<%= Url("albums.asp") %>">Álbumes</a> · <%= H(anio) %></p>
    <h1 class="hero__titulo"><%= H(titulo) %></h1>
    <p class="hero__sub">Listado de canciones incluidas en este álbum (relación TBL_TRACKLIST).</p>
    <p class="hero__bienvenida">
      <span class="hero__saludo">Bienvenido,</span>
      <strong><%= H(SesionNombre()) %></strong>
      <span class="chip chip--<%= IIf(UsuarioEsAdmin(), "admin", "usuario") %>"><%= H(SesionRolTexto()) %></span>
    </p>
  </div>
</section>

<section class="panel">
  <div class="panel__cabecera">
    <div>
      <h2 class="panel__titulo">Canciones del álbum</h2>
      <p class="panel__sub">Haz clic en el botón de reproducción de cualquier fila.</p>
    </div>
  </div>

  <div class="tabla-envoltorio">
    <table class="tabla-canciones">
      <thead>
        <tr>
          <th class="col-indice" scope="col">#</th>
          <th scope="col">Título</th>
          <th scope="col" class="col-oculta-movil">Artista</th>
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
            data-artista="<%= H(Txt(rs.Fields("ARTISTA").Value)) %>"
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
          <td class="col-oculta-movil"><%= H(Txt(rs.Fields("ARTISTA").Value)) %></td>
          <td class="col-oculta-movil"><span class="contador-plays" id="plays<%= rs.Fields("ID_SONG").Value %>"><%= CLng(rs.Fields("PLAYS").Value) %></span></td>
        </tr>
      <%
            rs.MoveNext
        Loop
        rs.Close : Set rs = Nothing
        If i = 0 Then
      %>
        <tr><td colspan="4"><div class="vacio"><p>Este álbum todavía no tiene canciones asignadas.</p></div></td></tr>
      <% End If %>
      </tbody>
    </table>
  </div>
</section>

<%
Pie()
%>
