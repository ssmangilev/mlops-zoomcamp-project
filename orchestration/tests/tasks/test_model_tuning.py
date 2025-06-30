import pytest
import numpy as np
from unittest.mock import patch, MagicMock, call

from orchestration.tasks.model_tuning import (
    _model_tuning
)


@pytest.fixture
def mock_mlflow():
    with patch("orchestration.tasks.model_tuning.mlflow") as mock_mlflow:
        mock_run_context = MagicMock()
        mock_mlflow.start_run.return_value.__enter__.return_value =\
            mock_run_context
        yield mock_mlflow


@pytest.fixture
def mock_model_registry():
    with patch("orchestration.tasks.model_tuning"
               ".model_registry") as mock_registry:
        model_mock = MagicMock()
        mock_registry.get.return_value = model_mock
        yield mock_registry


@pytest.fixture
def mock_error_model_registry():
    with patch("orchestration.tasks.model_tuning."
               "model_registry") as mock_registry:
        mock_registry.get.side_effect =\
            KeyError("Model not found in registry")
        yield mock_registry


@pytest.fixture
def mock_artifacts():
    with patch("orchestration.tasks.model_tuning"
               ".mlflow.artifacts") as mock_artifacts:
        # Create sample data to return when download_artifacts is called
        x_train_data = [{"feature1": 1, "feature2": 2},
                        {"feature1": 3, "feature2": 4}]
        y_train_data = [0, 1]

        # Configure the mock to return different data based on URI
        def side_effect(artifact_uri, run_id, artifact_path, dst_path):
            if "X_train" in artifact_uri:
                return x_train_data
            elif "y_train" in artifact_uri:
                return y_train_data
            return None

        mock_artifacts.download_artifacts.side_effect = side_effect
        yield mock_artifacts


@pytest.fixture
def mock_dict_vectorizer():
    with patch("orchestration.tasks.model_tuning.DictVectorizer") as mock_dv:
        mock_dv_instance = MagicMock()
        mock_dv_instance.fit_transform.return_value = np.array([[1, 2], [3, 4]])
        mock_dv.return_value = mock_dv_instance
        yield mock_dv


@pytest.fixture
def mock_cross_val_score():
    with patch("orchestration.tasks.model_tuning.cross_val_score") as mock_cv:
        mock_cv.return_value = np.array([0.8, 0.85, 0.82, 0.79, 0.83])
        yield mock_cv


@pytest.fixture
def mock_fmin():
    with patch("orchestration.tasks.model_tuning.fmin") as mock_fmin:
        mock_fmin.return_value = {"param1": 0.75, "param2": 0.25}
        yield mock_fmin


@pytest.fixture
def mock_trials():
    with patch("orchestration.tasks.model_tuning.Trials") as mock_trials:
        mock_trials_instance = MagicMock()
        mock_trials.return_value = mock_trials_instance
        yield mock_trials


@pytest.fixture
def mock_np_random():
    with patch("orchestration.tasks.model_tuning.np"
               ".random.default_rng") as mock_rng:
        mock_rng_instance = MagicMock()
        mock_rng.return_value = mock_rng_instance
        yield mock_rng


def test_model_tuning_complete_flow(
    mock_mlflow, mock_model_registry, mock_artifacts,
    mock_dict_vectorizer, mock_cross_val_score,
    mock_fmin, mock_trials, mock_np_random
):
    """Test the complete flow of _model_tuning with all dependencies mocked"""
    # Setup test data
    run_id = "test_run_id"
    X_train_filename = "X_train.json"
    y_train_filename = "y_train.json"
    model_name = "test_model"
    model_hyperparameters = {"param1": [0, 1], "param2": [0.1, 0.5]}
    metric_name = "accuracy"
    metric_greater_is_better = True
    artifact_path = "artifacts"
    dst_path = "/tmp"
    params = {"param1": 0.5, "param2": 0.3}
    random_state = 42
    max_evals = 10

    # Mock model class
    mock_model = MagicMock()
    mock_model_registry.get.return_value = mock_model

    # Run the function
    result = _model_tuning(
        run_id=run_id,
        X_train_filename=X_train_filename,
        y_train_filename=y_train_filename,
        model_name=model_name,
        model_hyperparameters=model_hyperparameters,
        metric_name=metric_name,
        metric_greater_is_better=metric_greater_is_better,
        artifact_path=artifact_path,
        dst_path=dst_path,
        params=params,
        random_state=random_state,
        max_evals=max_evals,
    )

    # Check that model_registry.get was called with the correct model name
    mock_model_registry.get.assert_called_with(model_name)

    # Check that download_artifacts was called twice with correct parameters
    mock_mlflow.artifacts.download_artifacts.assert_has_calls([
        call(artifact_uri=X_train_filename, run_id=run_id,
             artifact_path=artifact_path, dst_path=dst_path),
        call(artifact_uri=y_train_filename, run_id=run_id,
             artifact_path=artifact_path, dst_path=dst_path)
    ])

    # Check that DictVectorizer was called
    mock_dict_vectorizer.return_value.fit_transform.assert_called_once()

    # Check that fmin was called with correct parameters
    mock_fmin.assert_called_once()
    assert mock_fmin.call_args[1]['space'] == model_hyperparameters
    assert mock_fmin.call_args[1]['algo'] is not None
    assert mock_fmin.call_args[1]['max_evals'] == 50
    assert mock_fmin.call_args[1]['trials'] == mock_trials.return_value

    # Check the result is as expected
    assert result == {"param1": 0.75, "param2": 0.25}


