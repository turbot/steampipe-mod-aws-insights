locals {
  glacier_common_tags = {
    service = "AWS/Glacier"
  }
}

category "aws_glacier_vault" {
  title = "Glacier Vault"
  color = local.storage_color
  href  = "/aws_insights.dashboard.glacier_vault_detail?input.vault_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:Glacier"
}