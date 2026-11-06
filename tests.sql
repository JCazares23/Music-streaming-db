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
