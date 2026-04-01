"""
Shared utility for formatting Lambda responses.

Why this exists:
- API Gateway expects specific response format
- CORS headers needed for browser requests
- Consistent error handling across all functions
"""

import json
from decimal import Decimal
from typing import Any, Dict


class DecimalEncoder(json.JSONEncoder):
    """
    Custom JSON encoder to handle DynamoDB Decimal types.
    
    DynamoDB returns numbers as Decimal objects (not int/float).
    Standard json.dumps() can't serialize Decimal → causes runtime error.
    
    Solution: Convert Decimal to int (if whole number) or float (if decimal).
    """
    def default(self, obj):
        if isinstance(obj, Decimal):
            # If it's a whole number, return as int
            if obj % 1 == 0:
                return int(obj)
            # Otherwise return as float
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def success(data: Any, status_code: int = 200) -> Dict:
    """
    Format successful response.
    
    API Gateway requires:
    - statusCode: HTTP status (200, 201, etc.)
    - headers: CORS headers for browser
    - body: JSON string (not dict!)
    
    Args:
        data: Your response data (dict, list, etc.)
        status_code: HTTP status code (default 200)
    
    Returns:
        Dict with statusCode, headers, body
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',  # CORS: allow all origins (for now)
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
        },
        'body': json.dumps(data, cls=DecimalEncoder)  # Use custom encoder for Decimal
    }


def error(message: str, status_code: int = 500) -> Dict:
    """
    Format error response.
    
    Args:
        message: Human-readable error message
        status_code: HTTP error code (400, 404, 500, etc.)
    
    Returns:
        Dict with error format
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
        },
        'body': json.dumps({
            'error': message,
            'statusCode': status_code
        })
    }
