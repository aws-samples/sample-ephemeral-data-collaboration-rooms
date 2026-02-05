#!/bin/bash
set -e

STACK_NAME="${1:-name_of_your_stack}"
TEMPLATE_FILE="ephemeral-collaboration-rooms.yaml"
BUCKET_NAME="${2:-name_of_your_bucket-$(aws sts get-caller-identity --query Account --output text)}"

if [ "$STACK_NAME" = "name_of_your_stack" ]; then
  echo "Usage: $0 <stack_name> [bucket_name]"
  echo "Example: $0 my-collab-rooms my-bucket"
  exit 1
fi

echo "🚀 Deploying Ephemeral Collaboration Rooms..."

aws cloudformation deploy \
  --stack-name $STACK_NAME \
  --template-file $TEMPLATE_FILE \
  --parameter-overrides \
    CollaborationBucketName=$BUCKET_NAME \
    DefaultRoomLifetimeHours=24 \
    MaxCredentialDurationHours=12 \
  --capabilities CAPABILITY_IAM \
  --no-fail-on-empty-changeset

echo "✅ Deployment complete!"
echo ""
echo "API Endpoint:"
aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
  --output text
