using System;
using System.Configuration;
using System.Web;
using System.Web.SessionState;

namespace WebAppPoliMusicV3
{
    /// <summary>
    /// Increases the plays counter of a song. Called by Song.js through AJAX.
    /// Usage: SongPlayHandler.ashx?id=1
    /// </summary>
    public class SongPlayHandler : IHttpHandler, IRequiresSessionState
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            context.Response.Cache.SetCacheability(HttpCacheability.NoCache);

            EntityLayer.PoliMusicV3.User user = context.Session[EntityLayer.PoliMusicV3.Util.Constants.USER] as EntityLayer.PoliMusicV3.User;
            if (user == null)
            {
                context.Response.StatusCode = 401;
                context.Response.Write("{\"error\":\"unauthorized\"}");
                return;
            }

            int idSong;
            if (!int.TryParse(context.Request.QueryString["id"], out idSong) || idSong <= 0)
            {
                context.Response.StatusCode = 400;
                context.Response.Write("{\"error\":\"invalid id\"}");
                return;
            }

            try
            {
                string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;
                BLL.PoliMusicV3.Song bllSong = new BLL.PoliMusicV3.Song(strConnString);
                bllSong.IncrementPlays(idSong);
                int plays = bllSong.GetPlays(idSong);
                context.Response.Write("{\"id\":" + idSong + ",\"plays\":" + plays + "}");
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write("{\"error\":\"" + ex.Message.Replace("\"", "'") + "\"}");
            }
        }

        public bool IsReusable
        {
            get { return false; }
        }
    }
}
