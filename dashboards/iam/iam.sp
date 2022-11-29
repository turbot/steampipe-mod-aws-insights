locals {
  iam_common_tags = {
    service = "AWS/IAM"
  }
}

category "aws_iam_access_key" {
  title = "IAM Access Key"
  color = local.iam_color
  icon  = "key"
}

category "aws_iam_group" {
  title = "IAM Group"
  color = local.iam_color
  href  = "/aws_insights.dashboard.aws_iam_group_detail?input.group_arn={{.properties.'ARN' | @uri}}"
  icon  = "user-group"
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

category "aws_iam_inline_policy" {
  icon  = "heroicons-outline:clipboard-document"
  color = "red"
  title = "IAM Policy"
}

category "aws_iam_policy_statement" {
  icon  = "heroicons-outline:clipboard-document"
  color = "red"
  title = "Statement"
}


category "aws_iam_policy_action" {
  href = "/aws_insights.dashboard.aws_iam_action_glob_report?input.action_glob={{.title | @uri}}"

  icon  = "heroicons-outline:bolt"
  color = "red"
  title = "Action"
}


category "aws_iam_policy_notaction" {
  icon  = "heroicons-outline:bolt-slash"
  color = "red"
  title = "NotAction"
}

category "aws_iam_policy_resource" {
  icon  = "heroicons-outline:bookmark"
  color = "red"
  title = "Resource"
}


category "aws_iam_policy_notresource" {
  icon  = "heroicons-outline:bookmark-slash"
  color = "red"
  title = "NotResource"
}



category "aws_iam_policy_condition" {
  icon  = "heroicons-outline:question-mark-circle"
  color = "red"
  title = "Condition"
}


category "aws_iam_policy_condition_key" {
  icon  = "text:key"
  color = "red"
  title = "Condition Key"
}


category "aws_iam_policy_condition_value" {
  icon  = "text:val"
  color = "red"
  title = "Condition Value"
}
