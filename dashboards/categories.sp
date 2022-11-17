category "aws_docdb_cluster" {
  title = "DocumentDB Cluster"
  icon  = "text:docdb"
  color = local.docdb_color
}

category "aws_ec2_classic_load_balancer" {
  title = "EC2 Classic Load Balancer"
  href  = "/aws_insights.dashboard.aws_ec2_classic_load_balancer_detail?input.clb={{.properties.'ARN' | @uri}}"
  icon  = "text:clb"
  color = local.network_color
}

category "aws_ec2_application_load_balancer" {
  title = "EC2 Application Load Balancer"
  href  = "/aws_insights.dashboard.aws_ec2_application_load_balancer_detail?input.alb={{.properties.'ARN' | @uri}}"
  icon  = "text:alb"
  color = local.network_color
}

category "aws_ec2_network_load_balancer" {
  title = "EC2 Network Load Balancer"
  href  = "/aws_insights.dashboard.aws_ec2_network_load_balancer_detail?input.nlb={{.properties.'ARN' | @uri}}"
  icon  = "text:nlb"
  color = local.network_color
}

category "aws_ec2_gateway_load_balancer" {
  title = "EC2 Gateway Load Balancer"
  href  = "/aws_insights.dashboard.aws_ec2_gateway_load_balancer_detail?input.glb={{.properties.'ARN' | @uri}}"
  icon  = "text:glb"
  color = local.network_color
}

category "aws_ec2_load_balancer_listener" {
  title = "EC2 Load Balancer Listener"
  color = local.network_color
  icon  = "text:lbl"
}

category "aws_ecs_cluster" {
  title = "ECS Cluster"
  href  = "/aws_insights.dashboard.aws_ecs_cluster_detail?input.ecs_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:ecs cluster"
  color = local.compute_color
}

category "aws_ecs_container_instance" {
  title = "ECS Container Instance"
  icon  = "text:ecs instance"
  color = local.compute_color
}

category "aws_ecs_task_definition" {
  title = "ECS Tasks Definition"
  color = local.compute_color
  href  = "/aws_insights.dashboard.aws_ecs_task_definition_detail?input.task_definition_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:ecs TD"
}

category "aws_ecs_service" {
  title = "ECS Service"
  color = local.compute_color
  icon  = "text:ecs service"
  href  = "/aws_insights.dashboard.aws_ecs_service_detail?input.service_arn={{.properties.'ARN' | @uri}}"
}

category "aws_s3_bucket" {
  title = "S3 Bucket"
  href  = "/aws_insights.dashboard.aws_s3_bucket_detail?input.bucket_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:s3 bucket"
  color = local.storage_color
}

category "aws_cloudfront_distribution" {
  title = "CloudFront Distribution"
  color = local.network_color
  href  = "/aws_insights.dashboard.aws_cloudfront_distribution_detail?input.distribution_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:CD"
}

category "aws_acm_certificate" {
  title = "ACM Certificate"
  href  = "/aws_insights.dashboard.acm_certificate_detail?input.certificate_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:acm"
  color = local.iam_color
}

category "aws_sns_topic" {
  title = "SNS Topic"
  href  = "/aws_insights.dashboard.aws_sns_topic_detail?input.topic_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:sns topic"
  color = "deeppink"
}

category "aws_sns_topic_subscription" {
  title = "SNS Subscription"
  icon  = "heroicons-outline:rss"
  color = "deeppink"
}


category "aws_kms_key" {
  title = "KMS Key"
  href  = "/aws_insights.dashboard.aws_kms_key_detail?input.key_arn={{.properties.'ARN' | @uri}}"
  icon  = "heroicons-outline:key"
  color = local.kms_color
}

category "aws_cloudtrail_trail" {
  title = "CloudTrail Trail"
  color = "pink"
  href  = "/aws_insights.dashboard.aws_cloudtrail_trail_detail?input.trail_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:trail"
}

category "aws_ebs_volume" {
  title = "EBS Volume"
  href  = "/aws_insights.dashboard.aws_ebs_volume_detail?input.volume_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:volume"
  color = local.storage_color
}

