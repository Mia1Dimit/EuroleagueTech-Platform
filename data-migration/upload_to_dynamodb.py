"""
DynamoDB Data Upload Script
Transforms JSON data into DynamoDB items and uploads in batches.

Prerequisites:
    pip install boto3

Usage:
    python upload_to_dynamodb.py
    python upload_to_dynamodb.py --sync
    python upload_to_dynamodb.py --sync --dry-run

Environment Variables:
    AWS_PROFILE=default (or your AWS CLI profile)
    AWS_REGION=eu-west-1
"""

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List, Set

import boto3
from boto3.dynamodb.conditions import Attr, Key


# ============================================================================
# Configuration
# ============================================================================

TABLE_NAME = "spotech-dev-main"
AWS_REGION = "eu-west-1"

DATA_DIR = Path(__file__).parent / "output"
TEAMS_FILE = DATA_DIR / "teams.json"
VENDORS_FILE = DATA_DIR / "vendors.json"
ADOPTION_PATCH_FILE = DATA_DIR / "adoption_metadata_patch.json"


# ============================================================================
# DynamoDB Client Setup
# ============================================================================

def get_dynamodb_resource():
    """Create boto3 DynamoDB resource."""
    return boto3.resource("dynamodb", region_name=AWS_REGION)


def get_table(dynamodb):
    """Get reference to DynamoDB table."""
    return dynamodb.Table(TABLE_NAME)


# ============================================================================
# Data Transformation: JSON -> DynamoDB Items
# ============================================================================

def transform_team_to_dynamodb_item(team: Dict[str, Any]) -> Dict[str, Any]:
    """Transform team JSON to DynamoDB item format."""
    team_id = team["team_id"]

    item = {
        "PK": f"TEAM#{team_id}",
        "SK": "METADATA",
        "EntityType": "TEAM",
        "TeamID": team_id,
        "Name": team["name"],
        "Country": team["country"],
        "Arena": team["arena"],
        "EuroleagueStatus": team.get("euroleague_status", ""),
        "LastUpdated": team.get("last_updated", ""),
        "Partnerships": team.get("partnerships", []),
        "GSI1PK": f"COUNTRY#{team['country']}",
        "GSI1SK": f"TEAM#{team_id}",
    }

    if team.get("arena_capacity"):
        item["ArenaCapacity"] = team["arena_capacity"]

    if team.get("partnership_metadata"):
        item["PartnershipMetadata"] = team["partnership_metadata"]

    return item