def test_model_tuning_objective_function(
    mock_mlflow, mock_model_registry, mock_artifacts,
    mock_dict_vectorizer, mock_cross_val_score
):
    """Test the objective function used inside _model_tuning"""
    # Setup test data
    run_id = "test_run_id"
    X_train_filename = "X_train.json"
    y_train_filename = "y_train.json"
    model_name = "test_model"
    model_hyperparameters = {"param1": [0, 1], "param2": [0.1, 0.5]}
    metric_name = "accuracy"
    metric_greater_is_better = True
    artifact_path = "artifacts"
    dst_path = "/tmp"
    params = {"param1": 0.5, "param2": 0.3}
    random_state = 42
    max_evals = 10

    # Create a patch to extract the objective function
    with patch("orchestration.tasks.model_tuning.fmin") as mock_fmin:
        def capture_objective(fn, **kwargs):
            # Save the objective function
            test_model_tuning_objective_function.captured_objective = fn
            return {"param1": 0.75, "param2": 0.25}

        mock_fmin.side_effect = capture_objective

        # Run _model_tuning to capture the objective function
        _model_tuning(
            run_id=run_id,
            X_train_filename=X_train_filename,
            y_train_filename=y_train_filename,
            model_name=model_name,
            model_hyperparameters=model_hyperparameters,
            metric_name=metric_name,
            metric_greater_is_better=metric_greater_is_better,
            artifact_path=artifact_path,
            dst_path=dst_path,
            params=params,
            random_state=random_state,
            max_evals=max_evals,
        )

        # Now test the objective function directly
        objective_fn = test_model_tuning_objective_function.captured_objective
        test_params = {"param1": 0.6, "param2": 0.4}
        result = objective_fn(test_params)

        # Check that the objective function uses MLflow correctly
        mock_mlflow.start_run.assert_called_with(
            run_id=run_id, nested=True, run_name="model_tuning"
        )
        mock_mlflow.log_params.assert_called_with(test_params)

        # Check model instantiation
        mock_model_instance = mock_model_registry.get.return_value.return_value
        mock_model_registry.get.return_value.assert_called_with(**test_params)

        # Check cross validation
        mock_cross_val_score.assert_called_with(
            mock_model_instance,
            mock_dict_vectorizer.return_value.fit_transform.return_value,
            mock_mlflow.artifacts.download_artifacts.side_effect(
                y_train_filename, run_id, artifact_path, dst_path),
            cv=5, scoring=metric_name
        )

        expected_score = -mock_cross_val_score.return_value.mean()
        mock_mlflow.log_metric.assert_called_with(metric_name, expected_score)

        # Check the result has correct structure
        assert result['status'] == 'ok'
        assert result['loss'] == -expected_score