category "aws_ebs_snapshot" {
  title = "EBS Snapshot"
  href  = "/aws_insights.dashboard.aws_ebs_snapshot_detail?input.snapshot_arn={{.properties.'ARN' | @uri}}"
  color = local.storage_color
  icon  = "text:snapshot"
}

category "aws_rds_db_cluster" {
  title = "RDS DB Cluster"
  color = "blue"
  href  = "/aws_insights.dashboard.aws_rds_db_cluster_detail.url_path?input.db_cluster_arn={{.properties.ARN | @uri}}"
  icon  = "text:cluster"
}

category "aws_rds_db_cluster_snapshot" {
  title = "RDS DB Cluster Snapshot"
  color = "blue"
  href  = "/aws_insights.dashboard.aws_rds_db_cluster_snapshot_detail.url_path?input.snapshot_arn={{.properties.ARN | @uri}}"
  icon  = "text:snapshot"
}

category "aws_rds_db_instance" {
  title = "RDS DB Instance"
  color = "blue"
  href  = "/aws_insights.dashboard.aws_rds_db_instance_detail.url_path?input.db_instance_arn={{.properties.ARN | @uri}}"
  icon  = "text:instance"
}

category "aws_rds_db_snapshot" {
  title = "RDS DB Snapshot"
  color = "blue"
  href  = "/aws_insights.dashboard.aws_rds_db_snapshot_detail.url_path?input.db_snapshot_arn={{.properties.ARN | @uri}}"
  icon  = "text:snapshot"
}

category "aws_rds_db_cluster_parameter_group" {
  title = "RDS DB Cluster Parameter Group"
  color = "blue"
  icon  = "text:PG"
}

category "aws_rds_db_parameter_group" {
  title = "RDS DB Parameter Group"
  color = "blue"
  icon  = "text:PG"
}

category "aws_rds_db_subnet_group" {
  title = "RDS DB Subnet Group"
  color = "blue"
  icon  = "text:SG"
}

category "aws_redshift_cluster" {
  title = "Redshift Cluster"
  color = local.network_color
  href  = "/aws_insights.dashboard.aws_redshift_cluster_detail?input.cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:redshift"
}

category "aws_redshift_snapshot" {
  title = "Redshift Snapshot"
  color = local.network_color
  href  = "/aws_insights.dashboard.aws_redshift_snapshot_detail?input.snapshot_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:snapshot"
}

category "aws_redshift_subnet_group" {
  title = "Redshift Subnet Group"
  color = local.network_color
  icon  = "text:SG"
}

category "aws_redshift_parameter_group" {
  title = "Redshift Parameter Group"
  color = local.network_color
  icon  = "text:PG"
}

category "aws_ec2_ami" {
  title = "EC2 AMI"
  href  = "aws_insights.dashboard.aws_ec2_ami_detail?input.ami={{.properties.'Image ID' | @uri}}"
  color = local.compute_color
  icon  = "text:AMI"
}

category "aws_ec2_autoscaling_group" {
  title = "EC2 Autoscaling Group"
  icon  = "heroicons-outline:square-2-stack"
  color = local.compute_color
}

category "aws_ec2_target_group" {
  title = "EC2 Target Group"
  icon  = "heroicons-outline:arrow-down-on-square"
  color = local.network_color
}

category "aws_ec2_key_pair" {
  title = "EC2 Key Pair"
  icon  = "heroicons-outline:key"
  color = local.compute_color
}

category "aws_ecr_repository" {
  title = "ECR repository"
  color = local.compute_color
  href  = "aws_insights.dashboard.aws_ecr_repository_detail?input.ecr_repository_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:ecr"
}

category "aws_ecr_image" {
  title = "ECR image"
  color = local.compute_color
  icon  = "text:image"
}

category "aws_efs_file_system" {
  title = "EFS File System"
  color = local.storage_color
  icon  = "text:file"
}

category "aws_efs_mount_target" {
  title = "EFS Mount Target"
  color = local.storage_color
  icon  = "text:target"
}

