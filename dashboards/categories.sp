category "aws_docdb_cluster" {
  title = "DocumentDB Cluster"
  icon  = "text:DDB"
  color = local.database_color
}

category "aws_ec2_classic_load_balancer" {
  title = "EC2 Classic Load Balancer"
  href  = "/aws_insights.dashboard.aws_ec2_classic_load_balancer_detail?input.clb={{.properties.'ARN' | @uri}}"
  icon  = "text:CLB"
  color = local.network_color
}

category "aws_ec2_application_load_balancer" {
  title = "EC2 Application Load Balancer"
  href  = "/aws_insights.dashboard.aws_ec2_application_load_balancer_detail?input.alb={{.properties.'ARN' | @uri}}"
  icon  = "text:ALB"
  color = local.network_color
}

category "aws_ec2_network_load_balancer" {
  title = "EC2 Network Load Balancer"
  href  = "/aws_insights.dashboard.aws_ec2_network_load_balancer_detail?input.nlb={{.properties.'ARN' | @uri}}"
  icon  = "text:NLB"
  color = local.network_color
}

category "aws_ec2_gateway_load_balancer" {
  title = "EC2 Gateway Load Balancer"
  href  = "/aws_insights.dashboard.aws_ec2_gateway_load_balancer_detail?input.glb={{.properties.'ARN' | @uri}}"
  icon  = "text:GLB"
  color = local.network_color
}

category "aws_ec2_load_balancer_listener" {
  title = "EC2 Load Balancer Listener"
  color = local.network_color
  icon  = "text:LBL"
}

category "aws_ecs_cluster" {
  title = "ECS Cluster"
  href  = "/aws_insights.dashboard.aws_ecs_cluster_detail?input.ecs_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:ECS"
  color = local.compute_color
}

category "aws_ecs_container_instance" {
  title = "ECS Container Instance"
  icon  = "text:ECS"
  color = local.compute_color
}

category "aws_ecs_task_definition" {
  title = "ECS Tasks Definition"
  color = local.compute_color
  href  = "/aws_insights.dashboard.aws_ecs_task_definition_detail?input.task_definition_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:ECS"
}

category "aws_ecs_service" {
  title = "ECS Service"
  color = local.compute_color
  icon  = "text:ECS"
  href  = "/aws_insights.dashboard.aws_ecs_service_detail?input.service_arn={{.properties.'ARN' | @uri}}"
}

category "aws_s3_bucket" {
  title = "S3 Bucket"
  href  = "/aws_insights.dashboard.aws_s3_bucket_detail?input.bucket_arn={{.properties.'ARN' | @uri}}"
  icon  = "archive-box"
  color = local.storage_color
}

category "aws_cloudfront_distribution" {
  title = "CloudFront Distribution"
  color = local.cd_color
  href  = "/aws_insights.dashboard.aws_cloudfront_distribution_detail?input.distribution_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:CD"
}

category "aws_acm_certificate" {
  title = "ACM Certificate"
  href  = "/aws_insights.dashboard.acm_certificate_detail?input.certificate_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:ACM"
  color = local.security_color
}

category "aws_sns_topic" {
  title = "SNS Topic"
  href  = "/aws_insights.dashboard.aws_sns_topic_detail?input.topic_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:Topic"
  color = local.integration_color
}

category "aws_sns_topic_subscription" {
  title = "SNS Subscription"
  icon  = "rss"
  color = local.integration_color
}


category "aws_kms_key" {
  title = "KMS Key"
  href  = "/aws_insights.dashboard.aws_kms_key_detail?input.key_arn={{.properties.'ARN' | @uri}}"
  icon  = "key"
  color = local.security_color
}

category "aws_kms_alias" {
  title = "KMS Key Alias"
  icon  = "key"
  color = local.security_color
}

category "aws_cloudtrail_trail" {
  title = "CloudTrail Trail"
  color = local.mg_color
  href  = "/aws_insights.dashboard.aws_cloudtrail_trail_detail?input.trail_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:CT"
}

category "aws_ebs_volume" {
  title = "EBS Volume"
  href  = "/aws_insights.dashboard.aws_ebs_volume_detail?input.volume_arn={{.properties.'ARN' | @uri}}"
  icon  = "inbox-stack"
  color = local.storage_color
}