def transform_teams_list_item(teams: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Create precomputed teams list item for cost-efficient list endpoint reads."""
    summaries: List[Dict[str, Any]] = []
    for team in teams:
        summaries.append(
            {
                "TeamID": team["team_id"],
                "Name": team["name"],
                "Country": team["country"],
                "Arena": team.get("arena", ""),
                "ArenaCapacity": team.get("arena_capacity"),
                "PartnershipsCount": len(team.get("partnerships", [])),
            }
        )

    return {
        "PK": "LIST#TEAM",
        "SK": "ALL",
        "EntityType": "TEAM_LIST",
        "Teams": summaries,
        "Count": len(summaries),
    }


def transform_vendors_list_item(vendors: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Create precomputed vendors list item for cost-efficient list endpoint reads."""
    summaries: List[Dict[str, Any]] = []
    for vendor in vendors:
        summaries.append(
            {
                "VendorID": vendor["vendor_id"],
                "Name": vendor["name"],
                "Headquarters": vendor.get("headquarters", ""),
                "Founded": vendor.get("founded", ""),
                "MarketPosition": vendor.get("market_position", ""),
                "Categories": vendor.get("categories", []),
                "Products": vendor.get("products", []),
            }
        )

    return {
        "PK": "LIST#VENDOR",
        "SK": "ALL",
        "EntityType": "VENDOR_LIST",
        "Vendors": summaries,
        "Count": len(summaries),
    }


def load_adoption_updates() -> List[Dict[str, Any]]:
    """Load optional adoption patch updates from sidecar JSON file."""
    if not ADOPTION_PATCH_FILE.exists():
        print(f"Adoption patch file not found (optional): {ADOPTION_PATCH_FILE}")
        return []

    with open(ADOPTION_PATCH_FILE, "r", encoding="utf-8") as f:
        payload = json.load(f)

    updates = payload.get("updates", [])
    print(f"   Loaded {len(updates)} adoption metadata updates")
    return updates


def apply_adoption_updates(teams: List[Dict[str, Any]], updates: List[Dict[str, Any]]):
    """Apply adoption patch updates to teams list in-memory before DynamoDB transform."""
    if not updates:
        return

    teams_by_id: Dict[str, Dict[str, Any]] = {team["team_id"]: team for team in teams}

    for update in updates:
        team_id = update.get("team_id")
        if not team_id or team_id not in teams_by_id:
            continue

        team = teams_by_id[team_id]
        partnerships = team.setdefault("partnerships", [])
        product = update.get("product")

        if update.get("action") == "add_partnership_and_annotate" and product and product not in partnerships:
            partnerships.append(product)

        if not product:
            continue

        partnership_metadata = team.setdefault("partnership_metadata", {})
        partnership_metadata[product] = {
            "VendorID": update.get("vendor_id", ""),
            "AdoptionStartYear": update.get("adoptionStartYear"),
            "AdoptionConfidence": update.get("adoptionConfidence", ""),
            "ConfirmationSource": update.get("confirmationSource", ""),
            "EvidenceNote": update.get("evidenceNote", ""),
        }


def transform_vendor_to_dynamodb_item(vendor: Dict[str, Any]) -> Dict[str, Any]:
    """Transform vendor JSON to DynamoDB metadata item format."""
    vendor_id = vendor["vendor_id"]

    return {
        "PK": f"VENDOR#{vendor_id}",
        "SK": "METADATA",
        "EntityType": "VENDOR",
        "VendorID": vendor_id,
        "Name": vendor["name"],
        "Headquarters": vendor.get("headquarters", ""),
        "Founded": vendor.get("founded", ""),
        "MarketPosition": vendor.get("market_position", ""),
        "Categories": vendor.get("categories", []),
        "Products": vendor.get("products", []),
    }


def transform_vendor_categories(vendor: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Transform vendor categories into separate DynamoDB items."""
    vendor_id = vendor["vendor_id"]
    categories = vendor.get("categories", [])

    category_items: List[Dict[str, Any]] = []
    for category in categories:
        category_slug = category.lower().replace(" ", "-").replace("&", "and")
        category_items.append(
            {
                "PK": f"VENDOR#{vendor_id}",
                "SK": f"CATEGORY#{category_slug}",
                "EntityType": "VENDOR_CATEGORY",
                "VendorID": vendor_id,
                "Category": category,
                "GSI1PK": f"CATEGORY#{category}",
                "GSI1SK": f"VENDOR#{vendor_id}",
            }
        )

    return category_items


# ============================================================================
# Sync Cleanup Helpers
# ============================================================================

def get_existing_entity_pks(table) -> Dict[str, Set[str]]:
    """
    Scan table and return current TEAM/VENDOR partition keys.

    Returns:
        {
            "TEAM": {"TEAM#..."},
            "VENDOR": {"VENDOR#..."}
        }
    """
    existing: Dict[str, Set[str]] = {"TEAM": set(), "VENDOR": set()}
    scan_kwargs = {
        "FilterExpression": Attr("EntityType").is_in(["TEAM", "VENDOR"]),
        "ProjectionExpression": "PK, EntityType",
    }

    response = table.scan(**scan_kwargs)
    items = response.get("Items", [])

    while "LastEvaluatedKey" in response:
        scan_kwargs["ExclusiveStartKey"] = response["LastEvaluatedKey"]
        response = table.scan(**scan_kwargs)
        items.extend(response.get("Items", []))

    for item in items:
        entity_type = item.get("EntityType")
        pk = item.get("PK")
        if entity_type in existing and pk:
            existing[entity_type].add(pk)

    return existing


def delete_partitions(table, partition_keys: List[str], dry_run: bool = False) -> int:
    """
    Delete all rows for each PK partition (METADATA + related rows).

    Returns number of rows deleted (or that would be deleted in dry run).
    """
    total_deleted = 0

    for pk in partition_keys:
        response = table.query(
            KeyConditionExpression=Key("PK").eq(pk),
            ProjectionExpression="PK, SK",
        )
        items = response.get("Items", [])

        while "LastEvaluatedKey" in response:
            response = table.query(
                KeyConditionExpression=Key("PK").eq(pk),
                ProjectionExpression="PK, SK",
                ExclusiveStartKey=response["LastEvaluatedKey"],
            )
            items.extend(response.get("Items", []))

        if not items:
            continue

        if dry_run:
            print(f"   [DRY-RUN] Would delete {len(items)} items for {pk}")
            total_deleted += len(items)
            continue

        with table.batch_writer() as batch:
            for item in items:
                batch.delete_item(Key={"PK": item["PK"], "SK": item["SK"]})
                total_deleted += 1

        print(f"   Deleted {len(items)} items for {pk}")

    return total_deleted


def cleanup_stale_entities(
    table,
    teams: List[Dict[str, Any]],
    vendors: List[Dict[str, Any]],
    dry_run: bool = False,
):
    """Remove stale TEAM/VENDOR partitions not present in current source files."""
    expected_team_pks = {f"TEAM#{team['team_id']}" for team in teams}
    expected_vendor_pks = {f"VENDOR#{vendor['vendor_id']}" for vendor in vendors}

    print("Sync mode: checking for stale TEAM/VENDOR partitions...")
    existing = get_existing_entity_pks(table)

    stale_team_pks = sorted(existing["TEAM"] - expected_team_pks)
    stale_vendor_pks = sorted(existing["VENDOR"] - expected_vendor_pks)
    stale_partition_keys = stale_team_pks + stale_vendor_pks

    print(f"   Existing teams: {len(existing['TEAM'])}, expected teams: {len(expected_team_pks)}")
    print(f"   Existing vendors: {len(existing['VENDOR'])}, expected vendors: {len(expected_vendor_pks)}")
    print(f"   Stale team partitions: {len(stale_team_pks)}")
    print(f"   Stale vendor partitions: {len(stale_vendor_pks)}")

    if not stale_partition_keys:
        print("   No stale partitions found.\n")
        return

    print(f"   Removing {len(stale_partition_keys)} stale partitions...")
    deleted_count = delete_partitions(table, stale_partition_keys, dry_run=dry_run)

    if dry_run:
        print(f"   Dry-run complete: {deleted_count} items would be deleted.\n")
    else:
        print(f"   Cleanup complete: deleted {deleted_count} stale items.\n")


# ============================================================================
# Upload Helpers
# ============================================================================

def upload_items_batch(table, items: List[Dict[str, Any]]):
    """Upload items to DynamoDB using batch writer."""
    print(f"Uploading {len(items)} items in batches...")

    with table.batch_writer() as batch:
        for idx, item in enumerate(items, 1):
            batch.put_item(Item=item)
            if idx % 10 == 0:
                print(f"   Uploaded {idx}/{len(items)} items...")

    print(f"Upload complete: {len(items)} items\n")


def validate_data_files() -> bool:
    """Validate that input JSON files exist before upload."""
    if not TEAMS_FILE.exists():
        print(f"Teams file not found: {TEAMS_FILE}")
        print("Run parse_markdown.py first.")
        return False

    if not VENDORS_FILE.exists():
        print(f"Vendors file not found: {VENDORS_FILE}")
        print("Run parse_markdown.py first.")
        return False

    return True


def parse_args():
    """Parse CLI arguments."""
    parser = argparse.ArgumentParser(description="Upload JSON data to DynamoDB")
    parser.add_argument(
        "--sync",
        action="store_true",
        help="Delete stale TEAM/VENDOR partitions before upload",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview stale deletions without deleting (effective only with --sync)",
    )
    return parser.parse_args()


# ============================================================================
# Main Execution
# ============================================================================

def main(args):
    """Load JSON -> optional sync cleanup -> transform -> upload."""
    print("=" * 70)
    print("DynamoDB Data Upload")
    print(f"Table: {TABLE_NAME}")
    print(f"Region: {AWS_REGION}")
    print(f"Sync Mode: {'ON' if args.sync else 'OFF'}")
    if args.sync:
        print(f"Dry Run: {'ON' if args.dry_run else 'OFF'}")
    print("=" * 70)
    print()

    if not validate_data_files():
        return

    print("Loading JSON files...")
    with open(TEAMS_FILE, "r", encoding="utf-8") as f:
        teams = json.load(f)
    print(f"   Loaded {len(teams)} teams")

    with open(VENDORS_FILE, "r", encoding="utf-8") as f:
        vendors = json.load(f)
    print(f"   Loaded {len(vendors)} vendors")

    print("Loading adoption metadata patch (optional)...")
    adoption_updates = load_adoption_updates()
    apply_adoption_updates(teams, adoption_updates)
    print()

    print("Connecting to DynamoDB...")
    dynamodb = get_dynamodb_resource()
    table = get_table(dynamodb)
    print(f"   Connected to table: {table.table_name}")
    print()

    if args.sync:
        cleanup_stale_entities(table, teams, vendors, dry_run=args.dry_run)

    print("Transforming teams to DynamoDB items...")
    team_items = [transform_team_to_dynamodb_item(team) for team in teams]
    print(f"   Transformed {len(team_items)} team items")
    print()

    print("Transforming vendors to DynamoDB items...")
    vendor_items = [transform_vendor_to_dynamodb_item(vendor) for vendor in vendors]
    print(f"   Transformed {len(vendor_items)} vendor metadata items")
    print()

    print("Transforming vendor categories...")
    vendor_category_items: List[Dict[str, Any]] = []
    for vendor in vendors:
        vendor_category_items.extend(transform_vendor_categories(vendor))
    print(f"   Transformed {len(vendor_category_items)} vendor category items")
    print()

    print("Transforming precomputed list items...")
    teams_list_item = transform_teams_list_item(teams)
    vendors_list_item = transform_vendors_list_item(vendors)
    print("   Transformed teams and vendors list items")
    print()

    print("Uploading teams to DynamoDB...")
    upload_items_batch(table, team_items)

    print("Uploading vendors to DynamoDB...")
    upload_items_batch(table, vendor_items)

    print("Uploading vendor categories to DynamoDB...")
    upload_items_batch(table, vendor_category_items)

    print("Uploading precomputed list items to DynamoDB...")
    upload_items_batch(table, [teams_list_item, vendors_list_item])

    total_items = len(team_items) + len(vendor_items) + len(vendor_category_items) + 2
    print("=" * 70)
    print("Upload Complete")
    print(f"   Total Items: {total_items}")
    print(f"   Teams: {len(team_items)}")
    print(f"   Vendors: {len(vendor_items)}")
    print(f"   Vendor Categories: {len(vendor_category_items)}")
    print("   Precomputed Lists: 2")
    print("=" * 70)


if __name__ == "__main__":
    main(parse_args())
