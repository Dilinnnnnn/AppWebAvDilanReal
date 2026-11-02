using System;
using System.Collections.Generic;
using System.Web;

namespace WebAppPoliMusicV2.Entities
{
    /// <summary>
    /// Entity that maps the table [TBL_SONG].
    /// Columns: ID_SONG, SONG_NAME, SONG_PATH, PLAYS
    /// </summary>
    public class Song
    {
        public Song()
        {
        }
        public Song(int id, string name, string path, int plays)
        {
            ID = id;
            Name = name;
            Path = path;
            Plays = plays;
        }
        public int ID { get; set; }
        public string Name { get; set; }
        public string Path { get; set; }
        public int Plays { get; set; }
    }

}
