locals {
  iam_common_tags = {
    service = "AWS/IAM"
  }
}

category "iam_access_key" {
  title = "IAM Access Key"
  color = local.iam_color
  icon  = "key"
}

category "iam_federated_principal" {
  icon  = "group"
  color = local.iam_color
  title = "Federated"
}

category "iam_group" {
  title = "IAM Group"
  color = local.iam_color
  href  = "/aws_insights.dashboard.iam_group_detail?input.group_arn={{.properties.'ARN' | @uri}}"
  icon  = "groups"
}

category "iam_inline_policy" {
  icon  = "admin-panel-settings"
  color = local.iam_color
  title = "IAM Policy"
}

category "iam_instance_profile" {
  title = "IAM Profile"
  icon  = "person-add"
  color = local.iam_color
}

category "iam_policy" {
  title = "IAM Policy"
  color = local.iam_color
  href  = "/aws_insights.dashboard.iam_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
  icon  = "rule"
}

category "iam_policy_action" {
  href  = "/aws_insights.dashboard.iam_action_glob_report?input.action_glob={{.title | @uri}}"
  icon  = "electric-bolt"
  color = local.iam_color
  title = "Action"
}

category "iam_policy_condition" {
  icon  = "help"
  color = local.iam_color
  title = "Condition"
}

category "iam_policy_condition_key" {
  icon  = "vpn-key"
  color = local.iam_color
  title = "Condition Key"
}

category "iam_policy_condition_value" {
  icon  = "text:val"
  color = local.iam_color
  title = "Condition Value"
}

category "iam_policy_notaction" {
  icon  = "flash-off"
  color = local.iam_color
  title = "NotAction"
}

category "iam_policy_notresource" {
  icon  = "bookmark-remove"
  color = local.iam_color
  title = "NotResource"
}

category "iam_policy_resource" {
  icon  = "bookmark"
  color = local.iam_color
  title = "Resource"
}

category "iam_policy_statement" {
  icon  = "assignment"
  color = local.iam_color
  title = "Statement"
}

category "iam_role" {
  title = "IAM Role"
  href  = "/aws_insights.dashboard.iam_role_detail?input.role_arn={{.properties.'ARN' | @uri}}"
  icon  = "person-add"
  color = local.iam_color
}

category "iam_service_principal" {
  icon  = "settings"
  color = local.iam_color
  title = "Service"
}

category "iam_user" {
  title = "IAM User"
  color = local.iam_color
  href  = "/aws_insights.dashboard.iam_user_detail?input.user_arn={{.properties.'ARN' | @uri}}"
  icon  = "person"
}
