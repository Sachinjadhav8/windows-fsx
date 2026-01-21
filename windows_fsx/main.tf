resource "aws_fsx_windows_file_system" "fsx_module" {
  storage_capacity      = var.storage_capacity
  subnet_ids            = local.subnet_ids
  preferred_subnet_id   = local.preferred_subnet_id
  throughput_capacity   = var.throughput_capacity
  deployment_type       = var.multi_az_deployment ? "MULTI_AZ_1" : "SINGLE_AZ_1"
  storage_type          = var.storage_type
  kms_key_id            = data.aws_kms_key.fsx_kms_key.arn

  self_managed_active_directory {
    dns_ips     = var.self_managed_ad_dns_ips
    domain_name = var.self_managed_ad_domain_name
    username    = local.ad_auth_username
    password    = local.ad_auth_password
  }

  automatic_backup_retention_days  = var.automatic_backup_retention_days
  daily_automatic_backup_start_time = var.automatic_backup_retention_days > 0 ? var.daily_automatic_backup_start_time : null
  weekly_maintenance_start_time     = var.weekly_maintenance_start_time

  # TODO: Need to check
  audit_log_configuration {
    file_access_audit_log_level       = "SUCCESS_AND_FAILURE" # or "FAILURE_ONLY" or "DISABLED"
    file_share_access_audit_log_level = "SUCCESS_AND_FAILURE"
    # audit_log_destination            = "cloudwatch-logs"
  }

  # Below is not available in new TF AWS provider versions, need to fix in AD integration
  # windows_configuration {
  #   smb_security_strategy = "ENFORCE_ENCRYPTION"
  # }

  tags = merge(var.tags, {
    Name        = var.tags.name
    Environment = var.environment
    ManagedBy  = "terraform"
  })
}

resource "aws_security_group" "fsx_sg" {
  name        = "fsx-${var.tags.name}-sg"
  description = "FSx access control"
  vpc_id      = data.aws_vpc.fsx_vpc.id

  ingress {
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.fsx_vpc.cidr_block]
    description = "SQL Server from VPC CIDR, NLB Healthcheck"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fsx-${var.tags.name}-sg"
  }
}

resource "aws_network_acl" "fsx_nacl" {
  vpc_id = data.aws_vpc.fsx_vpc.id

  tags = {
    Name = "fsx-nacl"
  }
}

resource "aws_network_acl_rule" "fsx_inbound" {
  network_acl_id = aws_network_acl.fsx_nacl.id
  rule_number    = 100 # Is this correct? need to check.
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = data.aws_vpc.fsx_vpc.cidr_block
  from_port      = 445
  to_port        = 445
}

resource "aws_cloudwatch_log_metric_filter" "fsx_failed_access" {
  name           = "${var.tags.name}-FSxFailedAccessAttempts"
  log_group_name = var.fsx_log_group_name # "/aws/fsx/windows"
  pattern        = var.fsx_failed_access_pattern # "{ $.Status = \"FAILURE\" }"

  metric_transformation {
    name      = "${var.tags.name}-FailedAccessAttempts"
    namespace = "FsxAudit" # TODO: Confirm namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "fsx_failed_access_alarm" {
  alarm_name          = "${var.tags.name}-FSxFailedAccessAttemptsAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.fsx_failed_access.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.fsx_failed_access.metric_transformation[0].namespace
  period              = 60 # 1 minute
  statistic           = "Sum"
  threshold           = 5

  alarm_description = "Triggers if 5 or more failed FSx access attempts occur in 1 minute."
  actions_enabled   = true
}
