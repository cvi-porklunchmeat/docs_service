import json
import logging
import os

from typing import Literal

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context) -> tuple[dict[str, str], Literal[200]]:
    sns_topic_arn = os.environ.get("SNS_TOPIC_ARN", "dev-arn-topic")
    role_arn = os.environ.get("TEXTRACT_ROLE_ARN", "dev-textract-role-arn")
    textract = boto3.client("textract")
    job_ids = []

    logger.info(f"Event: {json.dumps(event, indent=4)}")

    body = event["detail"]["body"]

    if body.get("Event") == "s3:TestEvent":
        return {"message": "Test message, skipping text extraction"}, 200

    for message in body["Records"]:
        bucket = message["s3"]["bucket"]["name"]
        key = message["s3"]["object"]["key"]

        response = textract.start_document_text_detection(
            DocumentLocation={"S3Object": {"Bucket": bucket, "Name": key}},
            NotificationChannel={"SNSTopicArn": sns_topic_arn, "RoleArn": role_arn},
        )

        job_id = response.get("JobId")
        job_ids.append(job_id)

        logger.info(f"Started Textract job {job_id} for file {key} in bucket {bucket}")

    return {"message": f"Textract jobs with the following ids: {', '.join(job_ids)} successfully submitted!"}, 200
