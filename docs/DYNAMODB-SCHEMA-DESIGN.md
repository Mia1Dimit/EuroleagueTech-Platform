# DynamoDB Schema Design - SportsTech Platform

**Created**: March 23, 2026  
**Updated**: March 23, 2026 (Terraform infrastructure ready)  
**Based On**: Analysis of Euroleague Tech workspace (20 teams, 36+ vendors, 6 staff rosters)  
**Purpose**: Backend database design for Phase 2 implementation  
**Status**: ✅ Terraform Validated - Ready to Deploy

---

## 🚀 Implementation Status

**Track 1 Progress (DynamoDB Infrastructure)**:
- ✅ Schema designed (single-table with 5 GSIs)
- ✅ Terraform module created (`modules/dynamodb/`)
- ✅ Infrastructure configured (`infrastructure/dynamodb.tf`)
- ✅ terraform init + terraform plan: SUCCESS
- 🚧 Ready for deployment (terraform apply tomorrow)

**Next**: Deploy table → Migrate data from markdown files

---

## 📊 Data Summary from Analysis

**Your Data Inventory:**
- 20 Euroleague teams with complete profiles
- 36+ technology vendors across 8 categories
- 6 team staff rosters documented
- 40+ confirmed partnerships verified
- 100+ products tracked
- Regional distribution networks mapped

---

## 🎯 Supported Access Patterns

Based on your data and user requirements:

### User Queries You Want to Support:

1. **Browse vendors** - Show all vendors, filter by category/country
2. **Browse teams** - Show all teams, filter by country
3. **View vendor details** - Get vendor + products + clients
4. **View team details** - Get team + partnerships + staff
5. **Compare vendors** - Get 2-3 vendors side-by-side with specifications
6. **Search by category** - "Show me all GPS tracking vendors"
7. **Search by team** - "Who does Real Madrid use for performance tracking?"
8. **Search by product** - "Which teams use KINEXON PERFORM?"
9. **Partnership timeline** - Recent confirmations, sorted by date
10. **Market share** - "How many teams use Catapult vs KINEXON?"

---

## 🏗️ Proposed Schema: Single-Table Design

### Why Single-Table Design?

