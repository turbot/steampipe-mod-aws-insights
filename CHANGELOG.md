## v0.17 [2023-11-30]

_Bug fixes_

- Fixed the index docs by removing unsupported images. ([#334](https://github.com/turbot/steampipe-mod-aws-insights/pull/334))

## v0.16 [2023-11-29]

_Bug fixes_

- Fixed missing closing tag in index doc. ([#331](https://github.com/turbot/steampipe-mod-aws-insights/pull/331))

## v0.15 [2023-11-03]

_Breaking changes_

- Updated the plugin dependency section of the mod to use `min_version` instead of `version`. ([#326](https://github.com/turbot/steampipe-mod-aws-insights/pull/326))

## v0.14 [2023-10-13]

_Enhancements_

- Added additional dashboard and query docs and updated metadata descriptions in docs. ([#323](https://github.com/turbot/steampipe-mod-aws-insights/pull/323))

## v0.13 [2023-06-28]

_Bug fixes_

- Updated the Age Report dashboards to order by the creation time of the resource. ([#311](https://github.com/turbot/steampipe-mod-aws-insights/pull/311))
- Fixed the `s3_bucket_encryption_table` query to correctly check if S3 buckets are configured to use an `S3 Bucket Key` for SSE-KMS. ([#313](https://github.com/turbot/steampipe-mod-aws-insights/pull/313)) (Thanks [@andy-werderman](https://github.com/andy-werderman) for the contribution!)
- Fixed dashboard localhost URLs in README and index doc. ([#310](https://github.com/turbot/steampipe-mod-aws-insights/pull/310))

## v0.12 [2023-05-10]

_Bug fixes_

- Removed cards, charts, and tables displaying inaccurate cost-based information from both `AWS RDS DB Cluster Snapshot Dashboard` and `AWS RDS DB Instance Snapshot Dashboard` dashboards. ([#304](https://github.com/turbot/steampipe-mod-aws-insights/pull/304)) ([#308](https://github.com/turbot/steampipe-mod-aws-insights/pull/308))

## v0.11 [2023-02-03]

_Enhancements_

- Updated the `card` width across all the dashboards to enhance readability. ([#298](https://github.com/turbot/steampipe-mod-aws-insights/pull/298))

_Bug fixes_

- Fixed the resource relationship graph in `AWS RDS DB Instance Detail` dashboard to correctly reflect the associated VPC security group resources. ([#296](https://github.com/turbot/steampipe-mod-aws-insights/pull/296))
- Removed the incorrectly placed `card` reflecting the EBS snapshot age in `AWS EBS Snapshot Detail` dashboard. ([#298](https://github.com/turbot/steampipe-mod-aws-insights/pull/298))

## v0.10 [2023-01-12]

_Dependencies_

- Steampipe `v0.18.0` or higher is now required ([#293](https://github.com/turbot/steampipe-mod-aws-insights/pull/293))
- AWS plugin `v0.91.0` or higher is now required. ([#293](https://github.com/turbot/steampipe-mod-aws-insights/pull/293))

_What's new?_

- Added resource relationship graphs across all the detail dashboards to highlight the relationship the resource shares with other resources. ([#291](https://github.com/turbot/steampipe-mod-aws-insights/pull/291))
- New dashboards added: ([#291](https://github.com/turbot/steampipe-mod-aws-insights/pull/291))
  - [AWS API Gateway V2 API Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.api_gatewayv2_detail)
  - [AWS Backup Plan Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.backup_plan_detail)
  - [AWS Backup Vault Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.backup_vault_detail)
  - [AWS Cloudfront Distribution Dashboard](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.cloudfront_distribution_dashboard)
  - [AWS CloudFront Distribution Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.cloudfront_distribution_detail)
  - [AWS CloudWatch Log Group Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.cloudwatch_log_group_detail)
  - [AWS Codebuild Project Dashboard](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.codebuild_project_dashboard)
  - [AWS CodeBuild Project Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.codebuild_project_detail)
  - [AWS Codecommit Repository Dashboard](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.codecommit_repository_dashboard)
  - [AWS CodeCommit Repository Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.codecommit_repository_detail)
  - [AWS Codepipeline Pipeline Dashboard](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.codepipeline_pipeline_dashboard)
  - [AWS CodePipeline Pipeline Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.codepipeline_pipeline_detail)
  - [AWS DAX Cluster Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.dax_cluster_detail)
  - [AWS EBS Snapshot Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.ebs_snapshot_detail)
  - [AWS EC2 AMI Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.ec2_ami_detail)
  - [AWS EC2 Application Load Balancer Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.ec2_application_load_balancer_detail)
  - [AWS EC2 Classic Load Balancer Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.ec2_classic_load_balancer_detail)
  - [AWS EC2 Gateway Load Balancer Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.ec2_gateway_load_balancer_detail)
  - [AWS EC2 Network Interface Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.ec2_network_interface_detail)
  - [AWS EC2 Network Load Balancer Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.ec2_network_load_balancer_detail)
  - [AWS ECR Repository Dashboard](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.ecr_repository_dashboard)
  - [AWS ECR Repository Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.ecr_repository_detail)
  - [AWS ECS Cluster Dashboard](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.ecs_cluster_dashboard)
  - [AWS ECS Cluster Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.ecs_cluster_detail)
  - [AWS ECS Service Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.ecs_service_detail)
  - [AWS ECS Task Definition Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.ecs_task_detail)
  - [AWS EFS File System Dashboard](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.efs_file_system_dashboard)
  - [AWS EKS Cluster Dashboard](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.eks_cluster_dashboard)
  - [AWS EKS Cluster Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.eks_cluster_detail)
  - [AWS ElastiCache Cluster Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.elasticache_cluster_detail)
  - [AWS Elasticache Cluster Node Dashboard](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.elasticache_cluster_node_dashboard)
  - [AWS ElastiCache Cluster Node Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.elasticache_cluster_node_detail)
  - [AWS EMR Cluster Dashboard](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.emr_cluster_dashboard)
  - [AWS EMR Cluster Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.emr_cluster_detail)
  - [AWS EventBridge Rule Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.eventbridge_rule_detail)
  - [AWS IAM Policy Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.iam_policy_detail)
  - [AWS Redshift Snapshot Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.redshift_snapshot_detail)
  - [AWS VPC Elastic IP Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.vpc_elastic_ip_detail)
  - [AWS VPC Flow Logs Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.vpc_flow_logs_detail)

## v0.9 [2022-12-02]

_Bug fixes_

- Fixed the `aws_sqs_queue_encryption` query in the `AWS SQS Queue Detail` dashboard to also check if a queue is encrypted by Amazon Managed SQS Key. ([#245](https://github.com/turbot/steampipe-mod-aws-insights/pull/245))

## v0.8 [2022-10-27]

_Enhancements_

- Updated the `aws_ebs_volume_unattached_count` and `aws_ebs_volume_attached_instances_count` queries in `AWS EBS Volume Dashboard` and `AWS EBS Volume Detail` dashboards respectively to handle the `attachments` column correctly when empty in the `aws_ebs_volume` table. ([#206](https://github.com/turbot/steampipe-mod-aws-insights/pull/206))

_Dependencies_

- AWS plugin `v0.80.0` or higher is now required. ([#208](https://github.com/turbot/steampipe-mod-aws-insights/pull/208))

## v0.7 [2022-09-19]

_Bug fixes_

- Fixed `AWS IAM User Detail` dashboard showing access keys for users with same name from other connections' accounts.

## v0.6 [2022-06-01]

_Enhancements_

- Added links in `AWS EC2 Instance Detail` dashboard to `AWS EBS Volume Detail` and `AWS VPC Security Group Detail` dashboards. ([#102](https://github.com/turbot/steampipe-mod-aws-insights/pull/102))
- Added a link in `AWS IAM Access Key Age Report` dashboard to `AWS IAM User Detail` dashboard. ([#103](https://github.com/turbot/steampipe-mod-aws-insights/pull/103))

## v0.5 [2022-05-09]

_Enhancements_

- Updated docs/index.md and README with new dashboard screenshots and latest format. ([#97](https://github.com/turbot/steampipe-mod-aws-insights/pull/97))

## v0.4 [2022-05-04]

_Enhancements_

- Simplified the jq expression in `AWS IAM User Detail` dashboard. ([#94](https://github.com/turbot/steampipe-mod-aws-insights/pull/94))

_Bug fixes_

- Fixed the `aws_vpc_empty_status` query in `AWS VPC Dashboard` dashboard to remove duplicate results. ([#90](https://github.com/turbot/steampipe-mod-aws-insights/pull/90))
- Fixed the `aws_iam_group_direct_attached_policy_count_for_group` and `aws_iam_role_inline_policy_count_for_role` card queries in `AWS IAM Group Detail` and `AWS IAM Role Detail` dashboards respectively to show `0` instead of `null` if there are no attached policies. ([#89](https://github.com/turbot/steampipe-mod-aws-insights/pull/89))
- Fixed the invalid jq expression in the `IAM User Excessive Privilege Report` dashboard. ([#92](https://github.com/turbot/steampipe-mod-aws-insights/pull/92))

## v0.3 [2022-03-31]

_Dependencies_

- AWS plugin `v0.53.0` or higher is now required ([#79](https://github.com/turbot/steampipe-mod-aws-insights/pull/66))

_What's new?_

- New dashboards added:
  - [ACM Certificate Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.acm_certificate_detail) ([#75](https://github.com/turbot/steampipe-mod-aws-insights/pull/75))
  - [DynamoDB Table Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.aws_dynamodb_table_detail) ([#76](https://github.com/turbot/steampipe-mod-aws-insights/pull/76))
  - [RDS DB Cluster Snapshot Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.aws_rds_db_cluster_snapshot_detail) ([#77](https://github.com/turbot/steampipe-mod-aws-insights/pull/77))

_Bug fixes_

- Added the missing document references for S3 dashboards ([#74](https://github.com/turbot/steampipe-mod-aws-insights/pull/74))

## v0.2 [2022-03-18]

_Dependencies_

- Steampipe v0.13.1 or higher is now required ([#66](https://github.com/turbot/steampipe-mod-aws-insights/pull/66))

_What's new?_

- Added: Select cards now include links to respective reports in all dashboards ([#65](https://github.com/turbot/steampipe-mod-aws-insights/pull/65))
- New dashboards added:
  - [IAM User Excessive Privilege Report](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.aws_iam_user_excessive_privilege_report) ([#67](https://github.com/turbot/steampipe-mod-aws-insights/pull/67))
  - [SNS Topic Detail](https://hub.steampipe.io/mods/turbot/aws_insights/dashboards/dashboard.aws_sns_topic_detail) ([#64](https://github.com/turbot/steampipe-mod-aws-insights/pull/64))

## v0.1 [2022-03-10]

_What's new?_

New dashboards, reports, and details for the following services:
- ACM
- CloudTrail
- DynamoDB
- EBS
- EC2
- IAM
- KMS
- Lambda
- RDS
- Redshift
- S3
- SNS
- SQS
- VPC
