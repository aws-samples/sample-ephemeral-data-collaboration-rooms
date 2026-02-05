#!/bin/bash

STACK_NAME="${1:-name_of_your_stack}"

if [ "$STACK_NAME" = "name_of_your_stack" ]; then
  echo "Usage: $0 <stack_name>"
  echo "Example: $0 my-collab-rooms"
  exit 1
fi

API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
  --output text)

curl -X POST ${API_ENDPOINT}/rooms \
  --aws-sigv4 "aws:amz:$(aws configure get region):execute-api" \
  --user "$(aws configure get aws_access_key_id):$(aws configure get aws_secret_access_key)" \
  -H "Content-Type: application/json" \
  -d '{
    "requester_email": "<email>",
    "lifetime_hours": 24,
    "description": "<description>"
  }' | jq .
