import json
import logging
import os

import boto3

from botocore.exceptions import ClientError

# Enable logging
LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)


def get_secret(secret_id, region_name):
    session = boto3.session.Session()
    client = session.client(
        service_name="secretsmanager",
        region_name=region_name,
    )

    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_id)
    except ClientError as e:
        if e.response["Error"]["Code"] == "ResourceNotFoundException":
            LOGGER.info("The requested secret " + secret_id + " was not found")
        elif e.response["Error"]["Code"] == "InvalidRequestException":
            LOGGER.info("The request was invalid due to:", e)
        elif e.response["Error"]["Code"] == "InvalidParameterException":
            LOGGER.info("The request had invalid params:", e)
        elif e.response["Error"]["Code"] == "DecryptionFailure":
            LOGGER.info("The requested secret can't be decrypted using the provided KMS key:", e)
        elif e.response["Error"]["Code"] == "InternalServiceError":
            LOGGER.info("An error occurred on service side:", e)
    else:
        # Secrets Manager decrypts the secret value using the associated KMS CMK
        # Depending on whether the secret was a string or binary, only one of these fields will be populated
        if "SecretString" in get_secret_value_response:
            text_secret_data = get_secret_value_response["SecretString"]
            return text_secret_data
        else:
            binary_secret_data = get_secret_value_response["SecretBinary"]
            return binary_secret_data


def handler(event, context):
    """
    Entry point for AWS Lambda
    """

    response = dict()
    response["body"] = json.dumps(dict())

    LOGGER.info(json.dumps(event, indent=4))

    if event["httpMethod"] == "GET":
        if not os.getenv("DEV"):
            LOGGER.info("Attempting to get secret ...")
            app_secret = get_secret(
                secret_id=os.environ["OKTA_CLIENT_SECRET_ID"],
                region_name=os.environ["OKTA_CLIENT_SECRET_REGION"],
            )
            LOGGER.info("Secret gathered")
        else:
            app_secret = os.getenv("DEV")

        LOGGER.info("JSON Load secret ...")
        try:
            secret_dict = json.loads(app_secret)
        except ValueError as e:
            LOGGER.info(f"{e}")
            exit(1)
        LOGGER.info("Loaded")

        tenant_id = secret_dict.get("AZURE_AD_TENANT_ID")
        url = f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/authorize"
        client_id = secret_dict.get("AZURE_AD_CLIENT_ID")
        response_type = "code%20id_token"
        response_mode = "fragment"
        callback_uri = f"{secret_dict['FRONTEND_HOST']}{secret_dict['FRONTEND_CALLBACK_ROUTE']}"
        state = event["queryStringParameters"].get("state")
        scopes = f"openid%20offline_access%20api%3A%2F%2F{client_id}%2F"
        nonce = "SomeNonceValue123"

        redirect = (
            f"{url}?client_id={client_id}&response_type={response_type}&nonce={nonce}&"
            f"response_mode={response_mode}&scope={scopes}&redirect_uri={callback_uri}&state={state}"
        )

        LOGGER.info(f"Redirecting to: {redirect}")

        response = dict()
        response["statusCode"] = 302
        response["body"] = json.dumps(dict())
        response["headers"] = {
            "Location": redirect,
            "Access-Control-Allow-Origin": os.environ["ALLOWED_ORIGIN"],
            "Access-Control-Allow-Methods": "GET,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        }
        return response

    else:
        response["statusCode"] = 500
        return response
