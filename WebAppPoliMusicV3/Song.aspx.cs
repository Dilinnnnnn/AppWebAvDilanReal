using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV3
{
    public partial class Song : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Verify that the user is logged in
            EntityLayer.PoliMusicV3.User user = Session[EntityLayer.PoliMusicV3.Util.Constants.USER] as EntityLayer.PoliMusicV3.User;
            if (user == null)
            {
                Response.Redirect("~/Login");
                return;
            }

            if (!IsPostBack)
            {
                LoadSongs();
            }
        }

        /// <summary>
        /// Load all songs from the database through BLL and bind them to the Repeater.
        /// </summary>
        private void LoadSongs()
        {
            string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;
            try
            {
                BLL.PoliMusicV3.Song bllSong = new BLL.PoliMusicV3.Song(strConnString);
                List<EntityLayer.PoliMusicV3.Song> songs = bllSong.ReadSongs();
                rptSongs.DataSource = songs;
                rptSongs.DataBind();
            }
            catch (Exception ex)
            {
                // If there is an error, show empty list
                rptSongs.DataSource = null;
                rptSongs.DataBind();
            }
        }

        /// <summary>
        /// Converts the stored song path (e.g. "~/SongFiles/song.mp3" or "../SongFiles/song.mp3")
        /// to a browser-usable URL (e.g. "/SongFiles/song.mp3").
        /// </summary>
        public string ResolveSongUrl(string songPath)
        {
            if (string.IsNullOrEmpty(songPath))
            {
                return string.Empty;
            }

            // Remove leading ~ or ../ to make it relative to the site root
            string cleanPath = songPath;
            if (cleanPath.StartsWith("~/"))
            {
                cleanPath = cleanPath.Substring(2);
            }
            else if (cleanPath.StartsWith("../"))
            {
                cleanPath = cleanPath.Substring(3);
            }
            else if (cleanPath.StartsWith("~"))
            {
                cleanPath = cleanPath.Substring(1);
            }

            return ResolveUrl("~/" + cleanPath);
        }
    }
}
