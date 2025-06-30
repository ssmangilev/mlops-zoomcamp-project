from airflow.decorators import dag, task
from datetime import datetime
import logging

logger = logging.getLogger("airflow.task")

@dag(
    dag_id="chained_taskflow_dag",
    schedule=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["example"],
)
def my_chained_dag():

    @task
    def extract():
        logger.info("🔍 Extracting data...")
        return {"name": "Alice", "age": 30}

    @task
    def transform(data: dict):
        logger.info("🔧 Transforming data...")
        data["age"] += 1
        return "transformed"

    @task
    def load(data: dict):
        logger.info(f"📦 Loading data: {data}")

    # Task chaining
    load(transform(extract()))


dag = my_chained_dag()