---
name: aws
description: AWS infrastructure with ECS/EKS, RDS, ElastiCache, SQS, S3, IAM, VPC, CloudWatch. Least-privilege IAM, private subnets, infrastructure as code.
---
# AWS

**Scope:** ECS/EKS, RDS, ElastiCache, SQS, S3, IAM, VPC, CloudWatch.

## Rules
- Least-privilege IAM policies — no `*` resources in production
- VPC with private subnets for databases and services
- CloudWatch alarms on key metrics, not just logs
- Infrastructure as code (Terraform/CDK) — no console-only changes

## IAM
- One role per service/function
- Condition keys to restrict by source VPC, account, or tag
- Audit with Access Analyzer
- MFA on root and admin accounts

## Networking
- Private subnets for data stores and internal services
- Public subnets only for load balancers
- VPC endpoints for S3, DynamoDB, ECR
- Security groups as allowlists, not denylists

## Data
- Encryption at rest for all storage (RDS, S3, EBS)
- Encryption in transit (TLS everywhere)
- Backup retention policies on RDS
- S3 bucket policies — no public access by default

## Monitoring
- CloudWatch alarms for CPU, memory, disk, queue depth
- X-Ray or OpenTelemetry for distributed tracing
- Cost alerts on billing
