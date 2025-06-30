import pytest
import pandas as pd
from unittest.mock import patch, MagicMock, call

from orchestration.tasks.split_data_into_train_and_test_datasets import (
    _split_data_into_train_and_test_datasets
)


@pytest.fixture
def sample_data():
    """Create sample data for testing"""
    X = pd.DataFrame({
        'feature1': [1, 2, 3, 4, 5],
        'feature2': [0.1, 0.2, 0.3, 0.4, 0.5],
        'feature3': ['a', 'b', 'c', 'd', 'e']
    }).to_dict('records')

    y = pd.DataFrame({
        'target': [0, 1, 0, 1, 0]
    })

    return X, y


@pytest.fixture
def mock_mlflow():
    """Mock MLflow for testing"""
    with patch("orchestration.tasks."
               "split_data_into_train_and_test_datasets.mlflow"
               ) as mock_mlflow:
        mock_run_context = MagicMock()
        mock_mlflow.start_run.return_value.__enter__.return_value =\
            mock_run_context
        yield mock_mlflow


@pytest.fixture
def mock_train_test_split():
    """Mock train_test_split function"""
    with patch("orchestration.tasks."
               "split_data_into_train_and_test_datasets.train_test_split"
               ) as mock_tts:
        # Create sample split data to return
        X_train = pd.DataFrame({
            'feature1': [1, 2, 3],
            'feature2': [0.1, 0.2, 0.3],
            'feature3': ['a', 'b', 'c']
        }).to_dict('records')

        X_test = pd.DataFrame({
            'feature1': [4, 5],
            'feature2': [0.4, 0.5],
            'feature3': ['d', 'e']
        }).to_dict('records')

        y_train = pd.DataFrame({
            'target': [0, 1, 0]
        })

        y_test = pd.DataFrame({
            'target': [1, 0]
        })

        mock_tts.return_value = (X_train, X_test, y_train, y_test)
        yield mock_tts


def test_split_data_into_train_and_test_datasets_internal(
        sample_data, mock_mlflow, mock_train_test_split):
    """Test the internal implementation function with mocked dependencies"""
    # Setup test data
    run_id = "test_run_id"
    X, y = sample_data
    test_size = 0.3
    random_state = 42

    # Run the function
    _split_data_into_train_and_test_datasets(
        run_id=run_id,
        X=X,
        y=y,
        test_size=test_size,
        random_state=random_state
    )

    # Check that mlflow.start_run was called with correct parameters
    mock_mlflow.start_run.assert_called_with(
        run_id=run_id, nested=True, run_name="split_data")

    # Check that train_test_split was called with correct parameters
    mock_train_test_split.assert_called_once_with(
        X,
        y,
        test_size=test_size,
        random_state=random_state
    )
    # Check that mlflow.log_artifact was called for each artifact
    mock_mlflow.log_artifact.assert_has_calls([
        call(path="train.pkl", artifact_path="train",
             body=pd.DataFrame(mock_train_test_split.return_value[0]).to_json(
                 orient="records")),
        call(path="test.pkl", artifact_path="test",
             body=pd.DataFrame(mock_train_test_split.return_value[1]).to_json(
                 orient="records")),
        call(path="train_target.pkl", artifact_path="train",
             body=pd.DataFrame(mock_train_test_split.return_value[2]).to_json(
                 orient="records")),
        call(path="test_target.pkl", artifact_path="test",
             body=pd.DataFrame(mock_train_test_split.return_value[3]).to_json(
                 orient="records"))
    ])


def test_split_data_default_parameters(sample_data, mock_mlflow,
                                       mock_train_test_split):
    """Test the default parameters of the split_data function"""
    # Setup test data
    run_id = "test_run_id"
    X, y = sample_data

    # Run the function with default parameters
    _split_data_into_train_and_test_datasets(
        run_id=run_id,
        X=X,
        y=y
    )

    # Check that train_test_split was called with the default parameters
    mock_train_test_split.assert_called_once_with(
        X,
        y,
        test_size=0.2,  # default test_size
        random_state=42  # default random_state
    )