output "alerts_topic_arn" {
  description = "SNS topic security alerts go to"
  value       = module.alerts.topic_arn
}

output "cloudtrail_bucket" {
  description = "Bucket with the CloudTrail logs"
  value       = module.cloudtrail.bucket_name
}

output "config_bucket" {
  description = "Bucket with the Config history"
  value       = module.config.bucket_name
}

output "backup_vault_arn" {
  description = "Backup vault, tag resources with Backup = true to have them backed up"
  value       = module.backup.vault_arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = module.guardduty.detector_id
}
