import io
import os
import random
import uuid

from datetime import datetime
from typing import Final, Literal

import boto3
import requests

from aws_lambda_powertools import Logger, Metrics, Tracer
from aws_lambda_powertools.event_handler import APIGatewayRestResolver
from aws_lambda_powertools.logging import correlation_paths
from aws_lambda_powertools.metrics import MetricUnit
from aws_lambda_powertools.utilities.typing import LambdaContext
from botocore.exceptions import ClientError
from requests.exceptions import HTTPError, Timeout
from user_agents import random_user_agent

app = APIGatewayRestResolver()
tracer = Tracer()
logger = Logger()
metrics = Metrics(namespace="Docs Service - Fetch/Download")

NAMESPACE: Final[str] = os.environ.get("NAMESPACE", "dev")
DOCUMENT_BUCKET: Final[str] = os.environ.get("DOCUMENT_BUCKET", "test-document-service")


@logger.inject_lambda_context(correlation_id_path=correlation_paths.API_GATEWAY_REST)
@tracer.capture_lambda_handler
@metrics.log_metrics(capture_cold_start_metric=True)
def lambda_handler(event: dict, context: LambdaContext) -> dict:
    logger.info(f"Event: {event}")
    return app.resolve(event, context)


@app.post("/upload/remote")
@tracer.capture_method
def upload() -> tuple[dict[str, str], Literal[201, 422]]:
    metrics.add_metric(name="UploadDocument", unit=MetricUnit.Count, value=1)
    logger.info("Upload document API called")
    data: dict = app.current_event.json_body
    remote_url: str | None = data.get("remote_url")

    if not remote_url or not remote_url.endswith(".pdf"):
        logger.info("Invalid document - Aborting process")
        response_message = (
            "It looks like you didn't provide a valid link, " "please double check your params and try again."
        )
        status_code = 422

    else:
        response_message, status_code = download_remote_file(remote_url=remote_url)

    return {"message": response_message}, status_code


def download_remote_file(remote_url: str) -> tuple[str, Literal[201, 422]]:
    logger.info("Start download process")
    s3_client = boto3.client("s3")
    today_date = datetime.today().strftime("%Y-%m-%d")
    status_code = 422

    random_referers = [
        "https://stackoverflow.com/",
        "https://twitter.com/",
        "https://www.google.com/",
        "https://www.bing.com/",
        "https://www.bbc.com/",
        "https://www.theguardian.com/",
        "https://www.dailymail.co.uk/",
        "https://www.openai.com/",
        "https://www.tesla.com/",
    ]

    try:
        headers = {
            "User-Agent": random_user_agent(),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Charset": "ISO-8859-1,utf-8;q=0.7,*;q=0.3",
            "Accept-Encoding": "none",
            "Accept-Language": "en-GB,en;q=0.5",
            "Connection": "keep-alive",
            "Referer": random.choice(random_referers),
        }

        response = requests.get(remote_url, headers=headers, stream=True, timeout=60)
        response.raise_for_status()
        document_body = io.BytesIO(response.content)
        document_id = str(uuid.uuid4())

        s3_client.upload_fileobj(
            document_body,
            DOCUMENT_BUCKET,
            f"files/{today_date}/{document_id}/document.pdf",
            ExtraArgs={
                "ContentType": "application/pdf",
                "ContentDisposition": "inline",
            },
        )

        response_message = f"Document {document_id} successfully downloaded, it will be processed soon."
        status_code = 201
        logger.info(response_message)

    except HTTPError:
        response_message = "Document failed to download due to an HTTP error."
        logger.info(response_message)

    except Timeout:
        response_message = "Document failed to download due to a connection timeout."
        logger.info(response_message)

    except ClientError:
        response_message = "Document failed to download due to a connection error with S3."
        logger.info(response_message)

    return response_message, status_code
