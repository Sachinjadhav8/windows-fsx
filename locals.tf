locals {
  config = yamldecode(
    file("${path.module}/config/pod.yml")
  )

  fsx_instances = {
    for fsx in local.config.fsx.instances :
    fsx.name => fsx
  }
}
