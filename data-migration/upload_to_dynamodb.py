"""
DynamoDB Data Upload Script
Transforms JSON data into DynamoDB items and uploads in batches

Prerequisites:
    pip install boto3

Usage:
    python upload_to_dynamodb.py

Environment Variables:
    AWS_PROFILE=default (or your AWS CLI profile)
    AWS_REGION=eu-west-1
"""

import boto3
import json
from pathlib import Path
from typing import Dict, List, Any
from datetime import datetime


# ============================================================================
# Configuration
# ============================================================================

# DynamoDB configuration
TABLE_NAME = "spotech-dev-main"
AWS_REGION = "eu-west-1"

# Input JSON files
DATA_DIR = Path(__file__).parent / "output"
TEAMS_FILE = DATA_DIR / "teams.json"
VENDORS_FILE = DATA_DIR / "vendors.json"


# ============================================================================
# DynamoDB Client Setup
# ============================================================================

def get_dynamodb_resource():
    """
    Create boto3 DynamoDB resource.
    
    Returns:
        boto3.resource('dynamodb')
    
    Learning Note:
        - boto3.client: Low-level API (more control)
        - boto3.resource: High-level API (easier to use)
        - We use resource for batch_writer() convenience
    """
    return boto3.resource('dynamodb', region_name=AWS_REGION)


def get_table(dynamodb):
    """
    Get reference to DynamoDB table.
    
    Args:
        dynamodb: boto3 DynamoDB resource
    
    Returns:
        Table object
    """
    return dynamodb.Table(TABLE_NAME)


# ============================================================================
# Data Transformation: JSON → DynamoDB Items
# ============================================================================

def transform_team_to_dynamodb_item(team: Dict[str, Any]) -> Dict[str, Any]:
    """
    Transform team JSON to DynamoDB item format.
    
    **Single-Table Design Pattern:**
        PK: TEAM#<team-id>         (Partition Key)
        SK: METADATA               (Sort Key)
    
    **Why this pattern?**
        - All team metadata in ONE item
        - Partnerships as SEPARATE items (same PK, different SK)
        - Enables querying: "Get team + all partnerships" efficiently
    
    **GSI Attributes:**
        - GSI1PK: COUNTRY#<country> → Query "Show all Spanish teams"
        - GSI1SK: TEAM#<team-id>
    
    Args:
        team: Team dictionary from JSON
    
    Returns:
        DynamoDB item (dict)
    """
    team_id = team["team_id"]
    
    item = {
        # Primary keys
        "PK": f"TEAM#{team_id}",
        "SK": "METADATA",
        
        # Entity metadata
        "EntityType": "TEAM",
        "TeamID": team_id,
        "Name": team["name"],
        "Country": team["country"],
        "Arena": team["arena"],
        "EuroleagueStatus": team.get("euroleague_status", ""),
        "LastUpdated": team.get("last_updated", ""),
        
        # Partnerships
        "Partnerships": team.get("partnerships", []),
        
        # GSI1: Query by country
        "GSI1PK": f"COUNTRY#{team['country']}",
        "GSI1SK": f"TEAM#{team_id}",
    }
    
    # Optional fields (only add if not None)
    if team.get("arena_capacity"):
        item["ArenaCapacity"] = team["arena_capacity"]
    
    return item


def transform_vendor_to_dynamodb_item(vendor: Dict[str, Any]) -> Dict[str, Any]:
    """
    Transform vendor JSON to DynamoDB main item (metadata only).
    
    **Single-Table Design Pattern:**
        PK: VENDOR#<vendor-id>
        SK: METADATA
    
    **Note**: Categories are stored as separate items (see transform_vendor_categories)
    
    Args:
        vendor: Vendor dictionary from JSON
    
    Returns:
        DynamoDB item (dict)
    """
    vendor_id = vendor["vendor_id"]
    
    item = {
        # Primary keys
        "PK": f"VENDOR#{vendor_id}",
        "SK": "METADATA",
        
        # Entity metadata
        "EntityType": "VENDOR",
        "VendorID": vendor_id,
        "Name": vendor["name"],
        "Headquarters": vendor.get("headquarters", ""),
        "Founded": vendor.get("founded", ""),
        "MarketPosition": vendor.get("market_position", ""),
        "Categories": vendor.get("categories", []),  # Array for display
        "Products": vendor.get("products", []),  # Product names
    }
    
    return item


def transform_vendor_categories(vendor: Dict[str, Any]) -> List[Dict[str, Any]]:
    """
    Transform vendor categories into separate DynamoDB items.
    
    **Multi-Category Pattern:**
        For each category a vendor sells, create a separate item:
        - PK: VENDOR#<vendor-id>
        - SK: CATEGORY#<category-slug>
        - GSI1PK: CATEGORY#<category-name> (for browsing by category)
    
    **Why separate items?**
        - Enables querying "Show all Performance Tracking vendors" via GSI1
        - Avoids duplicate vendor data
        - Supports many-to-many relationship (vendor ↔ categories)
    
    Args:
        vendor: Vendor dictionary from JSON
    
    Returns:
        List of DynamoDB category items
    """
    vendor_id = vendor["vendor_id"]
    categories = vendor.get("categories", [])
    
    category_items = []
    
    for category in categories:
        # Generate category slug for SK
        category_slug = category.lower().replace(" ", "-").replace("&", "and")
        
        item = {
            # Primary keys
            "PK": f"VENDOR#{vendor_id}",
            "SK": f"CATEGORY#{category_slug}",
            
            # Entity metadata
            "EntityType": "VENDOR_CATEGORY",
            "VendorID": vendor_id,
            "Category": category,
            
            # GSI1: Query by category
            "GSI1PK": f"CATEGORY#{category}",
            "GSI1SK": f"VENDOR#{vendor_id}",
        }
        
        category_items.append(item)
    
    return category_items


