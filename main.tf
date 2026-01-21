module "windows_fsx" {
#  source   = "../../modules/windows_fsx"
  source   = "./windows_fsx"
  for_each = local.fsx_instances

  environment         = local.config.environment

  storage_capacity    = local.config.fsx.storage_capacity
  throughput_capacity = local.config.fsx.throughput_capacity
  storage_type        = local.config.fsx.storage_type
  multi_az_deployment = local.config.fsx.multi_az_deployment

  automatic_backup_retention_days   = local.config.fsx.backups.retention_days
  daily_automatic_backup_start_time = local.config.fsx.backups.daily_start_time
  weekly_maintenance_start_time     = local.config.fsx.backups.weekly_maintenance_time

  fsx_log_group_name = local.config.fsx.logging.log_group_name

  vpc_name   = local.config.network.vpc_name
  kms_key_id = local.config.network.kms_key_id

  self_managed_ad_domain_name = local.config.ad.domain_name
  self_managed_ad_dns_ips     = local.config.ad.dns_ips
  ad_auth_secret_name         = local.config.ad.auth_secret_name

  tags = merge(
    local.config.tags,
    {
      name = each.key
    }
  )
}
