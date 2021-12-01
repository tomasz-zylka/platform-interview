#!/usr/bin/env bash

 echo "configuring dynamodb"
 echo "==================="
 
# Local Users table
awslocal dynamodb create-table \
  --table-name test_Users \
  --key-schema AttributeName=username,KeyType=HASH \
  --attribute-definitions AttributeName=username,AttributeType=S \
  --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10 \
  --region eu-central-1

# Local Messages table
awslocal dynamodb create-table \
  --table-name test_Messages \
  --key-schema AttributeName=room,KeyType=HASH AttributeName=message,KeyType=RANGE \
  --attribute-definitions AttributeName=room,AttributeType=S AttributeName=message,AttributeType=S \
  --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10 \
  --region eu-central-1
