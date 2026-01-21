variable "tags" {
  description = "Additional tags to apply to the FSx file system"
  type        = map(string)
  default     = {}
}

variable "storage_capacity" {
  description = "The storage capacity (GiB) for the FSx file system."
  type        = number
}

variable "multi_az_deployment" {
  description = "The deployment type for the FSx file system."
  type        = bool
  default     = false

  validation {
    condition     = !(var.environment == "prod" && var.multi_az_deployment == false)
    error_message = "multi_az_deployment must be true in production."
  }
}

variable "throughput_capacity" {
  description = "The throughput capacity (megabytes per second) for the FSx file system."
  type        = number
}

variable "storage_type" {
  description = "The storage type for the FSx file system. Valid values are 'SSD' for warm or 'HDD' for cold storage."
  type        = string
  default     = "SSD"

  validation {
    condition     = var.storage_type == "SSD" || var.storage_type == "HDD"
    error_message = "Storage type must be either 'SSD' or 'HDD'."
  }
}

variable "automatic_backup_retention_days" {
  description = "The number of days to retain automatic backups, default is 0 (no backups)."
  type        = number
  default     = 0
}

variable "daily_automatic_backup_start_time" {
  description = "The daily time to start automatic backups (HH:MM format)."
  type        = string
  default     = "02:00"

  validation {
    condition     = var.automatic_backup_retention_days == 0 || can(regex("^([01]?[0-9]|2[0-3]):[0-5][0-9]$", var.daily_automatic_backup_start_time))
    error_message = "Daily automatic backup start time must be in HH:MM format."
  }
}

variable "weekly_maintenance_start_time" {
  description = "The weekly time to start maintenance (d:HH:MM format, where d is day of week)."
  type        = string
  default     = "1:03:00"

  validation {
    condition     = can(regex("^[0-6]:([01]?[0-9]|2[0-3]):[0-5][0-9]$", var.weekly_maintenance_start_time))
    error_message = "Weekly maintenance start time must be in d:HH:MM format."
  }
}

variable "environment" {
  description = "Environment (prod or nonprod)"
  type        = string

  validation {
    condition     = contains(["prod", "nonprod"], var.environment)
    error_message = "Environment must be either 'prod' or 'nonprod'."
  }
}

variable "kms_key_id" {
  description = "The KMS Key ID or Alias for encrypting the FSx file system."
  type        = string
  default     = "your-key-name"
}

variable "vpc_name" {
  description = "VPC name which will be used for windows FSx deployment"
  type        = string

  validation {
    condition     = length(var.vpc_name) > 0
    error_message = "VPC name cannot be empty."
  }
}

variable "fsx_log_group_name" {
  description = "The name of the CloudWatch log group for FSx audit logs."
  type        = string
}

variable "fsx_failed_access_pattern" {
  description = "The filter pattern for failed access attempts in FSx audit logs."
  type        = string
  default     = "{ $.Status = \"FAILURE\" }"
}

variable "ad_auth_secret_name" {
  description = "Secrets Manager secret name to utilise for domain join which contains username and password as JSON keys"
  type        = string
  default     = ""

  validation {
    condition     = var.ad_auth_secret_name != ""
    error_message = "ad_auth_secret_name must be provided when enable_ad_join is true."
  }
}

variable "self_managed_ad_domain_name" {
  description = "The domain name for self-managed Active Directory"
  type        = string
  default     = ""
}

variable "self_managed_ad_dns_ips" {
  description = "List of DNS IPs for self-managed Active Directory"
  type        = list(string)
  default     = []
}
