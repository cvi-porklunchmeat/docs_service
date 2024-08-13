import logging
import os
import uuid

from datetime import datetime
from typing import Final

import boto3

from aws_lambda_powertools import Logger, Metrics, Tracer
from aws_lambda_powertools.event_handler import APIGatewayRestResolver
from aws_lambda_powertools.logging import correlation_paths
from aws_lambda_powertools.utilities.data_classes import (
    APIGatewayProxyEvent,
    event_source,
)
from aws_lambda_powertools.utilities.typing import LambdaContext

app = APIGatewayRestResolver(debug=True)
tracer = Tracer()
logger = Logger()
metrics = Metrics(namespace="Docs Service - Local Document Upload")


@logger.inject_lambda_context(correlation_id_path=correlation_paths.API_GATEWAY_REST)
@tracer.capture_lambda_handler
@metrics.log_metrics(capture_cold_start_metric=True)
@event_source(data_class=APIGatewayProxyEvent)
def lambda_handler(event: dict, context: LambdaContext) -> dict:
    logger.info(f"Event: {event}")
    return app.resolve(event, context)


EXPIRY_TIME: Final[int] = 900  # 15 minutes
DOCUMENT_BUCKET: Final[str] = os.environ.get("DOCUMENT_BUCKET", "test-document-service")
AWS_REGION_NAME = os.environ.get("REGION", "us-east-1")
DYNAMODB_TABLE_ID = os.environ.get("DYNAMODB_TABLE_ID", "test-docs-service")

logger = logging.getLogger()
logger.setLevel(logging.INFO)

response = {
    "body": "Unauthorized",
    "statusCode": 401,
    "headers": {
        "Access-Control-Allow-Origin": os.environ.get("ALLOWED_ORIGIN", "*"),
        "Access-Control-Allow-Methods": "GET,OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
    },
}


def store_in_database(params: dict[str, str]) -> None:
    client = boto3.resource("dynamodb", region_name=AWS_REGION_NAME)
    table = client.Table(DYNAMODB_TABLE_ID)
    table.put_item(Item=params)


@app.post("/upload/local")
@tracer.capture_method
def upload_local_document() -> dict[str, str | int]:
    s3_client = boto3.client("s3")
    today_date = datetime.today().strftime("%Y-%m-%d")
    document_id = str(uuid.uuid4())
    document_object_key = f"files/{today_date}/{document_id}/document.pdf"
    data: dict = app.current_event.json_body

    document_params: dict = {
        "tags": data.get("tags"),
        "user_email": data.get("user_email"),
        "doc_id": document_id,
        "company_name": data.get("company_name"),
        "sector": data.get("sector"),
        "year": data.get("year"),
        "document_name": data.get("document_name"),
        "group": data.get("group"),
    }

    try:
        presigned_url = s3_client.generate_presigned_url(
            ClientMethod="put_object",
            Params={
                "Bucket": DOCUMENT_BUCKET,
                "Key": document_object_key,
                "ContentType": "application/pdf",
                "ContentDisposition": "inline",
            },
            ExpiresIn=EXPIRY_TIME,
        )

        response["body"] = {
            "message": "Successfully created the pre-signed url.",
            "url": f"{presigned_url}",
        }
        response["statusCode"] = 200
        store_in_database(params=document_params)
        return response

    except Exception as error:
        logger.error(str(error))
        response["body"] = {
            "message": "An error occured while trying to create the pre-signed url. Please try again.",
            "exception_error": str(error),
        }
        response["statusCode"] = 422
        return response
