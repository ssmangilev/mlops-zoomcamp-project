import pytest
import numpy as np
from unittest.mock import patch, MagicMock, call

from orchestration.tasks.train_and_save_model import (
    _train_and_save_model
)


@pytest.fixture
def mock_mlflow():
    """Mock MLflow for testing"""
    with patch("orchestration.tasks."
               "train_and_save_model.mlflow") as mock_mlflow:
        # Create mock context manager for start_run
        mock_run_context = MagicMock()
        mock_mlflow.start_run.return_value.__enter__.return_value =\
            mock_run_context

        # Setup artifact URI
        mock_mlflow.get_artifact_uri.return_value =\
            "runs:/test-run-id/artifacts"

        yield mock_mlflow


@pytest.fixture
def mock_artifacts():
    """Mock MLflow artifacts module for testing"""
    with patch("orchestration.tasks."
               "train_and_save_model.mlflow.artifacts"
               ) as mock_artifacts:
        # Create sample data to return when download_artifacts is called
        x_train_data = [{"feature1": 1, "feature2": 2},
                        {"feature1": 3, "feature2": 4}]
        y_train_data = np.array([0, 1])
        x_test_data = [{"feature1": 5, "feature2": 6},
                       {"feature1": 7, "feature2": 8}]
        y_test_data = np.array([1, 0])

        # Configure the mock to return different data based on artifact URI
        def side_effect(artifact_uri, run_id, artifact_path, dst_path):
            if "X_train" in artifact_uri:
                return x_train_data
            elif "y_train" in artifact_uri:
                return y_train_data
            elif "X_test" in artifact_uri:
                return x_test_data
            elif "y_test" in artifact_uri:
                return y_test_data
            return None

        mock_artifacts.download_artifacts.side_effect = side_effect
        yield mock_artifacts


@pytest.fixture
def mock_dict_vectorizer():
    """Mock DictVectorizer for testing"""
    with patch("orchestration.tasks.train_and_save_model"
               ".DictVectorizer") as mock_dv:
        mock_dv_instance = MagicMock()
        mock_dv_instance.fit_transform.return_value = np.array([[1, 2], [3, 4]])
        mock_dv_instance.transform.return_value = np.array([[5, 6], [7, 8]])
        mock_dv.return_value = mock_dv_instance
        yield mock_dv


@pytest.fixture
def mock_metric_registry():
    """Mock metric_registry for testing"""
    with patch("orchestration.tasks.train_and_save_model"
               ".metric_registry") as mock_registry:
        # Create a mock metric calculation function
        mock_metric_fn = MagicMock(return_value=0.85)
        mock_registry.get.return_value = mock_metric_fn
        yield mock_registry


@pytest.fixture
def mock_model():
    """Mock model class and instance for testing"""
    mock_model_class = MagicMock()
    mock_model_instance = MagicMock()
    mock_model_instance.predict.return_value = np.array([0, 1])
    mock_model_class.return_value = mock_model_instance
    return mock_model_class


