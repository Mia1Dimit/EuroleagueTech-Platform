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
- 📋 **Next Phase Plan**: Implement API authentication (API keys or Cognito)
- 📋 **Next Phase Plan**: Enable rate limiting and throttling
- 📋 **Next Phase Plan**: Expand request validation coverage

### Frontend Security
- ✅ **Current State**: XSS output-encoding remediations are in place
- 📋 **Ongoing**: Keep output encoding and safe URL handling in all new UI code
- 📋 **Remediation**: Use CSP (Content Security Policy) headers

## Known Security Considerations

See [code-reviews/](code-reviews/) for principal-level security audit findings, including:

1. API authentication gaps (no auth required)
2. Rate limiting and abuse protections
3. CSP/security header hardening
4. IAM policy least-privilege maintenance
5. Data logging verbosity controls

Each finding includes remediation guidance. Keep the code-reviews folder as the source of truth for historical findings and closure notes.

## Keeping Dependencies Secure

- Check for `npm audit` and `pip audit` regularly
- Keep Terraform providers updated
- Review AWS service security bulletins
- Subscribe to GitHub security alerts

---

Thank you for helping keep EuroleagueTech secure!