category "aws_ebs_snapshot" {
  title = "EBS Snapshot"
  href  = "/aws_insights.dashboard.aws_ebs_snapshot_detail?input.snapshot_arn={{.properties.'ARN' | @uri}}"
  color = local.storage_color
  icon  = "viewfinder-circle"
}

category "aws_rds_db_cluster" {
  title = "RDS DB Cluster"
  color = local.database_color
  href  = "/aws_insights.dashboard.aws_rds_db_cluster_detail.url_path?input.db_cluster_arn={{.properties.ARN | @uri}}"
  icon  = "circle-stack"
}

category "aws_rds_db_cluster_snapshot" {
  title = "RDS DB Cluster Snapshot"
  color = local.database_color
  href  = "/aws_insights.dashboard.aws_rds_db_cluster_snapshot_detail.url_path?input.snapshot_arn={{.properties.ARN | @uri}}"
  icon  = "viewfinder-circle"
}

category "aws_rds_db_instance" {
  title = "RDS DB Instance"
  color = local.database_color
  href  = "/aws_insights.dashboard.aws_rds_db_instance_detail.url_path?input.db_instance_arn={{.properties.ARN | @uri}}"
  icon  = "circle-stack"
}

category "aws_rds_db_snapshot" {
  title = "RDS DB Snapshot"
  color = local.database_color
  href  = "/aws_insights.dashboard.aws_rds_db_snapshot_detail.url_path?input.db_snapshot_arn={{.properties.ARN | @uri}}"
  icon  = "viewfinder-circle"
}

category "aws_rds_db_cluster_parameter_group" {
  title = "RDS DB Cluster Parameter Group"
  color = local.database_color
  icon  = "text:PG"
}

category "aws_rds_db_parameter_group" {
  title = "RDS DB Parameter Group"
  color = local.database_color
  icon  = "text:PG"
}

category "aws_rds_db_subnet_group" {
  title = "RDS DB Subnet Group"
  color = local.database_color
  icon  = "text:SG"
}

category "aws_redshift_cluster" {
  title = "Redshift Cluster"
  color = local.database_color
  href  = "/aws_insights.dashboard.aws_redshift_cluster_detail?input.cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "circle-stack"
}

category "aws_redshift_snapshot" {
  title = "Redshift Snapshot"
  color = local.database_color
  href  = "/aws_insights.dashboard.aws_redshift_snapshot_detail?input.snapshot_arn={{.properties.'ARN' | @uri}}"
  icon  = "viewfinder-circle"
}

category "aws_redshift_subnet_group" {
  title = "Redshift Subnet Group"
  color = local.database_color
  icon  = "text:SG"
}

category "aws_redshift_parameter_group" {
  title = "Redshift Parameter Group"
  color = local.database_color
  icon  = "text:PG"
}

category "aws_ec2_ami" {
  title = "EC2 AMI"
  href  = "aws_insights.dashboard.aws_ec2_ami_detail?input.ami={{.properties.'Image ID' | @uri}}"
  color = local.compute_color
  icon  = "text:image"
}

category "aws_ec2_autoscaling_group" {
  title = "EC2 Autoscaling Group"
  icon  = "square-2-stack"
  color = local.compute_color
}

category "aws_ec2_target_group" {
  title = "EC2 Target Group"
  icon  = "arrow-down-on-square"
  color = local.network_color
}

category "aws_ec2_key_pair" {
  title = "EC2 Key Pair"
  icon  = "key"
  color = local.compute_color
}

category "aws_ecr_repository" {
  title = "ECR repository"
  color = local.container_color
  href  = "aws_insights.dashboard.aws_ecr_repository_detail?input.ecr_repository_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:ECR"
}

category "aws_ecr_image" {
  title = "ECR image"
  color = local.container_color
  icon  = "text:Image"
}

category "aws_efs_file_system" {
  title = "EFS File System"
  color = local.storage_color
  icon  = "text:File"
}

category "aws_efs_mount_target" {
  title = "EFS Mount Target"
  color = local.storage_color
  icon  = "text:Target"
}

category "aws_ec2_instance" {
  title = "EC2 Instance"
  href  = "/aws_insights.dashboard.aws_ec2_instance_detail?input.instance_arn={{.properties.'ARN' | @uri}}"
  icon  = "cpu-chip"
  color = local.compute_color
}

