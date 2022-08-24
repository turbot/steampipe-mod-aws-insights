graph "aws_graph_categories" {
  type  = "graph"
  title = "Relationships"

  category "aws_ec2_classic_load_balancer" {
    href = "/aws_insights.dashboard.aws_ec2_classic_load_balancer_detail?input.clb={{.properties.'ARN' | @uri}}"
    icon = local.aws_ec2_classic_load_balancer_icon
  }

  category "aws_ec2_application_load_balancer" {
    href = "/aws_insights.dashboard.aws_ec2_application_load_balancer_detail?input.alb={{.properties.'ARN' | @uri}}"
    icon = local.aws_ec2_application_load_balancer_icon
  }

  category "aws_ec2_network_load_balancer" {
    href = "/aws_insights.dashboard.aws_ec2_network_load_balancer_detail?input.nlb={{.properties.'ARN' | @uri}}"
    icon = local.aws_ec2_network_load_balancer_icon
  }

  category "aws_ec2_gateway_load_balancer" {
    href = "/aws_insights.dashboard.aws_ec2_gateway_load_balancer_detail?input.glb={{.properties.'ARN' | @uri}}"
    icon = local.aws_ec2_gateway_load_balancer_icon
  }

  category "aws_s3_bucket" {
    href = "/aws_insights.dashboard.aws_s3_bucket_detail?input.bucket_arn={{.properties.'ARN' | @uri}}"
    icon = local.aws_s3_bucket_icon
  }

  category "aws_cloudfront_distribution" {
    href = "/aws_insights.dashboard.aws_cloudfront_distribution_detail?input.distribution_arn={{.properties.'ARN' | @uri}}"
    icon = local.aws_cloudfront_distribution_icon
  }

  category "aws_acm_certificate" {
    href = "/aws_insights.dashboard.acm_certificate_detail?input.certificate_arn={{.properties.'ARN' | @uri}}"
    icon = local.aws_acm_certificate_icon
  }

  category "aws_sns_topic" {
    href = "/aws_insights.dashboard.aws_sns_topic_detail?input.topic_arn={{.properties.'ARN' | @uri}}"
    icon = local.aws_sns_topic_icon
  }

  category "aws_kms_key" {
    href = "/aws_insights.dashboard.aws_kms_key_detail?input.key_arn={{.properties.'ARN' | @uri}}"
    icon = local.aws_kms_key_icon
  }

  category "aws_cloudtrail_trail" {
    href = "/aws_insights.dashboard.aws_cloudtrail_trail_detail?input.trail_arn={{.properties.'ARN' | @uri}}"
    icon = local.aws_cloudtrail_trail_icon
  }

  category "aws_ebs_volume" {
    href = "/aws_insights.dashboard.aws_ebs_volume_detail?input.volume_arn={{.properties.'ARN' | @uri}}"
    icon = local.aws_ebs_volume_icon
  }

  category "aws_ebs_snapshot" {
    href = "/aws_insights.dashboard.aws_ebs_snapshot_detail?input.snapshot_arn={{.properties.'ARN' | @uri}}"
    icon = local.aws_ebs_snapshot_icon
  }

  category "aws_rds_db_cluster" {
    href = "/aws_insights.dashboard.aws_rds_db_cluster_detail.url_path?input.db_cluster_arn={{.properties.ARN | @uri}}"
    icon = local.aws_rds_db_cluster_icon
  }

  category "aws_rds_db_cluster_snapshot" {
    href = "/aws_insights.dashboard.aws_rds_db_cluster_snapshot_detail.url_path?input.snapshot_arn={{.properties.ARN | @uri}}"
  }

  category "aws_rds_db_instance" {
    href = "/aws_insights.dashboard.aws_rds_db_instance_detail.url_path?input.db_instance_arn={{.properties.ARN | @uri}}"
    icon = local.aws_rds_db_instance_icon
  }

  category "aws_rds_db_snapshot" {
    href = "/aws_insights.dashboard.aws_rds_db_snapshot_detail.url_path?input.db_snapshot_arn={{.properties.ARN | @uri}}"
  }

  category "aws_redshift_cluster" {
    href = "/aws_insights.dashboard.aws_redshift_cluster_detail?input.cluster_arn={{.properties.'ARN' | @uri}}"
    icon = local.aws_redshift_cluster_icon
  }

  category "aws_ec2_instance" {
    href = "/aws_insights.dashboard.aws_ec2_instance_detail?input.instance_arn={{.properties.'ARN' | @uri}}"
    icon = local.aws_ec2_instance_icon
  }

  category "aws_vpc" {
    href = "/aws_insights.dashboard.aws_vpc_detail?input.vpc_id={{.properties.'VPC ID' | @uri}}"
    icon = local.aws_vpc_icon
  }

  category "aws_vpc_security_group" {
    href = "/aws_insights.dashboard.aws_vpc_security_group_detail?input.security_group_id={{.properties.'Group ID' | @uri}}"
  }

  category "aws_iam_role" {
    href = "/aws_insights.dashboard.aws_iam_role_detail?input.role_arn={{.properties.'ARN' | @uri}}"
    icon = local.aws_iam_role_icon
  }

  category "aws_emr_instance" {
    href = "/aws_insights.dashboard.aws_ec2_instance_detail?input.instance_arn={{.properties.'EC2 Instance ARN' | @uri}}"
    icon = local.aws_ec2_instance_icon
  }

  category "aws_iam_policy" {
    href = "/aws_insights.dashboard.aws_iam_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
  }

  category "aws_iam_user" {
    href = "/aws_insights.dashboard.aws_iam_user_detail?input.user_arn={{.properties.'ARN' | @uri}}"
    icon = local.aws_iam_user_icon
  }

  category "aws_iam_group" {
    href = "/aws_insights.dashboard.aws_iam_group_detail?input.group_arn={{.properties.'ARN' | @uri}}"
  }

  category "aws_lambda_function" {
    href = "/aws_insights.dashboard.aws_lambda_function_detail?input.lambda_arn={{.properties.'ARN' | @uri}}"
    icon = local.aws_lambda_function_icon
  }

  category "aws_emr_cluster" {
    href = "/aws_insights.dashboard.aws_emr_cluster_detail?input.emr_cluster_arn={{.properties.'ARN' | @uri}}"
    icon = local.aws_emr_cluster_icon
  }

  category "aws_vpc_subnet" {
    href = "/aws_insights.dashboard.aws_vpc_subnet_detail?input.subnet_id={{.properties.'Subnet ID' | @uri}}"
  }

  category "aws_elasticache_cluster" {
    href = "/aws_insights.dashboard.aws_elasticache_cluster_detail.url_path?input.elasticache_cluster_arn={{.properties.ARN | @uri}}"
    icon = local.aws_elasticache_cluster_icon
  }

  category "aws_vpc_eip" {
    href = "/aws_insights.dashboard.aws_vpc_eip_detail?input.eip_arn={{.properties.'ARN' | @uri}}"
    icon = local.aws_vpc_eip_icon
  }

  category "aws_kinesisanalyticsv2_application" {
    icon = local.aws_kinesisanalytics_application_icon
  }

  category "aws_s3_access_point" {
    icon = local.aws_s3_access_point_icon
  }

  category "aws_cloudformation_stack" {
    icon = local.aws_cloudformation_stack_icon
  }

  category "aws_ec2_network_interface" {
    icon = local.aws_ec2_network_interface_icon
  }

  category "aws_ec2_ami" {
    icon = local.aws_ec2_ami_icon
  }

  category "aws_kinesis_stream" {
    icon = local.aws_kinesis_stream_icon
  }

  category "aws_vpc_endpoint" {
    icon = local.aws_vpc_endpoint_icon
  }

  category "aws_eventbridge_rule" {
    icon = local.aws_eventbridge_rule_icon
  }

  category "aws_vpc_internet_gateway" {
    icon = local.aws_vpc_internet_gateway_icon
  }

  category "aws_vpc_route_table" {
    icon = local.aws_vpc_route_table_icon
  }

  category "aws_vpc_nat_gateway" {
    icon = local.aws_vpc_nat_gateway_icon
  }

  category "aws_vpc_vpn_gateway" {
    icon = local.aws_vpc_vpn_gateway_icon
  }

  category "aws_vpc_network_acl" {
    icon = local.aws_vpc_network_acl_icon
  }

  category "aws_cloudwatch_log_group" {
    icon = local.aws_cloudwatch_log_group_icon
  }

  category "aws_guardduty_detector" {
    icon = local.aws_guardduty_detector_icon
  }

  category "aws_media_store_container" {
    icon = local.aws_media_store_container_icon
  }
}
