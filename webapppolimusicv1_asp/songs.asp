<%@Language=VBScript%>
<% Option Explicit %>
<!--#include file="includes/comun.asp"-->
<%
'=====================================================================
'  songs.asp  -  "Song List" (página de canciones)
'---------------------------------------------------------------------
'  * Muestra el listado completo de canciones con su artista, álbum,
'    carátula, número de reproducciones y duración real del archivo.
'  * Saludo de bienvenida con el nombre guardado en la sesión.
'  * Rol administrador: altas, edición y borrado (CRUD).
'  * Rol normal: solo escuchar.
'  * La duración se calcula leyendo la cabecera del MP3.
'=====================================================================

SesionRequerir()

Dim busqueda
busqueda = Trim(Request.QueryString("q") & "")

'--- Catálogo de canciones (usa las relaciones del modelo E-R:
'    TBL_SONG, TBL_PLAYER/TBL_ARTIST y TBL_TRACKLIST/TBL_ALBUM) ---
Dim sqlCanciones
sqlCanciones = _
    "SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, ISNULL(s.PLAYS,0) AS PLAYS, " & _
    "       ISNULL(t.ARTISTAS,'Artista desconocido') AS ARTISTAS, " & _
    "       t.PORTADA, t.ALBUM " & _
    "FROM TBL_SONG s " & _
    "OUTER APPLY ( " & _
    "   SELECT STRING_AGG(a.ARTIST_NAME + ' ' + ISNULL(a.ARTIST_LASTNAME,''), ', ') AS ARTISTAS, " & _
    "          (SELECT TOP 1 al.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST tl " & _
    "             JOIN TBL_ALBUM al ON al.ID_ALBUM = tl.ID_ALBUM " & _
    "            WHERE tl.ID_SONG = s.ID_SONG) AS PORTADA, " & _
    "          (SELECT TOP 1 al.TITLE_ALBUM FROM TBL_TRACKLIST tl " & _
    "             JOIN TBL_ALBUM al ON al.ID_ALBUM = tl.ID_ALBUM " & _
    "            WHERE tl.ID_SONG = s.ID_SONG) AS ALBUM " & _
    "   FROM TBL_PLAYER p " & _
    "   JOIN TBL_ARTIST a ON a.ID_ARTIST = p.ID_ARTIST " & _
    "   WHERE p.ID_SONG = s.ID_SONG " & _
    ") t "

Dim sqlFiltro, params
sqlFiltro = ""
params = Array()
If Len(busqueda) > 0 Then
    sqlFiltro = " WHERE (? = '' OR s.SONG_NAME LIKE '%' + ? + '%' " & _
                "        OR t.ARTISTAS LIKE '%' + ? + '%' " & _
                "        OR t.ALBUM LIKE '%' + ? + '%') "
    params = Array(busqueda, busqueda, busqueda, busqueda)
End If

Dim rsCanciones
Set rsCanciones = SqlConsulta(sqlCanciones & sqlFiltro & " ORDER BY s.ID_SONG", params)

Dim rsPortada, portadaHero, albumHero
Set rsPortada = SqlConsulta("SELECT TOP 1 a.ALBUM_IMAGE_PATH, a.TITLE_ALBUM, a.RELEASE_YEAR " & _
                            "FROM TBL_TRACKLIST t JOIN TBL_ALBUM a ON a.ID_ALBUM = t.ID_ALBUM " & _
                            "ORDER BY t.ID_ALBUM", Array())
If Not rsPortada.EOF Then
    portadaHero = AssetUrl(Txt(rsPortada.Fields("ALBUM_IMAGE_PATH").Value))
    albumHero    = Txt(rsPortada.Fields("TITLE_ALBUM").Value)
    If Len(Txt(rsPortada.Fields("RELEASE_YEAR").Value)) > 0 Then albumHero = albumHero & " · " & rsPortada.Fields("RELEASE_YEAR").Value
Else
    portadaHero = Url("assets/img/placeholder.svg")
    albumHero   = "PoliMusic"
End If
rsPortada.Close : Set rsPortada = Nothing

