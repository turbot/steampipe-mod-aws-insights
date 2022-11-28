locals {
  iam_common_tags = {
    service = "AWS/IAM"
  }
}

category "aws_iam_access_key" {
  title = "IAM Access Key"
  color = local.iam_color
  icon  = "text:Accesskey"
}

category "aws_iam_group" {
  title = "IAM Group"
  color = local.iam_color
  href  = "/aws_insights.dashboard.aws_iam_group_detail?input.group_arn={{.properties.'ARN' | @uri}}"
  icon  = "user-group"
}

category "aws_iam_instance_profile" {
  title = "IAM Instance Profile"
  color = local.iam_color
  icon  = "text:Profile"
}

category "aws_iam_policy" {
  title = "IAM Policy"
  color = local.iam_color
  href  = "/aws_insights.dashboard.aws_iam_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
  icon  = "document-check"
}

category "aws_iam_profile" {
  title = "IAM Profile"
  icon  = "user-plus"
  color = local.iam_color
}

category "aws_iam_role" {
  title = "IAM Role"
  href  = "/aws_insights.dashboard.aws_iam_role_detail?input.role_arn={{.properties.'ARN' | @uri}}"
  icon  = "user-plus"
  color = local.iam_color
}

category "aws_iam_user" {
  title = "IAM User"
  color = local.iam_color
  href  = "/aws_insights.dashboard.aws_iam_user_detail?input.user_arn={{.properties.'ARN' | @uri}}"
  icon  = "user"
}
