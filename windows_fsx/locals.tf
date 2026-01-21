locals {
  subnet_ids = data.aws_subnets.fsx_subnets.ids

  preferred_subnet_id = var.multi_az_deployment ? local.subnet_ids[0] : local.subnet_ids[0]

  ad_auth_username = jsondecode(
    data.aws_secretsmanager_secret_version.ad_auth_secret_version.secret_string
  ).username

  ad_auth_password = jsondecode(
    data.aws_secretsmanager_secret_version.ad_auth_secret_version.secret_string
  ).password
}
