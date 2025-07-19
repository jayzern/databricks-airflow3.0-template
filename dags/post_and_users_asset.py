import logging
import os

import py7zr
import requests
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.sdk import Asset, asset

posts_asset = Asset("s3://data-platform-tutorial/raw/Posts.xml")
users_asset = Asset("s3://data-platform-tutorial/raw/Users.xml")


@asset.multi(schedule="@daily", outlets=[posts_asset, users_asset, tags_asset])
def posts_and_users():
    key = "ai.meta.stackexchange.com"
    url = f"https://archive.org/download/stackexchange/{key}.7z"
    output_path = f"/tmp/{key}.7z"
    extract_path = f"/tmp/{key}"

    # Download the file from the URL
    logging.info(f"Downloading {url} to {output_path}")
    response = requests.get(url)
    response.raise_for_status()
    with open(output_path, "wb") as file:
        file.write(response.content)

    # Extract the downloaded zipped file
    logging.info(f"Extracting {output_path} to {extract_path}")
    with py7zr.SevenZipFile(output_path, mode="r") as archive:
        archive.extractall(path=extract_path)

    # Load the extracted files to S3
    s3_hook = S3Hook(aws_conn_id="aws_conn")
    posts_file = os.path.join(extract_path, "Posts.xml")
    users_file = os.path.join(extract_path, "Users.xml")
    s3_hook.load_file(
        filename=posts_file,
        key="raw/Posts.xml",
        bucket_name="data-platform-tutorial",
        replace=True,
    )
    s3_hook.load_file(
        filename=users_file,
        key="raw/Users.xml",
        bucket_name="data-platform-tutorial",
        replace=True,
    )
