locals {
  emr_common_tags = {
    service = "AWS/EMR"
  }
}

category "emr_cluster" {
  title = "EMR Cluster"
  color = local.analytics_color
  href  = "/aws_insights.dashboard.emr_cluster_detail?input.emr_cluster_arn={{.properties.'ARN' | @uri}}"
  icon  = "text:EMR"
}

category "emr_instance" {
  title = "EMR Instance"
  color = local.analytics_color
  href  = "/aws_insights.dashboard.ec2_instance_detail?input.instance_arn={{.properties.'EC2 Instance ARN' | @uri}}"
  icon  = "heroicons-outline:cpu-chip"
}

category "emr_instance_fleet" {
  title = "EMR instance fleet"
  color = local.analytics_color
  icon  = "text:EMR"
}

category "emr_instance_group" {
  title = "EMR instance group"
  color = local.analytics_color
  icon  = "heroicons-outline:rectangle-group"
}
