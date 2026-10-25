<%@Language=VBScript%>
<% Option Explicit %>
<!--#include file="includes/comun.asp"-->
<%
'=====================================================================
'  playlists.asp  -  Listas de reproducción (TBL_PLAYLIST +
'  TBL_PLAYLIST_SONG). El tipo (pública/privada) se lee de TBL_CATALOG.
'=====================================================================
SesionRequerir()

Dim rs
Set rs = SqlConsulta( _
    "SELECT p.ID_PLAYLIST, p.TITLE, p.CREATION_DATE, p.TYPE, p.PHOTO, " & _
    "       u.USERNAME, COUNT(ps.ID_SONG) AS CANCIONES " & _
    "FROM TBL_PLAYLIST p " & _
    "JOIN TBL_USER u ON u.ID_USER = p.ID_USER " & _
    "LEFT JOIN TBL_PLAYLIST_SONG ps ON ps.ID_PLAYLIST = p.ID_PLAYLIST " & _
    "GROUP BY p.ID_PLAYLIST, p.TITLE, p.CREATION_DATE, p.TYPE, p.PHOTO, u.USERNAME " & _
    "ORDER BY p.CREATION_DATE DESC", Array())

Cabecera "Listas de reproducción", "playlists"
%>

<section class="hero hero--compacto">
  <div class="hero__texto">
    <p class="hero__eyebrow">PoliMusic · Biblioteca</p>
    <h1 class="hero__titulo">Listas de reproducción</h1>
    <p class="hero__sub">Cada lista agrupa canciones de distintos álbumes y artistas.</p>
    <p class="hero__bienvenida">
      <span class="hero__saludo">Bienvenido,</span>
      <strong><%= H(SesionNombre()) %></strong>
      <span class="chip chip--<%= IIf(UsuarioEsAdmin(), "admin", "usuario") %>"><%= H(SesionRolTexto()) %></span>
    </p>
  </div>
</section>

<section class="rejilla-tarjetas">
<%
  If rs.EOF Then
%>
  <div class="vacio"><p>Todavía no hay listas de reproducción.</p></div>
<%
  End If
  Do While Not rs.EOF
    Dim tipoTexto, tipoClase
    If CLng(rs.Fields("TYPE").Value) = 1 Then
        tipoTexto = "Privada" : tipoClase = "chip--privada"
    Else
        tipoTexto = "Pública" : tipoClase = "chip--publica"
    End If
%>
  <a class="tarjeta" href="<%= Url("playlist_detail.asp?id=" & rs.Fields("ID_PLAYLIST").Value) %>">
    <div class="tarjeta__portada">
      <img src="<%= AssetUrl(Txt(rs.Fields("PHOTO").Value)) %>" alt="" loading="lazy">
      <span class="tarjeta__play" aria-hidden="true">
        <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
      </span>
    </div>
    <div class="tarjeta__texto">
      <strong><%= H(Txt(rs.Fields("TITLE").Value)) %></strong>
      <span><%= H(Txt(rs.Fields("USERNAME").Value)) %> · <%= rs.Fields("CANCIONES").Value %> canciones · <%= FechaCorta(rs.Fields("CREATION_DATE").Value) %></span>
      <span class="chip <%= tipoClase %>"><%= tipoTexto %></span>
    </div>
  </a>
<%
      rs.MoveNext
  Loop
  rs.Close : Set rs = Nothing
%>
</section>

<%
Pie()
%>
