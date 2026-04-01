# Backend API Documentation

Python Lambda handlers for the EuroleagueTech Cloud Platform.

---

## 🏗️ Architecture

```
AWS Lambda (Python 3.9)
├── vendors_api.py
│   └── lambda_handler(event, context)
│       ├── GET /vendors → Returns all 36 vendors
│       └── GET /vendors/{vendorId} → Returns single vendor detail
│
└── teams_api.py
    └── lambda_handler(event, context)
        ├── GET /teams → Returns all 20 teams
        └── GET /teams/{teamId} → Returns single team detail
```

---

## 📋 Handler Specifications

### Vendors API (`handlers/vendors_api.py`)

**GET /vendors**
```python
# Request
GET /vendors
# Response
{
  "statusCode": 200,
  "body": [
    {
      "VendorID": "CATAPULT",
      "Name": "Catapult Sports",
      "Categories": ["GPS", "Performance Analytics"],
      "Country": "Australia",
      ...
    },
    ...  # 36 total vendors
  ]
}
```

**GET /vendors/{vendorId}**
```python
# Request
GET /vendors/CATAPULT
# Response
{
  "statusCode": 200,
  "body": {
    "VendorID": "CATAPULT",
    "Name": "Catapult Sports",
    "Headquarters": "Melbourne, Australia",
    "Founded": 2006,
    "Categories": ["GPS", "Performance Analytics"],
    "WebsiteURL": "https://www.catapultsports.com",
    "Teams": ["Real Madrid", "Barcelona", ...],  # Teams using this vendor
    ...
  }
}
```

### Teams API (`handlers/teams_api.py`)

**GET /teams**
```python
# Request
GET /teams
# Response
{
  "statusCode": 200,
  "body": [
    {
      "TeamID": "REAL_MADRID",
      "Name": "Real Madrid Basketball",
      "League": "Euroleague",
      "Country": "Spain",
      ...
    },
    ...  # 20 total teams
  ]
}
```

**GET /teams/{teamId}**
```python
# Request
GET /teams/REAL_MADRID
# Response
{
  "statusCode": 200,
  "body": {
    "TeamID": "REAL_MADRID",
    "Name": "Real Madrid Basketball",
    "Headquarters": "Madrid, Spain",
    "Founded": 1911,
    "CoachName": "Chus Mateo",
    "Vendors": ["Catapult", "KINEXON", ...],  # Vendors used by this team
    "Staff": [
      { "StaffID": "COACH_001", "Name": "Chus Mateo", "Role": "Head Coach" },
      ...
    ],
    ...
  }
}
```

---

## 🔧 Utility Modules

### `utils/response.py`

Handles HTTP response formatting and CORS headers.

```python
from utils.response import format_response

# Successful response
response = format_response(
    status_code=200,
    body=data,
    is_json=True
)
# Returns:
# {
#   "statusCode": 200,
#   "headers": {
#     "Access-Control-Allow-Origin": "*",
#     "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE",
#     "Content-Type": "application/json"
#   },
#   "body": "[JSON string]"
# }

# Error response
response = format_response(
    status_code=400,
    body={"error": "Bad request"},
    is_json=True
)
```

**CORS Notes** (⚠️ Current State - Phase 3 to harden):
- Currently uses wildcard CORS: `Access-Control-Allow-Origin: *`
- Production should restrict to specific domains
- Security findings documented in [code-reviews/](../code-reviews/)

### `utils/dynamodb.py`

DynamoDB query operations.

```python
from utils.dynamodb import get_item, scan_items, query_by_gsi

# Get single item
vendor = get_item(
    table_name="spotech-dev-main",
    pk="VENDOR#CATAPULT",
    sk="METADATA"
)

# Scan all vendors
vendors = scan_items(
    table_name="spotech-dev-main",
    filter_expression="begins_with(PK, :prefix)",
    expression_values={":prefix": "VENDOR#"}
)

# Query by GSI (e.g., teams using vendor)
teams = query_by_gsi(
    table_name="spotech-dev-main",
    gsi_name="GSI2",
    pk_name="GSI2PK",
    pk_value="VENDOR#CATAPULT",
    sk_name="GSI2SK"
)
```

