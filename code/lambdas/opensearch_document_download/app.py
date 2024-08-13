import os

from typing import Final

import boto3

from aws_lambda_powertools import Logger, Metrics, Tracer
from aws_lambda_powertools.event_handler import APIGatewayRestResolver
from aws_lambda_powertools.logging import correlation_paths
from aws_lambda_powertools.metrics import MetricUnit
from aws_lambda_powertools.utilities.typing import LambdaContext
from boto3.session import Session
from opensearchpy import (
    AWSV4SignerAuth,
    NotFoundError,
    OpenSearch,
    RequestsHttpConnection,
)

AWS_REGION_NAME: Final[str] = os.environ.get("REGION", "eu-east-1")
DYNAMODB_TABLE_ID: Final[str] = os.environ.get("DYNAMODB_TABLE_ID", "dev")
ALLOWED_ORIGIN: Final[str] = os.environ.get("ALLOWED_ORIGIN", "*")
TARGET_ROLE: Final[str] = os.environ.get("TARGET_ROLE", "dev-role")
OPENSEARCH_COLLECTION: Final[str] = os.environ.get("OPENSEARCH_COLLECTION", "dev-collection")
INDEX_NAME: Final[str] = "ab_cloud"

# This secret is fine, it's just to wipe the index while we're testing the app
# We'll remove this when and the endpoint when the app is ready for production
DELETION_SECRET: Final[str] = "3749045450"


response = {
    "body": "Unauthorized",
    "statusCode": 401,
    "headers": {
        "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
        "Access-Control-Allow-Methods": "GET,OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
    },
}


app = APIGatewayRestResolver()
tracer = Tracer()
logger = Logger()
metrics = Metrics(namespace="Docs Service - RetrieveDataFromOpenSearch")


def open_search_client() -> OpenSearch:
    sts_client = boto3.client("sts")
    resp = sts_client.assume_role(RoleArn=TARGET_ROLE, RoleSessionName="doc-search-app-lambda")

    session = Session(
        aws_access_key_id=resp["Credentials"]["AccessKeyId"],
        aws_secret_access_key=resp["Credentials"]["SecretAccessKey"],
        aws_session_token=resp["Credentials"]["SessionToken"],
    )

    credentials = session.get_credentials()
    auth = AWSV4SignerAuth(credentials, AWS_REGION_NAME, "aoss")

    client = OpenSearch(
        hosts=[{"host": OPENSEARCH_COLLECTION, "port": 443}],
        http_auth=auth,
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection,
        pool_maxsize=20,
    )

    return client


def build_additional_index(principal_id: str | None) -> str | None:
    current_user = principal_id

    if current_user:
        index = current_user.split("@")[0]
        current_user = index.replace(".", "_")

    return current_user


@logger.inject_lambda_context(correlation_id_path=correlation_paths.API_GATEWAY_REST)
@tracer.capture_lambda_handler
@metrics.log_metrics(capture_cold_start_metric=True)
def lambda_handler(event: dict, context: LambdaContext) -> dict:
    logger.info(f"Event: {event}")
    return app.resolve(event, context)


@app.get("/docs/search")
@tracer.capture_method
def search() -> dict[str, dict[str, str | int] | list[dict[str, str]]]:
    metrics.add_metric(name="RetrieveOpenSearchData", unit=MetricUnit.Count, value=1)
    logger.info("Open Search data retrieval API called")
    search_term: str = app.current_event.get_query_string_value(name="search_term", default_value="")
    authorizer = app.current_event.request_context.authorizer
    logger.info(f"Authorizer: {authorizer}")
    current_user = app.current_event.request_context.authorizer.principal_id
    logger.info(f"Current User: {current_user}")
    additional_index = build_additional_index(principal_id=current_user)
    logger.info(f"Additional Index: {additional_index}")

    if not search_term:
        logger.info("Invalid search term - Aborting process")
        response_message = (
            "It looks like you didn't provide a valid search term, please double check your params and try again."
        )
        status_code = 422

        response["statusCode"] = status_code
        response["body"] = {"message": response_message}
        return response

    logger.info("Valid search term - Proceeding with search")

    client = open_search_client()
    query = {"query": {"match_phrase": {"raw_text": search_term}}}

    indices = (
        f"{INDEX_NAME},{additional_index}"
        if additional_index and client.indices.exists(index=additional_index)
        else INDEX_NAME
    )

    logger.info(f"Indices: {indices}")

    client_response = client.search(body=query, index=indices, _source_excludes=["raw_text"])

    logger.info(f"Client Response: {client_response}")

    matched_documents = client_response.get("hits", []).get("hits", [])

    if not matched_documents:
        logger.info("No documents found for the search term")
        response_message = f"Sorry, we couldn't find any documents for the search term {search_term}."
        status_code = 204
    else:
        response_message = f"Found {len(matched_documents)} documents for the search term {search_term}."
        status_code = 200

    documents = [document.get("_source") for document in matched_documents]

    response["statusCode"] = status_code
    response["body"] = {
        "message": response_message,
        "matched_documents": documents,
    }

    return response


@app.get("/docs/reset_opensearch_index")
@tracer.capture_method
def delete_index() -> str:
    message = "Index does not exist, skipping deletion."
    secret: str = app.current_event.get_query_string_value(name="secret", default_value="")

    if not secret or secret != DELETION_SECRET:
        return "Invalid secret provided, skipping index deletion."
    try:
        client = open_search_client()
        response = client.indices.delete(INDEX_NAME)
        message = f"Successfully deleted index {INDEX_NAME}" if response.get("acknowledged") else message
    except NotFoundError:
        pass

    return message
