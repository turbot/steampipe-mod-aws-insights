category "aws_appconfig_application" {
  title = "AppConfig Application"
  color = local.application_integration_color
  icon  = "cog-6-tooth"
}

category "aws_cloudformation_stack" {
  title = "CloudFormation Stack"
  color = local.management_governance_color
  icon  = "text:CFN"
}

category "aws_codedeploy_app" {
  title = "CodeDeploy Application"
  color = local.developer_tools_color
  icon  = "text:CICD"
}

category "aws_dms_replication_instance" {
  title = "DMS Replication Instance"
  color = local.database_color
  icon  = "text:DMS"
}

category "aws_docdb_cluster" {
  title = "DocumentDB Cluster"
  icon  = "text:DDB"
  color = local.database_color
}

category "aws_fsx_file_system" {
  title = "FSX File System"
  icon  = "document-arrowup"
  color = local.storage_color
}

category "aws_guardduty_detector" {
  title = "GuardDuty Detector"
  color = local.security_color
  icon  = "text:Detector"
}

category "aws_kinesis_stream" {
  title = "Kinesis Stream"
  color = local.analytics_color
  icon  = "text:Stream"
}

category "aws_kinesisanalyticsv2_application" {
  title = "Kinesis Analytics Application"
  color = local.analytics_color
  icon  = "text:Application"
}

category "aws_media_store_container" {
  title = "Media Store Container"
  color = local.containers_color
  icon  = "building-storefront"
}

category "aws_opensearch_domain" {
  title = "OpenSearch Domain"
  icon  = "text:OS"
  color = local.analytics_color
}

category "aws_sagemaker_notebook_instance" {
  title = "Sagemaker Notebook Instance"
  color = local.ml_color
  icon  = "text:Instance"
}

category "aws_sfn_state_machine" {
  title = "Step Function State Machine"
  color = local.application_integration_color
  icon  = "text:SFN"
}

category "aws_wafv2_web_acl" {
  title = "WAFV2 Web Acl"
  icon  = "text:ACL"
  color = local.front_end_web_color
}

category "aws_federated" {
  icon  = "heroicons-outline:user-group"
  color = "orange"
  title = "Federated"
}

category "aws_service" {
  icon  = "heroicons-outline:cog-6-tooth"
  color = "orange"
  title = "Service"
}

category "aws_action" {
  icon  = "heroicons-outline:cog-8-tooth"
  color = "orange"
  title = "Action"
}
