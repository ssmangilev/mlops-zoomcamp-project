import mlflow

from airflow.decorators import task
import mlflow.artifacts
from sklearn.feature_extraction import DictVectorizer

from orchestration.metric_registry import metric_registry


@task.python
def train_and_save_model(
    run_id: str,
    model_name: str,
    model_mlflow_name: str,
    model_mlflow_tags: dict[any, any],
    model_version: str,
    dataset_name: str,
    model_type: str,
    model_hyperparameters: dict[any, any],
    metric_name: str,
    metric_greater_is_better: bool,
    X_train_filename: str,
    y_train_filename: str,
    X_test_filename: str,
    y_test_filename: str,
    dst_path: str,
    artifact_path: str,
) -> None:
    """
    Train and save the model to MLflow.
    :param run_id: MLflow parent run ID
    :param model_name: Name of the model to be trained
    :param X_train_filename: Path to the training features file
    :param y_train_filename: Path to the training target variable file
    :param artifact_path: Path to save the model in MLflow
    """
    _train_and_save_model(
        run_id=run_id,
        model_name=model_name,
        model_mlflow_name=model_mlflow_name,
        X_train_filename=X_train_filename,
        y_train_filename=y_train_filename,
        artifact_path=artifact_path,
        dst_path=dst_path,
        model_hyperparameters=model_hyperparameters,
        metric_name=metric_name,
        metric_greater_is_better=metric_greater_is_better,
        X_test_filename=X_test_filename,
        y_test_filename=y_test_filename,
        model_version=model_version,
        dataset_name=dataset_name,
        model_type=model_type,
    )


def _train_and_save_model(
    run_id: str,
    model_name: str,
    model_hyperparameters: dict[any, any],
    metric_name: str,
    model_mlflow_name: str,
    model_mlflow_tags: dict[any, any],
    metric_greater_is_better: bool,
    model_version: str,
    dataset_name: str,
    model_type: str,
    X_train_filename: str,
    y_train_filename: str,
    X_test_filename: str,
    y_test_filename: str,
    artifact_path: str,
    dst_path: str,
) -> None:
    """
    Train and save the model to MLflow.
    :param run_id: MLflow parent run ID
    :param model_name: Name of the model to be trained
    :param X_train_filename: Path to the training features file
    :param y_train_filename: Path to the training target variable file
    :param artifact_path: Path to save the model in MLflow
    """
    with mlflow.start_run(run_id=run_id, nested=True, run_name="train_model"):
        mlflow.set_tag("model", model_name)
        mlflow.set_tag("version", model_version)
        mlflow.set_tag("dataset", dataset_name)
        mlflow.set_tag("model_type", model_type)
        mlflow.log_param("data_path", dst_path)
        # Load the training data
        X_train = mlflow.artifacts.download_artifacts(
            artifact_uri=X_train_filename, run_id=run_id,
            artifact_path=artifact_path,
            dst_path=dst_path
        )
        y_train = mlflow.artifacts.download_artifacts(
            artifact_uri=y_train_filename, run_id=run_id,
            artifact_path=artifact_path,
            dst_path=dst_path
        )
        X_test = mlflow.artifacts.download_artifacts(
            artifact_uri=X_test_filename, run_id=run_id,
            artifact_path=artifact_path,
            dst_path=dst_path
        )
        y_test = mlflow.artifacts.download_artifacts(
            artifact_uri=y_test_filename, run_id=run_id,
            artifact_path=artifact_path,
            dst_path=dst_path
        )
        dv = DictVectorizer()
        X_train = dv.fit_transform(X_train)
        X_test = dv.transform(X_test)
        # Train the model
        model = model_name(**model_hyperparameters)
        model.fit(X_train, y_train)

        y_pred = model.predict(X_test)

        metric_calcaulate_function = metric_registry.get(metric_name)
        metric_test_value = metric_calcaulate_function(y_test, y_pred)
        if metric_greater_is_better:
            metric_test_value = -metric_test_value
        mlflow.log_metric(
            key=f'test_{metric_name}_{run_id}',
            value=metric_test_value,
            step=0,
        )
        # Log the model
        mlflow.register_model(
            artifact_path=artifact_path,
            model_uri=mlflow.get_artifact_uri(),
            registered_model_name=model_mlflow_name,
            tags=model_mlflow_tags,
        )