category "aws_ec2_instance" {
  title = "EC2 Instance"
  href  = "/aws_insights.dashboard.aws_ec2_instance_detail?input.instance_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:instance"
  color = local.compute_color
}

category "aws_ec2_network_interface" {
  title = "EC2 Network Interface"
  href  = "/aws_insights.dashboard.aws_ec2_network_interface_detail?input.network_interface_id={{.properties.'Interface ID' | @uri}}"
  icon  = "text:eni"
  color = local.network_color
}

category "aws_vpc" {
  title = "VPC"
  href  = "/aws_insights.dashboard.aws_vpc_detail?input.vpc_id={{.properties.'VPC ID' | @uri}}"
  icon  = "heroicons-outline:cloud" //"text:vpc"
  color = local.network_color
}


category "aws_vpc_security_group" {
  title = "VPC Security Group"
  href  = "/aws_insights.dashboard.aws_vpc_security_group_detail?input.security_group_id={{.properties.'Group ID' | @uri}}"
  icon  = "heroicons-solid:lock-closed"
  color = local.network_color
}

category "aws_vpc_flow_log" {
  title = "VPC Flow Log"
  href  = "/aws_insights.dashboard.aws_vpc_flow_logs_detail?input.flow_log_id={{.properties.'Flow Log ID' | @uri}}"
  color = local.network_color
  icon  = "text:flowLog"
}

category "aws_iam_role" {
  title = "IAM Role"
  href  = "/aws_insights.dashboard.aws_iam_role_detail?input.role_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:role"
  color = local.iam_color
}

category "aws_emr_instance" {
  title = "EMR Instances"
  color = local.network_color
  href  = "/aws_insights.dashboard.aws_ec2_instance_detail?input.instance_arn={{.properties.'EC2 Instance ARN' | @uri}}"
  icon  = "text:emr"
}

category "aws_iam_policy" {
  title = "IAM Policy"
  color = local.iam_color
  href  = "/aws_insights.dashboard.aws_iam_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:policy"
}

category "aws_iam_user" {
  title = "IAM User"
  color = local.iam_color
  href  = "/aws_insights.dashboard.aws_iam_user_detail?input.user_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:user"
}

category "aws_iam_group" {
  title = "IAM Group"
  color = local.iam_color
  href  = "/aws_insights.dashboard.aws_iam_group_detail?input.group_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:group"
}

category "aws_iam_instance_profile" {
  title = "IAM Instance Profile"
  color = local.iam_color
  icon  = "text:profile"
}

category "aws_iam_access_key" {
  title = "IAM Access Key"
  color = local.iam_color
  icon  = "text:accesskey"
}

category "aws_iam_profile" {
  title = "IAM Profile"
  icon  = "heroicons-outline:user-plus"
  color = local.iam_color
}

category "aws_lambda_function" {
  title = "Lambda Function"
  href  = "/aws_insights.dashboard.aws_lambda_function_detail?input.lambda_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:lambda"
  color = local.compute_color
}

category "aws_lambda_alias" {
  title = "Lambda Alias"
  icon  = "heroicons-outline:at-symbol"
  color = local.compute_color
}

category "aws_lambda_version" {
  title = "Lambda Version"
  icon  = "heroicons-outline:document-duplicate"
  color = local.compute_color
}


category "aws_emr_cluster" {
  title = "EMR Cluster"
  color = local.network_color
  href  = "/aws_insights.dashboard.aws_emr_cluster_detail?input.emr_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:cluster"
}

category "aws_vpc_subnet" {
  title = "VPC Subnet"
  href  = "/aws_insights.dashboard.aws_vpc_subnet_detail?input.subnet_id={{.properties.'Subnet ID' | @uri}}"
  icon  = "heroicons-solid:share"
  color = local.network_color
}

category "aws_elasticache_cluster" {
  title = "ElastiCache Cluster"
  color = "blue"
  href  = "/aws_insights.dashboard.aws_elasticache_cluster_detail.url_path?input.elasticache_cluster_arn={{.properties.ARN | @uri}}"
  icon  = "text:cluster"
}

