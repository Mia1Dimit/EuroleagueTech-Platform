"""
Teams API Lambda Function.

Handles:
- GET /teams           → List all teams (optional: filter by country)
- GET /teams/{teamId}  → Get specific team with partnerships

Similar to vendors_api.py but for TEAM entities.
"""

import sys
import os

# Add utils to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'utils'))

from response import success, error
from dynamodb import get_item, scan_items


def lambda_handler(event, context):
    """
    Main Lambda entry point for Teams API.
    
    Routes:
    - GET /teams         → list_teams()
    - GET /teams/{id}    → get_team_by_id()
    
    Query params:
    - ?country=Spain     → Filter teams by country
    """
    
    print(f"Received event: {event}")  # CloudWatch Logs
    
    # Route based on path
    path_params = event.get('pathParameters') or {}
    team_id = path_params.get('teamId')
    
    if team_id:
        # GET /teams/{teamId}
        return get_team_by_id(team_id)
    else:
        # GET /teams (with optional filter)
        query_params = event.get('queryStringParameters') or {}
        country = query_params.get('country')
        return list_teams(country)


def get_team_by_id(team_id: str):
    """
    GET /teams/{teamId}
    
    Example: GET /teams/real-madrid
    
    Returns team with inline partnerships array:
        {
          "TeamID": "real-madrid",
          "Name": "Real Madrid CF (Basketball Section)",
          "Country": "Spain",
          "Arena": "WiZink Center",
          "Partnerships": ["Catapult Sports", "Microsoft Azure"],
          ...
        }
    
    Design Note:
        Partnerships stored inline (not separate items)
        Trade-off: Simple/fast reads vs limited query patterns
    """
    try:
        # DynamoDB key pattern: PK = TEAM#{id}, SK = METADATA
        pk = f"TEAM#{team_id}"
        
        item = get_item(pk=pk, sk='METADATA')
        
        if not item:
            return error(f"Team not found: {team_id}", status_code=404)
        
        return success(item)
    
    except Exception as e:
        print(f"Error getting team: {e}")
        return error(f"Internal server error: {str(e)}", status_code=500)


def list_teams(country: str = None):
    """
    GET /teams
    GET /teams?country=Spain
    
    Returns:
        {
          "count": 20,
          "teams": [
            {"TeamID": "real-madrid", "Name": "Real Madrid", ...},
            ...
          ]
        }
    
    Filter logic:
    - No filter: Return all 20 teams
    - country=Spain: Return only Spanish teams
    
    Performance Note:
        Using Scan (acceptable for 20 teams)
        For 1000+ teams, use Query with GSI1 (COUNTRY# partition key)
    """
    try:
        list_item = get_item(pk="LIST#TEAM", sk="ALL")
        items = list_item.get("Teams", []) if list_item else []

        # Fallback to Scan for backward compatibility while precomputed list is absent.
        if not items:
            filter_expr = "EntityType = :type"
            expr_values = {":type": "TEAM"}
            if country:
                filter_expr += " AND Country = :country"
                expr_values[":country"] = country
            items = scan_items(
                filter_expression=filter_expr,
                expression_attribute_values=expr_values
            )

        if country:
            items = [item for item in items if item.get("Country") == country]
        
        # Format response
        response_data = {
            'count': len(items),
            'teams': items
        }
        
        if country:
            response_data['filteredBy'] = {'country': country}
        
        return success(response_data)
    
    except Exception as e:
        print(f"Error listing teams: {e}")
        return error(f"Internal server error: {str(e)}", status_code=500)
