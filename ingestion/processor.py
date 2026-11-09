import json
import logging
import os
import sys
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path

import psycopg

LOG_DIR = Path("/app/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
RAW_DIR = Path("/app/data/raw")
ESTADO = Path("/app/data/estado.json")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S%z",
    handlers=[logging.FileHandler(LOG_DIR / "processor.log")],
)
log = logging.getLogger("processor")


def leer_lineas(archivo):
    """Regresa las lineas completas del archivo; la ultima puede estar a medio escribir."""
    with open(archivo, "rb") as f:
        partes = f.read().split(b"\n")
    return [p.decode("utf-8", errors="replace") for p in partes[:-1]]


def event_id_de(linea):
    try:
        return json.loads(linea)["event_id"]
    except (ValueError, KeyError, TypeError):
        return None


def ids_procesados(archivo, n):
    if not archivo.exists():
        return set()
    return {event_id_de(linea) for linea in leer_lineas(archivo)[:n]}


def archivo_anterior(topic, archivo):
    """El archivo del crudo de la hora anterior a la de este archivo."""
    hora = datetime.strptime(archivo.name[len(topic) + 1:-4], "%Y-%m-%dT%H")
    anterior = (hora - timedelta(hours=1)).strftime("%Y-%m-%dT%H")
    return RAW_DIR / f"{topic}_{anterior}.log"


def leer_mensaje(linea):
    m = json.loads(linea)
    played_at = datetime.fromisoformat(m["played_at"])
    if played_at.tzinfo is None:
        raise ValueError("played_at sin zona horaria")
    return (
        str(m["event_id"]),
        int(m["subscriber_id"]),
        int(m["song_id"]),
        played_at.astimezone(timezone.utc).date(),
        int(m["ms_played"]),
    )


def conectar():
    return psycopg.connect(
        host=os.environ["POSTGRES_HOST"],
        dbname=os.environ["POSTGRES_DB"],
        user=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"],
    )


def procesar(topic):
    archivos = sorted(RAW_DIR.glob(f"{topic}_*.log"))
    if not archivos:
        log.warning("El crudo de %s todavia no existe en %s", topic, RAW_DIR)
        return

    estado = json.loads(ESTADO.read_text()) if ESTADO.exists() else {}
    validos = []
    leidos = duplicados = skips = malformados = 0

    for archivo in archivos:
        lineas = leer_lineas(archivo)
        hechas = estado.get(archivo.name, 0)
        if hechas >= len(lineas):
            continue
        anterior = archivo_anterior(topic, archivo)
        vistos = ids_procesados(archivo, hechas) | ids_procesados(anterior, estado.get(anterior.name, 0))

        for linea in lineas[hechas:]:
            leidos += 1
            try:
                event_id, subscriber_id, song_id, play_date, ms_played = leer_mensaje(linea)
            except (ValueError, KeyError, TypeError):
                malformados += 1
                continue
            if event_id in vistos:
                duplicados += 1
                continue
            vistos.add(event_id)
            if ms_played < 30000:
                skips += 1
                continue
            validos.append((subscriber_id, song_id, play_date))
        estado[archivo.name] = len(lineas)

    if leidos == 0:
        log.info("Corrida sin mensajes nuevos")
        return

    with conectar() as conn:
        suscriptores = {r[0] for r in conn.execute("SELECT subscriber_id FROM subscribers").fetchall()}
        canciones = {r[0] for r in conn.execute("SELECT song_id FROM songs").fetchall()}
        conocidos = [v for v in validos if v[0] in suscriptores and v[1] in canciones]
        por_suscriptor = Counter((s, c) for s, c, d in conocidos)
        por_dia = Counter((c, d) for s, c, d in conocidos)
        with conn.cursor() as cur:
            cur.executemany(
                """INSERT INTO subscriber_song_play (subscriber_id, song_id, num_rep) VALUES (%s, %s, %s)
                   ON CONFLICT (subscriber_id, song_id)
                   DO UPDATE SET num_rep = subscriber_song_play.num_rep + EXCLUDED.num_rep""",
                [(s, c, n) for (s, c), n in por_suscriptor.items()],
            )
            cur.executemany(
                """INSERT INTO song_daily_play (song_id, play_date, num_rep) VALUES (%s, %s, %s)
                   ON CONFLICT (song_id, play_date)
                   DO UPDATE SET num_rep = song_daily_play.num_rep + EXCLUDED.num_rep""",
                [(c, d, n) for (c, d), n in por_dia.items()],
            )

    ESTADO.write_text(json.dumps(estado, indent=2))
    log.info(
        "Corrida: %s mensajes leidos, %s contados; descartados: %s duplicados, %s skips, %s mal formados, %s con ids que no existen",
        leidos, len(conocidos), duplicados, skips, malformados, len(validos) - len(conocidos),
    )


try:
    procesar(os.environ["KAFKA_TOPIC"])
except KeyError as e:
    log.error("Falta la variable de entorno %s; revisa docker-compose.yml y /etc/environment", e)
    sys.exit(1)
except psycopg.OperationalError as e:
    log.error("No se pudo conectar a PostgreSQL; se reintenta en la siguiente corrida: %s", e)
    sys.exit(1)
except Exception:
    log.exception("Error inesperado en la corrida")
    sys.exit(1)
