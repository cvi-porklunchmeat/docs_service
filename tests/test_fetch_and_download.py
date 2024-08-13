import io
import json
import os
import sys
import uuid

from datetime import datetime
from typing import Generator
from unittest.mock import MagicMock, patch

import pytest

from botocore.exceptions import ClientError
from requests.exceptions import HTTPError, Timeout

# # When the code runs in a λ environment, AWS automatically adds the directory containing the function to sys.path,
# # making app and user_agents top-level modules. Pytest doesn't do this so we need to do it before we can import app
current_directory = os.path.dirname(os.path.realpath(__file__))
root_directory = os.path.abspath(os.path.join(current_directory, os.pardir))
fetch_and_download_module_path = os.path.join(root_directory, "code", "lambdas", "fetch_and_download")

sys.path.insert(0, fetch_and_download_module_path)

from code.lambdas.fetch_and_download import app  # noqa E402 module level import not at top of file


def lambda_context() -> MagicMock:
    context = MagicMock()
    context.function_name = "test-func"
    context.memory_limit_in_mb = 128
    context.invoked_function_arn = "arn:aws:lambda:eu-west-1:809313241234:function:test-func"
    context.aws_request_id = "52fdfc07-2182-154f-163f-5f0f9a621d72"
    context.get_remaining_time_in_millis.return_value = 1000
    return context


def api_gw_event(body: str) -> dict:
    """Generates an API GW Event with a given body"""
    return {
        "resource": "/upload/remote",
        "path": "/upload/remote",
        "httpMethod": "POST",
        "headers": {"Accept": "*/*", "Content-Type": "application/json", "Host": "api.example.com"},
        "body": body,
    }


@pytest.fixture
def valid_post_request() -> Generator:
    yield api_gw_event('{"remote_url": "https://example.com/path/to/file.pdf"}')


@pytest.fixture
def invalid_file_link() -> Generator:
    yield api_gw_event('{"remote_url": "https://example.com/path/to/file.png"}')


@pytest.fixture
def invalid_post_request() -> Generator:
    yield api_gw_event("{}")


def validate_response(request, expected_status_code: int, expected_message: str) -> None:
    response = app.lambda_handler(request, lambda_context())
    data = json.loads(response.get("body"))
    assert response.get("statusCode") == expected_status_code
    assert data.get("message") == expected_message


@patch("uuid.uuid4", return_value=uuid.uuid4())
@patch("requests.get")
def test_download_remote_file_success(fake_request, fake_uuid, s3_client) -> None:
    mock_response, mock_s3_client, mock_upload_fileobj = MagicMock(), MagicMock(), MagicMock()
    mock_response.content = b"mock file content"
    fake_request.return_value = mock_response
    s3_client.return_value = mock_s3_client
    mock_s3_client.upload_fileobj = mock_upload_fileobj

    with patch("boto3.client", return_value=mock_s3_client):
        response_message, status_code = app.download_remote_file("https://example.com/document.pdf")

    assert response_message == f"Document {str(fake_uuid())} successfully downloaded, it will be processed soon."
    assert status_code == 201

    mock_upload_fileobj.assert_called_once()
    args, kwargs = mock_upload_fileobj.call_args_list[0]
    assert isinstance(args[0], io.BytesIO)
    assert args[1] == app.DOCUMENT_BUCKET
    assert args[2] == f"files/{datetime.today().strftime('%Y-%m-%d')}/{str(fake_uuid())}/document.pdf"
    assert kwargs["ExtraArgs"] == {"ContentType": "application/pdf", "ContentDisposition": "inline"}


@patch("requests.get")
@pytest.mark.parametrize(
    "side_effect, error_message",
    [
        (HTTPError, "Document failed to download due to an HTTP error."),
        (Timeout, "Document failed to download due to a connection timeout."),
        (
            ClientError({"Error": {"Code": "422", "Message": "Fake Error"}}, "upload_fileobj"),
            "Document failed to download due to a connection error with S3.",
        ),
    ],
)
def test_download_remote_file_fail(fake_request, side_effect, error_message) -> None:
    fake_request.side_effect = side_effect

    response_message, status_code = app.download_remote_file("https://example.com/document.pdf")

    assert response_message == error_message
    assert status_code == 422


def test_invalid_upload(invalid_post_request) -> None:
    validate_response(
        invalid_post_request,
        422,
        "It looks like you didn't provide a valid link, please double check your params and try again.",
    )


def test_invalid_link_upload(invalid_file_link) -> None:
    validate_response(
        invalid_file_link,
        422,
        "It looks like you didn't provide a valid link, please double check your params and try again.",
    )