def test_model_tuning_metric_not_greater_is_better(
    mock_mlflow, mock_model_registry, mock_artifacts,
    mock_dict_vectorizer, mock_cross_val_score
):
    """Test the case when metric_greater_is_better=False"""
    # Setup test data with metric_greater_is_better=False
    run_id = "test_run_id"
    X_train_filename = "X_train.json"
    y_train_filename = "y_train.json"
    model_name = "test_model"
    model_hyperparameters = {"param1": [0, 1], "param2": [0.1, 0.5]}
    metric_name = "mse"  # For metrics like MSE, lower is better
    metric_greater_is_better = False
    artifact_path = "artifacts"
    dst_path = "/tmp"
    params = {"param1": 0.5, "param2": 0.3}
    random_state = 42
    max_evals = 10

    # Create a patch to extract the objective function
    with patch("orchestration.tasks.model_tuning.fmin") as mock_fmin:
        def capture_objective(fn, **kwargs):
            # Save the objective function
            test_model_tuning_metric_not_greater_is_better.captured_objective =\
                fn
            return {"param1": 0.75, "param2": 0.25}

        mock_fmin.side_effect = capture_objective

        # Run _model_tuning to capture the objective function
        _model_tuning(
            run_id=run_id,
            X_train_filename=X_train_filename,
            y_train_filename=y_train_filename,
            model_name=model_name,
            model_hyperparameters=model_hyperparameters,
            metric_name=metric_name,
            metric_greater_is_better=metric_greater_is_better,
            artifact_path=artifact_path,
            dst_path=dst_path,
            params=params,
            random_state=random_state,
            max_evals=max_evals,
        )

        # Test the objective function
        objective_fn = test_model_tuning_metric_not_greater_is_better.\
            captured_objective
        test_params = {"param1": 0.6, "param2": 0.4}
        result = objective_fn(test_params)

        expected_score = mock_cross_val_score.return_value.mean()
        mock_mlflow.log_metric.assert_called_with(metric_name, expected_score)

        # But it should still be negated for the loss calculation for hyperopt
        assert result['loss'] == -expected_score


def test_model_tuning_error_downloading_artifacts():
    """Test error handling when downloading artifacts fails"""
    with patch("orchestration.tasks."
               "model_tuning.model_registry") as mock_registry:
        mock_registry.get.return_value = MagicMock()

        with patch("orchestration.tasks.model_tuning"
                   ".mlflow.artifacts") as mock_artifacts:
            mock_artifacts.download_artifacts.side_effect = Exception(
                "Failed to download artifacts")

            run_id = "test_run_id"
            X_train_filename = "X_train.json"
            y_train_filename = "y_train.json"
            model_name = "test_model"
            model_hyperparameters = {"param1": [0, 1], "param2": [0.1, 0.5]}
            metric_name = "accuracy"
            metric_greater_is_better = True
            artifact_path = "artifacts"
            dst_path = "/tmp"
            params = {"param1": 0.5, "param2": 0.3}
            random_state = 42
            max_evals = 10

            with pytest.raises(Exception) as exc_info:
                _model_tuning(
                    run_id=run_id,
                    X_train_filename=X_train_filename,
                    y_train_filename=y_train_filename,
                    model_name=model_name,
                    model_hyperparameters=model_hyperparameters,
                    metric_name=metric_name,
                    metric_greater_is_better=metric_greater_is_better,
                    artifact_path=artifact_path,
                    dst_path=dst_path,
                    params=params,
                    random_state=random_state,
                    max_evals=max_evals,
                )

            assert "Failed to download artifacts" in str(exc_info.value)
            mock_artifacts.download_artifacts.assert_called_once()


def test_model_tuning_invalid_model(mock_error_model_registry):
    """Test case when model_registry.get raises an exception"""
    run_id = "test_run_id"
    X_train_filename = "X_train.json"
    y_train_filename = "y_train.json"
    model_name = "test_model"
    model_hyperparameters = {"param1": [0, 1], "param2": [0.1, 0.5]}
    metric_name = "accuracy"
    metric_greater_is_better = True
    artifact_path = "artifacts"
    dst_path = "/tmp"
    params = {"param1": 0.5, "param2": 0.3}
    random_state = 42
    max_evals = 10

    with pytest.raises(KeyError) as exc_info:
        _model_tuning(
            run_id=run_id,
            X_train_filename=X_train_filename,
            y_train_filename=y_train_filename,
            model_name=model_name,
            model_hyperparameters=model_hyperparameters,
            metric_name=metric_name,
            metric_greater_is_better=metric_greater_is_better,
            artifact_path=artifact_path,
            dst_path=dst_path,
            params=params,
            random_state=random_state,
            max_evals=max_evals,
        )

    assert "Model not found in registry" in str(exc_info.value)
    mock_error_model_registry.get.assert_called_with(model_name)
