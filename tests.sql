SELECT ps.position, s.title, string_agg(a.artist_name, ', ' ORDER BY a.artist_name) AS artistas
FROM playlist_song ps
JOIN songs s        ON s.song_id = ps.song_id
JOIN song_artist sa ON sa.song_id = s.song_id
JOIN artists a      ON a.artist_id = sa.artist_id
WHERE ps.playlist_id = 10
GROUP BY ps.position, s.title
ORDER BY ps.position;

SELECT su.subscription_name, COUNT(sb.email) AS suscriptores
FROM subscriptions su
LEFT JOIN subscribers sb ON sb.subscription_name = su.subscription_name
GROUP BY su.subscription_name
ORDER BY suscriptores DESC, su.subscription_name;

SELECT s.song_id, s.title
FROM songs s
LEFT JOIN song_album sa ON sa.song_id = s.song_id
WHERE sa.song_id IS NULL;

SELECT sb.email, g.tipo, g.titulo
FROM subscribers sb
LEFT JOIN (
    SELECT ls.email, 'canción' AS tipo, s.title AS titulo
    FROM library_song ls
    JOIN songs s ON s.song_id = ls.song_id
    UNION ALL
    SELECT la.email, 'álbum' AS tipo, al.title AS titulo
    FROM library_album la
    JOIN albums al ON al.album_id = la.album_id
) g ON g.email = sb.email
ORDER BY sb.email, g.tipo, g.titulo;

-- Pregunta 5: no se puede responder, la base no guarda reproducciones; faltaría una tabla con cada reproducción (suscriptor, canción, fecha).

-- PRIMARY KEY: cada canción tiene un identificador único.
INSERT INTO songs (song_id, title, duration, genre)
VALUES (101, 'Canción repetida', '00:03:00', 'Pop');

-- PRIMARY KEY compuesta: una canción no se repite dentro de la misma playlist.
INSERT INTO playlist_song (playlist_id, song_id, position, added_at)
VALUES (10, 101, 4, '2026-07-01');

-- FOREIGN KEY: toda playlist pertenece a un suscriptor registrado.
INSERT INTO playlists (playlist_id, name, created_at, owner_email)
VALUES (15, 'Fiesta', '2026-07-01', 'nadie@mail.com');

-- FOREIGN KEY: un suscriptor solo puede contratar una suscripción que exista.
UPDATE subscribers SET subscription_name = 'VIP' WHERE email = 'ana@mail.com';

-- FOREIGN KEY al borrar: no se borra un artista que todavía tiene canciones o álbumes.
DELETE FROM artists WHERE artist_id = 2;

-- NOT NULL: todo suscriptor tiene exactamente una suscripción.
INSERT INTO subscribers (email, signup_date, subscription_name)
VALUES ('sin_plan@mail.com', '2026-07-01', NULL);

-- NOT NULL: todo álbum lo publica un artista.
INSERT INTO albums (album_id, title, release_year, cover, artist_id)
VALUES (207, 'Sin artista', 2025, 'sa.jpg', NULL);

-- UNIQUE: dos canciones no ocupan la misma posición en una playlist.
INSERT INTO playlist_song (playlist_id, song_id, position, added_at)
VALUES (10, 104, 1, '2026-07-01');

-- UNIQUE: dos canciones no tienen el mismo número de pista en un álbum.
INSERT INTO song_album (album_id, song_id, track_number)
VALUES (205, 101, 3);

-- CHECK: el precio de una suscripción no puede ser negativo.
UPDATE subscriptions SET price = -10 WHERE subscription_name = 'Premium';

-- CHECK: el rol de un artista en una canción solo puede ser principal o feat.
INSERT INTO song_artist (song_id, artist_id, role)
VALUES (104, 2, 'productor');

-- CHECK: la posición en una playlist empieza en 1.
UPDATE playlist_song SET position = 0 WHERE playlist_id = 11 AND song_id = 104;

