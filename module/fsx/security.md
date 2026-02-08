This file explains the security architecture to stakeholders (Security/Compliance teams).

```markdown
# Security & Compliance Documentation
**Module:** SBC AWS FSx for NetApp ONTAP

This document outlines the security controls, encryption standards, and compliance features implemented within this Terraform module.

## 1. Data Encryption
All data stored in the FSx file system is encrypted by default.

* **Encryption at Rest:**
  * Uses AWS KMS (Key Management Service).
  * Supports **Customer Managed Keys (CMK)** for granular control over key rotation and access policies.
  * **Option:** Users can let the module create a dedicated key OR provide an existing corporate KMS Key ARN (BYO Key).

* **Encryption in Transit:**
  * Nitro-based encryption for supported EC2 instances.
  * SMB Encryption can be enforced via Active Directory GPO.
  * Kerberos authentication supported for NFSv4.

## 2. Network Security
The module enforces strict network isolation.

* **VPC Integration:** The file system is deployed within private subnets and is not accessible from the public internet.
* **Security Groups:**
  * **Managed Mode:** The module creates a Security Group allowing traffic only on required ports (SMB: 445, NFS: 2049, Mgmt: 22) from specified CIDR blocks.
  * **BYO Mode:** Allows integration with pre-approved, hardened Security Groups provided by the InfoSec team.
* **Routing:** Updates Route Tables automatically to ensure seamless Multi-AZ failover and connectivity.

## 3. Identity & Access Management (IAM & AD)
* **Active Directory Integration:**
  * Supports Self-Managed AD and AWS Managed Microsoft AD.
  * Enforces SMB authentication via Domain Users.
  * **Zero-Knowledge Credential Handling:** Passwords are retrieved dynamically from AWS Secrets Manager at runtime; they are never stored in the Terraform state or code.

* **IAM Policies:**
  * KMS Key Policies are scoped to the root account and specific service roles (`fsx.amazonaws.com`) to prevent unauthorized access.

## 4. Auditing & Logging
* **CloudWatch Logs:**
  * The module automatically creates a CloudWatch Log Group (`/aws/fsx/.../audit`) for file access auditing.
  * Logs are encrypted using KMS.
  * Retention policy is set to 365 days by default (configurable).

* **Tagging Strategy:**
  * All resources are tagged with `ManagedBy`, `Environment`, `Application`, and `Owner` for cost allocation and resource tracking.
  * Custom tags are merged with system tags to ensure compliance with enterprise tagging standards.

## 5. Data Protection & Recovery
* **Backups:** Automated daily backups with configurable retention periods.
* **Snapshots:** NetApp ONTAP snapshots allow for near-instant point-in-time recovery of individual files by end-users.
* **Multi-AZ:** High Availability deployment ensures data resilience against Availability Zone failures.
