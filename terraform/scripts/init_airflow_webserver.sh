#!/bin/bash
# scripts/init_airflow_webserver.sh

set -e

echo "Running Airflow DB migrations..."
airflow db migrate

echo "Creating Airflow admin user..."
airflow users create \
    --username "${_AIRFLOW_WWW_USER_USERNAME}" \
    --firstname Airflow \
    --lastname Admin \
    --role Admin \
    --email admin@example.com \
    --password "${_AIRFLOW_WWW_USER_PASSWORD}"

echo "Airflow initialization complete."
exec "$@"