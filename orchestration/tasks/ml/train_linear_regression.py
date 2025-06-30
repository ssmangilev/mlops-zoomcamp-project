import logging
import mlflow.sklearn
import pandas as pd
import mlflow
import os

from airflow.decorators import task
from sklearn.linear_model import LinearRegression
from sklearn.feature_extraction import DictVectorizer
from sklearn.metrics import mean_squared_error

mlflow.set_tracking_uri("http://172.19.0.6:5000")


logger = logging.getLogger("airflow.task")


@task.python
def train_linear_regression_and_save_results_in_mlflow(
        df_filename: str, experiment_name: str) -> None:
    """
    Train a Linear Regression model on the provided DataFrame.

    :param df: Input DataFrame containing features and target variable
    :param experiment_name: Name of the MLflow experiment to log results
    :return: Tuple of trained Linear Regression model and DictVectorizer
    """
    return _train_linear_regression_and_save_results_in_mlflow(
        df_filename=df_filename, experiment_name=experiment_name)


def _train_linear_regression_and_save_results_in_mlflow(
        df_filename: str, experiment_name: str) -> None:
    """
    Train a Linear Regression model on the provided DataFrame.

    :param df: Input DataFrame containing features and target variable
    :param experiment_name: Name of the MLflow experiment to log results
    :return: Tuple of trained Linear Regression model and DictVectorizer
    """
    os.environ['GIT_PYTHON_REFRESH'] = 'quiet'
    df = pd.read_parquet(df_filename)
    categorical = ['PULocationID', 'DOLocationID']
    numerical = ['trip_distance']

    # Create experiment if it doesn't exist
    experiment = mlflow.get_experiment_by_name(experiment_name)
    if experiment is None:
        logger.info(f"Creating new experiment: {experiment_name}")
        mlflow.create_experiment(experiment_name)

    df[categorical] = df[categorical].astype(str)
    train_dicts = df[categorical + numerical].to_dict(orient='records')
    mlflow.set_experiment(experiment_name)
    mlflow.sklearn.autolog()

    with mlflow.start_run() as active_run:
        run_id = active_run.info.run_id
        mlflow.set_tag("mlflow.runName", "linear_regression")
        dv = DictVectorizer()
        X_train = dv.fit_transform(train_dicts)

        target = 'duration'
        y_train = df[target].values

        lr = LinearRegression()
        lr.fit(X_train, y_train)
        logger.info(lr.intercept_)

        mse = mean_squared_error(y_train, lr.predict(X_train))
        mlflow.sklearn.log_model(dv, "dict_vectorizer")
        mlflow.sklearn.log_model(lr, "model")
        mlflow.log_metric("mse", mse)

        # Log important parameters that aren't automatically captured
        mlflow.log_param("categorical_features", categorical)
        mlflow.log_param("numerical_features", numerical)
    # Register the best model
        mlflow.register_model(
            f"runs:/{run_id}/model",
            "NYC-Taxi-Model"
        )