**AWS Best Practice** for DynamoDB:
- ✅ Fewer API calls (get team + partnerships in one query)
- ✅ Lower cost (fewer read units)
- ✅ Better performance (fewer network requests)
- ✅ SAA exam topic (you'll learn the pattern)

**Trade-off**: More complex design upfront, simpler operations later

---

## 📋 Table Structure

### Main Table: `spotech-dev-main`

**Partition Key (PK)**: String  
**Sort Key (SK)**: String  

### Entity Types

```
TEAM#<teamId>
VENDOR#<vendorId>
PRODUCT#<vendorId>#<productId>
PARTNERSHIP#<teamId>#<vendorId>#<productId>
STAFF#<teamId>#<staffId>
REGIONALPARTNER#<vendorId>#<partnerId>
```

---

## 📦 Entity Schemas

### 1. TEAM Entity

**Example Item:**
```json
{
  "PK": "TEAM#real-madrid",
  "SK": "METADATA",
  "EntityType": "TEAM",
  "TeamID": "real-madrid",
  "Name": "Real Madrid",
  "ClubName": "Real Madrid CF (Basketball Section)",
  "Country": "Spain",
  "City": "Madrid",
  "Arena": "WiZink Center",
  "ArenaCapacity": 15000,
  "Founded": 1932,
  "EuroleagueStatus": "11-time champion",
  "Budget": "€30-50M",
  "Website": "https://www.realmadrid.com/basketball",
  "LastUpdated": "2026-03-06",
  "DataQuality": 4,
  "TotalPartnerships": 8,
  "GSI1PK": "COUNTRY#Spain",
  "GSI1SK": "TEAM#real-madrid"
}
```

**Fields from Your Data:**
- Core metadata (Name, Country, City, Arena, Capacity)
- Euroleague history
- Budget estimates
- Data quality ratings (your ⭐ system)
- Last updated tracking

---

### 2. VENDOR Entity

**Example Item:**
```json
{
  "PK": "VENDOR#catapult-sports",
  "SK": "METADATA",
  "EntityType": "VENDOR",
  "VendorID": "catapult-sports",
  "Name": "Catapult Sports",
  "HQ": "Melbourne, Australia",
  "Founded": 2006,
  "MarketPosition": "Leader",
  "Category": "Performance Tracking",
  "TechnologyTypes": ["GPS", "IMU", "Video Integration"],
  "Website": "https://catapultsports.com",
  "EuroleagueMarketShare": "15-20%",
  "TotalEuroleagueClients": 3,
  "LastUpdated": "2026-02-15",
  "GSI1PK": "CATEGORY#Performance Tracking",
  "GSI1SK": "VENDOR#catapult-sports"
}
```

**Fields from Your Data:**
- Company overview (HQ, founded, market position)
- Category focus
- Market share calculations
- Client counts

---

### 3. PRODUCT Entity

**Example Item:**
```json
{
  "PK": "VENDOR#catapult-sports",
  "SK": "PRODUCT#vector-gps",
  "EntityType": "PRODUCT",
  "ProductID": "vector-gps",
  "VendorID": "catapult-sports",
  "Name": "Catapult Vector",
  "Type": "GPS/IMU Wearable",
  "Description": "GPS/IMU player tracking system with video integration",
  "DataCollected": [
    "GPS coordinates",
    "Acceleration",
    "Player load",
    "Distance covered",
    "Speed zones",
    "Heart rate"
  ],
  "SamplingRate": "10 Hz GPS, 100 Hz IMU",
  "Accuracy": "Sub-meter GPS accuracy",
  "UseCases": [
    "Workload monitoring",
    "Load management",
    "Development tracking",
    "Video overlay"
  ],
  "IntegratesWith": ["Catapult Focus Platform", "Video systems"],
  "LaunchDate": "2015",
  "LastUpdated": "2026-02-15"
}
```

**Fields from Your Data:**
- Product specifications
- Technical details (sampling rate, accuracy)
- Data types collected
- Use cases
- Integration capabilities

---

### 4. PARTNERSHIP Entity

**Example Item:**
```json
{
  "PK": "TEAM#real-madrid",
  "SK": "PARTNERSHIP#catapult-sports#vector-gps",
  "EntityType": "PARTNERSHIP",
  "PartnershipID": "real-madrid-catapult-vector",
  "TeamID": "real-madrid",
  "VendorID": "catapult-sports",
  "ProductID": "vector-gps",
  "Products": ["Catapult Vector", "Catapult Focus"],
  "Status": "CONFIRMED",
  "ConfirmationDate": "2024-01-15",
  "Source": "Real Madrid high-performance staff references",
  "SourceURL": "https://...",
  "UseCases": [
    "Player workload monitoring",
    "Development tracking",
    "Load management",
    "Video overlay"
  ],
  "UsedBy": ["Coaches", "S&C staff", "Sports scientists", "Medical team"],
  "EstimatedCostMin": 50000,
  "EstimatedCostMax": 120000,
  "CostCurrency": "EUR",
  "CostPeriod": "annual",
  "LastUpdated": "2026-03-06",
  "GSI2PK": "VENDOR#catapult-sports",
  "GSI2SK": "PARTNERSHIP#real-madrid",
  "GSI3PK": "STATUS#CONFIRMED",
  "GSI3SK": "2024-01-15"
}
```

**Fields from Your Data:**
- Partnership metadata
- Confirmation status (✅ CONFIRMED, 🔍 LIKELY, ⚠️ UNCONFIRMED)
- Verification sources
- Use cases and users
- Cost estimates
- Adoption timeline

---

### 5. STAFF Entity

**Example Item:**
```json
{
  "PK": "TEAM#panathinaikos",
  "SK": "STAFF#dimitris-paspalas",
  "EntityType": "STAFF",
  "StaffID": "dimitris-paspalas",
  "TeamID": "panathinaikos",
  "Name": "Dimitris Paspalas",
  "Role": "Fitness Trainer",
  "RoleNative": "Γυμναστής",
  "Department": "Strength & Conditioning",
  "Nationality": "Greece",
  "Born": "2001-01-01",
  "Background": "Sports science degree, youth academy experience",
  "TechnologyUsed": ["KINEXON PERFORM", "Training load software"],
  "PotentialTechRole": "Training load monitoring, session design, injury prevention",
  "Source": "paobc.gr/en/team/dimitris-paspalas/",
  "LastUpdated": "2026-03-10"
}
```

**Fields from Your Data:**
- Staff profiles
- Role and department
- Background/experience
- Technology usage mapping
- Sources

---

### 6. REGIONAL PARTNER Entity

**Example Item:**
```json
{
  "PK": "VENDOR#kinexon",
  "SK": "REGIONALPARTNER#conartia",
  "EntityType": "REGIONALPARTNER",
  "RegionalPartnerID": "conartia",
  "VendorID": "kinexon",
  "PartnerName": "Conartia",
  "Region": "Greece & Cyprus",
  "Status": "Exclusive Partner",
  "Headquarters": "Greece",
  "Services": [
    "System installation",
    "Implementation support",
    "Training",
    "Power BI dashboard development",
    "Greek-language support",
    "Microsoft 365 integration"
  ],
  "Clients": [
    "Panathinaikos BC AKTOR (Euroleague)",
    "PAOK BC (Greek League)"
  ],
  "LastUpdated": "2026-02-20"
}
```

**Fields from Your Data:**
- Regional distribution networks
- Services provided
- Geography coverage
- Confirmed client lists

---

## 🔍 Global Secondary Indexes (GSIs)

### GSI1: Category + Country Queries

**Use Case**: "Show all GPS vendors" or "Show all Spanish teams"

**Keys:**
- **GSI1PK**: `CATEGORY#<category>` or `COUNTRY#<country>`
- **GSI1SK**: `VENDOR#<vendorId>` or `TEAM#<teamId>`

**Enables:**
- Browse vendors by category
- Browse teams by country
- Filter/search functionality

---

### GSI2: Vendor Client Lists

**Use Case**: "Show all teams using Catapult" (reverse partnership query)

**Keys:**
- **GSI2PK**: `VENDOR#<vendorId>`
- **GSI2SK**: `PARTNERSHIP#<teamId>`

**Enables:**
- Vendor detail pages with client lists
- Market share calculations
- Competitive analysis

---

### GSI3: Partnership Status + Timeline

**Use Case**: "Show recently confirmed partnerships" or "Show all LIKELY partnerships"

**Keys:**
- **GSI3PK**: `STATUS#<status>` (CONFIRMED, LIKELY, UNCONFIRMED)
- **GSI3SK**: `<confirmationDate>`

**Enables:**
- Recent confirmations feed
- Data quality filtering
- Partnership confidence levels

---

### GSI4: Product Usage

**Use Case**: "Which teams use KINEXON PERFORM?"

**Keys:**
- **GSI4PK**: `PRODUCT#<productId>`
- **GSI4SK**: `TEAM#<teamId>`

**Enables:**
- Product adoption analysis
- Competitive product comparison
- Market penetration tracking

---

### GSI5: Team Staff Roster

**Use Case**: "Show all staff for Real Madrid" (if you want staff separate from main query)

**Keys:**
- **GSI5PK**: `TEAM#<teamId>`
- **GSI5SK**: `STAFF#<staffId>`

**Enables:**
- Staff roster queries
- Team organization charts
- Role-based technology usage

**Note**: This might be redundant since staff items already have `PK=TEAM#<teamId>`, so you can query directly. Consider this optional.

---

## 📖 Query Examples

### Example 1: Get Team with All Partnerships

```python
# Single query gets team + all partnerships
response = dynamodb.query(
    TableName='spotech-dev-main',
    KeyConditionExpression='PK = :pk',
    ExpressionAttributeValues={
        ':pk': 'TEAM#real-madrid'
    }
)

# Returns:
# - TEAM#real-madrid#METADATA (team info)
# - TEAM#real-madrid#PARTNERSHIP#catapult-sports#vector-gps
# - TEAM#real-madrid#PARTNERSHIP#microsoft#azure
# - TEAM#real-madrid#PARTNERSHIP#...
# - TEAM#real-madrid#STAFF#...
```

---

### Example 2: Get Vendor with Products and Clients

```python
# Query 1: Get vendor + products
response1 = dynamodb.query(
    TableName='spotech-dev-main',
    KeyConditionExpression='PK = :pk',
    ExpressionAttributeValues={
        ':pk': 'VENDOR#catapult-sports'
    }
)
# Returns: Vendor metadata + all products + regional partners

# Query 2: Get clients via GSI2
response2 = dynamodb.query(
    IndexName='GSI2',
    KeyConditionExpression='GSI2PK = :vendorKey',
    ExpressionAttributeValues={
        ':vendorKey': 'VENDOR#catapult-sports'
    }
)
# Returns: All partnerships where Catapult is the vendor
```

---

### Example 3: Browse Vendors by Category

```python
# Use GSI1
response = dynamodb.query(
    IndexName='GSI1',
    KeyConditionExpression='GSI1PK = :category',
    ExpressionAttributeValues={
        ':category': 'CATEGORY#Performance Tracking'
    }
)
# Returns: All vendors in Performance Tracking category
```

---

### Example 4: Recent Confirmed Partnerships

```python
# Use GSI3
response = dynamodb.query(
    IndexName='GSI3',
    KeyConditionExpression='GSI3PK = :status',
    ScanIndexForward=False,  # Sort descending by date
    Limit=10,  # Last 10 confirmations
    ExpressionAttributeValues={
        ':status': 'STATUS#CONFIRMED'
    }
)
# Returns: 10 most recent CONFIRMED partnerships
```

---

## 💰 Cost Estimate

### DynamoDB Pricing (On-Demand Mode)

**Recommended for dev/learning:**
- No capacity planning required
- Pay per request
- Perfect for variable traffic

**Estimated Monthly Cost (Development):**
- Write requests: 100 items ÷ 1M free tier × $1.25 = **$0.00**
- Read requests: ~10,000 queries ÷ 2.5M free tier = **$0.00**
- Storage: ~0.1 GB × $0.25/GB = **$0.03/month**

**Total Phase 2**: **~$0-0.05/month** (under free tier)

**Production (after launch):**
- 100k reads/month: **~$0.03**
- 10k writes/month: **~$0.01**
- Storage: **~$0.25**

**Total**: **~$0.30/month**

---

## 🎯 Migration Path

### Step 1: Create DynamoDB Tables (Terraform)
- Main table with composite keys
- 4-5 GSI indexes
- On-demand billing mode

### Step 2: Parse Markdown Files
- Python script to read your `.md` files
- Extract structured data with regex
- Transform to JSON

### Step 3: Populate Database
-batch write items
- Start with teams (20 items)
- Then vendors (36 items)
- Then products (~100 items)
- Then partnerships (~40+ items)
- Finally staff (variable)

### Step 4: Test via CLI
```bash
# Test queries
aws dynamodb query \
  --table-name spotech-dev-main \
  --key-condition-expression "PK = :pk" \
  --expression-attribute-values '{":pk":{"S":"TEAM#real-madrid"}}'
```

### Step 5: Build Lambda APIs
- GET /api/vendors → Scan/query vendors
- GET /api/teams → Scan/query teams
- GET /api/vendors/{id} → Query vendor + products + clients
- etc.

---

## 🤔 Design Decisions Explained

### Why Single-Table vs Multi-Table?

**Single-Table (Recommended):**
- ✅ Get team + partnerships in 1 query (not 2)
- ✅ Lower cost (fewer API calls)
- ✅ Better performance
- ✅ AWS best practice
- ❌ More complex design

**Multi-Table (Simpler but inefficient):**
- ✅ Easier to understand (1 table = 1 entity)
- ❌ Need multiple queries (expensive)
- ❌ Higher latency
- ❌ More costly at scale

**Verdict**: Single-table for learning + cost optimization

---

### Why On-Demand vs Provisioned?

**On-Demand (Recommended for dev):**
- ✅ No capacity planning
- ✅ Scales automatically
- ✅ Perfect for learning
- ❌ Slightly more expensive at high scale

**Provisioned:**
- ✅ Cheaper at predictable scale
- ❌ Need to forecast capacity
- ❌ Can throttle if exceeded

**Verdict**: Start on-demand, migrate to provisioned if costs rise

---

### Why These Specific GSIs?

**Each GSI supports a user query:**
- GSI1 → Browse/filter pages
- GSI2 → Vendor detail pages
- GSI3 → Recent updates feed
- GSI4 → Product adoption analysis

**Cost**: Each GSI doubles storage cost, but storage is cheap (~$0.25/GB)

---

## 📚 Next Steps (When Ready for Terraform)

1. **Review this schema** - Does it match your vision?
2. **Adjust if needed** - Add/remove fields based on requirements
3. **Create Terraform module** - DynamoDB table + GSIs
4. **Build migration script** - Parse markdown → JSON → DynamoDB
5. **Test with real data** - Populate from your research
6. **Build Lambda APIs** - Query the database
7. **Build frontend** - Display the data

---

## ❓ Questions for You

Before we proceed to Terraform:

1. **Is this schema structure clear?** Any confusion about single-table design?
2. **Are these the right access patterns?** Missing any queries you want to support?
3. **Should staff be in main table or separate?** (Currently in main table)
4. **Do you need regional partners?** Or skip for Phase 2?
5. **Any additional fields** from your research that should be captured?

**When you're ready**: Say "create the Terraform" and I'll build the DynamoDB module.

---

**Design Status**: ✅ Complete, ready for review  
**Next Phase**: Terraform module creation (awaiting your approval)
