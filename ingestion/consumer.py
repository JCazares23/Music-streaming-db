import logging
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

from confluent_kafka import Consumer, KafkaError

LOG_DIR = Path("/app/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
RAW_DIR = Path("/app/data/raw")
RAW_DIR.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S%z",
    handlers=[logging.FileHandler(LOG_DIR / "consumer.log"), logging.StreamHandler()],
)
log = logging.getLogger("consumer")


def archivo_del_mensaje(topic, msg):
    """Archivo del crudo que corresponde a la hora UTC en que el mensaje llego a Kafka."""
    ms = msg.timestamp()[1]
    if ms <= 0:
        ms = time.time() * 1000
    hora = datetime.fromtimestamp(ms / 1000, timezone.utc).strftime("%Y-%m-%dT%H")
    return RAW_DIR / f"{topic}_{hora}.log"


try:
    topic = os.environ["KAFKA_TOPIC"]
    servidores = os.environ["KAFKA_BOOTSTRAP_SERVERS"]
except KeyError as e:
    log.error("Falta la variable de entorno %s; revisa el .env y docker-compose.yml", e)
    sys.exit(1)

consumer = Consumer({
    "bootstrap.servers": servidores,
    "group.id": "ingestion",
    "auto.offset.reset": "earliest",
    "allow.auto.create.topics": True,
    "enable.auto.offset.store": False,
})
consumer.subscribe([topic])
log.info("Suscrito al topico %s; el crudo se escribe en %s", topic, RAW_DIR)

while True:
    msg = consumer.poll(timeout=1.0)
    if msg is None:
        continue
    if msg.error():
        if msg.error().code() == KafkaError.UNKNOWN_TOPIC_OR_PART:
            log.warning("El topico %s todavia no existe; Kafka lo crea al publicar", topic)
        else:
            log.error("Kafka reporto un error: %s", msg.error())
        continue

    archivo = archivo_del_mensaje(topic, msg)
    try:
        with open(archivo, "ab") as f:
            f.write(msg.value() + b"\n")
    except OSError as e:
        log.error("No se pudo escribir en el crudo %s: %s", archivo, e)
        sys.exit(1)
    consumer.store_offsets(msg)
    log.info("Guardado en el crudo (offset %s): %s", msg.offset(), msg.value().decode("utf-8"))
