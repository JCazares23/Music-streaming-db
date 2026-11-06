CREATE TABLE countries (
    country_code char(2)     PRIMARY KEY,
    country_name varchar(60) NOT NULL UNIQUE
);

CREATE TABLE artists (
    artist_id    integer      PRIMARY KEY,
    artist_name  varchar(100) NOT NULL,
    country_code char(2)      NOT NULL REFERENCES countries (country_code)
);

CREATE TABLE albums (
    album_id     integer      PRIMARY KEY,
    title        varchar(150) NOT NULL,
    release_year integer      NOT NULL CHECK (release_year BETWEEN 1900 AND 2100),
    cover        varchar(255),
    artist_id    integer      NOT NULL REFERENCES artists (artist_id)
);

CREATE TABLE songs (
    song_id  integer      PRIMARY KEY,
    title    varchar(150) NOT NULL,
    duration time         NOT NULL CHECK (duration > '00:00:00'),
    genre    varchar(50)  NOT NULL
);

CREATE TABLE song_artist (
    song_id   integer     NOT NULL REFERENCES songs (song_id),
    artist_id integer     NOT NULL REFERENCES artists (artist_id),
    role      varchar(20) NOT NULL CHECK (role IN ('principal', 'feat.')),
    PRIMARY KEY (song_id, artist_id)
);

CREATE TABLE song_album (
    album_id     integer NOT NULL REFERENCES albums (album_id),
    song_id      integer NOT NULL REFERENCES songs (song_id),
    track_number integer NOT NULL CHECK (track_number > 0),
    PRIMARY KEY (album_id, song_id),
    UNIQUE (album_id, track_number)
);

CREATE TABLE subscriptions (
    subscription_name varchar(30)  PRIMARY KEY,
    price             decimal(6,2) NOT NULL CHECK (price >= 0),
    has_ads           boolean      NOT NULL
);

CREATE TABLE subscribers (
    email             varchar(120) PRIMARY KEY,
    signup_date       date         NOT NULL,
    subscription_name varchar(30)  NOT NULL REFERENCES subscriptions (subscription_name)
);

CREATE TABLE profiles (
    email        varchar(120) PRIMARY KEY REFERENCES subscribers (email),
    display_name varchar(50)  NOT NULL,
    photo        varchar(255),
    country_code char(2)      NOT NULL REFERENCES countries (country_code)
);
