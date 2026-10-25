<%
'=====================================================================
'  PoliMusic  -  includes/layout.asp   (se carga desde comun.asp)
'---------------------------------------------------------------------
'  Estructura visual común a todas las páginas: barra lateral,
'  barra superior, contenido y barra de reproducción fija.
'=====================================================================

Private Function NavActivo(seccion, actual)
    NavActivo = IIf(LCase(seccion) = LCase(actual), " nav__link--activo", "")
End Function

Public Sub Cabecera(titulo, seccionActual)
%><!DOCTYPE html>
<html lang="es" data-tema="oscuro">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="PoliMusic - clon de Spotify hecho en ASP clásico, VBScript y SQL Server 2025.">
<title><%= H(titulo) %> · PoliMusic</title>
<link rel="icon" href="<%= Url("assets/img/favicon.svg") %>" type="image/svg+xml">
<link rel="stylesheet" href="<%= Url("assets/css/styles.css") %>">
<script>
/* Aplica el tema guardado antes de pintar para evitar parpadeos. */
(function () {
  try {
    var t = localStorage.getItem("pm_tema");
    if (t === "claro") document.documentElement.setAttribute("data-tema", "claro");
  } catch (e) {}
})();
/* Ruta virtual de la aplicación (para construir URLs desde JS). */
window.PM_BASE = "<%= Url("") %>";
</script>
</head>
<body>
<div class="app">

  <!-- ======================= BARRA LATERAL ======================= -->
  <aside class="barra-lateral">
    <a class="marca" href="<%= Url("songs.asp") %>">
      <span class="marca__logo" aria-hidden="true">
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
          <path d="M9 18V6l10-2v12"/><circle cx="6.5" cy="18" r="2.5"/><circle cx="16.5" cy="16" r="2.5"/>
        </svg>
      </span>
      <span class="marca__texto">Poli<span class="marca__texto--verde">Music</span></span>
    </a>

    <nav class="nav" aria-label="Navegación principal">
      <p class="nav__titulo">Explorar</p>
      <a class="nav__link<%= NavActivo("canciones", seccionActual) %>" href="<%= Url("songs.asp") %>">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M9 18V6l10-2v12"/><circle cx="6.5" cy="18" r="2.5"/><circle cx="16.5" cy="16" r="2.5"/></svg>
        Canciones
      </a>
      <a class="nav__link<%= NavActivo("albumes", seccionActual) %>" href="<%= Url("albums.asp") %>">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="12" cy="12" r="4.5"/><circle cx="17.5" cy="6.5" r="1"/></svg>
        Álbumes
      </a>
      <a class="nav__link<%= NavActivo("artistas", seccionActual) %>" href="<%= Url("artists.asp") %>">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M16 21v-2a4 4 0 0 0-8 0v2"/><circle cx="12" cy="8" r="4"/></svg>
        Artistas
      </a>
      <a class="nav__link<%= NavActivo("playlists", seccionActual) %>" href="<%= Url("playlists.asp") %>">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 6h13M3 12h9M3 18h9"/><path d="M18 10v8"/><circle cx="20" cy="18" r="2"/></svg>
        Listas de reproducción
      </a>
    </nav>

    <nav class="nav nav--playlists" aria-label="Listas del usuario">
      <p class="nav__titulo">Tus listas</p>
      <%
        Dim rsPl
        Set rsPl = SqlConsulta("SELECT TOP 6 ID_PLAYLIST, TITLE FROM TBL_PLAYLIST ORDER BY CREATION_DATE DESC", Array())
        If Not rsPl.EOF Then
            Do While Not rsPl.EOF
      %>
      <a class="nav__link nav__link--mini" href="<%= Url("playlist_detail.asp?id=" & rsPl.Fields("ID_PLAYLIST").Value) %>">
        <span class="nav__bullet" aria-hidden="true"></span><%= H(rsPl.Fields("TITLE").Value) %>
      </a>
      <%
                rsPl.MoveNext
            Loop
        End If
        rsPl.Close : Set rsPl = Nothing
      %>
    </nav>

    <div class="barra-lateral__pie">
      <div class="tarjeta-usuario" id="tarjetaUsuario">
        <img class="avatar" src="<%= SesionFoto() %>" alt="" width="38" height="38" loading="lazy">
        <div class="tarjeta-usuario__info">
          <strong><%= H(SesionNombre()) %></strong>
          <span class="chip chip--<%= IIf(UsuarioEsAdmin(), "admin", "usuario") %>"><%= H(SesionRolTexto()) %></span>
        </div>
      </div>
      <a class="boton boton--fantasma boton--ancho" href="<%= Url("logout.asp") %>">
        <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/></svg>
        Cerrar sesión
      </a>
    </div>
  </aside>

  <!-- ======================= CONTENIDO ======================= -->
  <div class="zona">
    <header class="barra-superior">
      <form class="buscador" method="get" action="<%= Url("songs.asp") %>" role="search">
        <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>
        <input type="search" name="q" id="buscador" placeholder="Buscar canciones, artistas, álbumes..." aria-label="Buscar" value="<%= H(Request.QueryString("q")) %>">
      </form>
      <div class="barra-superior__acciones">
        <button type="button" class="boton-icono" id="btnTema" aria-label="Cambiar tema claro u oscuro" title="Cambiar tema">
          <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M21 12.8A8.5 8.5 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></svg>
        </button>
        <a class="boton boton--fantasma" href="<%= Url("logout.asp") %>">Salir</a>
      </div>
    </header>

    <main class="contenido" id="contenido">
      <%= LeerFlash() %>
