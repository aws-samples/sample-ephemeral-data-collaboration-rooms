#!/bin/bash

STACK_NAME="${1:-name_of_your_stack}"
REGION="${2:-us-east-1}"

if [ "$STACK_NAME" = "name_of_your_stack" ]; then
  echo "Usage: $0 <stack_name> [region]"
  echo "Example: $0 my-collab-rooms us-east-1"
  exit 1
fi

BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`CollaborationBucketName`].OutputValue' --output text 2>/dev/null)

if [ -z "$BUCKET_NAME" ]; then
  echo "Error: Could not retrieve bucket name from stack $STACK_NAME in region $REGION"
  exit 1
fi

echo "=== 1. S3 BUCKETS ==="
aws s3 ls | grep "$BUCKET_NAME"
echo "Encryption: $(aws s3api get-bucket-encryption --bucket $BUCKET_NAME 2>&1 | grep -q 'AES256' && echo 'Enabled' || echo '❌ Not found')"
echo "Versioning: $(aws s3api get-bucket-versioning --bucket $BUCKET_NAME --query 'Status' --output text)"

echo -e "\n=== 2. LAMBDA FUNCTIONS ==="
aws lambda list-functions --query 'Functions[?contains(FunctionName, `Collaboration`)].FunctionName' --output table

echo "=== 3. DYNAMODB TABLE ==="
TABLE_NAME=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`RoomMetadataTableName`].OutputValue' --output text)
if [ -n "$TABLE_NAME" ]; then
  aws dynamodb describe-table --table-name $TABLE_NAME --region $REGION --query 'Table.[TableName,TableStatus]' --output table
  aws dynamodb describe-time-to-live --table-name $TABLE_NAME --region $REGION --query 'TimeToLiveDescription.TimeToLiveStatus' --output text
fi

echo -e "\n=== 4. API GATEWAY ==="
aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' --output text

echo -e "\n=== 5. CLOUDWATCH LOG GROUPS ==="
aws logs describe-log-groups --query 'logGroups[?contains(logGroupName, `apigateway`) || contains(logGroupName, `Collaboration`)].logGroupName' --output table

echo -e "\nVerification complete!"
