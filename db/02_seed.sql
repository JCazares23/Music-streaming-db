INSERT INTO countries (country_code, country_name) VALUES
    ('MX', 'México'),
    ('CO', 'Colombia'),
    ('US', 'Estados Unidos'),
    ('AR', 'Argentina'),
    ('PR', 'Puerto Rico');

INSERT INTO artists (artist_id, artist_name, country_code) VALUES
    (1, 'Karol G', 'CO'),
    (2, 'Shakira', 'CO'),
    (3, 'Miley Cyrus', 'US'),
    (4, 'SZA', 'US'),
    (5, 'Bizarrap', 'AR'),
    (6, 'Eslabon Armado', 'US'),
    (7, 'Peso Pluma', 'MX'),
    (8, 'Bad Bunny', 'PR'),
    (9, 'Chencho Corleone', 'PR'),
    (10, 'Los del Pitic', 'MX');

INSERT INTO albums (album_id, title, release_year, cover, artist_id) VALUES
    (201, 'Desvelado', 2023, 'desvelado.jpg', 6),
    (202, 'Mañana Será Bonito', 2023, 'msb.jpg', 1),
    (203, 'Endless Summer Vacation', 2023, 'esv.jpg', 3),
    (204, 'SOS', 2022, 'sos.jpg', 4),
    (205, 'Un Verano Sin Ti', 2022, 'uvst.jpg', 8),
    (206, 'Las Mujeres Ya No Lloran', 2024, 'lmynl.jpg', 2);

INSERT INTO songs (song_id, title, duration, genre) VALUES
    (101, 'Ella Baila Sola', '00:02:45', 'Regional mexicano'),
    (102, 'TQG', '00:03:17', 'Reguetón'),
    (103, 'Bzrp Music Sessions #53', '00:03:33', 'Pop latino'),
    (104, 'Flowers', '00:03:20', 'Pop'),
    (105, 'Kill Bill', '00:02:33', 'R&B'),
    (106, 'Tití Me Preguntó', '00:04:03', 'Reguetón'),
    (107, 'Me Porto Bonito', '00:02:58', 'Reguetón'),
    (108, 'Calor de Agosto', '00:03:05', 'Regional mexicano');

INSERT INTO song_artist (song_id, artist_id, role) VALUES
    (101, 6, 'principal'),
    (101, 7, 'feat.'),
    (102, 1, 'principal'),
    (102, 2, 'feat.'),
    (103, 5, 'principal'),
    (103, 2, 'feat.'),
    (104, 3, 'principal'),
    (105, 4, 'principal'),
    (106, 8, 'principal'),
    (107, 8, 'principal'),
    (107, 9, 'feat.'),
    (108, 10, 'principal');

INSERT INTO song_album (album_id, song_id, track_number) VALUES
    (201, 101, 6),
    (202, 102, 6),
    (203, 104, 1),
    (204, 105, 2),
    (205, 107, 3),
    (205, 106, 4),
    (206, 103, 11),
    (206, 102, 12);

INSERT INTO subscriptions (subscription_name, price, has_ads) VALUES
    ('Premium', 129.00, false),
    ('Gratuita', 0.00, true),
    ('Familiar', 199.00, false);

INSERT INTO subscribers (email, signup_date, subscription_name) VALUES
    ('ana@mail.com', '2025-11-02', 'Premium'),
    ('luis@mail.com', '2026-01-15', 'Gratuita'),
    ('marta@mail.com', '2026-05-20', 'Familiar'),
    ('diego@mail.com', '2026-09-01', 'Familiar');

INSERT INTO profiles (email, display_name, photo, country_code) VALUES
    ('ana@mail.com', 'anaruiz', 'a1.jpg', 'MX'),
    ('luis@mail.com', 'luis.s', 'l2.jpg', 'MX'),
    ('marta@mail.com', 'marta_g', NULL, 'AR'),
    ('diego@mail.com', 'diegol', 'd4.jpg', 'MX');

INSERT INTO libraries (email) VALUES
    ('ana@mail.com'),
    ('luis@mail.com'),
    ('marta@mail.com'),
    ('diego@mail.com');

INSERT INTO library_song (email, song_id) VALUES
    ('ana@mail.com', 102),
    ('ana@mail.com', 104),
    ('luis@mail.com', 103),
    ('diego@mail.com', 101),
    ('diego@mail.com', 108);

INSERT INTO library_album (email, album_id) VALUES
    ('ana@mail.com', 205),
    ('luis@mail.com', 204),
    ('luis@mail.com', 206);

INSERT INTO playlists (playlist_id, name, created_at, owner_email) VALUES
    (10, 'Gym', '2026-03-01', 'ana@mail.com'),
    (11, 'Para estudiar', '2026-04-10', 'ana@mail.com'),
    (12, 'Gym', '2026-05-02', 'luis@mail.com'),
    (13, 'Viaje', '2026-06-15', 'marta@mail.com'),
    (14, 'Favoritas', '2026-06-20', 'luis@mail.com');

INSERT INTO playlist_song (playlist_id, song_id, position, added_at) VALUES
    (10, 101, 1, '2026-03-01'),
    (10, 102, 2, '2026-03-01'),
    (10, 103, 3, '2026-03-04'),
    (11, 104, 1, '2026-04-10'),
    (11, 101, 2, '2026-04-12'),
    (12, 102, 1, '2026-05-02'),
    (12, 105, 2, '2026-05-02'),
    (14, 103, 1, '2026-06-20'),
    (14, 104, 2, '2026-06-21'),
    (14, 102, 3, '2026-06-22');

INSERT INTO subscriptions (subscription_name, price, has_ads) VALUES
    ('Estudiantes', 69.00, false);

INSERT INTO artists (artist_id, artist_name, country_code) VALUES
    (11, 'Natalia Lafourcade', 'MX');
