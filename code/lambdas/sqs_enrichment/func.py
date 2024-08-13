import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    logger.info(event)

    for item in event:
        if "body" in item:
            item["body"] = json.loads(item["body"])

            if "Message" in item["body"]:
                item["body"]["Message"] = json.loads(item["body"]["Message"])

    return event