# ============================================================================
# Batch Upload to DynamoDB
# ============================================================================

def upload_items_batch(table, items: List[Dict[str, Any]]):
    """
    Upload items to DynamoDB using batch writer.
    
    **Why batch_writer()?**
        - Automatic batching (up to 25 items per request)
        - Automatic retries on throttling
        - Handles unprocessed items
        - More efficient than individual put_item() calls
    
    **Cost Optimization:**
        - 1 batch request (25 items) = 25 WCU (Write Capacity Units)
        - Same cost as 25 individual requests, but faster
        - On-demand billing: $1.25 per million writes
    
    Args:
        table: DynamoDB Table resource
        items: List of items to upload
    """
    print(f"📤 Uploading {len(items)} items in batches...")
    
    with table.batch_writer() as batch:
        for idx, item in enumerate(items, 1):
            batch.put_item(Item=item)
            
            # Progress indicator (every 10 items)
            if idx % 10 == 0:
                print(f"   Uploaded {idx}/{len(items)} items...")
    
    print(f"✅ Upload complete: {len(items)} items\n")


# ============================================================================
# Validation Helper
# ============================================================================

def validate_data_files():
    """
    Validate that JSON files exist before upload.
    
    Returns:
        bool: True if files exist, False otherwise
    """
    if not TEAMS_FILE.exists():
        print(f"❌ Teams file not found: {TEAMS_FILE}")
        print("   Run parse_markdown.py first!")
        return False
    
    if not VENDORS_FILE.exists():
        print(f"❌ Vendors file not found: {VENDORS_FILE}")
        print("   Run parse_markdown.py first!")
        return False
    
    return True


# ============================================================================
# Main Execution
# ============================================================================

def main():
    """
    Main execution: Load JSON → Transform → Upload to DynamoDB.
    """
    print("=" * 70)
    print("DynamoDB Data Upload")
    print(f"Table: {TABLE_NAME}")
    print(f"Region: {AWS_REGION}")
    print("=" * 70)
    print()
    
    # Validate input files exist
    if not validate_data_files():
        return
    
    # Load JSON data
    print("📂 Loading JSON files...")
    with open(TEAMS_FILE, 'r', encoding='utf-8') as f:
        teams = json.load(f)
    print(f"   Loaded {len(teams)} teams")
    
    with open(VENDORS_FILE, 'r', encoding='utf-8') as f:
        vendors = json.load(f)
    print(f"   Loaded {len(vendors)} vendors")
    print()
    
    # Connect to DynamoDB
    print("🔌 Connecting to DynamoDB...")
    dynamodb = get_dynamodb_resource()
    table = get_table(dynamodb)
    print(f"   Connected to table: {table.table_name}")
    print()
    
    # Transform teams to DynamoDB items
    print("🔄 Transforming teams to DynamoDB items...")
    team_items = [transform_team_to_dynamodb_item(team) for team in teams]
    print(f"   Transformed {len(team_items)} team items")
    print()
    
    # Transform vendors to DynamoDB items (metadata)
    print("🔄 Transforming vendors to DynamoDB items...")
    vendor_items = [transform_vendor_to_dynamodb_item(vendor) for vendor in vendors]
    print(f"   Transformed {len(vendor_items)} vendor metadata items")
    print()
    
    # Transform vendor categories to separate items (for GSI1 queries)
    print("🔄 Transforming vendor categories...")
    vendor_category_items = []
    for vendor in vendors:
        vendor_category_items.extend(transform_vendor_categories(vendor))
    print(f"   Transformed {len(vendor_category_items)} vendor category items")
    print()
    
    # Upload to DynamoDB
    print("📤 Uploading teams to DynamoDB...")
    upload_items_batch(table, team_items)
    
    print("📤 Uploading vendors to DynamoDB...")
    upload_items_batch(table, vendor_items)
    
    print("📤 Uploading vendor categories to DynamoDB...")
    upload_items_batch(table, vendor_category_items)
    
    # Summary
    total_items = len(team_items) + len(vendor_items) + len(vendor_category_items)
    print("=" * 70)
    print("✅ Upload Complete!")
    print(f"   Total Items: {total_items}")
    print(f"   Teams: {len(team_items)}")
    print(f"   Vendors: {len(vendor_items)}")
    print(f"   Vendor Categories: {len(vendor_category_items)}")
    print("=" * 70)
    print()
    print("🔍 Next Steps:")
    print("   1. Verify in AWS Console → DynamoDB → spotech-dev-main")
    print("   2. Test query: aws dynamodb query --table-name spotech-dev-main \\")
    print("                    --key-condition-expression 'PK = :pk' \\")
    print("                    --expression-attribute-values '{\":pk\":{\"S\":\"TEAM#real-madrid\"}}'")


if __name__ == "__main__":
    main()
