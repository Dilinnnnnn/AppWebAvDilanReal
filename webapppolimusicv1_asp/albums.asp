<%@Language=VBScript%>
<% Option Explicit %>
<!--#include file="includes/comun.asp"-->
<%
'=====================================================================
'  albums.asp  -  Catálogo de álbumes (TBL_ALBUM + TBL_TRACKLIST)
'=====================================================================
SesionRequerir()

Dim rs
Set rs = SqlConsulta( _
    "SELECT a.ID_ALBUM, a.TITLE_ALBUM, a.RELEASE_YEAR, a.ALBUM_IMAGE_PATH, " & _
    "       ISNULL(COUNT(DISTINCT t.ID_SONG),0) AS CANCIONES " & _
    "FROM TBL_ALBUM a " & _
    "LEFT JOIN TBL_TRACKLIST t ON t.ID_ALBUM = a.ID_ALBUM " & _
    "GROUP BY a.ID_ALBUM, a.TITLE_ALBUM, a.RELEASE_YEAR, a.ALBUM_IMAGE_PATH " & _
    "ORDER BY a.TITLE_ALBUM", Array())

Cabecera "Álbumes", "albumes"
%>

<section class="hero hero--compacto">
  <div class="hero__texto">
    <p class="hero__eyebrow">PoliMusic · Catálogo</p>
    <h1 class="hero__titulo">Álbumes</h1>
    <p class="hero__sub">Explora los álbumes registrados y las canciones que contiene cada uno.</p>
  </div>
</section>

<section class="rejilla-tarjetas">
<%
  If rs.EOF Then
%>
  <div class="vacio">
    <p>Todavía no hay álbumes registrados.</p>
  </div>
<%
  End If
  Do While Not rs.EOF
%>
  <a class="tarjeta tarjeta--album" href="<%= Url("album_detail.asp?id=" & rs.Fields("ID_ALBUM").Value) %>">
    <div class="tarjeta__portada">
      <img src="<%= AssetUrl(Txt(rs.Fields("ALBUM_IMAGE_PATH").Value)) %>" alt="Portada de <%= H(Txt(rs.Fields("TITLE_ALBUM").Value)) %>" loading="lazy">
      <span class="tarjeta__play" aria-hidden="true">
        <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
      </span>
    </div>
    <div class="tarjeta__texto">
      <strong><%= H(Txt(rs.Fields("TITLE_ALBUM").Value)) %></strong>
      <span><%= H(Txt(rs.Fields("RELEASE_YEAR").Value)) %> · <%= rs.Fields("CANCIONES").Value %> canciones</span>
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
