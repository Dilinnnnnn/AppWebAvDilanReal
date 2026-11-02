<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV2.Song" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>PoliMusic &middot; Song list</title>
    <link rel="stylesheet" href="Content/Song.css" />
</head>
<body data-plays-url="<%= ResolveUrl("~/Handlers/SongPlayHandler.ashx") %>">
    <form id="form1" runat="server">

        <header class="topbar">
            <div class="brand">
                <span class="brand-mark" aria-hidden="true">
                    <svg viewBox="0 0 24 24">
                        <path d="M9 17.5V6.2l10-2v10.6" fill="none" stroke="currentColor" stroke-width="2"
                            stroke-linecap="round" stroke-linejoin="round" />
                        <circle cx="6.6" cy="17.6" r="2.6" fill="currentColor" />
                        <circle cx="16.6" cy="15.6" r="2.6" fill="currentColor" />
                    </svg>
                </span>
                <span class="brand-name">PoliMusic</span>
            </div>

            <div class="user-area">
                <asp:Image ID="imgUser" runat="server" CssClass="avatar" AlternateText="User photo" />
                <span class="welcome">Welcome
                    <strong>
                        <asp:Literal ID="litUserName" runat="server" /></strong></span>
                <asp:LinkButton ID="lnkLogout" runat="server" CssClass="logout" CausesValidation="false"
                    OnClick="LnkLogout_Click">Logout</asp:LinkButton>
            </div>
        </header>

        <main class="content">
            <div class="page-head">
                <p class="eyebrow">Your library</p>
                <h1 class="page-title">Song list</h1>
                <p class="page-sub">
                    <asp:Literal ID="litCount" runat="server" />
                    songs available &middot; press play to listen</p>
            </div>

            <div class="table-wrap">
                <table class="song-table">
                    <thead>
                        <tr>
                            <th class="col-id">ID Canci&oacute;n</th>
                            <th class="col-name">Nombre</th>
                            <th class="col-path">Ruta</th>
                            <th class="col-plays">Reproducciones</th>
                            <th class="col-player">Reproducir</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptSongs" runat="server">
                            <ItemTemplate>
                                <tr>
                                    <td class="col-id"><%# Eval("ID") %></td>
                                    <td class="col-name"><span class="song-name"><%# Server.HtmlEncode(Convert.ToString(Eval("Name"))) %></span></td>
                                    <td class="col-path"><span class="song-path"><%# Server.HtmlEncode(Convert.ToString(Eval("Path"))) %></span></td>
                                    <td class="col-plays"><span class="plays" data-plays><%# Eval("Plays") %></span></td>
                                    <td class="col-player">
                                        <div class="player" data-song-id="<%# Eval("ID") %>">
                                            <audio preload="metadata" src="<%# ResolveSongUrl(Eval("Path")) %>"></audio>
                                            <button type="button" class="play-btn" data-play aria-label="Play or pause">
                                                <svg class="icon icon-play" viewBox="0 0 24 24" aria-hidden="true">
                                                    <path d="M8 5v14l11-7z" />
                                                </svg>
                                                <svg class="icon icon-pause" viewBox="0 0 24 24" aria-hidden="true">
                                                    <path d="M6 5h4v14H6zm8 0h4v14h-4z" />
                                                </svg>
                                            </button>
                                            <div class="progress" data-progress role="slider" aria-label="Seek">
                                                <div class="progress-fill" data-fill></div>
                                            </div>
                                            <span class="time" data-time>0:00 / 0:00</span>
                                            <button type="button" class="vol-btn" data-mute aria-label="Mute or unmute">
                                                <svg class="icon vol-on" viewBox="0 0 24 24" aria-hidden="true">
                                                    <path d="M4 9v6h4l5 4V5L8 9H4z" />
                                                    <path d="M16.5 8.5a5 5 0 0 1 0 7" fill="none" stroke="currentColor"
                                                        stroke-width="1.8" stroke-linecap="round" />
                                                </svg>
                                                <svg class="icon vol-off" viewBox="0 0 24 24" aria-hidden="true">
                                                    <path d="M4 9v6h4l5 4V5L8 9H4z" />
                                                    <path d="M16 9.5l4.5 5M20.5 9.5l-4.5 5" fill="none" stroke="currentColor"
                                                        stroke-width="1.8" stroke-linecap="round" />
                                                </svg>
                                            </button>
                                            <input type="range" class="vol-slider" data-vol min="0" max="100" value="100"
                                                aria-label="Volume" />
                                        </div>
                                    </td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>
                    </tbody>
                </table>
                <asp:Label ID="lblMessage" runat="server" CssClass="empty-state"></asp:Label>
            </div>
        </main>

    </form>

    <script src="<%= ResolveUrl("~/Scripts/Song.js") %>"></script>
</body>
</html>
