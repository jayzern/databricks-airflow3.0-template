from airflow.sdk import DAG
from airflow.providers.databricks.operators.databricks import (
    DatabricksRunNowOperator
)
from .post_and_users_asset import posts_asset, users_asset

with DAG(
    dag_id="trigger_databricks_workflow_dag",
    schedule=(posts_asset & users_asset)
):
    run_databricks_workflows = DatabricksRunNowOperator(
        task_id='trigger_databricks_workflow',
        databricks_conn_id="databricks_conn",
        job_id="879157959924010"
    )
