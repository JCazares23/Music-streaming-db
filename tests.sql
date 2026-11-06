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