category "aws_ec2_network_interface" {
  title = "EC2 Network Interface"
  href  = "/aws_insights.dashboard.aws_ec2_network_interface_detail?input.network_interface_id={{.properties.'Interface ID' | @uri}}"
  icon  = "text:ENI"
  color = local.compute_color
}

category "aws_vpc" {
  title = "VPC"
  href  = "/aws_insights.dashboard.aws_vpc_detail?input.vpc_id={{.properties.'VPC ID' | @uri}}"
  icon  = "cloud" //"text:vpc"
  color = local.network_color
}


category "aws_vpc_security_group" {
  title = "VPC Security Group"
  href  = "/aws_insights.dashboard.aws_vpc_security_group_detail?input.security_group_id={{.properties.'Group ID' | @uri}}"
  icon  = "lock-closed"
  color = local.network_color
}

category "aws_vpc_flow_log" {
  title = "VPC Flow Log"
  href  = "/aws_insights.dashboard.aws_vpc_flow_logs_detail?input.flow_log_id={{.properties.'Flow Log ID' | @uri}}"
  color = local.network_color
  icon  = "text:FlowLog"
}

category "aws_iam_role" {
  title = "IAM Role"
  href  = "/aws_insights.dashboard.aws_iam_role_detail?input.role_arn={{.properties.'ARN' | @uri}}"
  icon  = "user-plus"
  color = local.iam_color
}

category "aws_emr_instance" {
  title = "EMR Instances"
  color = local.analytics_color
  href  = "/aws_insights.dashboard.aws_ec2_instance_detail?input.instance_arn={{.properties.'EC2 Instance ARN' | @uri}}"
  icon  = "cpu-chip"
}

category "aws_iam_policy" {
  title = "IAM Policy"
  color = local.iam_color
  href  = "/aws_insights.dashboard.aws_iam_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
  icon  = "document-check"
}

