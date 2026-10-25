<%@Language=VBScript%>
<% Option Explicit %>
<!--#include file="includes/comun.asp"-->
<%
'=====================================================================
'  song_form.asp  -  Alta y edición de canciones (SOLO ADMIN)
'---------------------------------------------------------------------
'  Formulario CRUDS sobre TBL_SONG. Además permite relacionar la
'  canción con un álbum (TBL_TRACKLIST) y con un artista (TBL_PLAYER),
'  que son las tablas puente del modelo entidad-relación.
'=====================================================================
SesionRequerir()

If Not UsuarioEsAdmin() Then
    FijarFlash "Acceso restringido", "Solo el administrador puede crear o editar canciones.", "error"
    Response.Redirect "songs.asp"
End If

Dim idCancion, esNueva
idCancion = Request.QueryString("id") & ""
If Not EsEntero(idCancion) Then idCancion = "0"
esNueva = (CLng(idCancion) = 0)

'--- Datos actuales de la canción (si es edición) ---------------
Dim nombre, ruta, plays, idAlbum, idArtista, portadaActual
nombre = "" : ruta = "" : plays = 0 : idAlbum = 0 : idArtista = 0 : portadaActual = ""

If Not esNueva Then
    Dim rs
    Set rs = SqlConsulta("SELECT ID_SONG, SONG_NAME, SONG_PATH, ISNULL(PLAYS,0) AS PLAYS FROM TBL_SONG WHERE ID_SONG = ?", Array(CLng(idCancion)))
    If rs.EOF Then
        rs.Close : Set rs = Nothing
        FijarFlash "Canción no encontrada", "El registro que intentas editar ya no existe.", "error"
        Response.Redirect "songs.asp"
    End If
    nombre = Txt(rs.Fields("SONG_NAME").Value)
    ruta   = Txt(rs.Fields("SONG_PATH").Value)
    plays  = CLng(rs.Fields("PLAYS").Value)
    rs.Close : Set rs = Nothing

    ' relaciones actuales
    idAlbum  = CLng(SqlEscalar("SELECT TOP 1 ID_ALBUM FROM TBL_TRACKLIST WHERE ID_SONG = ? ORDER BY ID_ALBUM", Array(CLng(idCancion))) & "")
    idArtista = CLng(SqlEscalar("SELECT TOP 1 ID_ARTIST FROM TBL_PLAYER WHERE ID_SONG = ? ORDER BY ID_ARTIST", Array(CLng(idCancion))) & "")
End If

If Len(ruta) = 0 Then ruta = "~/SongFiles/"
portadaActual = AssetUrl(SqlEscalar("SELECT TOP 1 a.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST t " & _
                                    "JOIN TBL_ALBUM a ON a.ID_ALBUM = t.ID_ALBUM WHERE t.ID_SONG = ? ORDER BY t.ID_ALBUM", Array(CLng(idCancion))) & "")

Dim rsAlbumes, rsArtistas
Set rsAlbumes  = SqlConsulta("SELECT ID_ALBUM, TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH FROM TBL_ALBUM ORDER BY TITLE_ALBUM", Array())
Set rsArtistas = SqlConsulta("SELECT ID_ARTIST, ARTIST_NAME + ' ' + ISNULL(ARTIST_LASTNAME,'') AS NOMBRE FROM TBL_ARTIST ORDER BY ARTIST_NAME", Array())

Cabecera IIf(esNueva, "Nueva canción", "Editar canción"), "canciones"
%>

