locals {
  env_config = yamldecode(file("${path.module}/prod.yml"))

  region      = local.env_config.region
  environment = local.env_config.environment

  app_name = local.env_config.metadata.app_name
  tags     = local.env_config.metadata.tags

  fsx_file_system_name = local.env_config.fsx.file_system_name
  deployment_type      = local.env_config.fsx.deployment_type

  storage_capacity_gb = local.env_config.fsx.storage_capacity_gb
  throughput_capacity = local.env_config.fsx.throughput_capacity
  provisioned_iops    = local.env_config.fsx.ssd_iops.value

  backup = local.env_config.fsx.backup
  maintenance = local.env_config.fsx.maintenance

  vpc_id              = local.env_config.networking.vpc_id
  subnet_ids          = local.env_config.networking.subnet_ids
  security_group_ids  = local.env_config.networking.security_group_ids
  use_main_route_table = local.env_config.networking.route_tables.use_main

  network_type                = local.env_config.networking.network_type
  endpoint_ipv4_address_range = local.env_config.networking.endpoint_ipv4_address_range

  kms_key_alias        = local.env_config.encryption.kms_key_alias
  fsx_admin_secret_arn = local.env_config.admin_credentials.secret_arn

  svms    = local.env_config.svms
  volumes = local.env_config.volumes
}
