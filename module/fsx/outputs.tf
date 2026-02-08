output "fsx_id" {
  description = "The ID of the FSx ONTAP File System"
  value       = aws_fsx_ontap_file_system.main.id
}

output "fsx_management_dns" {
  description = "DNS name for FSx management (SSH/API)"
  value       = aws_fsx_ontap_file_system.main.dns_name
}

output "kms_key_arn" {
  description = "ARN of the KMS Key used"
  value       = local.final_kms_key_arn
}

output "svms" {
  description = "Map of created SVMs details (ID and Endpoints)"
  value = {
    for k, v in aws_fsx_ontap_storage_virtual_machine.svm : k => {
      id           = v.id
      smb_endpoint = try(v.endpoints[0].smb[0].dns_name, "N/A (NFS Only)")
      nfs_endpoint = try(v.endpoints[0].nfs[0].dns_name, "N/A")
    }
  }
}

output "volumes" {
  description = "Map of created Volumes"
  value = {
    for k, v in aws_fsx_ontap_volume.volume : k => v.id
  }
}
