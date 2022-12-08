edge "vpc_az_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      availability_zone as from_id,
      subnet_id as to_id
    from
      aws_vpc_subnet
    where
      vpc_id = any($1)
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_endpoint_to_vpc" {
  title = "vpc"

  sql = <<-EOQ
    select
      vpc_endpoint_id as from_id,
      vpc_id as to_id
    from
      aws_vpc_endpoint
    where
      vpc_endpoint_id = any($1);
  EOQ

  param "vpc_endpoint_ids" {}
}

edge "vpc_flow_log_to_cloudwatch_log_group" {
  title = "logs to"

  sql = <<-EOQ
    select
      flow_log_id as from_id,
      g.arn as to_id
    from
      aws_vpc_flow_log as f,
      aws_cloudwatch_log_group as g
    where
      f.log_group_name = g.name
      and f.log_destination_type = 'cloud-watch-logs'
      and f.region = g.region
      and f.flow_log_id = any($1);
  EOQ

  param "vpc_flow_log_ids" {}
}

edge "vpc_flow_log_to_iam_role" {
  title = "assumes"

  sql = <<-EOQ
    select
      flow_log_id as from_id,
      deliver_logs_permission_arn as to_id
    from
      aws_vpc_flow_log
    where
      flow_log_id = any($1);
  EOQ

  param "vpc_flow_log_ids" {}
}

edge "vpc_flow_log_to_s3_bucket" {
  title = "logs to"

  sql = <<-EOQ
    select
      flow_log_id as from_id,
      b.arn as to_id
    from
      aws_vpc_flow_log as f,
      aws_s3_bucket as b
    where
      f.bucket_name = b.name
      and f.log_destination_type = 's3'
      and f.flow_log_id = any($1);
  EOQ

  param "vpc_flow_log_ids" {}
}

edge "vpc_nat_gateway_to_ec2_network_interface" {
  title = "eni"

  sql = <<-EOQ
    select
      n.arn as from_id,
      a ->> 'NetworkInterfaceId' as to_id
    from
      aws_vpc_nat_gateway as n,
      jsonb_array_elements(nat_gateway_addresses) as a
    where
      a ->> 'NetworkInterfaceId' = any($1);
  EOQ

  param "ec2_network_interface_ids" {}
}

