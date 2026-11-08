using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BLL.PoliMusicV3
{
    /// <summary>
    /// Business layer for the songs. It only delegates the work to the DAL
    /// and turns the DataTable rows into EntityLayer.PoliMusicV3.Song objects.
    /// </summary>
    public class Song
    {
        private string strConnectionString;
        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }

        public int Save(EntityLayer.PoliMusicV3.Song song)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Save(song);
        }

        public DataTable Read()
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Read();
        }

        public DataTable ReadById(int idSong)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).ReadById(idSong);
        }

        /// <summary>
        /// Returns the song list as a typed list ready to be bound to the web page.
        /// </summary>
        public List<EntityLayer.PoliMusicV3.Song> ReadSongs()
        {
            List<EntityLayer.PoliMusicV3.Song> songs = new List<EntityLayer.PoliMusicV3.Song>();
            DataTable dtSong = new DAL.PoliMusicV3.Song(strConnectionString).Read();
            foreach (DataRow row in dtSong.Rows)
            {
                songs.Add(MapRow(row));
            }
            return songs;
        }

        /// <summary>
        /// Returns one song by id or null when it does not exist.
        /// </summary>
        public EntityLayer.PoliMusicV3.Song ReadSong(int idSong)
        {
            DataTable dtSong = new DAL.PoliMusicV3.Song(strConnectionString).ReadById(idSong);
            if (dtSong == null || dtSong.Rows.Count == 0)
            {
                return null;
            }
            return MapRow(dtSong.Rows[0]);
        }

        public int Update(EntityLayer.PoliMusicV3.Song song)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Update(song);
        }

        public int Delete(int idSong)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Delete(idSong);
        }

        public int IncrementPlays(int idSong)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).IncrementPlays(idSong);
        }

        public int GetPlays(int idSong)
        {
            EntityLayer.PoliMusicV3.Song song = ReadSong(idSong);
            return (song == null) ? 0 : song.Plays;
        }

        public int CheckExistSong(string songName)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).CheckExistSong(songName);
        }

        /// <summary>
        /// Basic validations before saving a song.
        /// </summary>
        public string Validations(EntityLayer.PoliMusicV3.Song song)
        {
            if (song == null)
            {
                return "The song is required.";
            }
            if (string.IsNullOrEmpty(song.Name) || song.Name.Trim().Length == 0)
            {
                return "The song name is required.";
            }
            if (string.IsNullOrEmpty(song.Path) || song.Path.Trim().Length == 0)
            {
                return "The song path is required.";
            }
            if (CheckExistSong(song.Name) != 0)
            {
                return "Song name already registered!";
            }
            return string.Empty;
        }

        private EntityLayer.PoliMusicV3.Song MapRow(DataRow row)
        {
            EntityLayer.PoliMusicV3.Song song = new EntityLayer.PoliMusicV3.Song();
            song.ID = Convert.ToInt32(row["ID_SONG"]);
            song.Name = row["SONG_NAME"].ToString();
            song.Path = row["SONG_PATH"].ToString();
            song.Plays = (row["PLAYS"] == DBNull.Value) ? 0 : Convert.ToInt32(row["PLAYS"]);
            return song;
        }
    }
}
