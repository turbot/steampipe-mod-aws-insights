locals {
  codecommit_common_tags = {
    service = "AWS/CodeCommit"
  }
}

category "codecommit_repository" {
  title = "CodeCommit Repository"
  href  = "/aws_insights.dashboard.codecommit_repository_detail?input.codecommit_repository_arn={{.properties.'ARN' | @uri}}"
  color = local.developer_tools_color
  icon  = "rebase_edit"
}