def test_train_and_save_model_implementation(
        mock_mlflow, mock_artifacts,
        mock_dict_vectorizer, mock_metric_registry, mock_model):
    """Test the internal implementation function"""
    # Setup test data
    run_id = "test_run_id"
    model_name = mock_model
    model_mlflow_name = "test_model"
    model_mlflow_tags = {"version": "v1", "type": "classification"}
    model_version = "v1"
    dataset_name = "test_dataset"
    model_type = "classification"
    model_hyperparameters = {"param1": 0.5, "param2": 10}
    metric_name = "accuracy"
    metric_greater_is_better = True
    X_train_filename = "X_train.json"
    y_train_filename = "y_train.json"
    X_test_filename = "X_test.json"
    y_test_filename = "y_test.json"
    dst_path = "/tmp"
    artifact_path = "artifacts"

    # Run the function
    _train_and_save_model(
        run_id=run_id,
        model_name=model_name,
        model_mlflow_name=model_mlflow_name,
        model_mlflow_tags=model_mlflow_tags,
        model_version=model_version,
        dataset_name=dataset_name,
        model_type=model_type,
        model_hyperparameters=model_hyperparameters,
        metric_name=metric_name,
        metric_greater_is_better=metric_greater_is_better,
        X_train_filename=X_train_filename,
        y_train_filename=y_train_filename,
        X_test_filename=X_test_filename,
        y_test_filename=y_test_filename,
        dst_path=dst_path,
        artifact_path=artifact_path
    )

    # Check that mlflow.start_run was called with correct parameters
    mock_mlflow.start_run.assert_called_with(
        run_id=run_id, nested=True, run_name="train_model")

    # Check that MLflow tags were set correctly
    mock_mlflow.set_tag.assert_has_calls([
        call("model", model_name),
        call("version", model_version),
        call("dataset", dataset_name),
        call("model_type", model_type)
    ])

    # Check that MLflow params were logged
    mock_mlflow.log_param.assert_called_with("data_path", dst_path)

    # Check that artifacts were downloaded
    mock_artifacts.download_artifacts.assert_has_calls([
        call(artifact_uri=X_train_filename, run_id=run_id,
             artifact_path=artifact_path, dst_path=dst_path),
        call(artifact_uri=y_train_filename, run_id=run_id,
             artifact_path=artifact_path, dst_path=dst_path),
        call(artifact_uri=X_test_filename, run_id=run_id,
             artifact_path=artifact_path, dst_path=dst_path),
        call(artifact_uri=y_test_filename, run_id=run_id,
             artifact_path=artifact_path, dst_path=dst_path)
    ])

    # Check that DictVectorizer was used correctly
    mock_dict_vectorizer.return_value.fit_transform.assert_called_once()
    mock_dict_vectorizer.return_value.transform.assert_called_once()

    # Check that model was created and trained
    model_name.assert_called_with(**model_hyperparameters)
    model_name.return_value.fit.assert_called_once_with(
        mock_dict_vectorizer.return_value.fit_transform.return_value,
        mock_artifacts.download_artifacts.side_effect(y_train_filename, run_id,
                                                      artifact_path, dst_path)
    )

    # Check that model predicted correctly
    model_name.return_value.predict.assert_called_once_with(
        mock_dict_vectorizer.return_value.transform.return_value
    )

    # Check that metric was calculated using the registry
    mock_metric_registry.get.assert_called_once_with(metric_name)
    mock_metric_registry.get.return_value.assert_called_once_with(
        mock_artifacts.download_artifacts.side_effect(y_test_filename, run_id,
                                                      artifact_path, dst_path),
        model_name.return_value.predict.return_value
    )

    mock_mlflow.log_metric.assert_called_with(
        key=f'test_{metric_name}_{run_id}',
        value=-mock_metric_registry.get.return_value.return_value,
        step=0
    )

    # Check that model was registered
    mock_mlflow.register_model.assert_called_with(
        artifact_path=artifact_path,
        model_uri=mock_mlflow.get_artifact_uri.return_value,
        registered_model_name=model_mlflow_name,
        tags=model_mlflow_tags
    )


def test_train_and_save_model_not_greater_is_better(
        mock_mlflow, mock_artifacts,
        mock_dict_vectorizer, mock_metric_registry, mock_model):
    """Test with metric_greater_is_better=False"""
    # Setup test data with metric_greater_is_better=False
    run_id = "test_run_id"
    model_name = mock_model
    model_hyperparameters = {"param1": 0.5, "param2": 10}
    metric_name = "rmse"
    metric_greater_is_better = False

    # Run the function with minimal required params
    _train_and_save_model(
        run_id=run_id,
        model_name=model_name,
        model_mlflow_name="test_model",
        model_mlflow_tags={},
        model_version="v1",
        dataset_name="test_dataset",
        model_type="regression",
        model_hyperparameters=model_hyperparameters,
        metric_name=metric_name,
        metric_greater_is_better=metric_greater_is_better,
        X_train_filename="X_train.json",
        y_train_filename="y_train.json",
        X_test_filename="X_test.json",
        y_test_filename="y_test.json",
        dst_path="/tmp",
        artifact_path="artifacts"
    )

    mock_mlflow.log_metric.assert_called_with(
        key=f'test_{metric_name}_{run_id}',
        value=mock_metric_registry.get.return_value.return_value,
        step=0
    )


def test_train_and_save_model_error_handling(mock_mlflow, mock_artifacts):
    """Test error handling in the model training function"""
    # Setup test data
    run_id = "test_run_id"

    # Mock artifacts.download_artifacts to raise an exception
    mock_artifacts.download_artifacts.side_effect =\
        Exception("Failed to download artifact")

    # Run the function and check that it raises an exception
    with pytest.raises(Exception) as excinfo:
        _train_and_save_model(
            run_id=run_id,
            model_name=MagicMock(),
            model_mlflow_name="test_model",
            model_mlflow_tags={},
            model_version="v1",
            dataset_name="test_dataset",
            model_type="regression",
            model_hyperparameters={},
            metric_name="rmse",
            metric_greater_is_better=False,
            X_train_filename="X_train.json",
            y_train_filename="y_train.json",
            X_test_filename="X_test.json",
            y_test_filename="y_test.json",
            dst_path="/tmp",
            artifact_path="artifacts"
        )

    # Check that the exception message is correct
    assert "Failed to download artifact" in str(excinfo.value)
