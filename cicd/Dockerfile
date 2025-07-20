FROM apache/airflow:3.0.2-python3.11

# Uncomment to bake in dags into Docker image
# COPY ./dags/ /opt/airflow/dags/

COPY ./requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt
