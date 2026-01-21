data "aws_iam_policy_document" "fsx_restrictions" {

  statement {
    sid    = "DenyPublicAccess"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["fsx:*"]
    resources = [aws_fsx_windows_file_system.fsx_module.arn]

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "DenyAnonymousAccess"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["fsx:*"]
    resources = [aws_fsx_windows_file_system.fsx_module.arn]

    condition {
      test     = "Null"
      variable = "aws:PrincipalArn"
      values   = ["true"]
    }
  }

  statement {
    sid    = "DenyOtherVPCEndpoint"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["fsx:*"]
    resources = [aws_fsx_windows_file_system.fsx_module.arn]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.fsx_endpoint.id]
    }
  }
}

# -----------------------------
# VPC Endpoint for FSx
# -----------------------------

resource "aws_vpc_endpoint" "fsx_endpoint" {
  vpc_id             = data.aws_vpc.fsx_vpc.id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.fsx"
  vpc_endpoint_type  = "Interface"
}

# -----------------------------
# Data Sources
# -----------------------------

data "aws_vpc" "fsx_vpc" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_kms_key" "fsx_kms_key" {
  key_id = var.kms_key_id
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_subnets" "fsx_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.fsx_vpc.id]
  }
}

# -----------------------------
# Secrets Manager (AD Auth)
# -----------------------------

data "aws_secretsmanager_secret" "ad_auth_secret" {
  name = var.ad_auth_secret_name
}

data "aws_secretsmanager_secret_version" "ad_auth_secret_version" {
  secret_id = data.aws_secretsmanager_secret.ad_auth_secret.id
}