-- Registro exitoso: un suscriptor nuevo siempre queda con su perfil y su biblioteca.
BEGIN;
INSERT INTO subscribers (email, signup_date, subscription_name)
VALUES ('sofia@mail.com', '2026-10-01', 'Premium');
INSERT INTO profiles (email, display_name, photo, country_code)
VALUES ('sofia@mail.com', 'sofi', NULL, 'MX');
INSERT INTO libraries (email)
VALUES ('sofia@mail.com');
COMMIT;

SELECT
    (SELECT COUNT(*) FROM subscribers WHERE email = 'sofia@mail.com') AS suscriptor,
    (SELECT COUNT(*) FROM profiles WHERE email = 'sofia@mail.com') AS perfil,
    (SELECT COUNT(*) FROM libraries WHERE email = 'sofia@mail.com') AS biblioteca;

-- Registro fallido: si el perfil falla, no queda un suscriptor sin perfil ni biblioteca.
SELECT
    (SELECT COUNT(*) FROM subscribers WHERE email = 'pedro@mail.com') AS suscriptor,
    (SELECT COUNT(*) FROM profiles WHERE email = 'pedro@mail.com') AS perfil,
    (SELECT COUNT(*) FROM libraries WHERE email = 'pedro@mail.com') AS biblioteca;

BEGIN;
INSERT INTO subscribers (email, signup_date, subscription_name)
VALUES ('pedro@mail.com', '2026-10-02', 'Gratuita');
INSERT INTO profiles (email, display_name, photo, country_code)
VALUES ('pedro@mail.com', 'pedro', NULL, 'XX');
INSERT INTO libraries (email)
VALUES ('pedro@mail.com');
COMMIT;

SELECT
    (SELECT COUNT(*) FROM subscribers WHERE email = 'pedro@mail.com') AS suscriptor,
    (SELECT COUNT(*) FROM profiles WHERE email = 'pedro@mail.com') AS perfil,
    (SELECT COUNT(*) FROM libraries WHERE email = 'pedro@mail.com') AS biblioteca;

-- Eliminación fallida: si un paso falla a medio camino, el suscriptor y todo lo suyo se conserva.
SELECT
    (SELECT COUNT(*) FROM subscribers WHERE email = 'ana@mail.com') AS suscriptor,
    (SELECT COUNT(*) FROM profiles WHERE email = 'ana@mail.com') AS perfil,
    (SELECT COUNT(*) FROM libraries WHERE email = 'ana@mail.com') AS biblioteca,
    (SELECT COUNT(*) FROM library_song WHERE email = 'ana@mail.com') AS canciones_guardadas,
    (SELECT COUNT(*) FROM library_album WHERE email = 'ana@mail.com') AS albumes_guardados,
    (SELECT COUNT(*) FROM playlists WHERE owner_email = 'ana@mail.com') AS playlists,
    (SELECT COUNT(*) FROM playlist_song
     WHERE playlist_id IN (SELECT playlist_id FROM playlists WHERE owner_email = 'ana@mail.com')) AS canciones_en_playlists;

BEGIN;
DELETE FROM playlist_song
WHERE playlist_id IN (SELECT playlist_id FROM playlists WHERE owner_email = 'ana@mail.com');
DELETE FROM playlists WHERE owner_email = 'ana@mail.com';
DELETE FROM library_song WHERE email = 'ana@mail.com';
DELETE FROM library_album WHERE email = 'ana@mail.com';
DELETE FROM subscribers WHERE email = 'ana@mail.com';
DELETE FROM libraries WHERE email = 'ana@mail.com';
DELETE FROM profiles WHERE email = 'ana@mail.com';
COMMIT;

