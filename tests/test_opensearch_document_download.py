import json

from code.lambdas.opensearch_document_download.app import DELETION_SECRET, lambda_handler
from typing import Generator
from unittest.mock import MagicMock, Mock, patch

import pytest

from opensearchpy import NotFoundError


@pytest.fixture
def lambda_context() -> Generator:
    context = MagicMock()
    context.function_name = "test-func"
    context.memory_limit_in_mb = 128
    context.invoked_function_arn = "arn:aws:lambda:eu-west-1:809313241234:function:test-func"
    context.aws_request_id = "52fdfc07-2182-154f-163f-5f0f9a621d72"
    context.get_remaining_time_in_millis.return_value = 1000
    yield context


@pytest.fixture
def mock_opensearch_client() -> Generator:
    with patch("code.lambdas.opensearch_document_download.app.open_search_client") as mock_opensearch_client:
        yield mock_opensearch_client


def search_event(search_term: str) -> dict:
    """Generates an API GW Event with a given search term in the query string"""
    return {
        "resource": "/docs/search",
        "path": "/docs/search",
        "httpMethod": "GET",
        "queryStringParameters": {"search_term": search_term},
        "requestContext": {"authorizer": {"principalId": "user@cloud.com"}},
    }


def delete_index_event(secret: str) -> dict:
    return {
        "resource": "/docs/reset_opensearch_index",
        "path": "/docs/reset_opensearch_index",
        "httpMethod": "GET",
        "queryStringParameters": {"secret": secret},
        "requestContext": {"authorizer": {"principalId": "user@cloud.com"}},
    }


@pytest.fixture
def valid_search_event() -> Generator:
    yield search_event("lorem")


@pytest.fixture
def invalid_search_event() -> Generator:
    yield search_event("wrong")


@pytest.fixture
def empty_search_event() -> Generator:
    yield {
        "resource": "/docs/search",
        "path": "/docs/search",
        "httpMethod": "GET",
        "requestContext": {"authorizer": {"principalId": "user@cloud.com"}},
    }


@pytest.fixture
def valid_open_search_object() -> Generator:
    yield {
        "year": 2023,
        "document_s3_path": "s3://path/to/document.pdf",
        "company": "Tesla",
        "id": "1231231231",
        "tag": "Technology",
        "sector": "Financial",
    }


@pytest.fixture
def valid_delete_index_event() -> Generator:
    yield delete_index_event(DELETION_SECRET)


@pytest.fixture
def invalid_delete_index_event() -> Generator:
    yield delete_index_event("wrong_secret")


def test_search_success_with_one_match(
    valid_search_event,
    valid_open_search_object,
    lambda_context,
    mock_opensearch_client,
) -> None:
    opensearch_client = Mock()
    mock_opensearch_client.return_value = opensearch_client

    opensearch_client.search.return_value = {
        "took": 4,
        "_shards": {"total": 4, "successful": 4, "skipped": 0, "failed": 0},
        "hits": {
            "total": {"value": 1, "relation": "eq"},
            "max_score": 1.0,
            "hits": [
                {
                    "_index": "ab_cloud",
                    "_id": "uiOTUIkBh0BFcH0iEpms",
                    "_score": 1.0,
                    "_source": valid_open_search_object,
                },
            ],
        },
    }

    response = lambda_handler(valid_search_event, lambda_context)
    gateway_response = json.loads(response.get("body"))
    data = gateway_response.get("body")

    assert response.get("statusCode") == 200
    assert data.get("message") == "Found 1 documents for the search term lorem."
    assert len(data.get("matched_documents")) == 1
    assert data.get("matched_documents")[0] == valid_open_search_object


def test_search_success_with_three_matches(
    valid_search_event,
    valid_open_search_object,
    lambda_context,
    mock_opensearch_client,
) -> None:
    opensearch_client = Mock()
    mock_opensearch_client.return_value = opensearch_client

    opensearch_client.search.return_value = {
        "took": 5,
        "_shards": {"total": 4, "successful": 4, "skipped": 0, "failed": 0},
        "hits": {
            "total": {"value": 3, "relation": "eq"},
            "max_score": 1.0,
            "hits": [
                {
                    "_index": "ab_cloud",
                    "_id": "uiOTUIkBh0BFcH0iEpms",
                    "_score": 1.0,
                    "_source": valid_open_search_object,
                },
                {
                    "_index": "ab_cloud",
                    "_id": "vCOlUIkBh0BFcH0iwpnO",
                    "_score": 1.0,
                    "_source": valid_open_search_object,
                },
                {
                    "_index": "ab_cloud",
                    "_id": "uyOlUIkBh0BFcH0ij5mI",
                    "_score": 1.0,
                    "_source": valid_open_search_object,
                },
            ],
        },
    }

    response = lambda_handler(valid_search_event, lambda_context)
    gateway_response = json.loads(response.get("body"))
    data = gateway_response.get("body")

    assert response.get("statusCode") == 200
    assert data.get("message") == "Found 3 documents for the search term lorem."
    assert len(data.get("matched_documents")) == 3
    assert data.get("matched_documents")[0] == valid_open_search_object


def test_search_with_no_match(
    invalid_search_event,
    lambda_context,
    mock_opensearch_client,
) -> None:
    opensearch_client = Mock()
    mock_opensearch_client.return_value = opensearch_client

    opensearch_client.search.return_value = {
        "took": 2,
        "_shards": {"total": 4, "successful": 4, "skipped": 0, "failed": 0},
        "hits": {"total": {"value": 0, "relation": "eq"}, "max_score": None, "hits": []},
    }

    response = lambda_handler(invalid_search_event, lambda_context)
    gateway_response = json.loads(response.get("body"))
    data = gateway_response.get("body")

    assert response.get("statusCode") == 200
    assert data.get("message") == "Sorry, we couldn't find any documents for the search term wrong."
    assert len(data.get("matched_documents")) == 0
    assert data.get("matched_documents") == []


def test_search_with_no_search_term(
    empty_search_event,
    lambda_context,
    mock_opensearch_client,
) -> None:
    opensearch_client = Mock()
    mock_opensearch_client.return_value = opensearch_client

    response = lambda_handler(empty_search_event, lambda_context)
    gateway_response = json.loads(response.get("body"))
    data = gateway_response.get("body")

    assert gateway_response.get("statusCode") == 422
    assert (
        data.get("message")
        == "It looks like you didn't provide a valid search term, please double check your params and try again."
    )


def test_delete_index_success(
    valid_delete_index_event,
    lambda_context,
    mock_opensearch_client,
) -> None:
    opensearch_client = Mock()
    mock_opensearch_client.return_value = opensearch_client
    opensearch_client.indices.delete.return_value = {"acknowledged": True}

    response = lambda_handler(valid_delete_index_event, lambda_context)
    data = json.loads(response.get("body"))

    assert data == "Successfully deleted index ab_cloud"


def test_delete_index_invalid_secret(
    invalid_delete_index_event,
    lambda_context,
) -> None:
    response = lambda_handler(invalid_delete_index_event, lambda_context)
    data = json.loads(response.get("body"))

    assert data == "Invalid secret provided, skipping index deletion."


def test_delete_index_not_found(
    valid_delete_index_event,
    lambda_context,
    mock_opensearch_client,
) -> None:
    opensearch_client = Mock()
    mock_opensearch_client.return_value = opensearch_client
    opensearch_client.indices.delete.side_effect = NotFoundError

    response = lambda_handler(valid_delete_index_event, lambda_context)
    data = json.loads(response.get("body"))

    assert data == "Index does not exist, skipping deletion."
