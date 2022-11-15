category "aws_docdb_cluster" {
  fold {
    title     = "DocumentDB Cluster"
    threshold = 3
  }
}

category "aws_ec2_classic_load_balancer" {
  href = "/aws_insights.dashboard.aws_ec2_classic_load_balancer_detail?input.clb={{.properties.'ARN' | @uri}}"
  icon = local.aws_ec2_classic_load_balancer_icon
  color = "purple"
  fold {
    title     = "EC2 Classic Load Balancers"
    icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "aws_ec2_application_load_balancer" {
  href = "/aws_insights.dashboard.aws_ec2_application_load_balancer_detail?input.alb={{.properties.'ARN' | @uri}}"
  icon = local.aws_ec2_application_load_balancer_icon
  color = "purple"

  fold {
    title     = "EC2 Application Load Balancers"
    icon      = local.aws_ec2_application_load_balancer_icon
    threshold = 3
  }
}

category "aws_ec2_network_load_balancer" {
  href = "/aws_insights.dashboard.aws_ec2_network_load_balancer_detail?input.nlb={{.properties.'ARN' | @uri}}"
  icon = local.aws_ec2_network_load_balancer_icon
  color = "purple"

  fold {
    title     = "EC2 Network Load Balancers"
    icon      = local.aws_ec2_network_load_balancer_icon
    threshold = 3
  }
}

category "aws_ec2_gateway_load_balancer" {
  href = "/aws_insights.dashboard.aws_ec2_gateway_load_balancer_detail?input.glb={{.properties.'ARN' | @uri}}"
  icon = local.aws_ec2_gateway_load_balancer_icon
  color = "purple"

  fold {
    title     = "EC2 Gateway Load Balancers"
    icon      = local.aws_ec2_gateway_load_balancer_icon
    threshold = 3
  }
}

category "aws_ec2_load_balancer_listener" {
  fold {
    title     = "EC2 Load Balancer Listeners"
    threshold = 3
  }
}

category "aws_ec2_transit_gateway" {
  icon = local.aws_ec2_transit_gateway_icon
  fold {
    title     = "EC2 Transit Gateways"
    icon = local.aws_ec2_transit_gateway_icon
    threshold = 3
  }
}

category "aws_ecs_cluster" {
  href  = "/aws_insights.dashboard.aws_ecs_cluster_detail?input.ecs_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = local.aws_ecs_task_definition_icon
  color = "orange"

  fold {
    icon = local.aws_ecs_task_definition_icon
    title     = "ECS Clusters"
    threshold = 3
  }
}

category "aws_ecs_container_instance" {
  fold {
    title     = "ECS Container Instances"
    threshold = 3
  }
}

category "aws_ecs_task_definition" {
  href = "/aws_insights.dashboard.aws_ecs_task_definition_detail?input.task_definition_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_ecs_task_definition_icon
  fold {
    title     = "ECS Tasks Definitions"
    threshold = 3
  }
}

category "aws_ecs_service" {
  href = "/aws_insights.dashboard.aws_ecs_service_detail?input.service_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_ecs_service_icon
  fold {
    threshold = 3
    title     = "ECS Services"
    icon      = local.aws_ecs_service_icon
  }
}

category "aws_s3_bucket" {
  href = "/aws_insights.dashboard.aws_s3_bucket_detail?input.bucket_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_s3_bucket_icon
  color = "green"

  fold {
    title     = "S3 Buckets"
    icon      = local.aws_s3_bucket_icon
    threshold = 3
  }
}

category "aws_cloudfront_distribution" {
  href = "/aws_insights.dashboard.aws_cloudfront_distribution_detail?input.distribution_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_cloudfront_distribution_icon
  fold {
    title     = "CloudFront Distributions"
    icon      = local.aws_cloudfront_distribution_icon
    threshold = 3
  }
}

category "aws_acm_certificate" {
  href = "/aws_insights.dashboard.acm_certificate_detail?input.certificate_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_acm_certificate_icon
  color = "red"
  fold {
    title     = "ACM Certificates"
    icon      = local.aws_acm_certificate_icon
    threshold = 3
  }
}

category "aws_sns_topic" {
  href = "/aws_insights.dashboard.aws_sns_topic_detail?input.topic_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_sns_topic_icon
  color = "red"

  fold {
    title     = "SNS Topics"
    icon      = local.aws_sns_topic_icon
    threshold = 3
  }
}

category "aws_sns_topic_subscription" {
  icon = "heroicons-outline:rss"
  color = "red"

  fold {
    title     = "SNS Subscription"
    icon = "heroicons-outline:rss"
    threshold = 3
  }
}


category "aws_kms_key" {
  href  = "/aws_insights.dashboard.aws_kms_key_detail?input.key_arn={{.properties.'ARN' | @uri}}"
  icon  = "heroicons-outline:key"
  color = "red"

  fold {
    title     = "KMS Keys"
    threshold = 3
  }
}

category "aws_cloudtrail_trail" {
  href = "/aws_insights.dashboard.aws_cloudtrail_trail_detail?input.trail_arn={{.properties.'ARN' | @uri}}"
  fold {
    title     = "CloudTrail Trails"
    threshold = 3
  }
}

category "aws_ebs_volume" {
  href  = "/aws_insights.dashboard.aws_ebs_volume_detail?input.volume_arn={{.properties.'ARN' | @uri}}"
  icon  = local.aws_ebs_volume_icon
  color = "green"
  fold {
    title     = "EBS Volumes"
    icon      = local.aws_ebs_volume_icon
    threshold = 3
  }
}

category "aws_ebs_snapshot" {
  href = "/aws_insights.dashboard.aws_ebs_snapshot_detail?input.snapshot_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_ebs_snapshot_icon
  fold {
    title     = "EBS Snapshots"
    icon      = local.aws_ebs_snapshot_icon
    threshold = 3
  }
}

category "aws_rds_db_cluster" {
  href = "/aws_insights.dashboard.aws_rds_db_cluster_detail.url_path?input.db_cluster_arn={{.properties.ARN | @uri}}"
  icon = local.aws_rds_db_cluster_icon
  fold {
    title     = "RDS DB Clusters"
    icon      = local.aws_rds_db_cluster_icon
    threshold = 3
  }
}

category "aws_rds_db_cluster_snapshot" {
  href = "/aws_insights.dashboard.aws_rds_db_cluster_snapshot_detail.url_path?input.snapshot_arn={{.properties.ARN | @uri}}"
  fold {
    title     = "RDS DB Cluster Snapshots"
    threshold = 3
  }
}

category "aws_rds_db_instance" {
  href = "/aws_insights.dashboard.aws_rds_db_instance_detail.url_path?input.db_instance_arn={{.properties.ARN | @uri}}"
  icon = local.aws_rds_db_instance_icon
  fold {
    title     = "RDS DB Instances"
    icon      = local.aws_rds_db_instance_icon
    threshold = 3
  }
}

category "aws_rds_db_snapshot" {
  href = "/aws_insights.dashboard.aws_rds_db_snapshot_detail.url_path?input.db_snapshot_arn={{.properties.ARN | @uri}}"
  fold {
    title     = "RDS DB Snapshots"
    threshold = 3
  }
}

category "aws_rds_db_cluster_parameter_group" {
  fold {
    title     = "RDS DB Cluster Parameter Group"
    threshold = 3
  }
}

category "aws_rds_db_parameter_group" {
  fold {
    title     = "RDS DB Parameter Group"
    threshold = 3
  }
}

category "aws_rds_db_subnet_group" {
  fold {
    title     = "RDS DB Subnet Group"
    threshold = 3
  }
}

category "aws_redshift_cluster" {
  href = "/aws_insights.dashboard.aws_redshift_cluster_detail?input.cluster_arn={{.properties.'ARN' | @uri}}"
  fold {
    title     = "Redshift Clusters"
    threshold = 3
  }
}

category "aws_redshift_snapshot" {
  href = "/aws_insights.dashboard.aws_redshift_snapshot_detail?input.snapshot_arn={{.properties.'ARN' | @uri}}"
  fold {
    title     = "Redshift Snapshots"
    threshold = 3
  }
}

category "aws_redshift_subnet_group" {
  fold {
    title     = "Redshift Subnet Groups"
    threshold = 3
  }
}

category "aws_redshift_parameter_group" {
  fold {
    title     = "Redshift Parameter Groups"
    threshold = 3
  }
}

category "aws_ec2_ami" {
  href = "aws_insights.dashboard.aws_ec2_ami_detail?input.ami={{.properties.'Image ID' | @uri}}"
  icon = local.aws_ec2_ami_icon
  fold {
    title     = "EC2 AMIs"
    icon      = local.aws_ec2_ami_icon
    threshold = 3
  }
}

category "aws_ec2_autoscaling_group" {
  icon  = "heroicons-outline:square-2-stack"
  color = "orange"

  fold {
    icon  = "heroicons-outline:square-2-stack"
    title     = "EC2 Autoscaling Groups"
    threshold = 3
  }
}

category "aws_ec2_target_group" {
  icon  = "heroicons-outline:arrow-down-on-square"
  color = "purple"

  fold {
    icon  = "heroicons-outline:arrow-down-on-square"
    title     = "EC2 Autoscaling Groups"
    threshold = 3
  }
}

category "aws_ec2_key_pair" {
  icon  = "heroicons-outline:key"
  color = "orange"
  fold {
    icon = "heroicons-outline:key"
    title     = "EC2 Key Pair"
    threshold = 3
  }
}

category "aws_ecr_repository" {
  href = "aws_insights.dashboard.aws_ecr_repository_detail?input.ecr_repository_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_ecr_repository_icon
  fold {
    title     = "ECR repositories"
    threshold = 3
  }
}

category "aws_ecr_image" {
  icon = local.aws_ecr_image_icon
  fold {
    title     = "ECR images"
    threshold = 3
  }
}

category "aws_efs_file_system" {
  fold {
    title     = "EFS File Systems"
    threshold = 3
  }
}

category "aws_efs_mount_target" {
  fold {
    title     = "EFS Mount Targets"
    threshold = 3
  }
}

category "aws_ec2_instance" {
  href  = "/aws_insights.dashboard.aws_ec2_instance_detail?input.instance_arn={{.properties.'ARN' | @uri}}"
  icon  = local.aws_ec2_instance_icon
  color = "orange"

  fold {
    title     = "EC2 Instances"
    icon      = local.aws_ec2_instance_icon
    threshold = 3
  }
}

category "aws_ec2_network_interface" {
  href  = "/aws_insights.dashboard.aws_ec2_network_interface_detail?input.network_interface_id={{.properties.'Interface ID' | @uri}}"
  icon  = local.aws_ec2_network_interface_icon
  color = "purple"
  fold {
    title     = "EC2 Network Interfaces"
    icon      = local.aws_ec2_network_interface_icon
    threshold = 3
  }
}

category "aws_vpc" {
  href  = "/aws_insights.dashboard.aws_vpc_detail?input.vpc_id={{.properties.'VPC ID' | @uri}}"
  icon  = "heroicons-outline:cloud"  //"text:vpc"
  color = "purple"

  fold {
    icon  = "heroicons-outline:cloud"  //"text:vpc"
    title     = "VPCs"
    threshold = 3
  }
}


category "aws_vpc_security_group" {
  href = "/aws_insights.dashboard.aws_vpc_security_group_detail?input.security_group_id={{.properties.'Group ID' | @uri}}"
  icon  = "heroicons-solid:lock-closed"
  color = "purple"

  fold {
    icon  = "heroicons-outline:lock-closed"
    title     = "VPC Security Groups"
    threshold = 3
  }
}

category "aws_vpc_flow_log" {
  href = "/aws_insights.dashboard.aws_vpc_flow_logs_detail?input.flow_log_id={{.properties.'Flow Log ID' | @uri}}"
  icon = local.aws_vpc_flow_log_icon
  fold {
    title     = "VPC Flow Logs"
    icon = local.aws_vpc_flow_log_icon
    threshold = 3
  }
}

category "aws_iam_role" {
  href  = "/aws_insights.dashboard.aws_iam_role_detail?input.role_arn={{.properties.'ARN' | @uri}}"
  icon  = local.aws_iam_role_icon
  color = "red"
  fold {
    title     = "IAM Roles"
    icon      = local.aws_iam_role_icon
    threshold = 3
  }
}

category "aws_emr_instance" {
  href = "/aws_insights.dashboard.aws_ec2_instance_detail?input.instance_arn={{.properties.'EC2 Instance ARN' | @uri}}"
  icon = local.aws_ec2_instance_icon
  fold {
    title     = "EMR Instances"
    icon      = local.aws_ec2_instance_icon
    threshold = 3
  }
}

category "aws_iam_policy" {
  href = "/aws_insights.dashboard.aws_iam_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
  fold {
    title     = "IAM Policies"
    threshold = 3
  }
}

category "aws_iam_user" {
  href = "/aws_insights.dashboard.aws_iam_user_detail?input.user_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_iam_user_icon
  fold {
    title     = "IAM Users"
    icon      = local.aws_iam_user_icon
    threshold = 3
  }
}

category "aws_iam_group" {
  href = "/aws_insights.dashboard.aws_iam_group_detail?input.group_arn={{.properties.'ARN' | @uri}}"
  fold {
    title     = "IAM Groups"
    threshold = 3
  }
}

category "aws_iam_instance_profile" {
  fold {
    title     = "IAM Instance Profiles"
    threshold = 3
  }
}

category "aws_iam_access_key" {
  fold {
    title     = "IAM Access Key"
    threshold = 3
  }
}

category "aws_iam_profile" {
  icon  = "heroicons-outline:user-plus"
  color = "red"
  fold {
    icon = "heroicons-outline:user-plus"
    title     = "IAM Profiles"
    threshold = 3
  }
}

category "aws_lambda_function" {
  href  = "/aws_insights.dashboard.aws_lambda_function_detail?input.lambda_arn={{.properties.'ARN' | @uri}}"
  icon  = local.aws_lambda_function_icon
  color = "orange"

  fold {
    title     = "Lambda Functions"
    icon      = local.aws_lambda_function_icon
    threshold = 3
  }
}

category "aws_lambda_alias" {
  icon  = "heroicons-outline:at-symbol"
  color = "orange"

  fold {
    title     = "Lambda Aliases"
    icon      = "heroicons-outline:at-symbol"
    threshold = 3
  }
}

category "aws_lambda_version" {
  icon  = "heroicons-outline:document-duplicate"
  color = "orange"

  fold {
    title     = "Lambda Aliases"
    icon      = "heroicons-outline:document-duplicate"
    threshold = 3
  }
}


category "aws_emr_cluster" {
  href = "/aws_insights.dashboard.aws_emr_cluster_detail?input.emr_cluster_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_emr_cluster_icon
  fold {
    title     = "EMR Clusters"
    icon      = local.aws_emr_cluster_icon
    threshold = 3
  }
}

category "aws_vpc_subnet" {
  href  = "/aws_insights.dashboard.aws_vpc_subnet_detail?input.subnet_id={{.properties.'Subnet ID' | @uri}}"
  icon  = "heroicons-solid:share"
  color = "purple"

fold {
    icon  = "heroicons-solid:share"
    //color = "purple"
    title     = "VPC Subnets"
    threshold = 3
  }
}

category "aws_elasticache_cluster" {
  href = "/aws_insights.dashboard.aws_elasticache_cluster_detail.url_path?input.elasticache_cluster_arn={{.properties.ARN | @uri}}"
  icon = local.aws_elasticache_cluster_icon
  fold {
    title     = "ElastiCache Clusters"
    icon      = local.aws_elasticache_cluster_icon
    threshold = 3
  }
}

category "aws_elasticache_subnet_group" {
  fold {
    title     = "elasticache Subnet Groups"
    threshold = 3
  }
}

category "aws_vpc_eip" {
  href = "/aws_insights.dashboard.aws_vpc_eip_detail?input.eip_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_vpc_eip_icon
  fold {
    title     = "VPC EIPs"
    icon      = local.aws_vpc_eip_icon
    threshold = 3
  }
}

category "aws_eks_cluster" {
  href = "/aws_insights.dashboard.aws_eks_cluster_detail?input.eks_cluster_arn={{.properties.'ARN' | @uri}}"
  fold {
    title     = "EKS Clusters"
    threshold = 3
  }
}

category "aws_sqs_queue" {
  href = "/aws_insights.dashboard.aws_sqs_queue_detail?input.queue_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_sqs_queue_icon
  fold {
    title     = "SQS Queues"
    icon      = local.aws_sqs_queue_icon
    threshold = 3
  }
}

category "aws_eventbridge_rule" {
  href = "/aws_insights.dashboard.aws_eventbridge_rule_detail?input.eventbridge_rule_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_eventbridge_rule_icon
  fold {
    title     = "EventBridge Rules"
    icon      = local.aws_eventbridge_rule_icon
    threshold = 3
  }
}

category "aws_api_gatewayv2_api" {
  href  = "/aws_insights.dashboard.api_gatewayv2_api_detail?input.api_id={{.properties.'ID' | @uri}}"
  icon  = "heroicons-outline:bolt"
  color = "red"

  fold {
    icon       = "heroicons-outline:bolt"
    title      = "API Gatewayv2 APIs"
    threshold  = 3
  }
}

category "aws_backup_plan" {
  href = "/aws_insights.dashboard.backup_plan_detail?input.backup_plan_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_backup_plan_icon
  fold {
    title     = "Backup Plans"
    icon      = local.aws_backup_plan_icon
    threshold = 3
  }
}

category "aws_backup_vault" {
  href = "/aws_insights.dashboard.backup_vault_detail?input.backup_vault_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_backup_vault_icon
  fold {
    title     = "Backup Vaults"
    icon      = local.aws_backup_vault_icon
    threshold = 3
  }
}

category "aws_glacier_vault" {
  href = "/aws_insights.dashboard.glacier_vault_detail?input.vault_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_glacier_vault_icon
  fold {
    title     = "Glacier Vaults"
    icon      = local.aws_glacier_vault_icon
    threshold = 3
  }
}

category "aws_codepipeline_pipeline" {
  href = "/aws_insights.dashboard.codepipeline_pipeline_detail?input.pipeline_arn={{.properties.'ARN' | @uri}}"
  fold {
    title     = "CodePipeline Pipelines"
    threshold = 3
  }
}

category "aws_dax_cluster" {
  href = "/aws_insights.dashboard.dax_cluster_detail?input.dax_cluster_arn={{.properties.'ARN' | @uri}}"
  fold {
    title     = "DAX Clusters"
    threshold = 3
  }
}

category "aws_dynamodb_table" {
  href = "/aws_insights.dashboard.dynamodb_table_detail?input.table_arn={{.properties.'ARN' | @uri}}"
  icon = local.aws_dynamodb_table_icon
  fold {
    title     = "DynamoDB Tables"
    icon      = local.aws_dynamodb_table_icon
    threshold = 3
  }
}

category "aws_dax_subnet_group" {
  fold {
    title     = "DAX Subnet Groups"
    threshold = 3
  }
}

category "aws_codecommit_repository" {
  fold {
    title     = "CodeCommit Repositories"
    threshold = 3
  }
}

category "aws_codebuild_project" {
  fold {
    title     = "CodeBuild Projects"
    threshold = 3
  }
}

category "aws_kinesisanalyticsv2_application" {
  fold {
    title     = "Kinesis Analytics Applications"
    threshold = 3
  }
}

category "aws_s3_access_point" {
  icon = local.aws_s3_access_point_icon
  fold {
    title     = "S3 Access Points"
    icon      = local.aws_s3_access_point_icon
    threshold = 3
  }
}

category "aws_cloudformation_stack" {
  icon = local.aws_cloudformation_stack_icon
  fold {
    title     = "CloudFormation Stacks"
    icon      = local.aws_cloudformation_stack_icon
    threshold = 3
  }
}

category "aws_kinesis_stream" {
  fold {
    title     = "Kinesis Streams"
    threshold = 3
  }
}

category "aws_vpc_endpoint" {
  icon = local.aws_vpc_endpoint_icon
  fold {
    title     = "VPC Endpoints"
    icon      = local.aws_vpc_endpoint_icon
    threshold = 3
  }
}

category "aws_vpc_internet_gateway" {
  icon  = local.aws_vpc_internet_gateway_icon
  color = "purple"

  fold {
    title     = "VPC Internet Gateways"
    icon      = local.aws_vpc_internet_gateway_icon
    threshold = 3
  }
}

category "aws_vpc_route_table" {
  icon  = local.aws_vpc_route_table_icon
  color = "purple"
  fold {
    title     = "VPC Route Tables"
    icon      = local.aws_vpc_route_table_icon
    threshold = 3
  }
}

category "aws_vpc_nat_gateway" {
  icon  = local.aws_vpc_nat_gateway_icon
  color = "purple"

  fold {
    title     = "VPC NAT Gateways"
    icon      = local.aws_vpc_nat_gateway_icon
    threshold = 3
  }
}

category "aws_vpc_vpn_gateway" {
  icon  = local.aws_vpc_vpn_gateway_icon
  color = "purple"

  fold {
    title     = "VPC VPN Gateways"
    icon      = local.aws_vpc_vpn_gateway_icon
    threshold = 3
  }
}

category "aws_vpc_network_acl" {
  icon  = local.aws_vpc_network_acl_icon
  color = "purple"

  fold {
    title     = "VPC Network ACLs"
    icon      = local.aws_vpc_network_acl_icon
    threshold = 3
  }
}

category "aws_cloudwatch_log_group" {
  fold {
    title     = "CloudWatch Log Groups"
    threshold = 3
  }
}

category "aws_guardduty_detector" {
  fold {
    title     = "GuardDuty Detectors"
    threshold = 3
  }
}

category "aws_media_store_container" {
  fold {
    title     = "Media Store Containers"
    threshold = 3
  }
}

category "aws_eventbridge_bus" {
  icon = local.aws_eventbridge_bus_icon
  fold {
    title     = "EventBridge Buses"
    icon      = local.aws_eventbridge_bus_icon
    threshold = 3
  }
}

category "aws_appconfig_application" {
  fold {
    title     = "AppConfig Applications"
    threshold = 3
  }
}

category "aws_api_gatewayv2_stage" {
  fold {
    title     = "API Gatewayv2 Stages"
    threshold = 3
  }
}

category "aws_sfn_state_machine" {
  fold {
    title     = "Step Function State Machines"
    threshold = 3
  }
}

category "aws_ec2_launch_configuration" {
  fold {
    title     = "EC2 Launch Configurations"
    threshold = 3
  }
}

category "aws_dms_replication_instance" {
  fold {
    title     = "DMS Replication Instances"
    threshold = 3
  }
}

category "aws_sagemaker_notebook_instance" {
  fold {
    title     = "Sagemaker Notebook Instances"
    threshold = 3
  }
}

category "aws_backup_selection" {
  fold {
    title     = "Backup Selections"
    threshold = 3
  }
}

category "aws_ecs_task" {
  icon = local.aws_ecs_task_icon
  fold {
    title     = "ECS Tasks"
    icon      = local.aws_ecs_task_icon
    threshold = 3
  }
}

category "aws_codedeploy_app" {
  fold {
    title     = "CodeDeploy Applications"
    threshold = 3
  }
}

category "aws_eks_addon" {
  fold {
    title     = "EKS Addons"
    threshold = 3
  }
}

category "aws_eks_node_group" {
  fold {
    title     = "EKS Node Groups"
    threshold = 3
  }
}

category "aws_emr_instance_fleet" {
  fold {
    title     = "EMR instance fleets"
    threshold = 3
  }
}

category "aws_emr_instance_group" {
  fold {
    title     = "EMR instance groups"
    threshold = 3
  }
}

category "aws_fsx_file_system" {
  icon = local.aws_fsx_file_system_icon
  fold {
    title     = "FSX File Systems"
    icon = local.aws_fsx_file_system_icon
    threshold = 3
  }
}

category "aws_vpc_peering_connection" {
  icon = local.aws_vpc_peering_connection_icon
  fold {
    title     = "VPC Peering Connections"
    icon = local.aws_vpc_peering_connection_icon
    threshold = 3
  }
}

graph "aws_graph_categories" {
  type  = "graph"
  title = "Relationships"
}

category "aws_fsx_file_system" {
  icon  = "heroicons-outline:document-duplicate"
  color = "green"

  fold {
    title     = "FSX Filesystem"
    icon = "heroicons-outline:document-duplicate"
    threshold = 3
  }
}


category "aws_ec2_transit_gateway" {
  icon  = "heroicons-outline:arrows-right-left"
  color = "purple"

  fold {
    title     = "Transit Gateways"
    icon      = "heroicons-outline:arrows-right-left"
    threshold = 3
  }
}

category "aws_availability_zone" {
  icon = "heroicons-outline:building-office"
  color = "purple"

  fold {
    title     = "Availability Zones"
    icon      = "heroicons-outline:building-office"
    threshold = 3
  }
}



category "aws_account" {
  icon = "heroicons-outline:globe-alt"
  color = "orange"

  fold {
    title     = "Accounts"
    icon      = "heroicons-outline:globe-alt"
    threshold = 3
  }
}


category "aws_region" {
  icon = "heroicons-outline:globe-americas"
  color = "orange"

  fold {
    title     = "Regions"
    icon      = "heroicons-outline:globe-americas"
    threshold = 3
  }
}


category "aws_api_gatewayv2_integration" {
  icon  = "heroicons-outline:puzzle-piece"
  color = "red"

  fold {
    icon       = "heroicons-outline:bolt"
    title      = "API Gatewayv2 puzzle-piece"
    threshold  = 3
  }
}