SELECT
    (SELECT COUNT(*) FROM subscribers WHERE email = 'ana@mail.com') AS suscriptor,
    (SELECT COUNT(*) FROM profiles WHERE email = 'ana@mail.com') AS perfil,
    (SELECT COUNT(*) FROM libraries WHERE email = 'ana@mail.com') AS biblioteca,
    (SELECT COUNT(*) FROM library_song WHERE email = 'ana@mail.com') AS canciones_guardadas,
    (SELECT COUNT(*) FROM library_album WHERE email = 'ana@mail.com') AS albumes_guardados,
    (SELECT COUNT(*) FROM playlists WHERE owner_email = 'ana@mail.com') AS playlists,
    (SELECT COUNT(*) FROM playlist_song
     WHERE playlist_id IN (SELECT playlist_id FROM playlists WHERE owner_email = 'ana@mail.com')) AS canciones_en_playlists;

-- Eliminación exitosa: se borra el suscriptor con todo lo suyo sin tocar canciones, álbumes ni artistas.
INSERT INTO playlists (playlist_id, name, created_at, owner_email)
VALUES (15, 'Para correr', '2026-10-02', 'sofia@mail.com');
INSERT INTO playlist_song (playlist_id, song_id, position, added_at) VALUES
    (15, 105, 1, '2026-10-02'),
    (15, 107, 2, '2026-10-02');
INSERT INTO library_song (email, song_id)
VALUES ('sofia@mail.com', 106);
INSERT INTO library_album (email, album_id)
VALUES ('sofia@mail.com', 203);

SELECT
    (SELECT COUNT(*) FROM subscribers WHERE email = 'sofia@mail.com') AS suscriptor,
    (SELECT COUNT(*) FROM profiles WHERE email = 'sofia@mail.com') AS perfil,
    (SELECT COUNT(*) FROM libraries WHERE email = 'sofia@mail.com') AS biblioteca,
    (SELECT COUNT(*) FROM library_song WHERE email = 'sofia@mail.com') AS canciones_guardadas,
    (SELECT COUNT(*) FROM library_album WHERE email = 'sofia@mail.com') AS albumes_guardados,
    (SELECT COUNT(*) FROM playlists WHERE owner_email = 'sofia@mail.com') AS playlists,
    (SELECT COUNT(*) FROM playlist_song
     WHERE playlist_id IN (SELECT playlist_id FROM playlists WHERE owner_email = 'sofia@mail.com')) AS canciones_en_playlists;

SELECT
    (SELECT COUNT(*) FROM songs) AS canciones,
    (SELECT COUNT(*) FROM albums) AS albumes,
    (SELECT COUNT(*) FROM artists) AS artistas;

BEGIN;
DELETE FROM playlist_song
WHERE playlist_id IN (SELECT playlist_id FROM playlists WHERE owner_email = 'sofia@mail.com');
DELETE FROM playlists WHERE owner_email = 'sofia@mail.com';
DELETE FROM library_song WHERE email = 'sofia@mail.com';
DELETE FROM library_album WHERE email = 'sofia@mail.com';
DELETE FROM libraries WHERE email = 'sofia@mail.com';
DELETE FROM profiles WHERE email = 'sofia@mail.com';
DELETE FROM subscribers WHERE email = 'sofia@mail.com';
COMMIT;

SELECT
    (SELECT COUNT(*) FROM subscribers WHERE email = 'sofia@mail.com') AS suscriptor,
    (SELECT COUNT(*) FROM profiles WHERE email = 'sofia@mail.com') AS perfil,
    (SELECT COUNT(*) FROM libraries WHERE email = 'sofia@mail.com') AS biblioteca,
    (SELECT COUNT(*) FROM library_song WHERE email = 'sofia@mail.com') AS canciones_guardadas,
    (SELECT COUNT(*) FROM library_album WHERE email = 'sofia@mail.com') AS albumes_guardados,
    (SELECT COUNT(*) FROM playlists WHERE owner_email = 'sofia@mail.com') AS playlists,
    (SELECT COUNT(*) FROM playlist_song
     WHERE playlist_id IN (SELECT playlist_id FROM playlists WHERE owner_email = 'sofia@mail.com')) AS canciones_en_playlists;

SELECT
    (SELECT COUNT(*) FROM songs) AS canciones,
    (SELECT COUNT(*) FROM albums) AS albumes,
    (SELECT COUNT(*) FROM artists) AS artistas;
