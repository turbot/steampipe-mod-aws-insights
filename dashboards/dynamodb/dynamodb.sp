locals {
  dynamodb_common_tags = {
    service = "AWS/DynamoDB"
  }
}

category "aws_dynamodb_backup" {
  title = "DynamoDB Backup"
  color = local.database_color
  icon  = "text:backup"
}

category "aws_dynamodb_table" {
  title = "DynamoDB Table"
  color = local.database_color
  href  = "/aws_insights.dashboard.dynamodb_table_detail?input.table_arn={{.properties.'ARN' | @uri}}"
  icon  = "circle-stack"
}
