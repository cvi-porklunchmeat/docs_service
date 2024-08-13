import json

from code.lambdas.retrieve_textract.app import lambda_handler
from typing import Final, Generator

import pytest

from moto import mock_textract

FILE_NAME: Final[str] = "test-file"
JOB_ID: Final[str] = "1234"
TEXT_LINE: Final[str] = "Test line of text"


@pytest.fixture
def aws_setup_with_textract(s3_client_with_bucket, bucket_name) -> Generator:
    s3_client_with_bucket.put_object(Bucket=bucket_name, Key=FILE_NAME, Body="This is a test file")
    mock_textract.get_document_text_detection = lambda JobId: {"Blocks": [{"BlockType": "LINE", "Text": TEXT_LINE}]}

    yield


@pytest.fixture
def retrieve_event(here) -> Generator:
    with open(f"{here}/../code/lambdas/retrieve_textract/event.json") as file:
        data = json.load(file)
    yield data


def test_lambda_handler_sns_event(aws_setup_with_textract, bucket_name, retrieve_event) -> None:
    response, status_code = lambda_handler(retrieve_event, None)

    assert status_code == 200
    assert response["message"] == "Successfully pushed the extracted raw text to S3"
