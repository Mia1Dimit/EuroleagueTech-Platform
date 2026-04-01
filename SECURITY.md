# Security Policy

## Reporting Security Issues

**Do NOT open public GitHub issues for security vulnerabilities.**

If you discover a security vulnerability in EuroleagueTech Cloud Platform, please report it responsibly:

### Reporting Process

1. **Email the maintainers** with details (see GitHub profile for contact info)
2. **Include**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

3. **Response timeline**:
   - Acknowledge receipt within 48 hours
   - Provide initial assessment within 5-7 days
   - Work toward fix and disclosure timeline mutually agreed

### What to Expect

- We take security seriously and will investigate all reports
- We'll work with you to understand and fix the issue
- We'll credit security researchers (unless you prefer anonymity)
- We'll coordinate disclosure timing when possible

## Security Best Practices

When deploying EuroleagueTech Cloud Platform:

### AWS Account
- ✅ Enable MFA on root account
- ✅ Use IAM roles (never use root credentials)
- ✅ Enable CloudTrail logging
- ✅ Rotate access keys regularly
- ✅ Review and restrict S3 bucket policies

### Infrastructure
- ✅ Use `terraform.tfvars` (never commit to version control)
- ✅ Enable encryption at rest (DynamoDB, S3)
- ✅ Enable encryption in transit (TLS/HTTPS)
- ✅ Use least-privilege IAM policies
- ✅ Enable CloudWatch alarms for suspicious activity

### Secrets Management
- ✅ Store secrets in AWS Secrets Manager or Parameter Store
- ✅ Never hardcode credentials in source code
- ✅ Use environment variables for sensitive configuration
- ✅ Rotate credentials regularly

### API Security
- ⚠️ **Current State**: API is publicly accessible (no authentication)
- 📋 **Phase 3 Plan**: Implement API authentication (API keys or Cognito)
- 📋 **Phase 3 Plan**: Enable rate limiting and throttling
- 📋 **Phase 3 Plan**: Validate all inputs

### Frontend Security
- ⚠️ **Current Finding**: XSS vulnerabilities in HTML injection (see code-reviews/)
- 📋 **Remediation**: Implement output encoding for user data
- 📋 **Remediation**: Use CSP (Content Security Policy) headers

## Known Security Considerations

See [code-reviews/](code-reviews/) for principal-level security audit findings, including:

1. XSS vulnerabilities (output encoding needed)
2. API authentication gaps (no auth required)
3. CORS configuration (wildcard origins in dev)
4. IAM policy least-privilege issues
5. Data logging verbosity

Each finding includes remediation guidance. Phase 3 prioritizes addressing P0/P1 findings.

## Keeping Dependencies Secure

- Check for `npm audit` and `pip audit` regularly
- Keep Terraform providers updated
- Review AWS service security bulletins
- Subscribe to GitHub security alerts

---

Thank you for helping keep EuroleagueTech secure!
