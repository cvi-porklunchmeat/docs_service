import json
import logging
import os

from io import BytesIO
from typing import Final

import boto3

from boto3.dynamodb.conditions import Attr
from boto3.session import Session
from opensearchpy import AWSV4SignerAuth, OpenSearch, RequestsHttpConnection
from opensearchpy.exceptions import RequestError

AWS_REGION_NAME: Final[str] = os.environ.get("REGION", "eu-east-1")
DYNAMODB_TABLE_ID: Final[str] = os.environ.get("DYNAMODB_TABLE_ID", "dev")

logger = logging.getLogger()
logger.setLevel(logging.INFO)


api_response = {
    "statusCode": 500,
    "body": {},
    "headers": {
        "content-type": "application/json",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Credentials": "true",
        "Access-Control-Allow-Origin": os.environ.get("ALLOWED_ORIGIN", "*"),
    },
}


def open_search_client() -> OpenSearch:
    sts_client = boto3.client("sts")
    resp = sts_client.assume_role(RoleArn=os.environ["TARGET_ROLE"], RoleSessionName="doc-search-app-lambda")

    session = Session(
        aws_access_key_id=resp["Credentials"]["AccessKeyId"],
        aws_secret_access_key=resp["Credentials"]["SecretAccessKey"],
        aws_session_token=resp["Credentials"]["SessionToken"],
    )

    host = os.environ["OPENSEARCH_COLLECTION"]
    service = "aoss"
    credentials = session.get_credentials()
    auth = AWSV4SignerAuth(credentials, AWS_REGION_NAME, service)

    client = OpenSearch(
        hosts=[{"host": host, "port": 443}],
        http_auth=auth,
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection,
        pool_maxsize=20,
    )

    return client


def fetch_document_metadata_from_database(document_id: str) -> dict[str, str] | None:
    logger.info(f"In fetch_document_metadata_from_database() - Document ID: {document_id}")

    client = boto3.resource("dynamodb", region_name=AWS_REGION_NAME)

    table = client.Table(DYNAMODB_TABLE_ID)
    result = table.scan(FilterExpression=Attr("doc_id").eq(document_id))

    logger.info(f"Fetched data from DynamoDB: {result}")
    data = result.get("Items")
    return data[0] if data else None


def handler(event, context) -> dict[str, dict | int | str]:
    logger.info(event)

    s3_client = boto3.client("s3")
    opensearch_client = open_search_client()

    message = "An error occurred while trying to store the documents. Please try again later."
    api_response["statusCode"] = 422
    s3_events = event.get("detail").get("body").get("Records")
    stored_documents = []

    for event in s3_events:
        bucket_name = event.get("s3").get("bucket").get("name")
        object_key = event.get("s3").get("object").get("key")

        response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
        body = BytesIO(response["Body"].read())
        raw_text = body.getvalue().decode()

        event_object_key = object_key.split("/")
        document_id = event_object_key[2]
        pdf_document = object_key.replace("document_raw_text.txt", "document.pdf")
        document_metadata = fetch_document_metadata_from_database(document_id)

        if document_metadata is None:
            api_response["body"] = json.dumps({
                "message": "An error occurred while trying to fetch the document metadata. Please try again later."
            })
            return api_response

        group = document_metadata.get("group", "ab_cloud")
        response = create_index(opensearch_client, group)

        document = {
            "id": document_id,
            "company": document_metadata.get("company_name"),
            "year": document_metadata.get("year"),
            "sector": document_metadata.get("sector"),
            "tags": document_metadata.get("tags"),
            "raw_text": raw_text,
            "document_s3_path": f"s3://{bucket_name}/{pdf_document}",
            "document_name": document_metadata.get("document_name"),
            "user": document_metadata.get("user_email"),
        }

        response = opensearch_client.index(index=group, body=document, params={"timeout": 60})
        message = f"Succesfully stored document {document_id}" if response.get("result") == "created" else message
        stored_documents.append(document_id)
        logger.info(message)

    if stored_documents:
        message = f"Succesfully stored documents: {', '.join(stored_documents)}"
        logger.info(message)
        api_response["statusCode"] = 200

    api_response["body"] = json.dumps({"message": message})

    return api_response


def create_index(client: OpenSearch, index_name: str) -> str:
    message = "Index already exists, skipping creation."

    try:
        index_body = {"settings": {"index": {"number_of_shards": 4}}}
        response = client.indices.create(index_name, body=index_body)
        message = f"Created index {index_name}" if response.get("acknowledged") else message
    except RequestError:
        pass

    return message
