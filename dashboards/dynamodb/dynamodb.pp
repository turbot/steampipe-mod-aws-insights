locals {
  dynamodb_common_tags = {
    service = "AWS/DynamoDB"
  }
}

category "dynamodb_backup" {
  title = "DynamoDB Backup"
  color = local.database_color
  icon  = "settings_backup_restore"
}

category "dynamodb_table" {
  title = "DynamoDB Table"
  color = local.database_color
  href  = "/aws_insights.dashboard.dynamodb_table_detail?input.table_arn={{.properties.'ARN' | @uri}}"
  icon  = "table"
}
