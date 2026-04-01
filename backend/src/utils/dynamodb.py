"""
Shared DynamoDB operations.

Why this exists:
- Reuse DynamoDB client across functions
- Centralize error handling
- DRY principle (Don't Repeat Yourself)
"""

import os
import boto3
from typing import Dict, List, Optional
from botocore.exceptions import ClientError


# Get table name from environment variable (set by Terraform)
TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME', 'spotech-dev-main')

# Create DynamoDB resource (high-level API, easier than client)
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(TABLE_NAME)


def get_item(pk: str, sk: str = 'METADATA') -> Optional[Dict]:
    """
    Get single item from DynamoDB.
    
    GetItem operation = fastest, cheapest (1 RCU)
    
    Args:
        pk: Partition key (e.g., "TEAM#real-madrid")
        sk: Sort key (default "METADATA")
    
    Returns:
        Item dict if found, None if not found
    
    Raises:
        Exception on DynamoDB errors
    """
    try:
        response = table.get_item(
            Key={'PK': pk, 'SK': sk}
        )
        return response.get('Item')  # Returns None if not found
    
    except ClientError as e:
        print(f"DynamoDB GetItem error: {e.response['Error']['Message']}")
        raise


def scan_items(filter_expression=None, expression_attribute_values=None) -> List[Dict]:
    """
    Scan table (read all items, optionally filter).
    
    WARNING: Scan is expensive! ($$$)
    - Reads EVERY item in table
    - Use only for small tables (<1000 items)
    - For production, use Query with GSI
    
    Args:
        filter_expression: boto3 filter (e.g., "EntityType = :type")
        expression_attribute_values: Values for filter (e.g., {":type": "VENDOR"})
    
    Returns:
        List of items
    
    Example:
        # Get all vendors
        items = scan_items(
            filter_expression="EntityType = :type",
            expression_attribute_values={":type": "VENDOR"}
        )
    """
    try:
        scan_kwargs = {}
        
        if filter_expression:
            scan_kwargs['FilterExpression'] = filter_expression
        
        if expression_attribute_values:
            scan_kwargs['ExpressionAttributeValues'] = expression_attribute_values
        
        # Scan with pagination (DynamoDB returns max 1MB at a time)
        items = []
        response = table.scan(**scan_kwargs)
        items.extend(response.get('Items', []))
        
        # Handle pagination if more than 1MB of data
        while 'LastEvaluatedKey' in response:
            scan_kwargs['ExclusiveStartKey'] = response['LastEvaluatedKey']
            response = table.scan(**scan_kwargs)
            items.extend(response.get('Items', []))
        
        return items
    
    except ClientError as e:
        print(f"DynamoDB Scan error: {e.response['Error']['Message']}")
        raise


def query_by_gsi(
    index_name: str,
    partition_key_name: str,
    partition_key_value: str
) -> List[Dict]:
    """
    Query Global Secondary Index.
    
    Query = efficient, targetted (better than Scan)
    
    Args:
        index_name: GSI name (e.g., "GSI1")
        partition_key_name: GSI partition key (e.g., "GSI1PK")
        partition_key_value: Value to query (e.g., "CATEGORY#Performance Tracking")
    
    Returns:
        List of matching items
    
    Example:
        # Get all vendors in Performance Tracking category
        vendors = query_by_gsi(
            index_name='GSI1',
            partition_key_name='GSI1PK',
            partition_key_value='CATEGORY#Performance Tracking'
        )
    """
    try:
        response = table.query(
            IndexName=index_name,
            KeyConditionExpression=f"{partition_key_name} = :pk",
            ExpressionAttributeValues={':pk': partition_key_value}
        )
        
        return response.get('Items', [])
    
    except ClientError as e:
        print(f"DynamoDB Query error: {e.response['Error']['Message']}")
        raise
