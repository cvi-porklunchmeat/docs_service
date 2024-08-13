import json

from code.lambdas.push_to_opensearch.func import create_index, handler
from io import BytesIO
from unittest.mock import Mock, patch

import pytest

event = {
    "detail": {
        "body": {
            "Records": [
                {
                    "s3": {
                        "bucket": {"name": "test-bucket"},
                        "object": {
                            "key": "files/2023-07-06/4f998f46-ebda-4048-9245-56622fd15409/document_raw_text.txt"
                        },
                    },
                }
            ]
        }
    }
}


def valid_dynamodb_response() -> dict[str, str | int]:
    document = {
        "company_name": "Fake Company",
        "year": 2023,
        "sector": "Finance",
        "tags": "#Finance, #Reports",
        "document_name": "Annual Report",
        "user_email": "user@test.com",
        "group": "ab_cloud",
    }

    return document


@pytest.mark.parametrize(
    "acknowledged, message",
    [
        (False, "Index already exists, skipping creation."),
        (True, "Created index test-index"),
    ],
)
def test_create_index(acknowledged, message) -> None:
    mock_client = Mock()
    mock_client.indices.create.return_value = {"acknowledged": acknowledged}

    assert create_index(mock_client, "test-index") == message


@patch(
    "code.lambdas.push_to_opensearch.func.fetch_document_metadata_from_database",
    return_value=valid_dynamodb_response(),
)
def test_handler(
    mocked_dynamodb_response,
    mock_open_search_client,
    s3_client,
    caplog,
) -> None:
    opensearch_client = Mock()
    mock_open_search_client.return_value = opensearch_client

    get_object_response = {"Body": BytesIO(b"Raw text content")}
    s3_client_mock = s3_client.return_value
    s3_client_mock.get_object.return_value = get_object_response

    result = handler(event, {})
    response = json.loads(result["body"])  # type: ignore

    assert result["statusCode"] == 200
    assert response["message"] == "Succesfully stored documents: 4f998f46-ebda-4048-9245-56622fd15409"

    assert len(s3_client.call_args_list) == 1

    assert s3_client_mock.assert_called_once
    assert s3_client_mock.get_object.call_args_list[0][1] == {
        "Bucket": "test-bucket",
        "Key": "files/2023-07-06/4f998f46-ebda-4048-9245-56622fd15409/document_raw_text.txt",
    }

    assert opensearch_client.index.assert_called_once
    assert opensearch_client.index.call_args_list[0][1] == {
        "index": "ab_cloud",
        "body": {
            "id": "4f998f46-ebda-4048-9245-56622fd15409",
            "company": "Fake Company",
            "year": 2023,
            "sector": "Finance",
            "tags": "#Finance, #Reports",
            "raw_text": "Raw text content",
            "document_s3_path": "s3://test-bucket/files/2023-07-06/4f998f46-ebda-4048-9245-56622fd15409/document.pdf",
            "document_name": "Annual Report",
            "user": "user@test.com",
        },
        "params": {"timeout": 60},
    }

    assert "Succesfully stored documents: 4f998f46-ebda-4048-9245-56622fd15409" in caplog.text


@patch(
    "code.lambdas.push_to_opensearch.func.fetch_document_metadata_from_database",
    return_value=None,
)
def test_dynamodb_error(mocked_dynamodb_response, mock_open_search_client, s3_client) -> None:
    opensearch_client = Mock()
    mock_open_search_client.return_value = opensearch_client

    get_object_response = {"Body": BytesIO(b"Raw text content")}
    s3_client_mock = s3_client.return_value
    s3_client_mock.get_object.return_value = get_object_response

    result = handler(event, {})
    response = json.loads(result["body"])  # type: ignore

    assert result["statusCode"] == 422
    assert (
        response["message"] == "An error occurred while trying to fetch the document metadata. Please try again later."
    )


def test_handler_with_error(mock_open_search_client) -> None:
    mock_open_search_client.return_value = Mock()

    event = {"detail": {"body": {"Records": []}}}

    result = handler(event, {})
    response = json.loads(result["body"])  # type: ignore

    assert result["statusCode"] == 422
    assert response["message"] == "An error occurred while trying to store the documents. Please try again later."
