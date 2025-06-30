import logging
from datetime import datetime, timedelta

from airflow.decorators import dag, task, task_group
from airflow.models.param import Param

# Import your existing tasks
from tasks.pandas.download_and_read_parquet import (
    download_and_read_parquet,
)
from tasks.pandas.prepare_taxi_dataset import (
    prepare_taxi_dataset,
)
from tasks.ml.train_linear_regression import (
    train_linear_regression_and_save_results_in_mlflow,
)

logger = logging.getLogger("airflow.task")

# Define the DAG using the TaskFlow API

@dag(
    dag_id="taxi_ml_pipeline",
    description="Pipeline to download taxi data, prepare it, and train a linear regression model",
    schedule=None,  # Set to None for manual triggering in Airflow 3.0
    start_date=datetime(2023, 1, 1),
    catchup=False,
    tags=["ml", "taxi", "linear-regression"],
    params={
        "file_url": Param(
            default="/tmp/taxi_data.parquet", # "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2023-03.parquet",
            type="string",
            description="URL of the Parquet file to download",
        ),
        "experiment_name": Param(
            default="taxi-duration-prediction",
            type="string",
            description="Name of the MLflow experiment",
        ),
    },
    doc_md="""
    # Taxi ML Pipeline

    This pipeline performs the following steps:

    1. Downloads a Parquet file containing taxi trip data
    2. Prepares the dataset by cleaning and feature engineering
    3. Trains a linear regression model to predict trip duration
    4. Logs the model and metrics to MLflow

    ## Parameters

    * `file_url`: URL of the Parquet file to download
    * `experiment_name`: Name of the MLflow experiment

    ## Usage

    Trigger this DAG manually with custom parameters:

    ```
    airflow dags trigger taxi_ml_pipeline --conf '{"file_url": "https://example.com/data.parquet", "experiment_name": "my-experiment"}'
    ```
    """,
)
def taxi_ml_pipeline():
    """
    DAG to orchestrate taxi data processing and ML model training
    """
    # downloaded_data_path = download_and_read_parquet(
    #     url="{{ params.file_url }}",
    #     filename="taxi_data.parquet"
    # )
    # prepared_dataset_path = prepare_taxi_dataset(
    #     filename="{{ params.file_url }}"
    # )
    train_linear_regression_and_save_results_in_mlflow(
        df_filename="/tmp/prepared_dataset.parquet",
        experiment_name="{{ params.experiment_name }}"
    )


dag = taxi_ml_pipeline()
