import pytest
import pandas as pd
from unittest.mock import patch
import os

from orchestration.tasks.prepare_data import _read_and_prepare_data


@pytest.fixture
def sample_dataframe():
    """Create a sample dataframe for testing"""
    return pd.DataFrame({
        'feature1': [1, 2, 3, 4, 5],
        'feature2': [0.1, 0.2, 0.3, 0.4, 0.5],
        'feature3': ['a', 'b', 'c', 'd', 'e'],
        'target': [0, 1, 0, 1, 0]
    })


@pytest.fixture
def mock_pandas_read_csv(sample_dataframe):
    """Mock pandas.read_csv to return the sample dataframe"""
    with patch('orchestration.tasks.prepare_data.pd.read_csv') as mock_read_csv:
        mock_read_csv.return_value = sample_dataframe
        yield mock_read_csv


def test_read_and_prepare_data(
        mock_pandas_read_csv, sample_dataframe):
    """Test the _read_and_prepare_data function"""
    # Define test inputs
    path = 'dummy/path/to/data.csv'
    target = 'target'

    # Call the function
    X_dict, y = _read_and_prepare_data(path, target)

    # Verify that read_csv was called with the correct path
    mock_pandas_read_csv.assert_called_once_with(path)

    # Verify the shape and content of the output X_dict
    assert len(X_dict) == len(sample_dataframe)
    assert isinstance(X_dict, list)
    assert all(isinstance(x, dict) for x in X_dict)
    assert all('feature1' in x for x in X_dict)
    assert all('feature2' in x for x in X_dict)
    assert all('feature3' in x for x in X_dict)
    assert all('target' not in x for x in X_dict)

    # Verify the output y is correct
    pd.testing.assert_series_equal(
        y, sample_dataframe['target'])


def test_read_and_prepare_data_error_handling():
    """Test error handling in _read_and_prepare_data function"""
    # Test with non-existent file path
    with pytest.raises(FileNotFoundError):
        _read_and_prepare_data('non_existent_file.csv', 'target')

    # Test with non-existent target column
    sample_df = pd.DataFrame({'feature1': [1, 2], 'feature2': [3, 4]})
    with patch(
        'orchestration.tasks.prepare_data.pd.read_csv',
        return_value=sample_df):
        with pytest.raises(KeyError):
            _read_and_prepare_data(
                'dummy_path.csv', 'non_existent_target')


@pytest.mark.parametrize(
    "test_df, target_col, expected_x_len, expected_y_len", [
        # Empty dataframe
        (pd.DataFrame(), 'target', 0, 0),
        # Dataframe with just the target column
        (pd.DataFrame({'target': [0, 1, 0]}), 'target', 0, 3),
        # Dataframe with multiple features
        (
            pd.DataFrame({
                'f1': [1, 2, 3],
                'f2': [4, 5, 6],
                'target': [0, 1, 0]
            }),
            'target',
            3,
            3
        ),
    ]
)
def test_prepare_data_various_inputs(
        test_df, target_col, expected_x_len, expected_y_len):
    """Test prepare_data with various input dataframes"""
    with patch(
        'orchestration.tasks.prepare_data.pd.read_csv',
        return_value=test_df):
        X_dict, y = _read_and_prepare_data('dummy_path.csv', target_col)

        assert len(X_dict) == expected_x_len
        assert len(y) == expected_y_len


def test_read_and_prepare_data_with_actual_file(tmp_path):
    """Test with an actual CSV file"""
    # Create a temporary CSV file
    df = pd.DataFrame({
        'feature1': [1, 2, 3],
        'feature2': [4, 5, 6],
        'target': [0, 1, 0]
    })
    file_path = os.path.join(tmp_path, 'test_data.csv')
    df.to_csv(file_path, index=False)

    # Call the function with the actual file
    X_dict, y = _read_and_prepare_data(file_path, 'target')

    # Verify results
    assert len(X_dict) == 3
    assert all('feature1' in x for x in X_dict)
    assert all('feature2' in x for x in X_dict)
    pd.testing.assert_series_equal(y, df['target'])
