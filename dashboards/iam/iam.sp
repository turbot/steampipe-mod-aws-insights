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
  color = local.iam_color
  icon  = "groups"
}

category "iam_group" {
  title = "IAM Group"
  color = local.iam_color
  href  = "/aws_insights.dashboard.iam_group_detail?input.group_arn={{.properties.'ARN' | @uri}}"
  icon  = "group"
}

category "iam_inline_policy" {
  title = "IAM Inline Policy"
  color = local.iam_color
  icon  = "rule"
}

category "iam_instance_profile" {
  title = "IAM Instance Profile"
  color = local.iam_color
  icon  = "manage_accounts"
}

category "iam_policy" {
  title = "IAM Managed Policy"
  color = local.iam_color
  href  = "/aws_insights.dashboard.iam_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
  icon  = "rule_folder"
}

category "iam_policy_action" {
  title = "IAM Policy Action"
  color = local.iam_color
  href  = "/aws_insights.dashboard.iam_action_glob_report?input.action_glob={{.title | @uri}}"
  icon  = "electric_bolt"
}

category "iam_policy_principal" {
  title = "IAM Policy Principal"
  color = local.iam_color
  icon  = "person"
}

category "iam_policy_condition" {
  title = "IAM Policy Condition"
  color = local.iam_color
  icon  = "help"
}

category "iam_policy_condition_key" {
  title = "IAM Policy Condition Key"
  color = local.iam_color
  icon  = "vpn_key"
}

category "iam_policy_condition_value" {
  title = "IAM Policy Condition Value"
  color = local.iam_color
  icon  = "numbers"
}

category "iam_policy_notaction" {
  title = "IAM Policy NotAction"
  color = local.iam_color
  icon  = "flash_off"
}

category "iam_policy_notresource" {
  title = "IAM Policy NotResource"
  color = local.iam_color
  icon  = "bookmark_remove"
}

category "iam_policy_resource" {
  title = "IAM Policy Resource"
  color = local.iam_color
  icon  = "bookmark"
}

category "iam_policy_statement" {
  title = "IAM Policy Statement"
  color = local.iam_color
  icon  = "assignment"
}

category "iam_resource_policy" {
  title = "Resource Policy"
  color = local.iam_color
  icon  = "rule_folder"
}

category "iam_role" {
  title = "IAM Role"
  color = local.iam_color
  href  = "/aws_insights.dashboard.iam_role_detail?input.role_arn={{.properties.'ARN' | @uri}}"
  icon  = "engineering"
}

category "iam_service_principal" {
  title = "IAM Service Principal"
  color = local.iam_color
  icon  = "component_exchange"
}

category "iam_user" {
  title = "IAM User"
  color = local.iam_color
  href  = "/aws_insights.dashboard.iam_user_detail?input.user_arn={{.properties.'ARN' | @uri}}"
  icon  = "person"
}
