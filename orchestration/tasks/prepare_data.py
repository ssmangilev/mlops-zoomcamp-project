from airflow.decorators import task

import pandas as pd


@task.python
def read_and_prepare_data(
    path: str,
    target: str,
) -> tuple[list[dict], pd.Series]:
    """
    Read and prepare the data for training.
    """
    return _read_and_prepare_data(path, target)


def _read_and_prepare_data(
    path: str,
    target: str,
) -> tuple[list[dict], pd.Series]:
    """
    Read and prepare the data for training.
    :path: path to the data
    :target: target variable
    :return: tuple of (X_dict, y)
    """
    df = pd.read_csv(path)

    # Handle empty DataFrame case
    if df.empty:
        return [], pd.Series(dtype='int64')

    # Check if target column exists
    if target not in df.columns:
        raise KeyError(f"Target column '{target}' not found in the dataset")

    y = df[target]
    X = df.drop(columns=[target], errors='ignore')
    X_dict = X.to_dict(orient="records")
    return X_dict, y
