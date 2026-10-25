-- Script post-instalacion: normaliza rutas de assets y restaura cuentas extra de prueba
USE [BDD_PoliMusic];
GO

-- 1) Rutas canonicas (coinciden con las carpetas fisicas del sitio)
UPDATE TBL_SONG      SET SONG_PATH = '~/SongFiles/bensound-' + LOWER(REPLACE(SONG_NAME, ' ', '-')) + '.mp3';
UPDATE TBL_ALBUM     SET ALBUM_IMAGE_PATH = '~/AlbumImages/album' + CAST(ID_ALBUM AS varchar(10)) + '.png';
UPDATE TBL_ARTIST    SET ARTIST_IMAGE = '~/ArtistImages/artist' + CAST(ID_ARTIST AS varchar(10)) + '.jpg';
UPDATE TBL_PLAYLIST  SET PHOTO = '~/PlaylistImages/' + CASE WHEN ID_PLAYLIST % 5 = 1 THEN 'default.jpg' ELSE 'playlist' + CAST(ID_PLAYLIST AS varchar(10)) + '.png' END;
UPDATE TBL_USER      SET USER_PHOTO = '~/UserImages/' + CASE WHEN USER_TYPE = 1 THEN 'root.png' ELSE 'default.jpg' END;
GO

-- 2) Cuenta del estudiante (misma que usaba en sus pruebas)
IF NOT EXISTS (SELECT 1 FROM TBL_USER WHERE USERNAME = 'Dilan.Real')
BEGIN
    INSERT INTO TBL_USER (USERNAME, PASSWORD, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE)
    VALUES ('Dilan.Real', '12345678', 'dilan.real@epn.edu.ec', '2003-03-28', '~/UserImages/default.jpg', 0);
    PRINT 'Usuario Dilan.Real creado (rol normal)';
END
GO

SELECT ID_SONG, SONG_NAME, SONG_PATH FROM TBL_SONG;
SELECT ID_USER, USERNAME, USER_TYPE FROM TBL_USER;
GO