edge "vpc_peered_vpc" {
  title = "peered with"

  sql = <<-EOQ
    select
      any($1) as to_id,
      case
        when accepter_vpc_id = any($1) then requester_vpc_id
        else accepter_vpc_id
      end as from_id
    from
      aws_vpc_peering_connection
    where
      accepter_vpc_id = any($1)
      or requester_vpc_id = any($1)
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_security_group_to_dax_cluster" {
  title = "dax cluster"

  sql = <<-EOQ
    select
      sg ->> 'SecurityGroupIdentifier' as from_id,
      arn as to_id
    from
      aws_dax_cluster,
      jsonb_array_elements(security_groups) as sg
    where
      sg ->> 'SecurityGroupIdentifier' = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

edge "vpc_security_group_to_dax_subnet_group" {
  title = "subnet group"
  sql   = <<-EOQ
    select
      sg ->> 'SecurityGroupIdentifier' as from_id,
      subnet_group as to_id
    from
      aws_dax_cluster,
      jsonb_array_elements(security_groups) as sg
    where
      arn = any($1);
  EOQ

  param "dax_cluster_arns" {}
}

edge "vpc_security_group_to_dms_replication_instance" {
  title = "replication instance"

  sql = <<-EOQ
    select
      vsg.group_id as from_id,
      ri.arn as to_id
    from
      aws_dms_replication_instance as ri,
      jsonb_array_elements(ri.vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

edge "vpc_security_group_to_docdb_cluster" {
  title = "docdb cluster"

  sql = <<-EOQ
    select
      vsg.group_id as from_id,
      c.arn as to_id
    from
      aws_docdb_cluster as c,
      jsonb_array_elements(c.vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

edge "vpc_security_group_to_ec2_application_load_balancer" {
  title = "application load balancer"

  sql = <<-EOQ
    select
      sg as from_id,
      arn as to_id
    from
      aws_ec2_application_load_balancer,
      jsonb_array_elements_text(security_groups) as sg
    where
      sg = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

edge "vpc_security_group_to_ec2_classic_load_balancer" {
  title = "classic load balancer"

  sql = <<-EOQ
    select
      sg as from_id,
      arn as to_id
    from
      aws_ec2_classic_load_balancer,
      jsonb_array_elements_text(security_groups) as sg
    where
      sg = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

edge "vpc_security_group_to_ec2_instance" {
  title = "ec2 instance"

  sql = <<-EOQ
    select
      s ->> 'GroupId' as from_id,
      arn as to_id
    from
      aws_ec2_instance
      join jsonb_array_elements(security_groups) as s on true
    where
      s ->> 'GroupId' = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

edge "vpc_security_group_to_ec2_launch_configuration" {
  title = "launch configuration"

  sql = <<-EOQ
    select
      vsg.group_id as from_id,
      c.launch_configuration_arn as to_id
    from
      aws_ec2_launch_configuration as c,
      jsonb_array_elements_text(c.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

edge "vpc_security_group_to_efs_mount_target" {
  title = "efs mount target"

  sql = <<-EOQ
    select
      vsg.group_id as from_id,
      mt.mount_target_id as to_id
    from
      aws_efs_mount_target as mt,
      jsonb_array_elements_text(mt.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

edge "vpc_security_group_to_elasticache_cluster" {
  title = "elasticache cluster"

  sql = <<-EOQ
    select
      sg ->> 'SecurityGroupId' as from_id,
      arn as to_id
    from
      aws_elasticache_cluster,
      jsonb_array_elements(security_groups) as sg
    where
      sg ->> 'SecurityGroupId' = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

edge "vpc_security_group_to_lambda_function" {
  title = "lambda function"

  sql = <<-EOQ
    select
      s as from_id,
      arn as to_id
    from
      aws_lambda_function,
      jsonb_array_elements_text(vpc_security_group_ids) as s
    where
      s = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

edge "vpc_security_group_to_rds_db_cluster" {
  title = "rds cluster"

  sql = <<-EOQ
    select
      sg ->> 'VpcSecurityGroupId' as from_id,
      arn as to_id
    from
      aws_rds_db_cluster,
      jsonb_array_elements(vpc_security_groups) as sg
    where
      sg ->> 'VpcSecurityGroupId' = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

edge "vpc_security_group_to_rds_db_instance" {
  title = "rds instance"

  sql = <<-EOQ
    select
      dsg ->> 'VpcSecurityGroupId' as from_id,
      arn as to_id
    from
      aws_rds_db_instance as di,
      jsonb_array_elements(di.vpc_security_groups) as dsg
    where
      dsg ->> 'VpcSecurityGroupId' = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

edge "vpc_security_group_to_rds_db_subnet_group" {
  title = "subnet group"

  sql = <<-EOQ
    select
      distinct
      sg.group_id as from_id,
      rdsg.arn as to_id
    from
      aws_rds_db_cluster as c
      cross join
        jsonb_array_elements(c.vpc_security_groups) as csg
      join
        aws_vpc_security_group as sg
        on sg.group_id = csg ->> 'VpcSecurityGroupId'
      join
        aws_rds_db_subnet_group as rdsg
        on c.db_subnet_group = rdsg.name
        and c.region = rdsg.region
        and c.account_id = rdsg.account_id
    where
      c.arn = any($1);
  EOQ

  param "rds_db_cluster_arns" {}
}

edge "vpc_security_group_to_redshift_cluster" {
  title = "redshift cluster"

  sql = <<-EOQ
    select
      sg ->> 'VpcSecurityGroupId' as from_id,
      arn as to_id
    from
      aws_redshift_cluster,
      jsonb_array_elements(vpc_security_groups) as sg
    where
      sg ->> 'VpcSecurityGroupId' = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

edge "vpc_security_group_to_sagemaker_notebook_instance" {
  title = "notebook instance"

  sql = <<-EOQ
    select
      vsg.group_id as from_id,
      ni.arn as to_id
    from
      aws_sagemaker_notebook_instance ni,
      jsonb_array_elements_text(ni.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = any($1);
  EOQ

  param "vpc_security_group_ids" {}
}

edge "vpc_subnet_to_alb" {
  title = "alb"

  sql = <<-EOQ
    select
      az ->> 'SubnetId' as from_id,
      arn as to_id
    from
      aws_ec2_application_load_balancer,
      jsonb_array_elements(availability_zones) as az
    where
      az ->> 'SubnetId' = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "vpc_subnet_to_clb" {
  title = "clb"

  sql = <<-EOQ
    select
      az ->> 'SubnetId' as from_id,
      arn as to_id
    from
      aws_ec2_classic_load_balancer,
      jsonb_array_elements(availability_zones) as az
    where
      az ->> 'SubnetId' = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "vpc_subnet_to_ec2_instance" {
  title = "ec2 instance"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      arn as to_id
    from
      aws_ec2_instance
    where
      subnet_id = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "vpc_subnet_to_endpoint" {
  title = "vpc endpoint"

  sql = <<-EOQ
    select
      s as from_id,
      e.vpc_endpoint_id as to_id
    from
      aws_vpc_endpoint as e,
      jsonb_array_elements_text(e.subnet_ids) as s
    where
      e.vpc_id = any($1)
    union
    select
      vpc_id as from_id,
      vpc_endpoint_id as to_id
    from
      aws_vpc_endpoint as e
    where
      jsonb_array_length(subnet_ids) = 0
      and vpc_id = any($1);

  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_subnet_to_glb" {
  title = "glb"

  sql = <<-EOQ
    select
      az ->> 'SubnetId' as from_id,
      arn as to_id
    from
      aws_ec2_gateway_load_balancer,
      jsonb_array_elements(availability_zones) as az
    where
      az ->> 'SubnetId' = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "vpc_subnet_to_lambda_function" {
  title = "lambda function"

  sql = <<-EOQ
    select
      s as from_id,
      arn as to_id
    from
      aws_lambda_function,
      jsonb_array_elements_text(vpc_subnet_ids) as s
    where
      s = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "vpc_subnet_to_nat_gateway" {
  title = "nat gateway"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      arn as to_id
    from
      aws_vpc_nat_gateway
    where
      subnet_id = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "vpc_subnet_to_network_interface" {
  title = "eni"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      network_interface_id as to_id
    from
      aws_ec2_network_interface
    where
      subnet_id = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "vpc_subnet_to_nlb" {
  title = "nlb"

  sql = <<-EOQ
    select
      az ->> 'SubnetId' as from_id,
      arn as to_id
    from
      aws_ec2_network_load_balancer,
      jsonb_array_elements(availability_zones) as az
    where
      az ->> 'SubnetId' = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "vpc_subnet_to_rds_db_instance" {
  title = "rds db instance"

  sql = <<-EOQ
    select
      s ->> 'SubnetIdentifier' as from_id,
      arn as to_id
    from
      aws_rds_db_instance,
      jsonb_array_elements(subnets) as s
    where
      s ->> 'SubnetIdentifier' = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "vpc_subnet_to_route_table" {
  title = "route table"

  sql = <<-EOQ
    select
      a ->> 'SubnetId' as to_id,
      rt.route_table_id as from_id
      from
        aws_vpc_route_table as rt,
        jsonb_array_elements(associations) as a
      where
        rt.vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_subnet_to_sagemaker_notebook_instance" {
  title = "notebook instance"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      arn as to_id
    from
      aws_sagemaker_notebook_instance
    where
      subnet_id = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "vpc_subnet_to_vpc_flow_log" {
  title = "flow log"

  sql = <<-EOQ
    select
      resource_id as from_id,
      flow_log_id as to_id
    from
      aws_vpc_flow_log
    where
      resource_id = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "vpc_subnet_to_vpc_network_acl" {
  title = "network acl"

  sql = <<-EOQ
    select
      a ->> 'SubnetId' as from_id,
      network_acl_id as to_id
    from
      aws_vpc_network_acl,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "vpc_subnet_to_vpc_route_table" {
  title = "route to"

  sql = <<-EOQ
    select
      a ->> 'SubnetId' as from_id,
      route_table_id as to_id
    from
      aws_vpc_route_table,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "vpc_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      vpc_id as from_id,
      subnet_id as to_id
    from
      aws_vpc_subnet
    where
      vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_subnet_to_vpc_vpc" {
  title = "vpc"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      vpc_id as to_id
    from
      aws_vpc_subnet
    where
      subnet_id = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "vpc_to_az" {
  title = "az"

  sql = <<-EOQ
    select
      distinct on (availability_zone)
      vpc_id as from_id,
      availability_zone as to_id
    from
      aws_vpc_subnet
    where
      vpc_id = any($1)
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_to_igw" {
  title = "vpc"

  sql = <<-EOQ
    select
      a ->> 'VpcId' as to_id,
      i.internet_gateway_id as from_id
    from
      aws_vpc_internet_gateway as i,
      jsonb_array_elements(attachments) as a
    where
      a ->> 'VpcId' = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_to_transit_gateway" {
  title = "transit_gateway"

  sql = <<-EOQ
    select
      resource_id as to_id,
      transit_gateway_id as from_id
    from
      aws_ec2_transit_gateway_vpc_attachment
      where resource_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_to_s3_access_point" {
  title = "s3 access point"

  sql = <<-EOQ
    select
      vpc_id as from_id,
      access_point_arn as to_id
    from
      aws_s3_access_point
    where
      vpc_id = any($1)
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_to_vpc_flow_log" {
  title = "flow log"

  sql = <<-EOQ
    select
      resource_id as from_id,
      flow_log_id as to_id
    from
      aws_vpc_flow_log
    where
      resource_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_to_vpc_route_table" {
  title = "route table"

  sql = <<-EOQ
    select
      rt.vpc_id as from_id,
      rt.route_table_id as to_id
      from
        aws_vpc_route_table as rt,
        jsonb_array_elements(associations) as a
      where
        rt.vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    select
      vpc_id as from_id,
      group_id as to_id
    from
      aws_vpc_security_group
    where
      vpc_id = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}

edge "vpc_to_vpn_gateway" {
  title = "vpn gateway"

  sql = <<-EOQ
    select
      a ->> 'VpcId' as to_id,
      g.vpn_gateway_id as from_id
    from
      aws_vpc_vpn_gateway as g,
      jsonb_array_elements(vpc_attachments) as a
    where
      a ->> 'VpcId' = any($1);
  EOQ

  param "vpc_vpc_ids" {}
}
