import os

from typing import Final, Literal

import boto3

from aws_lambda_powertools import Logger, Metrics, Tracer
from aws_lambda_powertools.event_handler import APIGatewayRestResolver
from aws_lambda_powertools.logging import correlation_paths
from aws_lambda_powertools.metrics import MetricUnit
from aws_lambda_powertools.utilities.data_classes import (
    APIGatewayProxyEvent,
    event_source,
)
from aws_lambda_powertools.utilities.typing import LambdaContext

app = APIGatewayRestResolver(debug=True)
tracer = Tracer()
logger = Logger()
metrics = Metrics(namespace="Docs Service - Fetch/Download")

NAMESPACE: Final[str] = os.environ.get("NAMESPACE", "dev")
DOCUMENT_BUCKET: Final[str] = os.environ.get("DOCUMENT_BUCKET", "test-document-service")


@logger.inject_lambda_context(correlation_id_path=correlation_paths.API_GATEWAY_REST)
@tracer.capture_lambda_handler
@metrics.log_metrics(capture_cold_start_metric=True)
@event_source(data_class=APIGatewayProxyEvent)
def lambda_handler(event: dict, context: LambdaContext) -> dict:
    logger.info(f"Event: {event}")
    return app.resolve(event, context)


@app.get("/generate_document_url")
@tracer.capture_method
def generate_document_url() -> tuple[dict[str, str], Literal[200, 422]]:
    metrics.add_metric(name="GenerateDocumentUrl", unit=MetricUnit.Count, value=1)
    logger.info("Generate document url API called")
    document_path: str = app.current_event.get_query_string_value(name="document_path", default_value="")

    if not document_path or not document_path.startswith("s3://"):
        logger.info("Invalid document path - Aborting process")
        response_message = (
            "It looks like you didn't provide a valid document path, please double check your params and try again."
        )
        status_code = 422

        return {"message": response_message}, status_code

    s3_client = boto3.client("s3")
    bucket, path = document_path.replace("s3://", "").split("/", 1)

    s3_params = {
        "Bucket": bucket,
        "Key": path,
        "ResponseContentDisposition": "inline",
    }

    presigned_url = s3_client.generate_presigned_url(
        "get_object",
        Params=s3_params,
        ExpiresIn=300,
    )

    return {"message": presigned_url}, 200
