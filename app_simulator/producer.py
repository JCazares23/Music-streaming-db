import json
import logging
import os
import random
import sys
import time
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path

import psycopg
from confluent_kafka import Producer

LOG_DIR = Path("/app/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
SENT_LOG = LOG_DIR / "sent.log"
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S%z",
    handlers=[logging.FileHandler(LOG_DIR / "producer.log"), logging.StreamHandler()],
)
log = logging.getLogger("producer")


def leer_ids():
    """Regresa los ids de suscriptores y de canciones que existen en la base."""
    with psycopg.connect(
        host=os.environ["POSTGRES_HOST"],
        dbname=os.environ["POSTGRES_DB"],
        user=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"],
    ) as conn:
        suscriptores = [r[0] for r in conn.execute("SELECT subscriber_id FROM subscribers").fetchall()]
        canciones = [r[0] for r in conn.execute("SELECT song_id FROM songs").fetchall()]
    return suscriptores, canciones


def reportar_original(err, msg):
    if err is not None:
        log.error("Kafka no confirmo el mensaje: %s", err)
        return
    valor = msg.value().decode("utf-8")
    with open(SENT_LOG, "a", encoding="utf-8") as f:
        f.write(valor + "\n")
    log.info("Enviado: %s", valor)


def reportar_duplicado(err, msg):
    if err is not None:
        log.error("Kafka no confirmo el duplicado: %s", err)
        return
    log.info("Duplicado enviado: %s", msg.value().decode("utf-8"))


def nueva_reproduccion(suscriptores, canciones, skip_rate, max_dias):
    ahora = datetime.now(timezone.utc)
    played_at = ahora - timedelta(seconds=random.uniform(0, max_dias * 86400))
    if random.random() < skip_rate:
        ms_played = random.randint(1000, 29999)
    else:
        ms_played = random.randint(30000, 300000)
    return {
        "event_id": str(uuid.uuid4()),
        "subscriber_id": random.choice(suscriptores),
        "song_id": random.choice(canciones),
        "played_at": played_at.isoformat(timespec="seconds"),
        "ms_played": ms_played,
    }


try:
    topic = os.environ["KAFKA_TOPIC"]
    servidores = os.environ["KAFKA_BOOTSTRAP_SERVERS"]
    intervalo = float(os.environ["INTERVAL_SECONDS"])
    skip_rate = float(os.environ["SKIP_RATE"])
    duplicate_rate = float(os.environ["DUPLICATE_RATE"])
    max_retraso = min(float(os.environ["MAX_DUPLICATE_DELAY_SECONDS"]), 300)
    max_dias = float(os.environ["MAX_PLAY_AGE_DAYS"])
    suscriptores, canciones = leer_ids()
except KeyError as e:
    log.error("Falta la variable de entorno %s; revisa el .env y docker-compose.yml", e)
    sys.exit(1)
except psycopg.OperationalError as e:
    log.error("No se pudo conectar a PostgreSQL; Docker volvera a iniciar el producer: %s", e)
    sys.exit(1)

log.info("Iniciando: %s suscriptores y %s canciones, publicando en %s", len(suscriptores), len(canciones), topic)
producer = Producer({"bootstrap.servers": servidores})
pendientes = []

while True:
    valor = json.dumps(nueva_reproduccion(suscriptores, canciones, skip_rate, max_dias))
    producer.produce(topic, value=valor, on_delivery=reportar_original)
    if random.random() < duplicate_rate:
        pendientes.append((time.time() + random.uniform(0, max_retraso), valor))

    ahora = time.time()
    listos = [v for m, v in pendientes if m <= ahora]
    pendientes = [(m, v) for m, v in pendientes if m > ahora]
    for duplicado in listos:
        producer.produce(topic, value=duplicado, on_delivery=reportar_duplicado)

    producer.flush()
    time.sleep(intervalo)
