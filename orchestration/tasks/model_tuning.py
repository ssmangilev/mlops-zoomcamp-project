import mlflow
import numpy as np

from airflow.decorators import task
from hyperopt import fmin, tpe, Trials
from hyperopt import STATUS_OK
from sklearn.feature_extraction import DictVectorizer
from sklearn.model_selection import cross_val_score
import mlflow.artifacts

from orchestration.registries import model_registry


@task.python
def model_tuning(
    X_train_filename: str,
    y_train_filename: str,
    model_name: str,
    model_hyperparameters: dict[any, any],
    metric_name: str,
    metric_greater_is_better: bool,
    artifact_path: str,
    dst_path: str,
    run_id: str = None,
    params: dict[any, any] = None,
    random_state: int = 42,
    max_evals: int = 10,
) -> dict[any, any]:
    """
    Perform hyperparameter tuning using Hyperopt and log the best model
        to MLflow.
    :param run_id: MLflow parent run ID
    :param X_train_filename: Path to the training features file
    :param X_test_filename: Path to the testing features file
    :param y_train_filename: Path to the training target variable file
    :param y_test_filename: Path to the testing target variable file
    :param random_state: Random state for reproducibility
    :param max_evals: Maximum number of evaluations for Hyperopt
    :param model_name: Name of the model to be tuned
    :param params: Hyperparameters for the model
    :return: Best hyperparameters found by Hyperopt
    """
    return _model_tuning(
        run_id=run_id,
        X_train_filename=X_train_filename,
        y_train_filename=y_train_filename,
        model_name=model_name,
        model_hyperparameters=model_hyperparameters,
        metric_name=metric_name,
        metric_greater_is_better=metric_greater_is_better,
        params=params,
        artifact_path=artifact_path,
        dst_path=dst_path,
        random_state=random_state,
        max_evals=max_evals,
    )


def _model_tuning(
    X_train_filename: str,
    y_train_filename: str,
    model_name: str,
    model_hyperparameters: dict[any, any],
    metric_name: str,
    metric_greater_is_better: bool,
    artifact_path: str,
    dst_path: str,
    run_id: str = None,
    params: dict[any, any] = None,
    random_state: int = 42,
    max_evals: int = 10,
) -> dict[any, any]:
    """
    Perform hyperparameter tuning using Hyperopt and log the best model
        to MLflow.
    :param run_id: MLflow parent run ID
    :param X_train_filename: Path to the training features file
    :param X_test_filename: Path to the testing features file
    :param y_train_filename: Path to the training target variable file
    :param y_test_filename: Path to the testing target variable file
    :param random_state: Random state for reproducibility
    :param max_evals: Maximum number of evaluations for Hyperopt
    :param model_name: Name of the model to be tuned
    :param params: Hyperparameters for the model
    :return: Best hyperparameters found by Hyperopt
    """
    model_class = model_registry.get(model_name)
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
    dv = DictVectorizer()
    X_train = dv.fit_transform(X_train)

    def objective(params):
        with mlflow.start_run(
            run_id=run_id,
            nested=True,
            run_name="model_tuning"
        ):
            mlflow.log_params(params)
            model = model_class(**params)
            score = cross_val_score(
                model, X_train,
                y_train, cv=5, scoring=metric_name).mean()
            if metric_greater_is_better:
                score = -score
            mlflow.log_metric(metric_name, score)
            return {'loss': -score, 'status': STATUS_OK}

    trials = Trials()

    best = fmin(
        fn=objective,
        space=model_hyperparameters,
        algo=tpe.suggest,
        max_evals=50,
        trials=trials,
        rstate=np.random.default_rng(random_state)
    )
    return best
