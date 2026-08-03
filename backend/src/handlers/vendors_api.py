"""
Vendors API Lambda Function.

Handles:
- GET /vendors           → List all vendors (optional: filter by category)
- GET /vendors/{vendorId} → Get specific vendor with products

API Gateway Integration:
- event['httpMethod'] = 'GET'
- event['pathParameters'] = {'vendorId': 'catapult-sports'} or None
- event['queryStringParameters'] = {'category': 'Performance Tracking'} or None
"""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'utils'))

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext
from response import success, error
from dynamodb import get_item, scan_items

logger = Logger()
tracer = Tracer()


@tracer.capture_lambda_handler
@logger.inject_lambda_context(log_event=False)
def lambda_handler(event, context: LambdaContext):
    path_params = event.get('pathParameters') or {}
    vendor_id = path_params.get('vendorId')
    
    if vendor_id:
        # GET /vendors/{vendorId} → Get specific vendor
        return get_vendor_by_id(vendor_id)
    else:
        # GET /vendors → List all vendors
        query_params = event.get('queryStringParameters') or {}
        category = query_params.get('category')
        return list_vendors(category)


def get_vendor_by_id(vendor_id: str):
    """
    GET /vendors/{vendorId}
    
    Example: GET /vendors/catapult-sports
    
    Returns:
        {
          "VendorID": "catapult-sports",
          "Name": "Catapult Sports",
          "Products": ["Vector Core", "Vector T7", ...],
          ...
        }
    """
    try:
        # DynamoDB key pattern: PK = VENDOR#{id}, SK = METADATA
        pk = f"VENDOR#{vendor_id}"
        
        item = get_item(pk=pk, sk='METADATA')
        
        if not item:
            return error(f"Vendor not found: {vendor_id}", status_code=404)
        
        return success(item)
    
    except Exception as e:
        print(f"Error getting vendor: {e}")
        return error(f"Internal server error: {str(e)}", status_code=500)


def list_vendors(category: str = None):
    """
    GET /vendors
    GET /vendors?category=Performance%20Tracking
    
    Returns:
        {
          "count": 36,
          "vendors": [
            {"VendorID": "catapult-sports", "Name": "Catapult Sports", ...},
            ...
          ]
        }
    
    Note: Uses Scan (reads all items, filters client-side)
          For production scale, use Query with GSI1
    """
    try:
        list_item = get_item(pk="LIST#VENDOR", sk="ALL")
        items = list_item.get("Vendors", []) if list_item else []

        # Fallback to Scan for backward compatibility while precomputed list is absent.
        if not items:
            filter_expr = "EntityType = :type"
            expr_values = {":type": "VENDOR"}
            if category:
                filter_expr += " AND contains(Categories, :category)"
                expr_values[":category"] = category
            items = scan_items(
                filter_expression=filter_expr,
                expression_attribute_values=expr_values
            )

        if category:
            items = [
                item for item in items
                if category in (item.get("Categories") or [])
            ]
        
        # Format response
        response_data = {
            'count': len(items),
            'vendors': items
        }
        
        # Optional: Add category info if filtered
        if category:
            response_data['filteredBy'] = {'category': category}
        
        return success(response_data)
    
    except Exception as e:
        print(f"Error listing vendors: {e}")
        return error(f"Internal server error: {str(e)}", status_code=500)
