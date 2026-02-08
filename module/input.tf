# -------------------------------------------------------------------
# 1. Common Variables
# -------------------------------------------------------------------

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where FSx will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of Subnet IDs (Private preferred)"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access FSx"
  type        = list(string)
}

variable "route_table_ids" {
  description = "List of Route Table IDs to update for Multi-AZ routing"
  type        = list(string)
}

# -------------------------------------------------------------------
# 2. Secret & Identity
# -------------------------------------------------------------------

variable "secret_arn" {
  description = "Name or ARN of the Secrets Manager secret (e.g., dev/fsx-ontap/creds)"
  type        = string
}

variable "kms_key_admin_arn" {
  description = "ARN of the IAM Role/User who administers the KMS Key"
  type        = string
}

# -------------------------------------------------------------------
# 3. Scenario 4: BYO (Bring Your Own) Security & Encryption 🔐 (NEW)
# -------------------------------------------------------------------

variable "create_new_security_group" {
  description = "Set to false to use an existing Security Group (Scenario 4)"
  type        = bool
  default     = true
}

variable "fsx_security_group_id" {
  description = "The ID of the existing Security Group (Required if create_new_security_group is false)"
  type        = string
  default     = null
}

variable "create_new_key" {
  description = "Set to false to use an existing KMS Key (Scenario 4)"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "The ARN of the existing KMS Key (Required if create_new_key is false)"
  type        = string
  default     = null
}

# -------------------------------------------------------------------
# 4. FSx Configuration
# -------------------------------------------------------------------

variable "storage_capacity_gb" {
  description = "Storage capacity in GB (Min 1024)"
  type        = number
  default     = 1024
}

variable "throughput_capacity" {
  description = "Throughput capacity in MBps"
  type        = number
  default     = 128
}

variable "backup_retention_days" {
  description = "Number of days to keep backups"
  type        = number
  default     = 7
}

# -------------------------------------------------------------------
# 5. Active Directory Configuration
# -------------------------------------------------------------------

variable "ad_domain_name" {
  description = "Fully Qualified Domain Name (e.g., corp.test.local)"
  type        = string
}

variable "ad_dns_ips" {
  description = "List of DNS IP addresses for the AD"
  type        = list(string)
}

variable "ad_ou_distinguished_name" {
  description = "OU path where Computer Object will be created"
  type        = string
}

variable "tags" {
  description = "A map of custom tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "app_name" {
  description = "Application Name (e.g., payment, sap, shared)"
  type        = string
}

# -------------------------------------------------------------------
# 6. SVMs & Volumes (Multi-Tenancy Input)
# -------------------------------------------------------------------

variable "svms" {
  description = "Map of SVMs to create. Key is internal ID, Value is object with name and ad_join flag."
  type = map(object({
    name                     = string
    ad_join                 = bool
    root_volume_security_style = optional(string, "NTFS") # Defaults to NTFS
  }))
  default = {}
}

variable "volumes" {
  description = "Map of Volumes to create. Links to SVM via 'svm_key'."
  type = map(object({
    svm_key        = string # Must match a key in var.svms
    name           = string
    junction_path  = string
    size_mb        = number
    security_style = optional(string, "NTFS")
    tiering_policy = optional(string, "AUTO")
    cooling_period = optional(number, 31)
  }))
  default = {}
}
