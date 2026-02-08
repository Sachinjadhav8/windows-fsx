locals {
  # 1. Naming Convention
  name_prefix = "sbc-aws-fsx-${var.app_name}-${var.environment}"

  # 2. Common Tags
  system_tags = {
    Environment       = var.environment
    ManagedBy         = "Terraform"
    Application       = "FSx-ONTAP" # Hardcoded value to fix missing variable
    Classification    = "OFFICIAL: Sensitive"
    Data_Sovereignty  = "AU"
    Baseline_UID      = "sbc-aws-amazon.FSx.NetApp.ONTAP"
  }

  common_tags = merge(var.tags, local.system_tags)
}
