import json
import logging

from typing import Literal

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context) -> tuple[dict[str, str], Literal[200]]:
    textract_client = boto3.client("textract")
    s3_client = boto3.client("s3")

    logger.info(f"Event: {json.dumps(event, indent=4)}")

    message = event["detail"]["body"]["Message"]
    job_id = message["JobId"]

    response = textract_client.get_document_text_detection(JobId=job_id)

    raw_text = ""
    for item in response["Blocks"]:
        if item["BlockType"] == "LINE":
            raw_text += item["Text"] + "\n"

    document_bucket = message["DocumentLocation"]["S3Bucket"]
    document_key = message["DocumentLocation"]["S3ObjectName"]

    text_file_key = f"{document_key.rsplit('.', 1)[0]}_raw_text.txt"

    s3_client.put_object(Body=raw_text, Bucket=document_bucket, Key=text_file_key)

    success_message = "Successfully pushed the extracted raw text to S3"
    logger.info(success_message)

    return {"message": success_message}, 200
