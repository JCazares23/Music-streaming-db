# Base de datos de Spotify

Tarea 3 del curso: implementación en PostgreSQL 18 de la base de datos transaccional de Spotify a partir del diagrama ER de la Tarea 2. La base se carga con los datos de Laura y se comprueba que sus reglas de negocio se cumplen.

## Contexto

Laura entregó cuatro exports del sistema anterior:

| Export | Contenido |
|---|---|
| Tabla A | Playlists: dueño, suscripción, precio, anuncios y sus canciones en orden |
| Tabla B | Créditos de canciones: duración, género y artistas con su país y su rol |
| Tabla C | Álbumes: año, portada, artista y pistas |
| Tabla D | Suscriptores: registro, suscripción, perfil y lo que guardan en su biblioteca |

En la Tarea 2 se normalizaron hasta 3FN. El resultado son 14 tablas: 9 entidades (`subscriptions`, `subscribers`, `profiles`, `libraries`, `playlists`, `songs`, `artists`, `albums` y `countries`) y 5 tablas de unión (`playlist_song`, `song_artist`, `song_album`, `library_song` y `library_album`).

## Diagramas

### Diagrama conceptual

![Diagrama conceptual](docs/diagrama_conceptual.png)

### Diagrama ER

Tablas, columnas, tipos de dato, PK, FK y cardinalidades. Es el que implementa `db/01_schema.sql`.

![Diagrama ER](docs/diagrama_er.png)

## Estructura

```
db/
  01_schema.sql      tablas, llaves y restricciones
  02_seed.sql        datos de Laura y casos extra
docs/
  diagrama_conceptual.png
  diagrama_er.png
.env.example         plantilla de variables
.gitignore
docker-compose.yml
tests.sql            consultas de Laura, intentos de romper reglas y transacciones
```

## Variables del .env

El archivo `.env` no se sube al repositorio. Se crea a partir de la plantilla:

```
cp .env.example .env
```

| Variable | Valor | Uso |
|---|---|---|
| `POSTGRES_USER` | `admin` | usuario que crea PostgreSQL al inicializarse |
| `POSTGRES_PASSWORD` | la que elijas | contraseña de ese usuario |
| `POSTGRES_DB` | `spotify` | base de datos donde se crean las tablas |

Estos valores solo se usan cuando el volumen está vacío. Si se cambian después, hay que borrar el volumen con `docker compose down -v`.

## Cómo iniciar PostgreSQL

Desde la carpeta del repositorio, en la terminal de Ubuntu:

```
docker compose up -d
```

La primera vez se ejecutan `db/01_schema.sql` y `db/02_seed.sql`. Después de unos segundos se revisa que no haya errores:

```
docker compose logs postgres | grep ERROR
```

Si no muestra nada, la inicialización terminó bien. Para empezar desde cero:

```
docker compose down -v
docker compose up -d
```

## Cómo correr las pruebas

```
docker compose exec postgres psql -U admin -d spotify -f /tests.sql
```

Las pruebas dejan la base igual que como la dejó `02_seed.sql`, así que se pueden correr varias veces con la misma salida. Después de correrlas, `docker compose logs postgres | grep ERROR` también muestra los errores de las pruebas, que son intencionales.

### a) Preguntas de Laura

| # | Pregunta | Resultado |
|---|---|---|
| 1 | ¿Qué canciones tiene la playlist 10, en orden, y quiénes son sus artistas? | 1 Ella Baila Sola (Eslabon Armado, Peso Pluma), 2 TQG (Karol G, Shakira), 3 Bzrp Music Sessions #53 (Bizarrap, Shakira) |
| 2 | ¿Cuántos suscriptores tiene cada suscripción? | Familiar 2, Gratuita 1, Premium 1, Estudiantes 0 |
| 3 | ¿Qué canciones no están en ningún álbum? | 108 Calor de Agosto |
| 4 | ¿Qué tiene guardado cada suscriptor en su biblioteca? | Canciones y álbumes en una sola lista; marta aparece sin nada guardado |
| 5 | ¿Cuál es la canción más escuchada? | No se puede responder: la base no guarda reproducciones |

### b) Intentos de romper las reglas

