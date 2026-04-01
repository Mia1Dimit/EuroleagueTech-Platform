# Code Review - 30/03/2026

## Executive Summary
This principal-level code review covered frontend, backend, infrastructure, and cloud integrations for the current SportsTech Cloud Platform setup. The architecture is solid for an MVP serverless stack (CloudFront + S3 + API Gateway + Lambda + DynamoDB), and recent category-normalization work improved functional correctness.

The most important gaps are in security hardening, operational guardrails, and long-term maintainability. In particular, unsanitized HTML rendering in the frontend creates an XSS risk, API exposure is currently fully public with permissive CORS, and several infrastructure settings are still in dev-mode posture.

Overall assessment: strong foundational architecture, but not yet production-hardened.

## Findings (11 Points)

### 1. Critical - Frontend XSS risk from unsanitized HTML injection
The frontend renders API-provided fields directly into `innerHTML` templates without sanitization. If a DynamoDB record is poisoned, JavaScript could execute in end-user browsers.

### 2. High - API is fully public with no authentication and no explicit throttling limits
All API routes are configured with `authorization_type = "NONE"`, and stage route settings do not define explicit throttling values. This increases abuse and cost-exhaustion risk.

### 3. High - Overly permissive CORS policy in backend responses
Lambda responses return `Access-Control-Allow-Origin: *` for all requests. This is acceptable for fully public APIs but not ideal for frontend-restricted production patterns.

### 4. Medium - S3 public access block posture is too relaxed for OAC-based CloudFront
The frontend bucket settings include `blockpublicpolicy = false`, `ignorepublicacls = false`, and `restrictpublicbuckets = false`. With OAC, stricter settings are preferred to reduce accidental exposure.

### 5. Medium - IAM permissions broader than least privilege
DynamoDB IAM policy uses account wildcard in ARNs (`eu-west-1:*`) instead of scoping to the specific account ID. This weakens least-privilege posture.

### 6. Medium - Backend list APIs rely on DynamoDB Scan operations
`/vendors` and `/teams` list behavior uses table scans with filters. This is acceptable at current scale but can become expensive and slower as data grows.

### 7. Medium - Logging configuration may expose request details and increase cost
Lambda handlers print full incoming event objects, and API stage has `data_trace_enabled = true`. This can produce noisy logs, increase cost, and potentially expose request metadata.

### 8. Medium - Terraform drift risk from Lambda lifecycle ignore settings
Lambda module includes `lifecycle { ignore_changes = [timeout, image_uri] }`. Timeout changes can be silently ignored and drift from intended IaC state.

### 9. Medium - Frontend data contract inconsistency across pages
The vendors page now supports `Categories[]` normalization, but the homepage still references `PrimaryCategory`. This mismatch can cause inconsistent UX and regressions.

### 10. Low - API base URL is hardcoded in multiple frontend files
The API endpoint is duplicated in `home.js`, `teams.js`, and `vendors.js`, making environment management harder (dev/stage/prod separation).

### 11. Low - Missing automated tests and CI workflows
No test suite or CI workflow was identified for frontend/backend/infrastructure validation. This increases regression risk for future changes.

## Recommended Next Step
Create a prioritized remediation backlog (P0/P1/P2) and implement hardening in this order:
1. XSS mitigation and output encoding
2. API auth/throttling/CORS tightening
3. IAM/S3 least-privilege hardening
4. Query-based DynamoDB access patterns
5. CI + automated integration tests
