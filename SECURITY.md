# Security Policy

## Reporting Vulnerabilities

If you discover a security vulnerability in this project, please report it by
emailing aws-security@amazon.com. Do not report security vulnerabilities
through public GitHub issues.

## Security Best Practices

This solution is provided as a sample pattern. Before deploying to production,
review and implement the following recommendations based on your requirements.

### Encryption

This pattern uses AWS-managed encryption (SSE-S3) for S3 buckets. For
production deployments handling sensitive data, consider using
customer-managed AWS KMS keys for S3 encryption to enable key rotation
control and CloudTrail audit logging of all encryption operations.

### Network Security

Lambda functions in this pattern run outside a VPC for simplicity. Production
deployments handling sensitive data should consider deploying Lambda functions
inside a VPC with VPC endpoints for all AWS services used (S3, DynamoDB, STS,
IAM, EventBridge, SQS). This prevents data from traversing the public internet.

### Input Validation

The sample pattern validates the `lifetime_hours` parameter. Production
deployments should add validation for all user-supplied fields including
email format validation for `requester_email` and length limits on
`description`.

### IAM Permissions

KMS key policies in this pattern grant administrative access to the root
account for break-glass scenarios. Production deployments should scope
these permissions to specific IAM roles used by your operations team.

### Audit Logging

The AuditLogBucket stores access logs for the CollaborationBucket. For
production deployments, consider adding a separate logging bucket for
audit log access logs to create a complete audit trail.

## Known Security Considerations

- Lambda functions are not deployed inside a VPC (acceptable for sample pattern)
- S3 buckets use SSE-S3 rather than customer-managed KMS keys
- API Gateway caching is not enabled (performance optimization, not security)

## Architecture Security

This solution implements the following security controls:
- All data encrypted at rest using AWS KMS and SSE-S3
- All data in transit protected by TLS (enforced via bucket/queue policies)
- API protected by AWS WAF with managed rule groups and rate limiting
- Access controlled via AWS IAM with SigV4 request signing
- Temporary scoped credentials generated per collaboration room
- Audit logging with 90-day retention
- Automatic resource cleanup via TTL and EventBridge scheduling
