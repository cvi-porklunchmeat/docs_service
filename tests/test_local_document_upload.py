import json
import uuid

from code.lambdas.local_document_upload.app import DYNAMODB_TABLE_ID, lambda_handler, store_in_database
from typing import Generator
from unittest.mock import MagicMock, patch

import pytest


def lambda_context() -> MagicMock:
    context = MagicMock()
    context.function_name = "test-func"
    context.memory_limit_in_mb = 128
    context.invoked_function_arn = "arn:aws:lambda:eu-west-1:809313241234:function:test-func"
    context.aws_request_id = "52fdfc07-2182-154f-163f-5f0f9a621d72"
    context.get_remaining_time_in_millis.return_value = 1000
    return context


def api_gw_event(body: str) -> dict:
    return {
        "resource": "/upload/local",
        "path": "/upload/local",
        "httpMethod": "POST",
        "headers": {"Accept": "*/*", "Content-Type": "application/json", "Host": "api.example.com"},
        "body": body,
    }


@pytest.fixture
def valid_post_request() -> Generator:
    data = {
        "tags": "Finance, Reports",
        "user_email": "test@test.com",
        "doc_id": "123123-123123",
        "company_name": "Fake Company",
        "sector": "Fake Sector",
        "year": "2023",
        "document_name": "My Specific Document Name",
        "group": "ab_cloud",
    }

    data = json.dumps(data)

    yield api_gw_event(data)


@pytest.fixture
def invalid_post_request() -> Generator:
    yield api_gw_event("{}")


@patch("uuid.uuid4", return_value=uuid.uuid4())
@patch("boto3.resource")
def test_local_document_upload(
    boto_resource,
    fake_uuid,
    valid_post_request,
    dynamodb_client,
) -> None:
    mock_table = MagicMock()
    mock_table.put_item = MagicMock()
    dynamodb_client.Table = MagicMock(return_value=mock_table)
    boto_resource.return_value = dynamodb_client

    response = lambda_handler(valid_post_request, lambda_context())

    gateway_response = json.loads(response.get("body"))
    data = gateway_response.get("body")

    expected_item = {
        "tags": "Finance, Reports",
        "user_email": "test@test.com",
        "doc_id": str(fake_uuid.return_value),
        "company_name": "Fake Company",
        "sector": "Fake Sector",
        "year": "2023",
        "document_name": "My Specific Document Name",
        "group": "ab_cloud",
    }
    mock_table.put_item.assert_called_once_with(Item=expected_item)

    assert response.get("statusCode") == 200
    assert data["message"] == "Successfully created the pre-signed url."
    assert "url" in data.keys()


def test_local_document_upload_with_error(invalid_post_request, s3_client_with_bucket) -> None:
    with patch("boto3.client") as mock_s3_client:
        mock_s3_client.return_value.generate_presigned_url.side_effect = Exception("This is a test exception message")

        response = lambda_handler(invalid_post_request, lambda_context())

    gateway_response = json.loads(response.get("body"))
    data = gateway_response.get("body")

    assert gateway_response.get("statusCode") == 422
    assert data["message"] == "An error occured while trying to create the pre-signed url. Please try again."
    assert data["exception_error"] == "This is a test exception message"


def test_store_in_database(dynamodb_client_with_table) -> None:
    params = {"param1": "value1", "param2": "value2"}

    store_in_database(params)

    table = dynamodb_client_with_table.Table(DYNAMODB_TABLE_ID)
    response = table.get_item(Key={"param1": "value1"})
    assert response["Item"] == params
