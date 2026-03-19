# PacerPro Platform Engineer Test - Overview

Monitoring and auto-remediation solution for slow `/api/data` response times

## Part 1 - Sumo Logic

- Query finds `responsetime > 3s`
- Alert fires on > 5 results in 10-minute window
- Webhook triggers Lambda

## Part 2 - Lambda

- Reboots EC2 via `reboot_instances`
- Logs to CloudWatch
- Publishes SNS notification

## Part 3 - Terraform

- Provisions EC2, SNS, Lambda, IAM
- Least-privilege IAM policies
- Lambda Function URL for webhook

## Recordings

- Part 1: ADD LINK HERE
- Part 2: ADD LINK HERE
- Part 3: ADD LINK HERE
