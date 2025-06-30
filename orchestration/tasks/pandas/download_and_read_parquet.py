import pandas as pd
from io import BytesIO
import logging
import requests
from airflow.decorators import task


logger = logging.getLogger("airflow.task")


@task.python
def download_and_read_parquet(
    url: str,
    filename: str = None,
) -> str:
    """
    Download a Parquet file from a URL and return it as a pandas DataFrame.

    Args:
        url: The URL of the Parquet file
        filename: Optional filename to save the downloaded file (if needed)
        run_id: Optional MLflow run ID for tracking

    Returns:
        pandas DataFrame containing the Parquet data
    """
    return _download_and_read_parquet(
        url=url,
        filename=filename,
    )


def _download_and_read_parquet(
    url: str,
    filename: str = None,
) -> str:
    """
    Download a Parquet file from a URL and return it as a pandas DataFrame.

    Args:
        url: The URL of the Parquet file
        filename: Optional filename to save the downloaded file (if needed)
        run_id: Optional MLflow run ID for tracking
    Returns:
        pandas DataFrame containing the Parquet data
    """

    df = pd.read_parquet(url)
    logger.info(f"Successfully read Parquet data from {url}")
    logger.info(len(df))
    logger.info(df.head())
    df.to_parquet(f"/tmp/{filename}")
    return f"/tmp/{filename}"
