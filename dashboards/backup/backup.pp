locals {
  backup_common_tags = {
    service = "AWS/Backup"
  }
}

category "backup_plan" {
  title = "Backup Plan"
  color = local.storage_color
  href  = "/aws_insights.dashboard.backup_plan_detail?input.backup_plan_arn={{.properties.'ARN' | @uri}}"
  icon  = "cloud_sync"
}

category "backup_plan_rule" {
  title = "Backup Plan Rule"
  color = local.storage_color
  icon  = "rule_folder"
}

category "backup_recovery_point" {
  title = "Backup Recovery Point"
  color = local.storage_color
  icon  = "settings_backup_restore"
}

category "backup_selection" {
  title = "Backup Selection"
  color = local.storage_color
  icon  = "checklist"
}

category "backup_vault" {
  title = "Backup Vault"
  color = local.storage_color
  href  = "/aws_insights.dashboard.backup_vault_detail?input.backup_vault_arn={{.properties.'ARN' | @uri}}"
  icon  = "shelves"
}
