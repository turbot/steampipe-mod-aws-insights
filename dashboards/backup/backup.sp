locals {
  backup_common_tags = {
    service = "AWS/Backup"
  }
}

category "aws_backup_plan" {
  title = "Backup Plan"
  color = local.storage_color
  href  = "/aws_insights.dashboard.backup_plan_detail?input.backup_plan_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:Backup"
}

category "aws_backup_recovery_point" {
  title = "Backup Recovery Point"
  color = local.storage_color
  icon  = "text:recovery"
}

category "aws_backup_selection" {
  title = "Backup Selection"
  color = local.storage_color
  icon  = "text:Selection"
}

category "aws_backup_vault" {
  title = "Backup Vault"
  color = local.storage_color
  href  = "/aws_insights.dashboard.backup_vault_detail?input.backup_vault_arn={{.properties.'ARN' | @uri}}"
  icon  = "archive-box-arrow-down"
}
