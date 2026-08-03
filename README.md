# EuroleagueTech Cloud Platform

A **knowledge hub and comparison platform for European sports technology**, built on **AWS serverless architecture** with real data from months of Euroleague basketball research.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Terraform Version](https://img.shields.io/badge/terraform-%3E%3D1.0-blue)](https://www.terraform.io/)
[![Python](https://img.shields.io/badge/python-3.9%2B-green)](https://www.python.org/)

---

## 🎯 What Is This?

A production-ready platform combining:

| Component | Purpose |
|-----------|---------|
| **Knowledge Hub** | Centralized database of European sports tech vendors (36+) and teams (20+)|
| **Comparison Tool** | Interactive side-by-side vendor comparisons (e.g., Catapult vs KINEXON) |
| **Research Foundation** | Structured data model for Euroleague sports analytics |

**Live Demo**: [Visit the platform](https://d3n25hf9bvh9rw.cloudfront.net)

---

## 🏗️ Architecture at a Glance

```
┌─────────────────────────────────────────────────────────────────┐
│                     FRONTEND (Static)                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  S3 Bucket (HTML/CSS/JS)  ←→  CloudFront CDN (Global)  │   │
│  └──────────────────────┬────────────────────────────────┘   │
└─────────────────────────┼─────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│                   API LAYER (Serverless)                        │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  API Gateway (HTTP v2)                                 │    │
│  │  Routes: /vendors, /vendors/{id}, /teams, /teams/{id}  │    │
│  └──────────────────────┬─────────────────────────────────┘    │
└─────────────────────────┼─────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│               COMPUTE & DATA LAYER (AWS)                        │
│  ┌───────────────────┐         ┌──────────────────────────┐    │
│  │  Lambda (Python)  │   ←→    │  DynamoDB Single-Table  │    │
│  │  - vendors_api    │         │  - 5 Global Secondary   │    │
│  │  - teams_api      │         │    Indexes              │    │
│  └───────────────────┘         └──────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

**Key Services**:
- **Frontend**: Static S3 website + CloudFront global CDN
- **API**: API Gateway HTTP API (cheap, modern)
- **Compute**: Lambda Python 3.12 (pay-per-invocation)
- **Data**: DynamoDB single-table design (pay-per-request)
- **Logging**: CloudWatch Logs (14-day retention) + X-Ray distributed tracing
- **Observability**: SNS alarms, CloudWatch dashboard, Lambda Powertools
- **IaC**: Terraform with 18 reusable modules

---

## 📊 Data Model

### Entities (56 items)
| Type | Count | Examples |
|------|-------|----------|
| Teams | 20 | Real Madrid, Barcelona, Anadolu Efes, Fenerbahe, etc. |
| Vendors | 36 | Catapult, KINEXON, WIMU PRO, Hawk-Eye, etc. |

### Relationships
- **Partnerships**: Which teams use which vendors (vendor adoption tracking)
- **Staff**: Coaches, analysts, managers per team
- **Products**: Specific tools/solutions offered by vendors

### Query Patterns (5 GSIs)
| GSI | Purpose | Example Query |
|-----|---------|---|
| **GSI1** | Category + Country | "All GPS vendors in Spain" |
| **GSI2** | Vendor client list | "Which teams use Catapult?" |
| **GSI3** | Status + timeline | "Partnerships confirmed in Q1 2026" |
| **GSI4** | Product usage | "Teams using KINEXON PERFORM" |
| **GSI5** | Team staff | "Coaches at Real Madrid" |

---

## 🚀 Quick Start

### Prerequisites
- **AWS Account** (free tier eligible for dev environment)
- **Git** (for version control)
- **Terraform** ≥ 1.0 (IaC)
- **AWS CLI** (for deployment verification)
- **Python** 3.9+ (for backend development)

### Deploy in 5 Minutes

```bash
# 1. Clone repository
git clone https://github.com/Mia1Dimit/EuroleagueTech-Platform.git
cd EuroleagueTech-Cloud-Platform

# 2. Configure AWS credentials
aws configure
# ✔ AWS Access Key ID: [YOUR_KEY]
# ✔ AWS Secret Access Key: [YOUR_KEY]
# ✔ Default region: eu-west-1 (Ireland)

# 3. Set up infrastructure
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# ✔ Edit terraform.tfvars with your S3 bucket names 

terraform init -backend-config=backend-config-dev.tfvars
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars

# 4. Deploy frontend
# ✔ Terraform automatically uploads HTML/CSS/JS to S3
# ✔ CloudFront CDN distribution is created

# 5. Test API
curl https://your-api-endpoint.execute-api.eu-west-1.amazonaws.com/dev/vendors
# ✔ Response: List of 36 vendors in JSON

# 6. Access frontend
# ✔ Navigate to CloudFront distribution URL or S3 website endpoint
# ✔ Browse vendors and teams with filtering
```

**Deployment cost**: ~$0.09/month (within $20 target) ✅

---

## 📁 Project Structure

```
EuroleagueTech-Cloud-Platform/
├── README.md                          # This file
├── LICENSE                            # MIT License
├── CONTRIBUTING.md                    # How to contribute
├── CODE_OF_CONDUCT.md                 # Community standards
├── SECURITY.md                        # Security policy
├── CHANGELOG.md                       # Version history
│
├── frontend/                          # Static website
│   ├── index.html                    # Home page
│   ├── vendors.html                  # Vendor discovery + filters
│   ├── teams.html                    # Team discovery + country filter
│   ├── about.html                    # Platform info + roadmap
│   └── assets/
│       ├── css/                      # Styling
│       └── js/                       # Vanilla DOM manipulation
│
├── backend/                           # Lambda functions
│   ├── README.md                     # Backend docs
│   ├── requirements.txt              # Python dependencies
│   └── src/
│       ├── handlers/                 # API endpoints
│       │   ├── vendors_api.py        # GET /vendors
│       │   └── teams_api.py          # GET /teams
│       └── utils/
│           ├── response.py           # Response formatting + CORS
│           └── dynamodb.py           # Query helpers
│
├── modules/                           # 18 reusable Terraform modules
│   ├── dynamodb/
│   ├── lambda-function/
│   ├── api-gatewayv2-api/
│   ├── s3-bucket/
│   ├── cloudfront/
│   ├── cloudwatch-alarm/
│   ├── cloudwatch-dashboard/
│   ├── sns-topic/
│   └── [10 more modules...]
│
├── infrastructure/                    # Terraform IaC
│   ├── README.md                     # Deployment guide
│   ├── *.tf                          # Terraform config files
│   └── data/                         # IAM policy templates (templatefile)
│
├── data-migration/                    # Migration utilities
│   ├── upload_to_dynamodb.py         # Batch upload script
│   └── output/
│       ├── teams.json                # 20 teams
│       └── vendors.json              # 36 vendors
│
├── docs/                              # Technical documentation
│   ├── ARCHITECTURE.md               # Full design + WAF alignment
│   └── DYNAMODB-SCHEMA-DESIGN.md     # Single-table pattern
│
├── code-reviews/                      # Security audits
│   └── 2026-03-30-security-audit.md  # Principal-level findings
│
└── .gitignore                         # Git exclusions (secure)
```

---

## 🔐 Security & Privacy

### Current State
- ✅ No hardcoded secrets (static IAM credentials via GitHub Secrets)
- ✅ Encryption at rest (DynamoDB, S3)
- ✅ Encryption in transit (TLS/HTTPS via CloudFront)
- ✅ XSS remediated: escapeHtml + safeHref on all frontend API output (v0.3.0)
- ✅ CORS scoped to CloudFront origin (no wildcard `*`)
- ✅ Raw event logging removed from Lambda handlers
- ✅ IAM policies ARN-scoped to account + region via templatefile()
- ⚠️ **Public API** (no authentication — planned)

### Security Audit
See [code-reviews/](code-reviews/) for principal-level audit findings:
- 11 findings catalogued (severity: Critical → Low)
- P0/P1 XSS findings remediated in v0.3.0
- Remaining: API authentication, WAF

### Responsible Disclosure
🔒 Found a vulnerability? See [SECURITY.md](SECURITY.md) for reporting.

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Full system design, all 6 AWS WAF pillars |
| [DYNAMODB-SCHEMA-DESIGN.md](docs/DYNAMODB-SCHEMA-DESIGN.md) | Single-table pattern, query design |
| [backend/README.md](backend/README.md) | Lambda handler docs, testing |
| [infrastructure/README.md](infrastructure/README.md) | Terraform deployment guide |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute code |
| [code-reviews/](code-reviews/) | Security findings + remediation |

---

## 🛠️ Development

### Local Setup

```bash
# Set up backend environment
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Test backend locally
python -c "from handlers.vendors_api import lambda_handler; print(lambda_handler({}, None))"

# Set up frontend locally
# Option 1: Use Python HTTP server
cd ../frontend
python -m http.server 8000
# Visit http://localhost:8000

# Option 2: Use Node.js http-server (if installed)
npm install -g http-server
http-server .
```

### Testing

```bash
# Backend tests
cd backend
pytest  # (after adding test files)

# Terraform validation
cd infrastructure
terraform validate
terraform plan -var-file=terraform.tfvars

# Frontend smoke test
# Visit each HTML page and verify filters work:
# - /vendors.html (category filter)
# - /teams.html (country filter)
# - /about.html (roadmap visible)
```

---

## 📈 Performance & Cost

### AWS Billing Estimate (Monthly)
| Service | Cost | Notes |
|---------|------|-------|
| **DynamoDB** | ~$0.02 | Pay-per-request, 56 items |
| **Lambda** | ~$0.01 | ~1000 invocations/month |
| **API Gateway** | ~$0.03 | HTTP API (cheaper than REST) |
| **CloudFront** | ~$0.02 | Edge caching, low traffic |
| **S3** | <$0.01 | Static website, small size |
| **Total** | **~$0.09** | ✅ Well under $20 target |

### Performance Targets
- **API Latency**: <100ms (DynamoDB query)
- **Frontend Load**: <2s (CDN + CloudFront compression)
- **Availability**: 99.95% (AWS SLA)

---

## 🎓 Learning Value

This project demonstrates:

### Cloud Architecture
- ✅ Serverless patterns (Lambda, DynamoDB, API Gateway)
- ✅ Single-table DynamoDB design
- ✅ Global content delivery (CloudFront CDN)
- ✅ Infrastructure as Code (Terraform)
- ✅ AWS Well-Architected Framework alignment

### DevOps & Platform Engineering
- ✅ Reusable Terraform modules (18+, private registry pattern)
- ✅ Environment config management (dev.tfvars pattern)
- ✅ Least-privilege IAM, ARN-scoped policies via templatefile()
- ✅ CloudWatch alarms + dashboard + SNS alerts
- ✅ Lambda Powertools: structured JSON logging + X-Ray tracing
- ✅ CI/CD: GitHub Actions workflows (Terraform plan/apply, Lambda deploy, S3 sync)

### Software Engineering
- ✅ API design patterns (REST endpoints)
- ✅ Data model design (single-table nosql)
- ✅ Frontend static site generation
- ✅ Security code review walkthrough

---

## 🗺️ Roadmap

### v0.1–v0.2 ✅ (Complete)
- ✅ Infrastructure deployment (Terraform, 18 modules)
- ✅ Backend Lambda endpoints (Python 3.12)
- ✅ DynamoDB single-table (20 teams + 36 vendors, 5 GSIs)
- ✅ Frontend static pages (4 HTML pages, broadcast design system)
- ✅ API integration end-to-end
- ✅ Security code review (11 findings catalogued)

### v0.3.0 ✅ (PE Hardening — Complete)
- ✅ XSS remediated on all three frontend JS files
- ✅ CORS scoped to CloudFront origin (env var, no wildcard)
- ✅ Raw event logging removed from Lambda handlers
- ✅ Lambda Powertools: structured JSON logging + X-Ray tracing
- ✅ IAM policies ARN-scoped via templatefile() (no wildcards)
- ✅ CloudWatch alarms: API 5XX, Lambda errors per function
- ✅ SNS alert topic for alarm fan-out
- ✅ CloudWatch operational dashboard (6 widgets)
- ✅ Log retention raised to 14 days
- ✅ GitHub Actions: Terraform plan/apply, Lambda deploy, S3 sync

### Next
- 📋 API authentication (Cognito or API keys)
- 📋 CloudFront WAF Web ACL + rate-based rules
- 📋 Vendor comparison feature (multi-select UI)
- 📋 React migration (from static HTML)

---

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- 🔧 Development setup
- 📋 How to report bugs
- 🎯 Feature request process
- 👥 Code review standards
- 📖 How to keep docs current

**Code of Conduct**: See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

---

## 📄 License

This project is licensed under the **MIT License** - see [LICENSE](LICENSE) for details.

---

## 🙋 Questions?

- 📖 **Getting Started**: Check [Quick Start](#-quick-start) section
- ⚙️ **Deployment Issues**: See [infrastructure/README.md](infrastructure/README.md)
- 🐛 **Found a Bug**: [Open an issue](https://github.com/YOUR_USERNAME/EuroleagueTech-Cloud-Platform/issues)
- 💡 **Have an Idea**: [Start a discussion](https://github.com/YOUR_USERNAME/EuroleagueTech-Cloud-Platform/discussions)
- 🔒 **Security Concern**: See [SECURITY.md](SECURITY.md)

---

## 🙏 Acknowledgments

- **AWS**: For serverless architecture services
- **Euroleague**: For inspiration from European basketball excellence
- **Community**: For feedback and contributions

---

**Made with ❤️ for the sports tech community**

[⬆ Back to top](#euroleaguetech-cloud-platform)
