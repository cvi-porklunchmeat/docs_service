import os

from code.lambdas.local_document_upload.app import DYNAMODB_TABLE_ID
from typing import Final, Generator
from unittest.mock import patch

import boto3
import pytest

from moto import mock_dynamodb

BUCKET_NAME: Final[str] = "test-bucket"


@pytest.fixture
def bucket_name() -> Generator:
    yield BUCKET_NAME


@pytest.fixture
def here() -> Generator:
    here = os.path.dirname(os.path.realpath(__file__))
    yield here


@pytest.fixture
def aws_credentials() -> None:
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"


@pytest.fixture
def s3_client(aws_credentials) -> Generator:
    with patch("boto3.client") as mock:
        yield mock


@pytest.fixture
def s3_client_with_bucket(aws_credentials) -> Generator:
    with patch("boto3.client") as s3_client:
        s3_client.create_bucket(Bucket=BUCKET_NAME)
        yield s3_client


@pytest.fixture
def mock_open_search_client() -> Generator:
    with patch("code.lambdas.push_to_opensearch.func.open_search_client") as mock_open_search_client:
        yield mock_open_search_client


@pytest.fixture
def dynamodb_client(aws_credentials) -> Generator:
    with mock_dynamodb():
        client = boto3.resource("dynamodb", region_name="us-east-1")
        yield client


@pytest.fixture
def dynamodb_client_with_table(aws_credentials) -> Generator:
    with mock_dynamodb():
        client = boto3.resource("dynamodb", region_name="us-east-1")
        table_name = DYNAMODB_TABLE_ID

        client.create_table(
            TableName=table_name,
            KeySchema=[{"AttributeName": "param1", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "param1", "AttributeType": "S"}],
            ProvisionedThroughput={"ReadCapacityUnits": 5, "WriteCapacityUnits": 5},
        )
        yield client
