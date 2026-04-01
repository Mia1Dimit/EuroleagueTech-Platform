# Data Migration - Euroleague Tech to DynamoDB

**Purpose**: Migrate markdown data from Euroleague Tech workspace to DynamoDB  
**Created**: March 27, 2026  
**Status**: Scripts created, ready to execute

---

## 📋 Overview

This directory contains scripts to:
1. Parse markdown files from `Euroleague Tech` workspace
2. Transform data into DynamoDB single-table format
3. Upload items to `spotech-dev-main` table using boto3

---

## 🗂️ Files

### `parse_markdown.py`
Extracts structured data from markdown files:
- **Input**: `c:\Dev\Personal\Euroleague Tech\euroleague-teams\*.md`
- **Input**: `c:\Dev\Personal\Euroleague Tech\vendor-profiles\*.md`
- **Output**: `./output/teams.json`, `./output/vendors.json`

**Features**:
- Regex-based metadata extraction
- ID generation (URL-friendly slugs)
- **Category normalization** (9 canonical categories with alias mapping)
- **Multi-field support** (handles both `**Category Focus**:` and `**Category:**`)
- Partnership parsing (TODO: enhance)
- Product parsing (TODO: enhance)

**Category Framework** (9 canonical categories):
1. Performance Tracking
2. Video Analysis
3. Data Analytics
4. Recovery & Medical
5. Fan Engagement
6. Facilities & Infrastructure
7. Business Operations
8. Scouting & Recruitment
9. Content & Broadcasting

The parser automatically normalizes category variations (e.g., "Video" → "Video Analysis", "CRM" → "Business Operations") and flags unknown categories for manual review.

### `upload_to_dynamodb.py`
Uploads JSON data to DynamoDB:
- **Input**: `./output/teams.json`, `./output/vendors.json`
- **Output**: Items in DynamoDB table `spotech-dev-main`

**Features**:
- PK/SK construction for single-table design
- GSI attribute population (GSI1PK, GSI1SK)
- Batch writer for efficient uploads
- Progress indicators

---

## 🚀 Quick Start

### Prerequisites

```powershell
# Install boto3 (AWS SDK for Python)
pip install boto3

# Ensure AWS credentials configured
aws configure list
# Should show your AWS access key and region (eu-west-1)
```

### Step 1: Parse Markdown Files

```powershell
cd c:\Dev\Personal\SportsTech-Cloud-Platform\data-migration
python parse_markdown.py
```

**Expected Output**:
```
======================================================================
Euroleague Tech Data Parser
======================================================================

� Using 9 canonical categories:
   • Business Operations
   • Content & Broadcasting
   • Data Analytics
   • Facilities & Infrastructure
   • Fan Engagement
   • Performance Tracking
   • Recovery & Medical
   • Scouting & Recruitment
   • Video Analysis

📂 Parsing teams from: c:\Dev\Personal\Euroleague Tech\euroleague-teams
  - Parsing real-madrid.md...
  - Parsing barcelona-bc.md...
  ...
✅ Parsed 20 teams

📂 Parsing vendors from: c:\Dev\Personal\Euroleague Tech\vendor-profiles
  - Parsing catapult-sports.md...
    ⚠️  Unknown categories: Athlete Management
  - Parsing kinexon.md...
  ...
✅ Parsed 36 vendors

📊 Category Analysis:
   Total unique categories found: 12
   Canonical categories used: 9
   ⚠️  Unknown categories: 3
      - Athlete Management
      - Cloud Infrastructure
      - Productivity & Collaboration

💾 Saved teams to: output\teams.json
💾 Saved vendors to: output\vendors.json
======================================================================
✅ Parsing Complete!
   Teams: 20
   Vendors: 36
======================================================================
```

**Note**: Unknown categories are flagged for manual review. You can either:
- Update the vendor markdown file with canonical categories
- Add new aliases to `CATEGORY_ALIASES` in `parse_markdown.py`
- Add new canonical categories if justified

**Verify Output**:
```powershell
cat output\teams.json | ConvertFrom-Json | Select-Object -First 1
cat output\vendors.json | ConvertFrom-Json | Select-Object -First 1
```

---

### Step 2: Upload to DynamoDB

```powershell
python upload_to_dynamodb.py
```

**Expected Output**:
```
======================================================================
DynamoDB Data Upload
Table: spotech-dev-main
Region: eu-west-1
======================================================================

📂 Loading JSON files...
   Loaded 20 teams
   Loaded 36 vendors

🔌 Connecting to DynamoDB...
   Connected to table: spotech-dev-main

🔄 Transforming teams to DynamoDB items...
   Transformed 20 team items

🔄 Transforming vendors to DynamoDB items...
   Transformed 36 vendor items

📤 Starting batch upload...
📤 Uploading 20 items in batches...
   Uploaded 10/20 items...
   Uploaded 20/20 items...
✅ Upload complete: 20 items

📤 Uploading 36 items in batches...
   Uploaded 10/36 items...
   Uploaded 20/36 items...
   Uploaded 30/36 items...
   Uploaded 36/36 items...
✅ Upload complete: 36 items

======================================================================
✅ Upload Complete!
   Total Items: 56
   Teams: 20
   Vendors: 36
======================================================================
```