category "aws_iam_user" {
  title = "IAM User"
  color = local.iam_color
  href  = "/aws_insights.dashboard.aws_iam_user_detail?input.user_arn={{.properties.'ARN' | @uri}}"
  icon  = "user"
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

category "aws_iam_access_key" {
  title = "IAM Access Key"
  color = local.iam_color
  icon  = "text:Accesskey"
}

category "aws_iam_profile" {
  title = "IAM Profile"
  icon  = "user-plus"
  color = local.iam_color
}

category "aws_lambda_function" {
  title = "Lambda Function"
  href  = "/aws_insights.dashboard.aws_lambda_function_detail?input.lambda_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:Lambda"
  color = local.compute_color
}

category "aws_lambda_alias" {
  title = "Lambda Alias"
  icon  = "at-symbol"
  color = local.compute_color
}

category "aws_lambda_version" {
  title = "Lambda Version"
  icon  = "document-duplicate"
  color = local.compute_color
}


category "aws_emr_cluster" {
  title = "EMR Cluster"
  color = local.analytics_color
  href  = "/aws_insights.dashboard.aws_emr_cluster_detail?input.emr_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:EMR"
}

category "aws_vpc_subnet" {
  title = "VPC Subnet"
  href  = "/aws_insights.dashboard.aws_vpc_subnet_detail?input.subnet_id={{.properties.'Subnet ID' | @uri}}"
  icon  = "share"
  color = local.network_color
}

category "aws_elasticache_cluster" {
  title = "ElastiCache Cluster"
  color = local.database_color
  href  = "/aws_insights.dashboard.aws_elasticache_cluster_detail.url_path?input.elasticache_cluster_arn={{.properties.ARN | @uri}}"
  icon  = "circle-stack"
}

category "aws_elasticache_parameter_group" {
  title = "elasticache Parameter Group"
  color = local.database_color
  icon  = "text:PG"
}

category "aws_elasticache_subnet_group" {
  title = "elasticache Subnet Group"
  color = local.database_color
  icon  = "text:SG"
}

category "aws_vpc_eip" {
  title = "VPC EIP"
  color = local.network_color
  href  = "/aws_insights.dashboard.aws_vpc_eip_detail?input.eip_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:EIP"
}

category "aws_eks_cluster" {
  title = "EKS Cluster"
  color = local.container_color
  href  = "/aws_insights.dashboard.aws_eks_cluster_detail?input.eks_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "cog"
}

category "aws_eks_identity_provider_config" {
  title = "EKS Identity Provider Config"
  color = local.container_color
  icon  = "IPC"
}

category "aws_eks_fargate_profile" {
  title = "EKS Farget Profile"
  color = local.container_color
  icon  = "FP"
}

category "aws_sqs_queue" {
  title = "SQS Queue"
  color = local.integration_color
  href  = "/aws_insights.dashboard.aws_sqs_queue_detail?input.queue_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:Queue"
}

category "aws_eventbridge_rule" {
  title = "EventBridge Rule"
  color = local.integration_color
  href  = "/aws_insights.dashboard.aws_eventbridge_rule_detail?input.eventbridge_rule_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:Rule"
}

category "aws_api_gatewayv2_api" {
  title = "API Gatewayv2 API"
  href  = "/aws_insights.dashboard.api_gatewayv2_api_detail?input.api_id={{.properties.'ID' | @uri}}"
  icon  = "bolt"
  color = local.frontend_web_color
}

category "aws_backup_plan" {
  title = "Backup Plan"
  color = local.storage_color
  href  = "/aws_insights.dashboard.backup_plan_detail?input.backup_plan_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:Backup"
}

category "aws_backup_vault" {
  title = "Backup Vault"
  color = local.storage_color
  href  = "/aws_insights.dashboard.backup_vault_detail?input.backup_vault_arn={{.properties.'ARN' | @uri}}"
  icon  = "archive-box-arrow-down"
}

category "aws_backup_recovery_point" {
  title = "Backup Recovery Point"
  color = local.storage_color
  icon  = "text:recovery"
}

category "aws_glacier_vault" {
  title = "Glacier Vault"
  color = local.storage_color
  href  = "/aws_insights.dashboard.glacier_vault_detail?input.vault_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:Glacier"
}

category "aws_codepipeline_pipeline" {
  title = "CodePipeline Pipeline"
  color = local.dev_tool_color
  href  = "/aws_insights.dashboard.codepipeline_pipeline_detail?input.pipeline_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:CICD"
}

category "aws_dax_cluster" {
  title = "DAX Cluster"
  color = local.database_color
  href  = "/aws_insights.dashboard.dax_cluster_detail?input.dax_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "clipboard-document-check"
}

category "aws_dynamodb_table" {
  title = "DynamoDB Table"
  color = local.database_color
  href  = "/aws_insights.dashboard.dynamodb_table_detail?input.table_arn={{.properties.'ARN' | @uri}}"
  icon  = "circle-stack"
}

category "aws_dax_subnet_group" {
  title = "DAX Subnet Group"
  color = local.database_color
  icon  = "text:SG"
}

category "aws_codecommit_repository" {
  title = "CodeCommit Repository"
  href  = "/aws_insights.dashboard.aws_codecommit_repository_detail?input.codecommit_repository_arn={{.properties.'ARN' | @uri}}"
  color = local.dev_tool_color
  icon  = "text:CICD"
}

category "aws_codebuild_project" {
  title = "CodeBuild Project"
  color = local.dev_tool_color
  href  = "/aws_insights.dashboard.aws_codebuild_project_detail?input.codebuild_project_arn={{.properties.'ARN' | @uri}}"
  icon  = "code-bracket-square"
}

category "aws_kinesisanalyticsv2_application" {
  title = "Kinesis Analytics Applications"
  color = local.analytics_color
  icon  = "text:Application"
}

category "aws_s3_access_point" {
  title = "S3 Access Point"
  color = local.storage_color
  icon  = "text:AP"
}

category "aws_cloudformation_stack" {
  title = "CloudFormation Stack"
  color = local.mg_color
  icon  = "text:CFN"
}

category "aws_kinesis_stream" {
  title = "Kinesis Stream"
  color = local.analytics_color
  icon  = "text:Stream"
}

category "aws_vpc_endpoint" {
  title = "VPC Endpoint"
  color = local.network_color
  icon  = "text:Endpoint"
}

category "aws_vpc_internet_gateway" {
  title = "VPC Internet Gateway"
  icon  = "text:IGW"
  color = local.network_color
}

category "aws_vpc_route_table" {
  title = "VPC Route Table"
  icon  = "arrows-right-left"
  color = local.network_color
}

category "aws_vpc_nat_gateway" {
  title = "VPC NAT Gateway"
  icon  = "text:NAT"
  color = local.network_color
}

category "aws_vpc_vpn_gateway" {
  title = "VPC VPN Gateway"
  icon  = "text:VPN"
  color = local.network_color
}

category "aws_vpc_network_acl" {
  title = "VPC Network ACL"
  icon  = "text:ACL"
  color = local.network_color
}

category "aws_cloudwatch_log_group" {
  title = "CloudWatch Log Group"
  color = local.mg_color
  href  = "/aws_insights.dashboard.aws_cloudwatch_log_group_detail?input.log_group_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:CW"
}

category "aws_guardduty_detector" {
  title = "GuardDuty Detector"
  color = local.security_color
  icon  = "text:Detector"
}

category "aws_media_store_container" {
  title = "Media Store Container"
  color = local.container_color
  icon  = "building-storefront"
}

category "aws_eventbridge_bus" {
  title = "EventBridge Bus"
  color = local.integration_color
  icon  = "text:Bus"
}

category "aws_appconfig_application" {
  title = "AppConfig Application"
  color = local.integration_color
  icon  = "cog-6-tooth"
}

category "aws_api_gatewayv2_stage" {
  title = "API Gatewayv2 Stage"
  color = local.frontend_web_color
  icon  = "text:Stage"
}

category "aws_sfn_state_machine" {
  title = "Step Function State Machine"
  color = local.integration_color
  icon  = "text:SFN"
}

category "aws_ec2_launch_configuration" {
  title = "EC2 Launch Configuration"
  color = local.compute_color
  icon  = "newspaper"
}

category "aws_dms_replication_instance" {
  title = "DMS Replication Instance"
  color = local.database_color
  icon  = "text:DMS"
}

category "aws_sagemaker_notebook_instance" {
  title = "Sagemaker Notebook Instance"
  color = local.ml_color
  icon  = "text:Instance"
}

category "aws_backup_selection" {
  title = "Backup Selection"
  color = local.storage_color
  icon  = "text:Selection"
}

category "aws_ecs_task" {
  title = "ECS Task"
  color = local.compute_color
  icon  = "text:Task"
}

category "aws_codedeploy_app" {
  title = "CodeDeploy Application"
  color = local.dev_tool_color
  icon  = "text:CICD"
}

category "aws_eks_addon" {
  title = "EKS Addon"
  color = local.container_color
  icon  = "text:Addon"
}

category "aws_eks_node_group" {
  title = "EKS Node Group"
  color = local.container_color
  icon  = "rectangle-group"
}

category "aws_emr_instance_fleet" {
  title = "EMR instance fleet"
  color = local.analytics_color
  icon  = "text:EMR"
}

category "aws_emr_instance_group" {
  title = "EMR instance group"
  color = local.analytics_color
  icon  = "rectangle-group"
}

category "aws_vpc_peering_connection" {
  title = "VPC Peering Connection"
  color = local.network_color
  icon  = "text:Peering"
}

graph "aws_graph_categories" {
  type  = "graph"
  title = "Relationships"
}

category "aws_fsx_file_system" {
  title = "FSX File System"
  icon  = "document-arrowup"
  color = local.storage_color
}


category "aws_ec2_transit_gateway" {
  title = "Transit Gateway"
  icon  = "arrows-right-left"
  color = local.network_color
}

category "aws_availability_zone" {
  title = "Availability Zone"
  icon  = "building-office"
  color = local.network_color
}


category "aws_account" {
  title = "Account"
  icon  = "globe-alt"
  color = local.compute_color
}


category "aws_region" {
  title = "Region"
  icon  = "globe-americas"
  color = local.compute_color
}


category "aws_api_gatewayv2_integration" {
  title = "API Gatewayv2 integration"
  icon  = "puzzle-piece"
  color = local.frontend_web_color
}

category "aws_opensearch_domain" {
  title = "OpenSearch Domain"
  icon  = "text:OS"
  color = local.analytics_color
}
