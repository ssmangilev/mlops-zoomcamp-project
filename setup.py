from setuptools import setup, find_packages

setup(
    name="mlops-zoomcamp-project",
    version="0.1.0",
    packages=find_packages(),
    description="MLOps Zoomcamp Project",
    author="MLOps Zoomcamp",
    install_requires=[
        "mlflow",
        "numpy",
        "scikit-learn",
        "hyperopt",
        "apache-airflow",
        "pytest",
    ],
)