using System;
using System.Collections.Generic;
using System.Data;
using System.Web;

namespace WebAppPoliMusicV2.BLL
{
    /// <summary>
    /// Business layer for the songs. It only delegates the work to the DAL
    /// and turns the DataTable rows into Entities.Song objects.
    /// </summary>
    public class Song
    {
        private string strConnectionString;
        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }

        public int Save(Entities.Song song)
        {
            return new DAL.Song(strConnectionString).Save(song);
        }

        public DataTable Read()
        {
            return new DAL.Song(strConnectionString).Read();
        }

        public DataTable ReadById(int idSong)
        {
            return new DAL.Song(strConnectionString).ReadById(idSong);
        }

        /// <summary>
        /// Returns the song list as a typed list ready to be bound to the web page.
        /// </summary>
        public List<Entities.Song> ReadSongs()
        {
            List<Entities.Song> songs = new List<Entities.Song>();
            DataTable dtSong = new DAL.Song(strConnectionString).Read();
            foreach (DataRow row in dtSong.Rows)
            {
                songs.Add(MapRow(row));
            }
            return songs;
        }

        /// <summary>
        /// Returns one song by id or null when it does not exist.
        /// </summary>
        public Entities.Song ReadSong(int idSong)
        {
            DataTable dtSong = new DAL.Song(strConnectionString).ReadById(idSong);
            if (dtSong == null || dtSong.Rows.Count == 0)
            {
                return null;
            }
            return MapRow(dtSong.Rows[0]);
        }

        public int Update(Entities.Song song)
        {
            return new DAL.Song(strConnectionString).Update(song);
        }

        public int Delete(int idSong)
        {
            return new DAL.Song(strConnectionString).Delete(idSong);
        }

        public int IncrementPlays(int idSong)
        {
            return new DAL.Song(strConnectionString).IncrementPlays(idSong);
        }

        public int GetPlays(int idSong)
        {
            Entities.Song song = ReadSong(idSong);
            return (song == null) ? 0 : song.Plays;
        }

        public int CheckExistSong(string songName)
        {
            return new DAL.Song(strConnectionString).CheckExistSong(songName);
        }

        /// <summary>
        /// Basic validations before saving a song.
        /// </summary>
        public string Validations(Entities.Song song)
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

        private Entities.Song MapRow(DataRow row)
        {
            Entities.Song song = new Entities.Song();
            song.ID = Convert.ToInt32(row["ID_SONG"]);
            song.Name = row["SONG_NAME"].ToString();
            song.Path = row["SONG_PATH"].ToString();
            song.Plays = (row["PLAYS"] == DBNull.Value) ? 0 : Convert.ToInt32(row["PLAYS"]);
            return song;
        }
    }

}
