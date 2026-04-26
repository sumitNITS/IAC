# Development Environment Configuration

This directory contains Terraform configuration to get started with **dev** environment.

## Structure

- `main.tf` — Module instantiation and wiring
- `variables.tf` — Variable definitions with descriptions and types
- `outputs.tf` — Comprehensive outputs from all modules for downstream usage
- `provider.tf` — AWS provider configuration with version constraints
- `backend.tf` — Terraform state backend (S3 + DynamoDB)

## Best Practices Followed

- Variables have descriptions and types
- Outputs documented for downstream consumption
- Provider version constraints specified
- State backend encrypted and locked
- Common tags managed centrally
- Module dependencies explicit
- Private-first security model
- High availability (Multi-AZ EKS node distribution)
- VPC Endpoints for private AWS service access (no internet required)
- Comprehensive outputs for CLI commands

