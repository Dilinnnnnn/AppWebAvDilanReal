using System;
using System.Collections.Generic;
using System.Configuration;
using System.Web;
using System.Web.Security;
using System.Web.UI;

namespace WebAppPoliMusicV2
{
    public partial class Song : System.Web.UI.Page
    {
        private string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                Entities.User user = Session[Util.Constants.USER] as Entities.User;
                if (user == null)
                {
                    Response.Redirect("~/Login.aspx", true);
                    return;
                }
                LoadUser(user);
                LoadSongs();
            }
        }

        /// <summary>
        /// Shows the logged user name and photo on the header.
        /// </summary>
        private void LoadUser(Entities.User user)
        {
            string userName = string.IsNullOrEmpty(user.UserName) ? "user" : user.UserName;
            litUserName.Text = Server.HtmlEncode(userName);
            imgUser.ImageUrl = string.IsNullOrEmpty(user.Photo)
                ? ResolveUrl("~/UserImages/default.jpg")
                : ResolveUrl(user.Photo);
            imgUser.AlternateText = userName;
        }

        /// <summary>
        /// Binds the song list that comes from the BLL.
        /// </summary>
        private void LoadSongs()
        {
            List<Entities.Song> songs = new BLL.Song(strConnString).ReadSongs();
            rptSongs.DataSource = songs;
            rptSongs.DataBind();
            litCount.Text = songs.Count.ToString();
            if (songs.Count == 0)
            {
                lblMessage.Text = "There are no songs registered in the database yet.";
            }
        }

        /// <summary>
        /// Turns the path stored in TBL_SONG (~/SongFiles/x.mp3) into a url
        /// that the browser can request.
        /// </summary>
        protected string ResolveSongUrl(object path)
        {
            string songPath = Convert.ToString(path);
            if (string.IsNullOrEmpty(songPath))
            {
                return string.Empty;
            }
            if (songPath.StartsWith("~"))
            {
                return ResolveUrl(songPath);
            }
            if (songPath.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                songPath.StartsWith("https://", StringComparison.OrdinalIgnoreCase) ||
                songPath.StartsWith("//"))
            {
                return songPath;
            }
            return ResolveUrl("~/" + songPath.TrimStart('.', '/'));
        }

        protected void LnkLogout_Click(object sender, EventArgs e)
        {
            FormsAuthentication.SignOut();
            Session.Clear();
            Response.Redirect("~/Login.aspx", true);
        }
    }

}
