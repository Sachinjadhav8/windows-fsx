module "fsx_ontap_standard" {
# source = "git::ssh://dev.azure.com/EATechnology/ea-aws-tf-modules-ng//sbc-aws-fsx-NetApp-ONTAP-general"
  source   = "../../modules/fsx"
  app_name    = local.app_name
  environment = local.environment
  tags        = local.tags

  file_system_name = local.fsx_file_system_name
  deployment_type  = local.deployment_type

  storage_capacity_gb = local.storage_capacity_gb
  throughput_capacity = local.throughput_capacity
  provisioned_iops    = local.provisioned_iops

  daily_automatic_backup_enabled = local.backup.daily_backup_enabled
  automatic_backup_start_time    = local.backup.backup_start_time
  backup_retention_days          = local.backup.retention_days

  weekly_maintenance_start_time = "${local.maintenance.weekly_day}:${local.maintenance.weekly_start_time}"

  vpc_id               = local.vpc_id
  subnet_ids           = local.subnet_ids
  security_group_ids   = local.security_group_ids
  use_main_route_table = local.use_main_route_table

  network_type                = local.network_type
  endpoint_ipv4_address_range = local.endpoint_ipv4_address_range

  kms_key_alias = local.kms_key_alias
  secret_arn    = local.fsx_admin_secret_arn

  svms    = local.svms
  volumes = local.volumes
}
