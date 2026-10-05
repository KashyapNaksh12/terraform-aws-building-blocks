import json
import os


def handler(event, context):
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "hello", "table": os.environ.get("TABLE_NAME")}),
    }