category "aws_elasticache_subnet_group" {
  title = "elasticache Subnet Group"
  color = "blue"
  icon  = "text:sg"
}

category "aws_vpc_eip" {
  title = "VPC EIP"
  color = local.network_color
  href  = "/aws_insights.dashboard.aws_vpc_eip_detail?input.eip_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:eip"
}

category "aws_eks_cluster" {
  title = "EKS Cluster"
  color = local.compute_color
  href  = "/aws_insights.dashboard.aws_eks_cluster_detail?input.eks_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:cluster"
}

category "aws_sqs_queue" {
  title = "SQS Queue"
  color = local.sqs_color
  href  = "/aws_insights.dashboard.aws_sqs_queue_detail?input.queue_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:queue"
}

category "aws_eventbridge_rule" {
  title = "EventBridge Rule"
  color = "pink"
  href  = "/aws_insights.dashboard.aws_eventbridge_rule_detail?input.eventbridge_rule_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:rule"
}

category "aws_api_gatewayv2_api" {
  title = "API Gatewayv2 API"
  href  = "/aws_insights.dashboard.api_gatewayv2_api_detail?input.api_id={{.properties.'ID' | @uri}}"
  icon  = "heroicons-outline:bolt"
  color = local.iam_color
}

category "aws_backup_plan" {
  title = "Backup Plan"
  color = local.storage_color
  href  = "/aws_insights.dashboard.backup_plan_detail?input.backup_plan_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:plan"
}

category "aws_backup_vault" {
  title = "Backup Vault"
  color = local.storage_color
  href  = "/aws_insights.dashboard.backup_vault_detail?input.backup_vault_arn={{.properties.'ARN' | @uri}}"
  icon  = "vault"
}

category "aws_glacier_vault" {
  title = "Glacier Vault"
  color = local.storage_color
  href  = "/aws_insights.dashboard.glacier_vault_detail?input.vault_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:glacier"
}

category "aws_codepipeline_pipeline" {
  title = "CodePipeline Pipeline"
  color = "blue"
  href  = "/aws_insights.dashboard.codepipeline_pipeline_detail?input.pipeline_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:pipeline"
}

category "aws_dax_cluster" {
  title = "DAX Cluster"
  color = "blue"
  href  = "/aws_insights.dashboard.dax_cluster_detail?input.dax_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:dax"
}

category "aws_dynamodb_table" {
  title = "DynamoDB Table"
  color = "blue"
  href  = "/aws_insights.dashboard.dynamodb_table_detail?input.table_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:dynamodb"
}

category "aws_dax_subnet_group" {
  title = "DAX Subnet Group"
  color = "blue"
  icon  = "text:SG"
}

category "aws_codecommit_repository" {
  title = "CodeCommit Repository"
  href  = "/aws_insights.dashboard.aws_codecommit_repository_detail?input.codecommit_repository_arn={{.properties.'ARN' | @uri}}"
  color = "blue"
  icon  = "text:repo"
}

category "aws_codebuild_project" {
  title = "CodeBuild Project"
  color = "blue"
  href  = "/aws_insights.dashboard.aws_codebuild_project_detail?input.codebuild_project_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:project"
}

category "aws_kinesisanalyticsv2_application" {
  title = "Kinesis Analytics Applications"
  color = local.network_color
  icon  = "text:applications"
}

category "aws_s3_access_point" {
  title = "S3 Access Point"
  color = local.storage_color
  icon  = "text:point"
}

category "aws_cloudformation_stack" {
  title = "CloudFormation Stack"
  color = "pink"
  icon  = "text:stack"
}

category "aws_kinesis_stream" {
  title = "Kinesis Stream"
  color = local.network_color
  icon  = "text:stream"
}

category "aws_vpc_endpoint" {
  title = "VPC Endpoint"
  color = local.network_color
  icon  = "text:endpoint"
}

category "aws_vpc_internet_gateway" {
  title = "VPC Internet Gateway"
  icon  = "text:gateway"
  color = local.network_color
}