Dim rsStats, totalCanciones, totalPlays
totalCanciones = 0 : totalPlays = 0
Set rsStats = SqlConsulta("SELECT COUNT(*) AS C, ISNULL(SUM(PLAYS),0) AS P FROM TBL_SONG", Array())
If Not rsStats.EOF Then
    totalCanciones = CLng(rsStats.Fields("C").Value)
    totalPlays     = CDbl(rsStats.Fields("P").Value)
End If
rsStats.Close : Set rsStats = Nothing

Cabecera "Canciones", "canciones"
%>

<!-- ========================= HERO ========================= -->
<section class="hero">
  <div class="hero__portada">
    <img src="<%= portadaHero %>" alt="Portada del álbum destacado" width="220" height="220" loading="lazy">
    <button type="button" class="hero__play js-play-todo" aria-label="Reproducir todas las canciones" title="Reproducir todo">
      <svg viewBox="0 0 24 24" width="26" height="26" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
    </button>
  </div>
  <div class="hero__texto">
    <p class="hero__eyebrow">PoliMusic · Catálogo</p>
    <h1 class="hero__titulo">Song List</h1>
    <p class="hero__sub">Listado de canciones disponibles en la plataforma, con su artista, álbum y número de reproducciones.</p>
    <p class="hero__bienvenida">
      <span class="hero__saludo">Bienvenido,</span>
      <strong><%= H(SesionNombre()) %></strong>
      <span class="chip chip--<%= IIf(UsuarioEsAdmin(), "admin", "usuario") %>"><%= H(SesionRolTexto()) %></span>
    </p>
    <p class="hero__meta"><%= totalCanciones %> canciones · <%= totalPlays %> reproducciones · <%= H(albumHero) %></p>
    <div class="hero__acciones">
      <button type="button" class="boton boton--principal js-play-todo">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
        Reproducir todo
      </button>
      <button type="button" class="boton boton--fantasma" id="btnAleatorioTodo">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M16 3h5v5"/><path d="M4 20 21 3"/><path d="M21 16v5h-5"/><path d="M15 15l6 6"/><path d="M4 4l5 5"/></svg>
        Aleatorio
      </button>
      <% If UsuarioEsAdmin() Then %>
      <a class="boton boton--exito" href="<%= Url("song_form.asp") %>">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>
        Nueva canción
      </a>
      <% End If %>
    </div>
  </div>
</section>