<section class="panel">
  <div class="panel__cabecera">
    <div>
      <p class="panel__eyebrow"><a class="enlace-simple" href="<%= Url("songs.asp") %>">Canciones</a> / <%= IIf(esNueva, "Nueva", "Editar") %></p>
      <h2 class="panel__titulo"><%= IIf(esNueva, "Agregar canción al catálogo", "Editar canción") %></h2>
      <p class="panel__sub">
        <% If esNueva Then %>
          Registra una nueva pista en la tabla TBL_SONG y relaciónala con su álbum y artista.
        <% Else %>
          Modifica los datos de la canción y sus relaciones del modelo entidad-relación.
        <% End If %>
      </p>
    </div>
    <span class="aviso-rol">Solo el administrador ve este formulario</span>
  </div>

  <form method="post" action="<%= Url("song_save.asp") %>" class="formulario formulario--amplio" id="formCancion" novalidate>
    <input type="hidden" name="id" value="<%= CLng(idCancion) %>">

    <div class="formulario__rejilla">
      <div class="campo">
        <label for="nombre">Nombre de la canción <span class="requerido">*</span></label>
        <div class="campo__caja">
          <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M9 18V6l10-2v12"/><circle cx="6.5" cy="18" r="2.5"/><circle cx="16.5" cy="16" r="2.5"/></svg>
          <input type="text" id="nombre" name="nombre" maxlength="50" value="<%= H(nombre) %>" placeholder="Adventure" required>
        </div>
        <p class="campo__ayuda">Máximo 50 caracteres (columna SONG_NAME).</p>
      </div>

      <div class="campo">
        <label for="ruta">Ruta del archivo MP3 <span class="requerido">*</span></label>
        <div class="campo__caja">
          <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M9 18V6l10-2v12"/><circle cx="6.5" cy="18" r="2.5"/><circle cx="16.5" cy="16" r="2.5"/></svg>
          <input type="text" id="ruta" name="ruta" maxlength="255" value="<%= H(ruta) %>" placeholder="~/SongFiles/bensound-adventure.mp3" required>
        </div>
        <p class="campo__ayuda">Ejemplo: <code>~/SongFiles/bensound-adventure.mp3</code></p>
      </div>

      <div class="campo">
        <label for="plays">Reproducciones</label>
        <div class="campo__caja">
          <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>
          <input type="number" id="plays" name="plays" min="0" step="1" value="<%= plays %>">
        </div>
        <p class="campo__ayuda">Valor inicial del contador (columna PLAYS).</p>
      </div>

      <div class="campo">
        <label for="album">Álbum (TBL_ALBUM)</label>
        <div class="campo__caja">
          <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="12" cy="12" r="4.5"/></svg>
          <select id="album" name="album">
            <option value="0">Sin álbum</option>
            <% Do While Not rsAlbumes.EOF %>
            <option value="<%= rsAlbumes.Fields("ID_ALBUM").Value %>" data-portada="<%= AssetUrl(Txt(rsAlbumes.Fields("ALBUM_IMAGE_PATH").Value)) %>" <%= IIf(CLng(idAlbum) = CLng(rsAlbumes.Fields("ID_ALBUM").Value), "selected", "") %>>
              <%= H(rsAlbumes.Fields("TITLE_ALBUM").Value) %> (<%= H(rsAlbumes.Fields("RELEASE_YEAR").Value) %>)
            </option>
            <% rsAlbumes.MoveNext : Loop %>
          </select>
        </div>
        <p class="campo__ayuda">Crea la relación TBL_TRACKLIST.</p>
      </div>

      <div class="campo">
        <label for="artista">Artista (TBL_ARTIST)</label>
        <div class="campo__caja">
          <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M16 21v-2a4 4 0 0 0-8 0v2"/><circle cx="12" cy="8" r="4"/></svg>
          <select id="artista" name="artista">
            <option value="0">Sin artista</option>
            <% Do While Not rsArtistas.EOF %>
            <option value="<%= rsArtistas.Fields("ID_ARTIST").Value %>" <%= IIf(CLng(idArtista) = CLng(rsArtistas.Fields("ID_ARTIST").Value), "selected", "") %>>
              <%= H(rsArtistas.Fields("NOMBRE").Value) %>
            </option>
            <% rsArtistas.MoveNext : Loop %>
          </select>
        </div>
        <p class="campo__ayuda">Crea la relación TBL_PLAYER (canción - artista).</p>
      </div>
    </div>

    <div class="formulario__previa">
      <img class="formulario__portada" id="prevPortada" src="<%= portadaActual %>" alt="Portada asociada" width="140" height="140">
      <div class="formulario__reproducir">
        <p class="formulario__previa-titulo">Previsualización</p>
        <audio id="previoAudio" controls preload="none" src=""></audio>
        <p class="campo__ayuda">Verifica que el archivo MP3 suene antes de guardar.</p>
      </div>
    </div>

    <div class="formulario__acciones">
      <button type="submit" class="boton boton--principal">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M5 12l5 5L20 7"/></svg>
        <%= IIf(esNueva, "Guardar canción", "Guardar cambios") %>
      </button>
      <a class="boton boton--fantasma" href="<%= Url("songs.asp") %>">Cancelar</a>
    </div>
  </form>
</section>

<script>
/* Actualiza la previsualización al cambiar la ruta o el álbum. */
(function () {
  var ruta = document.getElementById("ruta");
  var audio = document.getElementById("previoAudio");
  var portada = document.getElementById("prevPortada");
  var album = document.getElementById("album");
  function normalizar(v) {
    v = (v || "").replace(/^~\/?/, "").replace(/^\/+/, "");
    var base = (window.PM_BASE || "/").replace(/\/$/, "");
    return base + "/" + v;
  }
  function refrescar() {
    var url = normalizar(ruta.value);
    if (/\.mp3$/i.test(url)) { audio.src = url; audio.load(); }
    var opt = album.options[album.selectedIndex];
    var p = opt && opt.getAttribute("data-portada");
    if (p) portada.src = p;
  }
  ruta.addEventListener("change", refrescar);
  album.addEventListener("change", refrescar);
})();
</script>

<%
rsAlbumes.Close  : Set rsAlbumes  = Nothing
rsArtistas.Close : Set rsArtistas = Nothing
Pie()
%>
