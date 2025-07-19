import datetime

from airflow.sdk import DAG, task

with DAG(
    dag_id="my_example_dag",
    start_date=datetime.datetime(2021, 1, 1),
    schedule="@daily",
):

    @task
    def hello_world():
        print("Hello, Airflow!")

    hello_world()
