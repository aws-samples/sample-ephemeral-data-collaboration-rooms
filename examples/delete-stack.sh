#!/bin/bash
set -e

STACK_NAME="${1:-name_of_your_stack}"

if [ "$STACK_NAME" = "name_of_your_stack" ]; then
  echo "Usage: $0 <stack_name>"
  echo "Example: $0 my-collab-rooms"
  exit 1
fi

echo "⚠️  Deleting stack: $STACK_NAME"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs[?OutputKey==`CollaborationBucketName`].OutputValue' \
  --output text 2>/dev/null || echo "")

if [ -n "$BUCKET_NAME" ]; then
  echo "🗑️  Emptying bucket: $BUCKET_NAME"
  aws s3 rm s3://$BUCKET_NAME --recursive
  aws s3 rm s3://${BUCKET_NAME}-audit-logs --recursive
fi

echo "🗑️  Deleting CloudFormation stack..."
aws cloudformation delete-stack --stack-name $STACK_NAME

echo "⏳ Waiting for deletion..."
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME

echo "✅ Stack deleted successfully!"
