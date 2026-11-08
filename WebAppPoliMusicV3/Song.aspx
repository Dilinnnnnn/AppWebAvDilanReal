<%@ Page Title="Canciones" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV3.Song" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <!-- Song.css -->
    <link href="Content/Song.css" rel="stylesheet" type="text/css" />

    <!-- Student Badge (visible for screenshot - shows student name) -->
    <div class="song-student-badge">
        <span class="dot"></span>
        Dilan Real
    </div>

    <!-- Hero Section -->
    <section class="song-hero">
        <div class="song-hero-content">
            <div class="song-hero-eyebrow">PoliMusic V3</div>
            <h1 class="song-hero-title">Tu m&uacute;sica, tu momento</h1>
            <p class="song-hero-subtitle">
                Explora nuestra colecci&oacute;n de canciones. Reproduce, disfruta y descubre nuevo sonido en una experiencia dise&ntilde;ada para ti.
            </p>
            <div class="song-hero-student">Estudiante: Dilan Real</div>
        </div>
    </section>

    <!-- Song List Section -->
    <section class="song-section">
        <div class="song-section-header">
            <div class="song-section-eyebrow">Cat&aacute;logo</div>
            <h2 class="song-section-title">Canciones Disponibles</h2>
        </div>

        <!-- Song Table (GridView-style with Repeater) -->
        <div class="song-table-wrapper">
            <table class="song-table">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Canci&oacute;n</th>
                        <th>Reproducciones</th>
                        <th>Reproductor</th>
                    </tr>
                </thead>
                <tbody>
                    <asp:Repeater ID="rptSongs" runat="server">
                        <ItemTemplate>
                            <tr>
                                <td><%# Eval("ID") %></td>
                                <td><span class="song-table-song-name"><%# Eval("Name") %></span></td>
                                <td><span class="song-table-plays" id="plays-<%# Eval("ID") %>"><%# Eval("Plays") %> reproducciones</span></td>
                                <td class="song-table-play-cell">
                                    <div class="song-inline-player">
                                        <button type="button"
                                            class="song-inline-player-btn"
                                            data-audio-url="<%# ResolveSongUrl(Eval("Path").ToString()) %>"
                                            data-song-id="<%# Eval("ID") %>">
                                            <svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>
                                        </button>
                                        <div class="song-inline-player-track">
                                            <div class="song-inline-player-fill"></div>
                                        </div>
                                        <span class="song-inline-player-time">0:00</span>
                                    </div>
                                </td>
                            </tr>
                        </ItemTemplate>
                    </asp:Repeater>
                </tbody>
            </table>
        </div>
    </section>

    <!-- Footer Section -->
    <section class="song-footer-section">
        <h3 class="song-footer-title">PoliMusic V3</h3>
        <p class="song-footer-text">Plataforma de m&uacute;sica acad&eacute;mica - Arquitectura en 3 capas</p>
        <div class="song-footer-credit">Desarrollado por Dilan Real</div>
    </section>

    <!-- Song.js -->
    <script src="Scripts/Song.js" type="text/javascript"></script>

</asp:Content>