---

## 🔍 Verification

### AWS Console
1. Navigate to: **AWS Console → DynamoDB → Tables**
2. Click: `spotech-dev-main`
3. Click: **Explore table items**
4. View items:
   - `PK = TEAM#real-madrid, SK = METADATA`
   - `PK = VENDOR#catapult-sports, SK = METADATA`

### AWS CLI
```bash
# Query a specific team
aws dynamodb get-item \
  --table-name spotech-dev-main \
  --key '{"PK":{"S":"TEAM#real-madrid"},"SK":{"S":"METADATA"}}' \
  --region eu-west-1

# Query all teams from Spain (using GSI1)
aws dynamodb query \
  --table-name spotech-dev-main \
  --index-name GSI1 \
  --key-condition-expression "GSI1PK = :country" \
  --expression-attribute-values '{":country":{"S":"COUNTRY#Spain"}}' \
  --region eu-west-1

# Count total items in table
aws dynamodb scan \
  --table-name spotech-dev-main \
  --select COUNT \
  --region eu-west-1
```

---

## 📊 DynamoDB Item Structure

### Team Item
```json
{
  "PK": "TEAM#real-madrid",
  "SK": "METADATA",
  "EntityType": "TEAM",
  "TeamID": "real-madrid",
  "Name": "Real Madrid",
  "Country": "Spain",
  "Arena": "WiZink Center",
  "ArenaCapacity": 15000,
  "EuroleagueStatus": "11-time champion",
  "GSI1PK": "COUNTRY#Spain",
  "GSI1SK": "TEAM#real-madrid"
}
```

### Vendor Item
```json
{
  "PK": "VENDOR#catapult-sports",
  "SK": "METADATA",
  "EntityType": "VENDOR",
  "VendorID": "catapult-sports",
  "Name": "Catapult Sports",
  "Headquarters": "Melbourne, Australia",
  "Founded": "2006",
  "Category": "Performance Tracking, Video Analysis",
  "GSI1PK": "CATEGORY#Performance Tracking, Video Analysis",
  "GSI1SK": "VENDOR#catapult-sports"
}
```

---

## 🎓 Learning Concepts

### boto3 - AWS SDK for Python
```python
import boto3

# High-level API (easier)
dynamodb = boto3.resource('dynamodb', region_name='eu-west-1')
table = dynamodb.Table('spotech-dev-main')

# Low-level API (more control)
dynamodb_client = boto3.client('dynamodb', region_name='eu-west-1')
```

### Batch Writer Pattern
```python
# Efficient batch uploads (up to 25 items per request)
with table.batch_writer() as batch:
    for item in items:
        batch.put_item(Item=item)
# Automatic batching, retries, error handling
```

### Single-Table Design
- **One table** for all entities (teams, vendors, partnerships)
- **PK/SK pattern** groups related data together
- **GSIs** enable different query patterns
- **Cost-efficient**: Fewer tables = simpler management

---

## 🔧 Customization

### Add Partnership Parsing
Edit `parse_markdown.py`:
```python
def extract_partnerships(content: str) -> List[Dict]:
    """Extract partnerships from '## CONFIRMED Technology Partnerships' section"""
    # TODO: Implement regex to find vendor names, products, sources
    pass
```

### Add Product Parsing
Edit `parse_markdown.py`:
```python
def extract_products(content: str) -> List[Dict]:
    """Extract products from vendor markdown"""
    # TODO: Parse product sections (e.g., ### Catapult Vector)
    pass
```

---

## 🐛 Troubleshooting

### boto3 not installed
```powershell
pip install boto3
```

### AWS credentials not configured
```powershell
aws configure
# Enter: Access Key ID, Secret Access Key, Region (eu-west-1)
```

### Table not found error
```
ResourceNotFoundException: spotech-dev-main
```
Ensure DynamoDB table deployed:
```powershell
cd ..\infrastructure
terraform apply -var-file="dev.tfvars"
```

### Permission denied
```
AccessDeniedException: User not authorized to perform PutItem
```
Check IAM permissions - user needs `dynamodb:PutItem` permission

---

## 📈 Cost Estimate

**Data Volume**:
- 20 teams × ~1 KB = 20 KB
- 36 vendors × ~1 KB = 36 KB
- **Total**: ~56 KB

**Upload Cost**:
- 56 write requests × $1.25 per million = **$0.00007**
- Essentially free!

**Storage Cost**:
- 56 KB × $0.25 per GB-month = **$0.000014/month**
- Well under free tier (25 GB)

---

**Next**: Test queries, then build Lambda functions to expose data via API Gateway!
