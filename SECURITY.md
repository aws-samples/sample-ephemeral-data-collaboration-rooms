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

## Limitations

### IAM role quota and propagation latency

Each collaboration room provisions a dedicated `CollaborationRoom-<room_id>` IAM role with an
inline `RoomAccessPolicy`. These roles count against the account's IAM roles quota, which defaults
to **1,000 roles per account**. High room-creation churn can exhaust this quota; for high-volume
deployments, request a quota increase or move to a shared-role design (for example, a single role
scoped per request via a session policy, or S3 Access Grants — see below).

Newly created IAM roles are not immediately usable for `sts:AssumeRole` because role creation
propagates asynchronously across IAM. The create path absorbs this with a **10-attempt retry loop**
(2-second backoff) around `assume_role`, so callers should expect occasional multi-second latency on
the first room created after a cold start.

### Credential revocability

STS session credentials issued for a room expire automatically at the end of their duration
(bounded by `MaxCredentialDurationHours`, default 12 hours). They can also be revoked **before**
natural expiry if needed:

- Attach an inline deny policy to the per-room role using a token-issue-time condition
  (`aws:TokenIssueTime` with `DateLessThan`), the `AWSRevokeOlderSessions` pattern, to invalidate
  already-issued sessions.
- Delete the per-room role outright, which immediately stops any active session from being used.

The cleanup Lambda deletes the per-room role on expiry, so credentials cannot outlive the room.

### Identity-scoped S3 access alternative

This pattern grants room access via per-room IAM roles plus STS credentials. For deployments where
the IAM role quota or per-room role management is a concern, **Amazon S3 Access Grants** is an
alternative: it maps identities (IAM principals or directory identities) to time-bound,
prefix-scoped S3 permissions without minting a new IAM role per room.

### Automatic cleanup

Room cleanup is scheduled with **Amazon EventBridge Scheduler** using a one-time `at()` schedule
that fires once at the room's expiration and deletes itself afterward
(`ActionAfterCompletion='DELETE'`). The cleanup Lambda removes the room's S3 objects, marks the
DynamoDB metadata as `Deleted`, deletes the per-room IAM role and inline policy, and deletes the
schedule — so neither IAM roles nor schedules accumulate across room lifecycles.

## Architecture Security

This solution implements the following security controls:
- All data encrypted at rest using AWS KMS and SSE-S3
- All data in transit protected by TLS (enforced via bucket/queue policies)
- API protected by AWS WAF with managed rule groups and rate limiting
- Access controlled via AWS IAM with SigV4 request signing
- Temporary scoped credentials generated per collaboration room
- Audit logging with 90-day retention
- Automatic resource cleanup via TTL and EventBridge scheduling
