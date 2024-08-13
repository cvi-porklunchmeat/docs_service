import json

from code.lambdas.start_textract.app import lambda_handler
from typing import Final, Generator

import pytest

FILE_NAME: Final[str] = "test-file"
JOB_ID: Final[str] = "1234"


@pytest.fixture
def aws_setup_with_textract(s3_client_with_bucket, bucket_name) -> Generator:
    s3_client_with_bucket.put_object(Bucket=bucket_name, Key=FILE_NAME, Body="This is a test file")
    s3_client_with_bucket.return_value.start_document_text_detection.return_value = {"JobId": JOB_ID}
    yield


@pytest.fixture
def start_event(here) -> Generator:
    with open(f"{here}/../code/lambdas/start_textract/event.json") as file:
        data = json.load(file)
    yield data


def test_lambda_handler_s3_event(aws_setup_with_textract, bucket_name, start_event) -> None:
    response, status_code = lambda_handler(start_event, None)

    assert status_code == 200
    assert response["message"] == f"Textract jobs with the following ids: {JOB_ID} successfully submitted!"


def test_lambda_handler_with_invalid_event(aws_setup_with_textract) -> None:
    test_event = {"detail": {"body": {"Event": "s3:TestEvent"}}}

    response, status_code = lambda_handler(test_event, None)

    assert status_code == 200
    assert response["message"] == "Test message, skipping text extraction"
