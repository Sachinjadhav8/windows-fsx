# AWS FSx for NetApp ONTAP Module - Usage Examples

This document provides example configurations for deploying the **SBC AWS FSx ONTAP** Terraform module.

## Prerequisites
Before applying these configurations, ensure you have:
1. **VPC & Subnets:** A VPC with at least two private subnets in different Availability Zones.
2. **Secrets Manager:** A secret created containing the FSx admin password and Active Directory credentials.
3. **Active Directory:** Connectivity to your self-managed AD or AWS Managed AD.

---

## Scenario 1: Fully Managed Deployment (Standard)
Use this configuration when you want the module to automatically create and manage the **KMS Encryption Key** and **Security Group**.

```hcl
module "fsx_managed" {
  source = "git::ssh://dev.azure.com/EATechnology/ea-aws-tf-modules-ng//sbc-aws-fsx-NetApp-ONTAP-general"

  # --- Metadata ---
  app_name    = "shared-services"
  environment = "dev"

  # --- Networking ---
  vpc_id             = "vpc-05c2e127d..."
  subnet_ids         = ["subnet-0aff...", "subnet-016f..."]
  route_table_ids    = ["rtb-0d46...", "rtb-07cf..."]
  allowed_cidr_blocks = ["10.0.0.0/16"] # Allow entire VPC

  # --- Security (Module will create Key & SG) ---
  secret_arn        = "dev/fsx-ontap/creds" #provide only name, NO ARN#
  kms_key_admin_arn = "arn:aws:iam::123456789012:root" ##The ARN of the IAM Principal (Role or User) that will have administrative permissions (kms:*) on the new KMS Key. CRITICAL: This prevents the key from becoming unmanageable. Recommended: Use the Account Root ARN or a specific Admin Role.

  # Default behavior: create_new_security_group = true
  # Default behavior: create_new_key = true

  # --- Active Directory ---
  ad_domain_name            = "corp.example.local"
  ad_dns_ips                = ["10.0.1.10", "10.0.2.10"]
  ad_ou_distinguished_name  = "OU=Computers,OU=AWS,DC=corp,DC=example,DC=local"

  # --- Resources ---
  storage_capacity_gb = 1024
  throughput_capacity = 128

  svms = {
    "svm_win" = { name = "svm-windows", ad_join = true }
  }

  volumes = {
    "share_data" = {
      svm_key      = "svm_win"
      name         = "data"
      junction_path = "/data"
      size_mb      = 10240
    }
  }
}
