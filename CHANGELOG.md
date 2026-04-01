# Changelog

All notable changes to EuroleagueTech Cloud Platform are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-03-31

### Added
- ✅ Static frontend deployment (4 pages: home, vendors, teams, about)
- ✅ Category-based filtering for vendors and teams
- ✅ Modal detail views for single vendor/team exploration
- ✅ CloudFront CDN distribution for frontend
- ✅ 56 data items (20 teams + 36 vendors) initial upload
- ✅ DynamoDB refresh with corrected metadata
- ✅ Principal-level security code review (11 findings catalogued)
- ✅ Architecture documentation and schema design guide

### Fixed
- ✅ Category normalization across frontend/backend/API
- ✅ Data migration accuracy (100% manual verification)
- ✅ Frontend integration endpoints verified end-to-end

### Changed
- Updated About page with current platform roadmap

### Docs
- Added DYNAMODB-SCHEMA-DESIGN.md (single-table pattern explained)
- Enhanced ARCHITECTURE.md with all 6 WAF pillars

---

## [0.1.0] - 2026-03-23

### Added
- ✅ Infrastructure as Code setup (Terraform + AWS)
- ✅ Serverless backend (2 Lambda handlers: vendors_api, teams_api)
- ✅ DynamoDB single-table design with 5 GSIs
- ✅ API Gateway HTTP API (4 routes: GET /vendors, /vendors/{id}, /teams, /teams/{id})
- ✅ S3 buckets for frontend, data, logs
- ✅ CloudWatch logging and monitoring
- ✅ IAM roles with least-privilege policies
- ✅ 15 reusable Terraform modules (api-gateway, dynamodb, lambda, s3, etc.)
- ✅ Backend utility modules (response.py, dynamodb.py)
- ✅ Data migration framework (Python + boto3)
- ✅ Static frontend foundation (HTML/CSS/JavaScript)

### Infrastructure Highlights
- Region: eu-west-1 (Ireland)
- Billing: Pay-per-request (cost-optimized)
- Estimated cost: ~$0.09/month (within $20 target)
- 15+ AWS services integrated
- 100% Infrastructure as Code

---

## Planned for Next Phases

### Phase 3 (Vendor Comparison Feature) - Q2 2026
- [ ] Vendor comparison endpoint (GET /compare?vendors=id1,id2,id3)
- [ ] Multi-select UI for comparison
- [ ] Side-by-side comparison view
- [ ] Advanced filtering and sorting

### Phase 3 (Hardening - Security) - Parallel Track
- [ ] XSS output encoding (HTML escaping)
- [ ] API authentication (Cognito or API keys)
- [ ] Rate limiting and throttling
- [ ] IAM least-privilege tightening
- [ ] Query-based DynamoDB access patterns (replace scans)

### Phase 4 (Scale & Analytics) - Q3 2026
- [ ] React migration (from static HTML)
- [ ] ECS Fargate backend (optional, if scaling needed)
- [ ] Analytics dashboard (Athena + QuickSight)
- [ ] CI/CD pipeline (GitHub Actions)

### Phase 5 (Community) - Q4 2026
- [ ] Open source release
- [ ] Contributing guidelines
- [ ] Community-driven features
- [ ] Performance benchmarks

---

## Version Support Policy

- **Latest (0.2.0)**: Current release, fully supported
- **0.1.0**: Maintenance mode, critical fixes only
- Older versions: Not supported

---

## Security Updates

See [SECURITY.md](SECURITY.md) for security disclosure policy and known issues.

---

## Questions?

- 📖 Check [README.md](README.md) for overview
- 📚 See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for technical details
- 🐛 Open an issue for bugs
- 💬 Start a discussion for questions
