import datetime

from airflow.sdk import DAG, task
import requests
import py7zr
import os
from airflow.providers.amazon.aws.hooks.s3 import S3Hook

with DAG(
    dag_id="databricks_dag",
    start_date=datetime.datetime(2021, 1, 1),
    schedule="@daily",
):

    @task
    def download_raw_files_to_s3():
        url = "https://archive.org/download/stackexchange/ai.meta.stackexchange.com.7z"
        output_path = "/tmp/ai.meta.stackexchange.com.7z"

        # Download the file from the URL
        with requests.get(url, stream=True) as response:
            response.raise_for_status()
            with open(output_path, "wb") as file:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        file.write(chunk)

        # Extract the downloaded 7z file
        extract_path = "/tmp/ai.meta.stackexchange.com"
        with py7zr.SevenZipFile(output_path, mode="r") as archive:
            archive.extractall(path=extract_path)

        print("Extracted files in:", extract_path)
        print("\n".join(os.listdir(extract_path)))

        s3_hook = S3Hook(aws_conn_id="aws_conn")
        for root, _, files in os.walk(extract_path):
            for file in files:
                local_file = os.path.join(root, file)
                relative_path = os.path.relpath(local_file, extract_path)
                s3_key = os.path.join("raw", relative_path)
                s3_hook.load_file(
                    filename=local_file,
                    key=s3_key,
                    bucket_name="data-platform-tutorial",
                    replace=True,
                )

    download_raw_files_to_s3()
