FROM python:3.12-slim

# Create a non-root user
RUN groupadd -g 1000 mlflow && \
    useradd -u 1000 -g mlflow -s /bin/bash -m mlflow

# Set working directory and permissions
WORKDIR /home/mlflow
RUN chown -R mlflow:mlflow /home/mlflow

COPY ./my_auth_config.ini /home/mlflow/my_auth_config.ini
RUN chmod 600 /home/mlflow/my_auth_config.ini

# Switch to non-root user
USER mlflow

COPY ./requirements.txt /tmp/requirements.txt


RUN pip install --no-cache-dir -r /tmp/requirements.txt

ENV PATH="/home/mlflow/.local/bin:$PATH"

CMD mlflow server \
# MLFLOW_AUTH_CONFIG_PATH=/home/mlflow/my_auth_config.ini \
# --app-name basic-auth \
--backend-store-uri ${BACKEND_URI} \
--default-artifact-root ${ARTIFACT_ROOT} \
--host 0.0.0.0
