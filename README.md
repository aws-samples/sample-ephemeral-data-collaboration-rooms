# Ephemeral Collaboration Rooms

Automated time-bound secure data sharing infrastructure on AWS.

## Overview

This project provides a secure, ephemeral data collaboration system using AWS services. It creates temporary "rooms" with time-limited access credentials for secure data sharing.

## Architecture

- **S3**: Stores collaboration room data with encryption and versioning
- **DynamoDB**: Tracks room metadata (table: `CollaborationRoomMetadata`)
- **Lambda**: Manages room creation (`CreateCollaborationRoom`) and cleanup (`CleanupCollaborationRoom`)
- **API Gateway**: RESTful API (`CollaborationRoomsAPI`) for room management
- **EventBridge**: Schedules automatic room cleanup
- **IAM**: Generates temporary credentials with scoped permissions

## Prerequisites

- AWS CLI configured with appropriate credentials
- AWS account with permissions to create CloudFormation stacks
- Bash shell (for deployment scripts)

## Deployment

1. Deploy the CloudFormation stack:
```bash
cd examples
./deploy.sh <stack_name> [bucket_name]
```

Example:
```bash
./deploy.sh my-collab-stack my-collab-bucket
```

If bucket name is not provided, it defaults to `name_of_your_bucket-<account_id>`

2. Verify the deployment:
```bash
./verify-stack.sh <stack_name>
```

## Usage

Create a new collaboration room:
```bash
./create-room.sh <stack_name>
```

Or use curl directly:
```bash
curl -X POST https://<api-endpoint>/prod/rooms \
  --aws-sigv4 "aws:amz:<region>:execute-api" \
  --user "<access_key>:<secret_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "requester_email": "user@example.com",
    "lifetime_hours": 24,
    "description": "Project collaboration"
  }'
```

Upload files to a room:
```bash
python3 upload-file.py <access_key> <secret_key> <session_token> <file_path>
```

## Resource Names

**User-defined (dynamic):**
- Stack name (provided during deployment)
- S3 bucket name (provided during deployment)

**Fixed (hardcoded):**
- DynamoDB table: `CollaborationRoomMetadata`
- Lambda functions: `CreateCollaborationRoom`, `CleanupCollaborationRoom`
- API Gateway: `CollaborationRoomsAPI`
- IAM roles (per room): `CollaborationRoom-<room_id>`
- EventBridge rules (per room): `CollaborationRoom-Cleanup-<room_id>`

## Configuration

Default parameters in CloudFormation template:
- `DefaultRoomLifetimeHours`: 24 hours (1-168)
- `MaxCredentialDurationHours`: 12 hours (1-12)

## Cleanup

Delete the stack:
```bash
./delete-stack.sh <stack_name>
```

## Security Features

- Server-side encryption (AES256)
- S3 versioning and object lock
- Public access blocked
- Audit logging (90-day retention)
- Temporary IAM credentials
- Automatic cleanup via TTL and EventBridge

