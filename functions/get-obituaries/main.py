import boto3
import json

def lambda_handler(event, context):
    # Create a DynamoDB client
    dynamodb = boto3.client("dynamodb")
    
    # Query the obituaries table to get all items
    response = dynamodb.scan(TableName="obituaries")
    
    # Extract the items from the response
    items = response["Items"]
    for item in items:
        item['id'] = item['id']['S']
        item['name'] = item['name']['S']
        item['description'] = item['description']['S']
    
    # Convert the items to a JSON array and return them as the response body
    response = {
        "statusCode": 200,
        "body": json.dumps(items, default=str)
    }
    
    return response