<%
End Sub

Public Sub Pie()
%>
    </main>
  </div>

  <!-- ================= BARRA DE REPRODUCCIÓN ================= -->
  <footer class="reproductor" id="reproductor" aria-label="Reproductor de audio">
    <div class="reproductor__info">
      <img class="reproductor__portada" id="repPortada" src="<%= Url("assets/img/placeholder.svg") %>" alt="" width="56" height="56">
      <div class="reproductor__texto">
        <strong id="repTitulo">Sin reproducir</strong>
        <span id="repArtista">PoliMusic</span>
      </div>
      <button type="button" class="boton-icono boton-icono--mini" id="btnFavorito" aria-label="Me gusta" title="Me gusta">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M20.8 5.6a5 5 0 0 0-7.1 0L12 7.3l-1.7-1.7a5 5 0 1 0-7.1 7.1L12 21l8.8-8.3a5 5 0 0 0 0-7.1z"/></svg>
      </button>
    </div>

    <div class="reproductor__controles">
      <div class="reproductor__botones">
        <button type="button" class="boton-icono" id="btnAleatorio" aria-label="Reproducción aleatoria" title="Aleatorio">
          <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M16 3h5v5"/><path d="M4 20 21 3"/><path d="M21 16v5h-5"/><path d="M15 15l6 6"/><path d="M4 4l5 5"/></svg>
        </button>
        <button type="button" class="boton-icono" id="btnAnterior" aria-label="Anterior canción" title="Anterior">
          <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor"><path d="M6 5h2v14H6zM20 5v14L9 12z"/></svg>
        </button>
        <button type="button" class="boton-play" id="btnPlay" aria-label="Reproducir o pausar" title="Reproducir">
          <svg class="ico-play" viewBox="0 0 24 24" width="22" height="22" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
          <svg class="ico-pausa" viewBox="0 0 24 24" width="22" height="22" fill="currentColor" style="display:none"><path d="M7 5h4v14H7zM13 5h4v14h-4z"/></svg>
        </button>
        <button type="button" class="boton-icono" id="btnSiguiente" aria-label="Siguiente canción" title="Siguiente">
          <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor"><path d="M16 5h2v14h-2zM4 5v14l11-7z"/></svg>
        </button>
        <button type="button" class="boton-icono" id="btnRepetir" aria-label="Repetir" title="Repetir">
          <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M17 2l4 4-4 4"/><path d="M3 12v-2a4 4 0 0 1 4-4h14"/><path d="M7 22l-4-4 4-4"/><path d="M21 12v2a4 4 0 0 1-4 4H3"/></svg>
        </button>
      </div>
      <div class="reproductor__progreso">
        <span class="reproductor__tiempo" id="repTiempoActual">0:00</span>
        <input type="range" id="repBarra" min="0" max="100" value="0" step="0.1" aria-label="Progreso de la canción">
        <span class="reproductor__tiempo" id="repDuracion">0:00</span>
      </div>
    </div>

    <div class="reproductor__extra">
      <span class="reproductor__cola" id="repCola">Cola: 0</span>
      <button type="button" class="boton-icono" id="btnVolumen" aria-label="Silenciar" title="Silenciar">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M11 5 6 9H3v6h3l5 4z"/><path d="M16 9a4 4 0 0 1 0 6"/><path d="M19 6a8 8 0 0 1 0 12"/></svg>
      </button>
      <input type="range" id="repVolumen" min="0" max="100" value="80" aria-label="Volumen">
    </div>
  </footer>
</div>

<audio id="audio" preload="none"></audio>
<div class="zona-mensajes" id="zonaMensajes" aria-live="polite"></div>
<script src="<%= Url("assets/js/app.js") %>" defer></script>
</body>
</html>
<%
End Sub
%>
