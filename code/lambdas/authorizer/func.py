import base64
import json
import logging
import os
import re

from datetime import datetime

import boto3
import jwt
import requests

from botocore.exceptions import ClientError
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.rsa import RSAPublicNumbers

# Enable logging
LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)


class HttpVerb:
    GET = "GET"
    POST = "POST"
    PUT = "PUT"
    PATCH = "PATCH"
    HEAD = "HEAD"
    DELETE = "DELETE"
    OPTIONS = "OPTIONS"
    ALL = "*"


class AuthPolicy(object):
    awsAccountId = ""
    """The AWS account id the policy will be generated for. This is used to create the method ARNs."""
    principalId = ""
    """The principal used for the policy, this should be a unique identifier for the end user."""
    version = "2012-10-17"
    """The policy version used for the evaluation. This should always be '2012-10-17'"""
    pathRegex = "^[/.a-zA-Z0-9-\*]+$"  # noqa: W605
    """The regular expression used to validate resource paths for the policy"""

    """these are the internal lists of allowed and denied methods. These are lists
    of objects and each object has 2 properties: A resource ARN and a nullable
    conditions statement.
    the build method processes these lists and generates the approriate
    statements for the final policy"""
    allowMethods = []
    denyMethods = []

    restApiId = os.getenv("API_GATEWAY_API_ID", "")
    region = os.getenv("API_GATEWAY_REGION", "")
    stage = region = os.getenv("API_GATEWAY_STAGE", "")

    def __init__(self, principal, awsAccountId):
        self.awsAccountId = awsAccountId
        self.principalId = principal
        self.allowMethods = []
        self.denyMethods = []

    def _addMethod(self, effect, verb, resource, conditions):
        """Adds a method to the internal lists of allowed or denied methods. Each object in
        the internal list contains a resource ARN and a condition statement. The condition
        statement can be null."""
        if verb != "*" and not hasattr(HttpVerb, verb):
            raise NameError("Invalid HTTP verb " + verb + ". Allowed verbs in HttpVerb class")
        resourcePattern = re.compile(self.pathRegex)
        if not resourcePattern.match(resource):
            raise NameError("Invalid resource path: " + resource + ". Path should match " + self.pathRegex)

        if resource[:1] == "/":
            resource = resource[1:]

        resourceArn = (
            "arn:aws:execute-api:"
            + self.region
            + ":"
            + self.awsAccountId
            + ":"
            + self.restApiId
            + "/"
            + self.stage
            + "/"
            + verb
            + "/"
            + resource
        )

        if effect.lower() == "allow":
            self.allowMethods.append({"resourceArn": resourceArn, "conditions": conditions})
        elif effect.lower() == "deny":
            self.denyMethods.append({"resourceArn": resourceArn, "conditions": conditions})

    def _getEmptyStatement(self, effect):
        """Returns an empty statement object prepopulated with the correct action and the
        desired effect."""
        statement = {
            "Action": "execute-api:Invoke",
            "Effect": effect[:1].upper() + effect[1:].lower(),
            "Resource": [],
        }

        return statement

    def _getStatementForEffect(self, effect, methods):
        """This function loops over an array of objects containing a resourceArn and
        conditions statement and generates the array of statements for the policy."""
        statements = []

        if len(methods) > 0:
            statement = self._getEmptyStatement(effect)

            for curMethod in methods:
                if curMethod["conditions"] is None or len(curMethod["conditions"]) == 0:
                    statement["Resource"].append(curMethod["resourceArn"])
                else:
                    conditionalStatement = self._getEmptyStatement(effect)
                    conditionalStatement["Resource"].append(curMethod["resourceArn"])
                    conditionalStatement["Condition"] = curMethod["conditions"]
                    statements.append(conditionalStatement)

            statements.append(statement)

        return statements

    def allowAllMethods(self):
        """Adds a '*' allow to the policy to authorize access to all methods of an API"""
        self._addMethod("Allow", HttpVerb.ALL, "*", [])

    def denyAllMethods(self):
        """Adds a '*' allow to the policy to deny access to all methods of an API"""
        self._addMethod("Deny", HttpVerb.ALL, "*", [])

    def allowMethod(self, verb, resource):
        """Adds an API Gateway method (Http verb + Resource path) to the list of allowed
        methods for the policy"""
        self._addMethod("Allow", verb, resource, [])

    def denyMethod(self, verb, resource):
        """Adds an API Gateway method (Http verb + Resource path) to the list of denied
        methods for the policy"""
        self._addMethod("Deny", verb, resource, [])

    def allowMethodWithConditions(self, verb, resource, conditions):
        """Adds an API Gateway method (Http verb + Resource path) to the list of allowed
        methods and includes a condition for the policy statement. More on AWS policy
        conditions here: http://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements.html#Condition
        """
        self._addMethod("Allow", verb, resource, conditions)

    def denyMethodWithConditions(self, verb, resource, conditions):
        """Adds an API Gateway method (Http verb + Resource path) to the list of denied
        methods and includes a condition for the policy statement. More on AWS policy
        conditions here: http://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements.html#Condition
        """
        self._addMethod("Deny", verb, resource, conditions)

    def build(self):
        """Generates the policy document based on the internal lists of allowed and denied
        conditions. This will generate a policy with two main statements for the effect:
        one statement for Allow and one statement for Deny.
        Methods that includes conditions will have their own statement in the policy."""
        if (self.allowMethods is None or len(self.allowMethods) == 0) and (
            self.denyMethods is None or len(self.denyMethods) == 0
        ):
            raise NameError("No statements defined for the policy")

        policy = {
            "principalId": self.principalId,
            "policyDocument": {"Version": self.version, "Statement": []},
        }

        policy["policyDocument"]["Statement"].extend(self._getStatementForEffect("Allow", self.allowMethods))
        policy["policyDocument"]["Statement"].extend(self._getStatementForEffect("Deny", self.denyMethods))

        return policy


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