---

## 🧪 Testing

### Local Testing

```bash
# Activate virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Test vendors handler
python -c "
from handlers.vendors_api import lambda_handler
event = {'requestContext': {'http': {'method': 'GET', 'path': '/vendors'}}}
response = lambda_handler(event, None)
print(response)
"

# Test teams handler
python -c "
from handlers.teams_api import lambda_handler
event = {'requestContext': {'http': {'method': 'GET', 'path': '/teams'}}}
response = lambda_handler(event, None)
print(response)
"
```

### Unit Tests (Phase 3)

```bash
# Run pytest
pytest tests/

# With coverage
pytest --cov=handlers --cov=utils tests/
```

---

## 📦 Dependencies

See `requirements.txt`:

```
AWS SDK (boto3)
  - Provides DynamoDB access
  - No additional Python dependencies

Environment Variables (set by Lambda execution role):
  - DYNAMODB_TABLE_NAME: "spotech-dev-main"
```

---

## 🚀 Deployment

### Build & Package

```bash
# Zip Lambda code
cd backend/src
zip -r ../lambda-package.zip handlers/ utils/ *.py

# Upload to AWS (Terraform handles this)
terraform apply -var-file=dev.tfvars
```

### Via Terraform

```bash
cd infrastructure
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Terraform automatically:
1. ✅ Packages backend code
2. ✅ Uploads to Lambda
3. ✅ Sets environment variables
4. ✅ Configures IAM permissions
5. ✅ Wires API Gateway routes

---

## 📊 Performance & Cost

| Metric | Value | Notes |
|--------|-------|-------|
| **Memory** | 256 MB | Sufficient for data lookups |
| **Timeout** | 10 seconds | Comfortable for DynamoDB queries |
| **Estimated Invocations** | ~1000/month | Typical dev environment load |
| **Cost** | ~$0.01/month | Well under budget |

### Optimization Opportunities (Phase 3)

```python
# ⚠️ Current: Uses scan() for list operations - expensive at scale
vendors = scan_items(table_name, filter_expression)

# ✅ Better: Use query() with GSI when possible
vendors = query_by_gsi(table_name, gsi_name="GSI1", ...)
```

---

## 🔐 Security Notes

### Current State
- ✅ No hardcoded credentials (uses IAM Lambda execution role)
- ✅ No SQL injection (DynamoDB is NoSQL)
- ✅ No business logic secrets

### Areas for Phase 3 Hardening
- ⚠️ XSS vulnerabilities in frontend (for data returned to browser)
- ⚠️ NO API authentication (should add API keys or Cognito)
- ⚠️ NO rate limiting
- 📋 See [SECURITY.md](../SECURITY.md) for full findings

---

## 📚 DynamoDB Schema

Reference: [DYNAMODB-SCHEMA-DESIGN.md](../docs/DYNAMODB-SCHEMA-DESIGN.md)

Single-table design with:
- **PK**: Entity type + ID (e.g., `VENDOR#CATAPULT`)
- **SK**: Entity metadata or relationship key
- **5 GSIs**: Enable different query patterns

---

## 🤝 Contributing

- Follow PEP 8 style guide
- Include docstrings on all functions
- Test locally before committing
- Document any new endpoints

See [CONTRIBUTING.md](../CONTRIBUTING.md) for full guidelines.

---

## 🔗 Related Documentation

- [API Endpoints](../infrastructure/README.md#api-routes)
- [DynamoDB Schema](../docs/DYNAMODB-SCHEMA-DESIGN.md)
- [Security Code Review](../code-reviews/)
- [Architecture](../docs/ARCHITECTURE.md)

---

**Last Updated**: March 31, 2026  
**Status**: Production-Ready (Phase 2) → Phase 3 enhancements incoming