12 instrucciones que PostgreSQL rechaza con `ERROR`, al menos una por cada tipo de restricción:

| Restricción | Qué se intenta |
|---|---|
| `PRIMARY KEY` | repetir un `song_id`; repetir una canción en la misma playlist |
| `FOREIGN KEY` | playlist de un suscriptor que no existe; cambiar a una suscripción que no existe; borrar un artista con canciones |
| `NOT NULL` | suscriptor sin suscripción; álbum sin artista |
| `UNIQUE` | dos canciones en la misma posición de una playlist; dos canciones con la misma pista en un álbum |
| `CHECK` | precio negativo; rol distinto de `principal` o `feat.`; posición 0 |

### c) Registro y eliminación de un suscriptor

Cada operación es una transacción todo o nada:

1. **Registro exitoso:** se crea sofia@mail.com con su perfil y su biblioteca, y se confirma con `COMMIT`.
2. **Registro fallido:** pedro@mail.com tiene un perfil con país `XX`, que no existe. La transacción falla y termina en `ROLLBACK`; la consulta de antes y la de después muestran que no quedó nada.
3. **Eliminación fallida:** a ana@mail.com se le borran playlists y biblioteca, pero se intenta borrar el suscriptor antes que su perfil. La llave foránea lo impide y todo regresa con `ROLLBACK`; los conteos de antes y después son iguales.
4. **Eliminación exitosa:** sofia crea una playlist y guarda una canción y un álbum. Después se borran en orden sus canciones de playlist, sus playlists, lo guardado, su biblioteca, su perfil y el suscriptor. El catálogo sigue con 8 canciones, 6 álbumes y 11 artistas.

## Supuestos

Además de los supuestos de la Tarea 2:

- Los artistas de Laura tienen identificadores `A1` a `A10`. Como el ER define `artist_id` como `INT`, se guarda solo el número (`A1` es 1, `A10` es 10).
- Las duraciones como `2:45` son minutos y segundos, y se guardan como `TIME` en formato `00:02:45`.
- La playlist vacía (13, Viaje) y la canción sin álbum (108, Calor de Agosto) ya venían en los datos de Laura, así que no se agregaron otras. Se agregaron la suscripción `Estudiantes` (69 MXN, sin anuncios), que no tiene suscriptores, y el artista 11, Natalia Lafourcade, sin canciones ni álbumes.
- La foto del perfil y la portada del álbum pueden quedar vacías (Marta no tiene foto).
- El rol de un artista en una canción solo puede ser `principal` o `feat.`.
- La posición en una playlist y el número de pista en un álbum empiezan en 1 y no se repiten dentro de la misma playlist o álbum.
- El año de un álbum va de 1900 a 2100 y la duración de una canción es mayor a cero.
- El nombre de un país no se repite.

## Cardinalidades y restricciones

| Cardinalidad del ER | Restricción |
|---|---|
| Mínimo 1 del lado "uno" (toda fila hija tiene padre) | FK `NOT NULL`, por ejemplo `subscribers.subscription_name`, `playlists.owner_email`, `albums.artist_id` |
| Relación 1:1 de suscriptor con perfil y con biblioteca | la PK de `profiles` y `libraries` es a la vez FK a `subscribers.email` |
| Relaciones N:M | tabla de unión con PK compuesta y una FK a cada lado |

Ninguna llave foránea usa `ON DELETE CASCADE`: para borrar un suscriptor hay que borrar sus dependencias de forma explícita, y no se puede borrar del catálogo algo que está en uso.

Algunos mínimos de 1 van en el lado contrario a la llave foránea y no se pueden forzar solo con restricciones:

- Todo suscriptor tiene un perfil y una biblioteca. Se garantiza con la transacción de registro, que inserta los tres o ninguno.
- Toda canción tiene al menos un artista y todo álbum tiene al menos una canción. Se cumple en los datos, pero la base no lo impide.

## Cambios respecto al ER

El esquema sigue el diagrama ER de la Tarea 2 sin cambios en tablas, columnas, tipos ni llaves. Solo se agregaron restricciones `CHECK` y `UNIQUE` que no se dibujan en el diagrama (las de la sección de supuestos).