##############################################
## Entra token validation functions
##############################################
def find_rsa_key(jwks: dict, unverified_header: dict) -> dict | None:
    for key in jwks.get("keys"):
        if key["kid"] == unverified_header["kid"]:
            return key


def ensure_bytes(key: str) -> bytes:
    if isinstance(key, str):
        key = key.encode("utf-8")
    return key


def decode_value(val: str) -> int:
    decoded = base64.urlsafe_b64decode(ensure_bytes(val) + b"==")
    return int.from_bytes(decoded, "big")


def rsa_pem_from_jwk(jwk: dict) -> str:
    return (
        RSAPublicNumbers(n=decode_value(jwk["n"]), e=decode_value(jwk["e"]))
        .public_key(default_backend())
        .public_bytes(encoding=serialization.Encoding.PEM, format=serialization.PublicFormat.SubjectPublicKeyInfo)
    )


def jwt_expiry(access_token: str, key: str, alg: str) -> datetime:
    tokenExpiry = datetime.fromtimestamp(int(access_token["exp"]))
    LOGGER.info(f"Token Expires at: {str(tokenExpiry)}")
    return tokenExpiry


def entra_authorize(secret_dict: dict, access_token: str) -> dict | str:
    LOGGER.info("Entering Entra Authorize")
    tenant_id = secret_dict.get("AZURE_AD_TENANT_ID")
    client_id = secret_dict.get("AZURE_AD_API_CLIENT_ID")
    jwks_url = f"https://login.microsoftonline.com/{tenant_id}/discovery/v2.0/keys"
    unverified_header = jwt.get_unverified_header(access_token)

    try:
        response = requests.get(jwks_url)
    except Exception as e:
        LOGGER.error(f"{e}")
        raise e

    jwks = json.loads(response.text)
    rsa_key = find_rsa_key(jwks, unverified_header)
    public_key = rsa_pem_from_jwk(rsa_key)
    alg = jwt.get_unverified_header(access_token)["alg"]

    LOGGER.info("Supplied JWT")
    LOGGER.info(f"{access_token}")

    try:
        decodedAccessToken = jwt.decode(
            access_token, key=public_key, algorithms=[alg], audience=client_id, \
            options={"verify_signature": True, "verify_exp": True, "verify_aud": True}
        )
    except Exception as e:
        LOGGER.error(f"TOKEN_INVALID: {e}")
        raise e
        # return "TOKEN_INVALID"
    LOGGER.info("Decoded Access Token")
    LOGGER.info(json.dumps(decodedAccessToken, indent=4))

    # Token Expiry
    tokenExpiry = jwt_expiry(decodedAccessToken, public_key, alg)
    minutesToExpiry = tokenExpiry.second % 3600
    LOGGER.info(f"Access Token Expires in {str(minutesToExpiry)} minutes")
    if minutesToExpiry < 1:
        raise Exception("TOKEN_EXPIRED")
        # return "TOKEN_EXPIRED"  # Token expired

    return decodedAccessToken


##############################################
## End of entra functions
##############################################


## AWS Lambda handler
def handler(event, context):
    """
    Entry point for AWS Lambda
    """
    # Split authorizationToken from the event, and extract the JWT behind Bearer
    arr = event["authorizationToken"].split(" ")
    jwt = arr[1]

    fail_response = {
        "body": "Unauthorized",
        "statusCode": 401,
        "headers": {
            "Access-Control-Allow-Origin": os.environ["ALLOWED_ORIGIN"],
            "Access-Control-Allow-Methods": "GET,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        },
    }

    try:
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

    except Exception as e:
        LOGGER.info(f"{e}")
        exit(1)

    ## Entra token validation
    try:
        response = entra_authorize(secret_dict=secret_dict, access_token=jwt)
    except Exception as e:
        LOGGER.error(f"{e}")
        return fail_response

    if isinstance(response, dict):
        LOGGER.info("JWT is active. Creating auth response...")

        principalId = response["sub"]

        tmp = event["methodArn"].split(":")
        apiGatewayArnTmp = tmp[5].split("/")
        awsAccountId = tmp[4]

        policy = AuthPolicy(principalId, awsAccountId)
        policy.restApiId = apiGatewayArnTmp[0]
        policy.region = tmp[3]
        policy.stage = apiGatewayArnTmp[1]
        # policy.denyAllMethods()
        policy.allowMethod(HttpVerb.GET, "/*")

        # Finally, build the policy
        authResponse = policy.build()

        # new! -- add additional key-value pairs associated with the authenticated principal
        # these are made available by APIGW like so: $context.authorizer.<key>
        # additional context is cached
        context = {
            "key": "value",  # $context.authorizer.key -> value
            "number": 1,
            "bool": True,
        }

        authResponse["context"] = context

        LOGGER.info(f"Authenticated: {response['sub']}")

        return authResponse

    else:
        LOGGER.info("JWT is not active or invalid")
        return fail_response
