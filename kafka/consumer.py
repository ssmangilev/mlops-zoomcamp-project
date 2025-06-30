import os
import signal
import time
import json
import threading
from typing import List, Tuple

import mlflow
import pandas as pd
from confluent_kafka import Consumer
from mlflow.pyfunc import PyFuncModel
from mlflow.tracking import MlflowClient

# Control flags
running = True

# Buffer for batch logging: List of tuples (input_data_dict, prediction)
batch_buffer: List[Tuple[dict, any]] = []
buffer_lock = threading.Lock()  # To avoid race conditions on buffer

BATCH_SIZE = 10           # Save after every 10 messages (adjust as needed)
BATCH_SAVE_INTERVAL = 30  # Also save every 30 seconds if batch not full

LOG_FILE_PATH = "batch_predictions.jsonl"


def shutdown_handler(sig, frame):
    global running
    print("Shutdown signal received.")
    running = False


signal.signal(signal.SIGINT, shutdown_handler)
signal.signal(signal.SIGTERM, shutdown_handler)


def save_batch_to_file():
    """Save buffered input and predictions to file in JSONL format."""
    global batch_buffer

    with buffer_lock:
        if not batch_buffer:
            return

        with open(LOG_FILE_PATH, "a") as f:
            for input_data, prediction in batch_buffer:
                record = {
                    "input": input_data,
                    "prediction": prediction,
                    "timestamp": time.time(),
                }
                f.write(json.dumps(record) + "\n")

        print(f"Saved batch of {len(batch_buffer)} records to {LOG_FILE_PATH}")
        batch_buffer.clear()


def periodic_saver():
    """Background thread to save batch every BATCH_SAVE_INTERVAL seconds."""
    while running:
        time.sleep(BATCH_SAVE_INTERVAL)
        save_batch_to_file()


def start_kafka_consumer() -> Consumer:
    conf = {
        'bootstrap.servers': os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092"),
        'group.id': os.getenv('KAFKA_GROUP_ID', 'my-group'),
        'auto.offset.reset': os.getenv('KAFKA_AUTO_OFFSET_RESET', 'earliest'),
    }
    consumer = Consumer(conf)
    consumer.subscribe([os.getenv('KAFKA_TOPIC', 'my-topic')])
    return consumer


def read_messages_from_topic(consumer: Consumer, model: PyFuncModel) -> None:
    import json

    try:
        while running:
            msg = consumer.poll(timeout=1.0)
            if msg is None:
                continue
            if msg.error():
                print(f"Kafka error: {msg.error()}")
                continue

            raw_value = msg.value().decode('utf-8')
            print(f"Received message: {raw_value}")

            try:
                input_data = json.loads(raw_value)
                prediction = predict(model, input_data)
                print(f"Prediction: {prediction}")

                with buffer_lock:
                    batch_buffer.append((input_data, prediction))

                    if len(batch_buffer) >= BATCH_SIZE:
                        save_batch_to_file()

            except Exception as e:
                print(f"Error processing message: {e}")

    finally:
        print("Closing Kafka consumer...")
        consumer.close()
        # Save remaining data on shutdown
        save_batch_to_file()


def get_latest_model_from_mlflow(model_name: str) -> PyFuncModel:
    client = MlflowClient()
    latest_versions = client.get_latest_versions(name=model_name, stages=["Production"])

    if not latest_versions:
        versions = client.search_model_versions(f"name='{model_name}'")
        latest_version = max(versions, key=lambda v: int(v.version))
    else:
        latest_version = latest_versions[0]

    print(f"Latest model version: {latest_version.version}, stage: {latest_version.current_stage}")

    model_uri = f"models:/{model_name}/{latest_version.version}"
    model = mlflow.pyfunc.load_model(model_uri)
    return model


def predict(model: PyFuncModel, input_data: dict):
    input_df = pd.DataFrame([input_data])
    prediction = model.predict(input_df)
    if hasattr(prediction, '__len__') and len(prediction) == 1:
        return prediction[0]
    return prediction


if __name__ == "__main__":
    model_name = os.getenv("MLFLOW_MODEL_NAME", "your_model_name")

    print("Loading model from MLflow...")
    model = get_latest_model_from_mlflow(model_name)

    # Start periodic saver thread
    saver_thread = threading.Thread(target=periodic_saver, daemon=True)
    saver_thread.start()

    print("Starting Kafka consumer...")
    consumer = start_kafka_consumer()

    read_messages_from_topic(consumer, model)

    # Wait for saver thread to finish if needed (optional)
    saver_thread.join(timeout=5)
