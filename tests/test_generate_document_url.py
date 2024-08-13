from code.lambdas.generate_document_url import app
from unittest.mock import MagicMock, patch


@patch("boto3.client")
@patch("code.lambdas.generate_document_url.app.APIGatewayRestResolver.current_event")
def test_generate_document_url(current_event_mock, boto3_client_mock) -> None:
    s3_client_mock = MagicMock()
    boto3_client_mock.return_value = s3_client_mock

    current_event_mock.get_query_string_value.return_value = "s3://mybucket/myfile.pdf"

    expected_presigned_url = "https://s3.amazonaws.com/mybucket/myfile.pdf"
    s3_client_mock.generate_presigned_url.return_value = expected_presigned_url

    result = app.generate_document_url()

    s3_client_mock.generate_presigned_url.assert_called_once_with(
        "get_object",
        Params={
            "Bucket": "mybucket",
            "Key": "myfile.pdf",
            "ResponseContentDisposition": "inline",
        },
        ExpiresIn=300,
    )

    assert result == ({"message": expected_presigned_url}, 200)


def test_generate_document_url_with_missing_document_path() -> None:
    result = app.generate_document_url()
    message = result[0]["message"]
    status_code = result[1]

    assert (
        message
        == "It looks like you didn't provide a valid document path, please double check your params and try again."
    )

    assert status_code == 422
