# -------------------------------------------------------------------
# 0. Fetch Secrets & Locals
# -------------------------------------------------------------------

data "aws_secretsmanager_secret" "fsx_secret" {
  name = var.secret_arn
}

data "aws_region" "current" {}

data "aws_secretsmanager_secret_version" "fsx_secret_val" {
  secret_id = data.aws_secretsmanager_secret.fsx_secret.id
}

data "aws_caller_identity" "current" {}

locals {
  creds = jsondecode(data.aws_secretsmanager_secret_version.fsx_secret_val.secret_string)

  # Logic: Either create a new KMS Key or use the provided one based on the variable
  final_kms_key_arn = var.create_new_key ? aws_kms_key.fsx[0].arn : var.kms_key_arn

  # Security Group ID Logic - Either use new SG or provided SG
  final_security_group_id = var.create_new_security_group ? aws_security_group.fsx[0].id : var.fsx_security_group_id
}

# -------------------------------------------------------------------
# 1. KMS Encryption (Conditional - Scenario 4)
# -------------------------------------------------------------------

resource "aws_kms_key" "fsx" {
  count                   = var.create_new_key ? 1 : 0
  description             = "CMK for FSx ONTAP - ${local.name_prefix}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_policy[0].json
  tags                    = local.common_tags
}

resource "aws_kms_alias" "fsx" {
  count         = var.create_new_key ? 1 : 0
  name          = "alias/${local.name_prefix}"
  target_key_id = aws_kms_key.fsx[0].key_id
}

data "aws_iam_policy_document" "kms_policy" {
  count = var.create_new_key ? 1 : 0

  # 1. Root Access
  statement {
    sid       = "AdminAccess"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # 2. FSx Service Access (For FSx to use the key for encryption/decryption)
  statement {
    sid       = "FSxServiceAccess"
    actions   = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["fsx.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # 3. CloudWatch Logs Access (For Auditing)
  statement {
    sid     = "Allow CloudWatch Logs"
    effect  = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.id}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:*"]
    }
  }
}

# -------------------------------------------------------------------
# 2. Network Security (Conditional - Scenario 4)
# -------------------------------------------------------------------

resource "aws_security_group" "fsx" {
  count       = var.create_new_security_group ? 1 : 0
  name        = "${local.name_prefix}-sg"
  description = "FSx ONTAP Security Group"
  vpc_id      = var.vpc_id
  tags        = local.common_tags
}

# Rules only created if we're managing the SG ourselves

resource "aws_security_group_rule" "ingress_smb" {
  count             = var.create_new_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 445
  to_port           = 445
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.fsx[0].id
}

resource "aws_security_group_rule" "ingress_nfs" {
  count             = var.create_new_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.fsx[0].id
}

resource "aws_security_group_rule" "ingress_mgmt" {
  count             = var.create_new_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.fsx[0].id
}

resource "aws_security_group_rule" "ingress_self" {
  count             = var.create_new_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.fsx[0].id
}

resource "aws_security_group_rule" "egress_all" {
  count             = var.create_new_security_group ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.fsx[0].id
}

# -------------------------------------------------------------------
# 3. FSx File System
# -------------------------------------------------------------------

resource "aws_fsx_ontap_file_system" "main" {
  storage_capacity        = var.storage_capacity_gb
  subnet_ids              = var.subnet_ids
  deployment_type         = "MULTI_AZ_1"
  throughput_capacity     = var.throughput_capacity
  preferred_subnet_id     = var.subnet_ids[0]
  route_table_ids         = var.route_table_ids

  # Uses the Local logic to pick either New SG or Provided SG
  security_group_ids = [local.final_security_group_id]

  # Uses the Local logic to pick either New Key or Provided Key
  kms_key_id = local.final_kms_key_arn

  fsx_admin_password = local.creds.fsx_password

  automatic_backup_retention_days = var.backup_retention_days

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-fs" })
}

# -------------------------------------------------------------------
# 4. Storage Virtual Machines (SVMs)
# -------------------------------------------------------------------

resource "aws_fsx_ontap_storage_virtual_machine" "svm" {
  for_each = var.svms

  file_system_id           = aws_fsx_ontap_file_system.main.id
  name                     = each.value.name
  root_volume_security_style = each.value.root_volume_security_style

  dynamic "active_directory_configuration" {
    for_each = each.value.ad_join ? [1] : []

    content {
      netbios_name = substr(each.value.name, 0, 15)

      self_managed_active_directory_configuration {
        dns_ips                                 = var.ad_dns_ips
        domain_name                             = var.ad_domain_name
        username                                = local.creds.ad_username
        password                                = local.creds.ad_password
        organizational_unit_distinguished_name = var.ad_ou_distinguished_name
      }
    }
  }

  # Ignore changes to AD config to prevent "Already Joined" errors
  lifecycle {
    ignore_changes = [active_directory_configuration]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-${each.value.name}" })
}

# -------------------------------------------------------------------
# 5. Volumes
# -------------------------------------------------------------------

resource "aws_fsx_ontap_volume" "volume" {
  for_each = var.volumes

  name                     = each.value.name
  junction_path             = each.value.junction_path
  size_in_megabytes         = each.value.size_mb
  storage_efficiency_enabled = true

  storage_virtual_machine_id = aws_fsx_ontap_storage_virtual_machine.svm[each.value.svm_key].id

  security_style = each.value.security_style

  tiering_policy {
    name           = each.value.tiering_policy
    cooling_period = each.value.cooling_period
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-${each.value.name}" })
}

# -------------------------------------------------------------------
# 6. Logging
# -------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "fsx_audit" {
  name              = "/aws/fsx/${local.name_prefix}/audit"
  retention_in_days = 365
  kms_key_id        = local.final_kms_key_arn
  tags              = local.common_tags
}
