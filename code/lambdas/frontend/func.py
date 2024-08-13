import os

import boto3

S3_CLIENT = boto3.client("s3")
S3_BUCKET = os.getenv("FRONTEND_BUCKET_NAME")


def handler(event, context):
    s3_object = S3_CLIENT.get_object(Bucket=S3_BUCKET, Key="index.html")
    index = s3_object["Body"].read().decode("utf-8")

    return {
        "statusCode": 200,
        "statusDescription": "200 OK",
        "isBase64Encoded": False,
        "headers": {"Content-Type": "text/html"},
        "body": str(index),
    }
