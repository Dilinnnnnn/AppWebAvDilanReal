<%@Language=VBScript%>
<% Option Explicit %>
<!--#include file="includes/comun.asp"-->
<%
'=====================================================================
'  artists.asp  -  Catálogo de artistas (TBL_ARTIST + TBL_PLAYER)
'=====================================================================
SesionRequerir()

Dim rs
Set rs = SqlConsulta( _
    "SELECT a.ID_ARTIST, a.ARTIST_NAME, a.ARTIST_LASTNAME, a.ARTIST_IMAGE, " & _
    "       COUNT(DISTINCT p.ID_SONG) AS CANCIONES " & _
    "FROM TBL_ARTIST a " & _
    "LEFT JOIN TBL_PLAYER p ON p.ID_ARTIST = a.ID_ARTIST " & _
    "GROUP BY a.ID_ARTIST, a.ARTIST_NAME, a.ARTIST_LASTNAME, a.ARTIST_IMAGE " & _
    "ORDER BY a.ARTIST_NAME, a.ARTIST_LASTNAME", Array())

Cabecera "Artistas", "artistas"
%>

<section class="hero hero--compacto">
  <div class="hero__texto">
    <p class="hero__eyebrow">PoliMusic · Catálogo</p>
    <h1 class="hero__titulo">Artistas</h1>
    <p class="hero__sub">Los intérpretes del catálogo y el número de canciones que tienen registradas.</p>
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
  <div class="vacio"><p>Todavía no hay artistas registrados.</p></div>
<%
  End If
  Do While Not rs.EOF
    Dim nombreCompleto
    nombreCompleto = Trim(Txt(rs.Fields("ARTIST_NAME").Value) & " " & Txt(rs.Fields("ARTIST_LASTNAME").Value))
%>
  <div class="tarjeta tarjeta--artista">
    <div class="tarjeta__portada tarjeta__portada--redonda">
      <img src="<%= AssetUrl(Txt(rs.Fields("ARTIST_IMAGE").Value)) %>" alt="" loading="lazy">
    </div>
    <div class="tarjeta__texto">
      <strong><%= H(nombreCompleto) %></strong>
      <span><%= rs.Fields("CANCIONES").Value %> canciones</span>
    </div>
  </div>
<%
      rs.MoveNext
  Loop
  rs.Close : Set rs = Nothing
%>
</section>

<%
Pie()
%>