<!-- ===================== LISTA DE CANCIONES ===================== -->
<section class="panel">
  <div class="panel__cabecera">
    <div>
      <h2 class="panel__titulo">Song List</h2>
      <p class="panel__sub">
        <% If Len(busqueda) > 0 Then %>
          Resultados para “<%= H(busqueda) %>”
        <% Else %>
          Todas las canciones del catálogo
        <% End If %>
      </p>
    </div>
    <% If UsuarioEsAdmin() Then %>
    <span class="aviso-rol">
      <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 3l8 4v5c0 5-3.5 8-8 9-4.5-1-8-4-8-9V7z"/><path d="M9 12l2 2 4-4"/></svg>
      Modo administrador: puedes crear, editar y eliminar canciones
    </span>
    <% End If %>
  </div>

  <div class="tabla-envoltorio">
    <table class="tabla-canciones" id="tablaCanciones">
      <thead>
        <tr>
          <th class="col-indice" scope="col">#</th>
          <th scope="col">Título</th>
          <th scope="col" class="col-oculta-movil">Artista</th>
          <th scope="col" class="col-oculta-tablet">Álbum</th>
          <th scope="col" class="col-oculta-movil">Reproducciones</th>
          <th scope="col" class="col-oculta-tablet">Duración</th>
          <th scope="col" class="col-acciones">Acciones</th>
        </tr>
      </thead>
      <tbody>
      <%
        Dim i, src, titulo, artista, album, portada, plays, duracion, rutaFisica
        i = 0
        Do While Not rsCanciones.EOF
            i = i + 1
            src      = AssetUrl(rsCanciones.Fields("SONG_PATH").Value)
            titulo   = Txt(rsCanciones.Fields("SONG_NAME").Value)
            artista  = Txt(rsCanciones.Fields("ARTISTAS").Value)
            If Len(artista) = 0 Then artista = "Artista desconocido"
            album    = Txt(rsCanciones.Fields("ALBUM").Value)
            If Len(album) = 0 Then album = "Sin álbum"
            portada  = AssetUrl(Txt(rsCanciones.Fields("PORTADA").Value))
            plays    = CLng(rsCanciones.Fields("PLAYS").Value)
            On Error Resume Next
            rutaFisica = Server.MapPath(src)
            If Err.Number <> 0 Then
                Err.Clear
                rutaFisica = ""
            End If
            On Error GoTo 0
            duracion = FormatoReloj(Mp3DuracionSeg(rutaFisica))
      %>
        <tr class="fila-cancion pista"
            data-id="<%= rsCanciones.Fields("ID_SONG").Value %>"
            data-src="<%= H(src) %>"
            data-titulo="<%= H(titulo) %>"
            data-artista="<%= H(artista) %>"
            data-album="<%= H(album) %>"
            data-portada="<%= H(portada) %>"
            data-plays="<%= plays %>">
          <td class="col-indice">
            <span class="fila-cancion__numero"><%= i %></span>
            <button type="button" class="fila-cancion__play js-play" aria-label="Reproducir <%= H(titulo) %>" title="Reproducir">
              <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
            </button>
            <span class="fila-cancion__ecualizador" aria-hidden="true"><i></i><i></i><i></i></span>
          </td>
          <td>
            <div class="fila-cancion__info">
              <img class="fila-cancion__portada" src="<%= portada %>" alt="" width="40" height="40" loading="lazy">
              <div>
                <span class="fila-cancion__titulo"><%= H(titulo) %></span>
                <span class="fila-cancion__artista fila-cancion__artista--movil"><%= H(artista) %></span>
              </div>
            </div>
          </td>
          <td class="col-oculta-movil"><%= H(artista) %></td>
          <td class="col-oculta-tablet"><%= H(album) %></td>
          <td class="col-oculta-movil"><span class="contador-plays" id="plays<%= rsCanciones.Fields("ID_SONG").Value %>"><%= plays %></span></td>
          <td class="col-oculta-tablet"><span class="duracion"><%= H(duracion) %></span></td>
          <td class="col-acciones">
            <div class="acciones-fila">
              <button type="button" class="boton-icono boton-icono--mini js-cola" aria-label="Añadir a la cola" title="Añadir a la cola">
                <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>
              </button>
              <a class="boton-icono boton-icono--mini" href="<%= H(src) %>" download aria-label="Descargar canción" title="Descargar">
                <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 3v12"/><path d="M7 10l5 5 5-5"/><path d="M5 21h14"/></svg>
              </a>
              <% If UsuarioEsAdmin() Then %>
              <a class="boton-icono boton-icono--mini" href="<%= Url("song_form.asp?id=" & rsCanciones.Fields("ID_SONG").Value) %>" aria-label="Editar <%= H(titulo) %>" title="Editar">
                <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z"/></svg>
              </a>
              <a class="boton-icono boton-icono--mini boton-icono--peligro" href="<%= Url("song_delete.asp?id=" & rsCanciones.Fields("ID_SONG").Value) %>" aria-label="Eliminar <%= H(titulo) %>" title="Eliminar">
                <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="M6 6l1 14h10l1-14"/></svg>
              </a>
              <% End If %>
            </div>
          </td>
        </tr>
      <%
            rsCanciones.MoveNext
        Loop
        rsCanciones.Close : Set rsCanciones = Nothing

        If i = 0 Then
      %>
        <tr>
          <td colspan="7">
            <div class="vacio">
              <svg viewBox="0 0 24 24" width="34" height="34" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>
              <p>No se encontraron canciones<% If Len(busqueda) > 0 Then %> para “<%= H(busqueda) %>”<% End If %>.</p>
              <% If UsuarioEsAdmin() Then %><a class="boton boton--principal" href="<%= Url("song_form.asp") %>">Agregar la primera canción</a><% End If %>
            </div>
          </td>
        </tr>
      <% End If %>
      </tbody>
    </table>
  </div>

  <p class="panel__nota">
    <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 8h.01M11 12h1v4h1"/></svg>
    Las canciones se sirven desde la carpeta <code>SongFiles</code> y las carátulas desde <code>AlbumImages</code> / <code>PlaylistImages</code>.
  </p>
</section>

<%
Pie()
%>