category "aws_vpc_route_table" {
  title = "VPC Route Table"
  icon  = "text:table"
  color = local.network_color
}

category "aws_vpc_nat_gateway" {
  title = "VPC NAT Gateway"
  icon  = "text:nat"
  color = local.network_color
}

category "aws_vpc_vpn_gateway" {
  title = "VPC VPN Gateway"
  icon  = "text:vpn"
  color = local.network_color
}

category "aws_vpc_network_acl" {
  title = "VPC Network ACL"
  icon  = "text:acl"
  color = local.network_color
}

category "aws_cloudwatch_log_group" {
  title = "CloudWatch Log Group"
  color = "pink"
  href  = "/aws_insights.dashboard.aws_cloudwatch_log_group_detail?input.log_group_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:log"
}

category "aws_guardduty_detector" {
  title = "GuardDuty Detector"
  color = local.iam_color
  icon  = "text:detector"
}

category "aws_media_store_container" {
  title = "Media Store Container"
  color = local.compute_color
  icon  = "text:container"
}

category "aws_eventbridge_bus" {
  title = "EventBridge Bus"
  color = "pink"
  icon  = "text:bus"
}

category "aws_appconfig_application" {
  title = "AppConfig Application"
  color = "pink"
  icon  = "text:application"
}

category "aws_api_gatewayv2_stage" {
  title = "API Gatewayv2 Stage"
  color = local.network_color
  icon  = "text:stage"
}

category "aws_sfn_state_machine" {
  title = "Step Function State Machine"
  color = "#B0084D"
  icon  = "text:sfn"
}

category "aws_ec2_launch_configuration" {
  title = "EC2 Launch Configuration"
  color = local.compute_color
  icon  = "text:launch_config"
}

category "aws_dms_replication_instance" {
  title = "DMS Replication Instance"
  color = "blue"
  icon  = "text:dms"
}

category "aws_sagemaker_notebook_instance" {
  title = "Sagemaker Notebook Instance"
  color = "light green"
  icon  = "text:instance"
}

category "aws_backup_selection" {
  title = "Backup Selection"
  color = local.storage_color
  icon  = "text:selection"
}

category "aws_ecs_task" {
  title = "ECS Task"
  color = local.compute_color
  icon  = "text:task"
}

category "aws_codedeploy_app" {
  title = "CodeDeploy Application"
  color = "blue"
  icon  = "text:app"
}

category "aws_eks_addon" {
  title = "EKS Addon"
  color = local.compute_color
  icon  = "text:addon"
}

category "aws_eks_node_group" {
  title = "EKS Node Group"
  color = local.compute_color
  icon  = "text:group"
}

category "aws_emr_instance_fleet" {
  title = "EMR instance fleet"
  color = local.network_color
  icon  = "text:fleet"
}

category "aws_emr_instance_group" {
  title = "EMR instance group"
  color = local.network_color
  icon  = "text:group"
}

category "aws_vpc_peering_connection" {
  title = "VPC Peering Connection"
  color = local.network_color
  icon  = "text:peering"
}

graph "aws_graph_categories" {
  type  = "graph"
  title = "Relationships"
}

category "aws_fsx_file_system" {
  title = "FSX File System"
  icon  = "heroicons-outline:document-duplicate"
  color = local.storage_color
}


category "aws_ec2_transit_gateway" {
  title = "Transit Gateway"
  icon  = "heroicons-outline:arrows-right-left"
  color = local.network_color
}

category "aws_availability_zone" {
  title = "Availability Zone"
  icon  = "heroicons-outline:building-office"
  color = local.network_color
}



category "aws_account" {
  title = "Account"
  icon  = "heroicons-outline:globe-alt"
  color = local.compute_color
}


category "aws_region" {
  title = "Region"
  icon  = "heroicons-outline:globe-americas"
  color = local.compute_color
}


category "aws_api_gatewayv2_integration" {
  title = "API Gatewayv2 integration"
  icon  = "heroicons-outline:puzzle-piece"
  color = local.iam_color
}
