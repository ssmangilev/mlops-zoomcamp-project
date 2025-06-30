from airflow.decorators import task

import logging
import pandas as pd


logger = logging.getLogger("airflow.task")


@task.python
def prepare_taxi_dataset(
    filename: str
) -> str:
    """
    Prepare the taxi dataset by filtering out rows with missing values in 'pickup_datetime' and 'dropoff_datetime',
    and converting 'pickup_datetime' to datetime format.

    :param df: Input DataFrame containing taxi data
    :return: Cleaned DataFrame with 'pickup_datetime' converted to datetime format
    """
    return _preparare_taxi_dataset(filename=filename)


def _preparare_taxi_dataset(
    filename: str
) -> str:
    logger.info(f"Task started: Preparing taxi dataset from {filename}")
    df = pd.read_parquet(filename)

    df['duration'] = df.tpep_dropoff_datetime - df.tpep_pickup_datetime
    df.duration = df.duration.dt.total_seconds() / 60

    df = df[(df.duration >= 1) & (df.duration <= 60)]

    categorical = ['PULocationID', 'DOLocationID']
    df[categorical] = df[categorical].astype(str)
    logger.info(f"Prepared taxi dataset with {len(df)} rows and {len(df.columns)} columns.")
    logger.info(df.head())
    df.to_parquet("/tmp/prepared_dataset.parquet")
    return "/tmp/prepared_dataset.parquet"  # f"/tmp/prepared_{filename}"
