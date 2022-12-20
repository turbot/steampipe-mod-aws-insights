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
  title = "IAM Federated Principal"
  icon  = "group"
  color = local.iam_color
}

category "iam_group" {
  title = "IAM Group"
  color = local.iam_color
  href  = "/aws_insights.dashboard.iam_group_detail?input.group_arn={{.properties.'ARN' | @uri}}"
  icon  = "groups"
}

category "iam_inline_policy" {
  title = "IAM Inline Policy"
  icon  = "admin-panel-settings"
  color = local.iam_color
}

category "iam_instance_profile" {
  title = "IAM Profile"
  icon  = "person-add"
  color = local.iam_color
}

category "iam_policy" {
  title = "IAM Managed Policy"
  color = local.iam_color
  href  = "/aws_insights.dashboard.iam_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
  icon  = "rule"
}

category "iam_policy_action" {
  title = "IAM Policy Action"
  href  = "/aws_insights.dashboard.iam_action_glob_report?input.action_glob={{.title | @uri}}"
  icon  = "electric-bolt"
  color = local.iam_color
}

category "iam_policy_condition" {
  title = "IAM Policy Condition"
  icon  = "help"
  color = local.iam_color
}

category "iam_policy_condition_key" {
  title = "IAM Policy Condition Key"
  icon  = "vpn-key"
  color = local.iam_color
}

category "iam_policy_condition_value" {
  title = "IAM Policy Condition Value"
  icon  = "text:val"
  color = local.iam_color
}

category "iam_policy_notaction" {
  title = "IAM Policy NotAction"
  icon  = "flash-off"
  color = local.iam_color
}

category "iam_policy_notresource" {
  title = "IAM Policy NotResource"
  icon  = "bookmark-remove"
  color = local.iam_color
}

category "iam_policy_resource" {
  title = "IAM Policy Resource"
  icon  = "bookmark"
  color = local.iam_color
}

category "iam_policy_statement" {
  title = "IAM Policy Statement"
  icon  = "assignment"
  color = local.iam_color
}

category "iam_role" {
  title = "IAM Role"
  href  = "/aws_insights.dashboard.iam_role_detail?input.role_arn={{.properties.'ARN' | @uri}}"
  icon  = "person-add"
  color = local.iam_color
}

category "iam_service_principal" {
  title = "IAM Service Service"
  icon  = "settings"
  color = local.iam_color
}

category "iam_user" {
  title = "IAM User"
  color = local.iam_color
  href  = "/aws_insights.dashboard.iam_user_detail?input.user_arn={{.properties.'ARN' | @uri}}"
  icon  = "person"
}
