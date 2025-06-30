import mlflow
import pandas as pd

from airflow.decorators import task
from sklearn.model_selection import train_test_split


@task.python
def split_data_into_train_and_test_datasets(
    run_id: str,
    X: dict[any, any],
    y: pd.DataFrame,
    test_size: float = 0.2,
    random_state: int = 42,
) -> tuple[dict[any, any], pd.DataFrame, dict[any, any], pd.DataFrame]:
    """
    Split the data into train and test datasets and save it into mlflow
        artifacts storage.
    :run_id: mlflow parent run id
    :X: features
    :y: target variable
    :test_size: size of the test set
    :random_state: random state for reproducibility
    """
    return _split_data_into_train_and_test_datasets(
        run_id=run_id,
        X=X,
        y=y,
        test_size=test_size,
        random_state=random_state,
    )


def _split_data_into_train_and_test_datasets(
    run_id: str,
    X: dict[any, any],
    y: pd.DataFrame,
    test_size: float = 0.2,
    random_state: int = 42,
) -> tuple[dict[any, any], pd.DataFrame, dict[any, any], pd.DataFrame]:
    """
    Split the data into train and test datasets and save it into mlflow
        artifacts storage.
    :run_id: mlflow parent run id
    :X: features
    :y: target variable
    :test_size: size of the test set
    :random_state: random state for reproducibility
    """
    with mlflow.start_run(run_id=run_id, nested=True, run_name="split_data"):
        X_train, X_test, y_train, y_test = train_test_split(
            X,
            y,
            test_size=test_size,
            random_state=random_state,
        )
        mlflow.log_artifact(
            path="train.pkl",
            artifact_path="train",
            body=pd.DataFrame(X_train).to_json(orient="records"),
        )
        mlflow.log_artifact(
            path="test.pkl",
            artifact_path="test",
            body=pd.DataFrame(X_test).to_json(orient="records"),
        )
        mlflow.log_artifact(
            path="train_target.pkl",
            artifact_path="train",
            body=pd.DataFrame(y_train).to_json(orient="records"),
        )
        mlflow.log_artifact(
            path="test_target.pkl",
            artifact_path="test",
            body=pd.DataFrame(y_test).to_json(orient="records"),
        )
