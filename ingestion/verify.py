import json
import logging
import os
import sys
from collections import Counter
from pathlib import Path

import psycopg

SENT_LOG = Path("/app/logs/sent.log")
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s", handlers=[logging.StreamHandler()])
log = logging.getLogger("verify")


def enviados_validos():
    """Reproducciones validas por cancion segun sent.log: sin skips y sin repetir event_id."""
    vistos = set()
    conteo = Counter()
    for linea in SENT_LOG.read_text(encoding="utf-8").splitlines():
        m = json.loads(linea)
        if m["event_id"] in vistos:
            continue
        vistos.add(m["event_id"])
        if m["ms_played"] >= 30000:
            conteo[m["song_id"]] += 1
    return conteo


def conteos_bd():
    with psycopg.connect(
        host=os.environ["POSTGRES_HOST"],
        dbname=os.environ["POSTGRES_DB"],
        user=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"],
    ) as conn:
        por_dia = dict(conn.execute("SELECT song_id, SUM(num_rep) FROM song_daily_play GROUP BY song_id").fetchall())
        por_suscriptor = dict(conn.execute("SELECT song_id, SUM(num_rep) FROM subscriber_song_play GROUP BY song_id").fetchall())
    return por_dia, por_suscriptor


try:
    enviados = enviados_validos()
    por_dia, por_suscriptor = conteos_bd()
except FileNotFoundError:
    log.error("No existe %s; el producer todavia no ha enviado nada", SENT_LOG)
    sys.exit(1)
except KeyError as e:
    log.error("Falta la variable de entorno %s", e)
    sys.exit(1)
except psycopg.OperationalError as e:
    log.error("No se pudo conectar a PostgreSQL: %s", e)
    sys.exit(1)

diferencias = []
for song_id in sorted(set(enviados) | set(por_dia) | set(por_suscriptor)):
    s, d, p = enviados.get(song_id, 0), por_dia.get(song_id, 0), por_suscriptor.get(song_id, 0)
    log.info("Cancion %s: sent.log %s, song_daily_play %s, subscriber_song_play %s", song_id, s, d, p)
    if not s == d == p:
        diferencias.append(song_id)

if diferencias:
    log.error("Hay diferencias en las canciones: %s", ", ".join(map(str, diferencias)))
    sys.exit(1)
log.info("OK: %s reproducciones validas en %s canciones coinciden con la base", sum(enviados.values()), len(enviados))
