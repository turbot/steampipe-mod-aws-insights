dashboard "aws_vpc_relationships" {

  title         = "AWS VPC Relationships"
  #documentation = file("./dashboards/vpc/docs/vpc_relationships.md")

  tags = merge(local.vpc_common_tags, {
    type = "Relationships"
  })


  input "vpc_id" {
    title = "Select a VPC:"
    sql   = query.aws_vpc.sql
    width = 4
  }

   graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_vpc_graph_from_vpc
    args = {
      vpc_id = self.input.vpc_id.value
    }

    category "aws_vpc" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_light.svg"))
      color = "orange"
      href  = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.'ID' | @uri}}"
    }

    category "aws_vpc_subnet" {
      color = "orange"
    }

    category "aws_vpc_security_group" {
      color = "red"
    }

    category "aws_vpc_internet_gateway" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_internet_gateway_light.svg"))
      color = "orange"
    }

    category "aws_vpc_route_table" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_router_light.svg"))
      color = "orange"
    }

    category "aws_ec2_transit_gateway" {
      # icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_router_light.svg"))
      color = "blue"
    }

    category "aws_vpc_endpoint" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_endpoint_light.svg"))
      color = "orange"
    }

    category "aws_vpc_nat_gateway" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_nat_gateway_light.svg"))
      color = "orange"
    }

    category "aws_vpc_vpn_gateway" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_vpn_gateway_light.svg"))
      color = "orange"
    }
  }

   graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_vpc_graph_to_vpc
    args = {
      vpc_id = self.input.vpc_id.value
    }

    category "aws_vpc" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_light.svg"))
      color = "orange"
      href  = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.'ID' | @uri}}"
    }

    category "aws_ec2_instance" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_instance_light.svg"))
      color = "orange"
      href  = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn={{.properties.'ARN' | @uri}}"
    }

    category "aws_lambda_function" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/lambda_function_light.svg"))
      color = "blue"
      href  = "${dashboard.aws_lambda_function_detail.url_path}?input.lambda_arn={{.properties.'ARN' | @uri}}"
    }

    category "aws_ec2_application_load_balancer" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_application_load_balancer_light.svg"))
      color = "green"
    }

    category "aws_ec2_network_load_balancer" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_network_load_balancer_light.svg"))
      color = "red"
    }

    category "aws_ec2_classic_load_balancer" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_classic_load_balancer_light.svg"))
      color = "red"
    }

    category "aws_ec2_gateway_load_balancer" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_gateway_load_balancer_light.svg"))
      color = "red"
    }

    category "aws_rds_db_instance" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/rds_db_instance_light.svg"))
      color = "orange"
      href  = "${dashboard.aws_rds_db_instance_detail.url_path}?input.db_instance_arn={{.properties.'ARN' | @uri}}"
    }

    category "aws_redshift_cluster" {
      # icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/aws_redshift_cluster.svg"))
      color = "orange"
      href  = "${dashboard.aws_redshift_cluster_detail.url_path}?input.cluster_arn={{.properties.'ARN' | @uri}}"
    }

    category "aws_ec2_target_group" {
      # icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/aws_redshift_cluster.svg"))
      color = "red"
    }

    category "aws_fsx_file_system" {
      # icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/aws_redshift_cluster.svg"))
      color = "orange"
    }

    category "aws_s3_access_point" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/s3_access_point_light.svg"))
      color = "orange"
    }

  }

}

query "aws_vpc" {
  sql = <<-EOQ
    select
      title as label,
      vpc_id as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'vpc_id', vpc_id
      ) as tags
    from
      aws_vpc
    order by
      title;
  EOQ
}

query "aws_vpc_graph_from_vpc" {
  sql = <<-EOQ
    with vpc as (select * from aws_vpc where vpc_id = $1)

    -- VPC node
    select
      null as from_id,
      null as to_id,
      vpc_id as id,
      title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      vpc

  -- Subnets Attached - nodes
    union all
    select
      null as from_id,
      null as to_id,
      subnet_arn as id,
      title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', subnet_arn,
        'ID', subnet_id,
        'CIDR Block', cidr_block,
        'IP Address Count', available_ip_address_count,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_subnet
    where
      vpc_id = $1

    -- Subnets Attached  - Edges
    union all
    select
      v.vpc_id as from_id,
      s.subnet_arn as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', s.subnet_arn,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      vpc as v
      left join aws_vpc_subnet as s on s.vpc_id = v.vpc_id

    -- Internet Gateway Attached - nodes
    union all
    select
      null as from_id,
      null as to_id,
      internet_gateway_id as id,
      title as title,
      'aws_vpc_internet_gateway' as category,
      jsonb_build_object(
        'ID', internet_gateway_id,
        'State', a ->> 'State',
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_internet_gateway,
      jsonb_array_elements(attachments) as a
    where
      a ->> 'VpcId' = $1

    -- Internet Gateway Attached  - Edges
    union all
    select
      v.vpc_id as from_id,
      i.internet_gateway_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ID', i.internet_gateway_id,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      vpc as v,
      aws_vpc_internet_gateway as i,
      jsonb_array_elements(attachments) as a
    where
      a ->> 'VpcId' = $1

    -- Route Table Attached - nodes
    union all
    select
      null as from_id,
      null as to_id,
      route_table_id as id,
      title as title,
      'aws_vpc_route_table' as category,
      jsonb_build_object(
        'ID', route_table_id,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_route_table
    where
      vpc_id = $1

    -- Route Table Attached  - Edges
    union all
    select
      v.vpc_id as from_id,
      rt.route_table_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ID', rt.route_table_id,
        'Account ID', rt.account_id,
        'Region', rt.region
      ) as properties
    from
      vpc as v
      left join aws_vpc_route_table as rt on rt.vpc_id = v.vpc_id

    -- VPC Endpoint  Attached - nodes
    union all
    select
      null as from_id,
      null as to_id,
      vpc_endpoint_id as id,
      title as title,
      'aws_vpc_endpoint' as category,
      jsonb_build_object(
        'ID', vpc_endpoint_id,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_endpoint
    where
      vpc_id = $1

    -- VPC Endpoint - Edges
    union all
    select
      v.vpc_id as from_id,
      e.vpc_endpoint_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ID', e.vpc_endpoint_id,
        'Account ID', e.account_id,
        'Region', e.region
      ) as properties
    from
      vpc as v
      left join aws_vpc_endpoint as e on e.vpc_id = v.vpc_id

    -- Transit Gateway Attached - nodes
    union all
    select
      null as from_id,
      null as to_id,
      g.transit_gateway_id as id,
      g.title as title,
      'aws_ec2_transit_gateway' as category,
      jsonb_build_object(
        'ID', g.transit_gateway_id,
        'ARN', g.transit_gateway_arn,
        'Attachment Id', t.transit_gateway_attachment_id,
        'Association State', t.association_state,
        'Region', g.region,
        'Account ID', g.account_id
      ) as properties
    from
      aws_ec2_transit_gateway_vpc_attachment as t
      left join aws_ec2_transit_gateway as g on t.transit_gateway_id = g.transit_gateway_id
    where
      t.resource_id = $1 and resource_type = 'vpc'

    -- Transit Gateway Attached  - Edges
    union all
    select
      v.vpc_id as from_id,
      a.transit_gateway_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ID', a.transit_gateway_id,
        'Account ID', a.account_id,
        'Region', a.region
      ) as properties
    from
      vpc as v
      left join aws_ec2_transit_gateway_vpc_attachment as a on a.resource_id = v.vpc_id

    -- NAT Gateway Attached - nodes
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_vpc_nat_gateway' as category,
      jsonb_build_object(
        'ARN', arn,
        'ID', nat_gateway_id,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_nat_gateway
    where
      vpc_id = $1

    -- NAT Gateway Attached  - Edges
    union all
    select
      v.vpc_id as from_id,
      n.arn as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ID', n.nat_gateway_id,
        'Account ID', n.account_id,
        'Region', n.region
      ) as properties
    from
      vpc as v
      left join aws_vpc_nat_gateway as n on n.vpc_id = v.vpc_id

    -- VPN Gateway Attached - nodes
    union all
    select
      null as from_id,
      null as to_id,
      vpn_gateway_id as id,
      title as title,
      'aws_vpc_vpn_gateway' as category,
      jsonb_build_object(
        'ID', vpn_gateway_id,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_vpn_gateway,
      jsonb_array_elements(vpc_attachments) as a
    where
      a ->> 'VpcId' = $1

    -- VPN Gateway Attached  - Edges
    union all
    select
      v.vpc_id as from_id,
      g.vpn_gateway_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Account ID', g.account_id,
        'Region', g.region
      ) as properties
    from
      vpc as v,
      aws_vpc_vpn_gateway as g,
      jsonb_array_elements(vpc_attachments) as a
    where
      a ->> 'VpcId' = v.vpc_id

    -- Security Groups Attached - nodes
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_vpc_security_group' as category,
      jsonb_build_object(
        'ARN', arn,
        'ID', group_id,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_security_group
    where
      vpc_id = $1

    -- Security Groups Attached  - Edges
    union all
    select
      v.vpc_id as from_id,
      sg.arn as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', sg.arn,
        'Account ID', sg.account_id,
        'Region', sg.region
      ) as properties
    from
      vpc as v
      left join aws_vpc_security_group as sg on sg.vpc_id = v.vpc_id

  EOQ
  param "vpc_id" {}
}

query "aws_vpc_graph_to_vpc" {
  sql = <<-EOQ
    with vpc as (select * from aws_vpc where vpc_id = $1)

    -- VPC node
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      vpc

    -- EC2 Instance that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_ec2_instance' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Account ID',i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_ec2_instance as i
    where
      i.vpc_id  = $1

    -- EC2 Instance that use me - edges
    union all
    select
      i.arn as from_id,
      v.arn as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      vpc as v
      left join aws_ec2_instance as i on i.vpc_id = v.vpc_id

    -- Lambda Function that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_lambda_function' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_lambda_function as l
    where
      l.vpc_id  = $1

    -- Lambda Function  that use me - edges
    union all
    select
      l.arn as from_id,
      v.arn as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', l.arn,
        'Account ID', l.account_id,
        'Region', l.region
      ) as properties
    from
      vpc as v
      left join aws_lambda_function as l on l.vpc_id = v.vpc_id

    -- EC2 Application Load Balancer that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_ec2_application_load_balancer' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_application_load_balancer as a
    where
      a.vpc_id  = $1

    -- EC2 Application Load Balancer that use me - edges
    union all
    select
      a.arn as from_id,
      v.arn as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', a.arn,
        'Account ID', a.account_id,
        'Region', a.region
      ) as properties
    from
      vpc as v
      left join aws_ec2_application_load_balancer as a on a.vpc_id = v.vpc_id

    -- EC2 Network Load Balancer that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_ec2_network_load_balancer' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_network_load_balancer as n
    where
      n.vpc_id  = $1

    -- EC2 Network Load Balancer that use me - edges
    union all
    select
      n.arn as from_id,
      v.arn as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', n.arn,
        'Account ID', n.account_id,
        'Region', n.region
      ) as properties
    from
      vpc as v
      left join aws_ec2_network_load_balancer as n on n.vpc_id = v.vpc_id

    -- EC2 Classic Load Balancer that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_ec2_classic_load_balancer' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_classic_load_balancer as c
    where
      c.vpc_id  = $1

    -- EC2 Classic Load Balancer that use me - edges
    union all
    select
      c.arn as from_id,
      v.arn as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', c.arn,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      vpc as v
      left join aws_ec2_classic_load_balancer as c on c.vpc_id = v.vpc_id

    -- EC2 Gateway Load Balancer that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_ec2_gateway_load_balancer' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_gateway_load_balancer as g
    where
      g.vpc_id  = $1

    -- EC2 Gateway Load Balancer that use me - edges
    union all
    select
      g.arn as from_id,
      v.arn as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', g.arn,
        'Account ID', g.account_id,
        'Region', g.region
      ) as properties
    from
      vpc as v
      left join aws_ec2_gateway_load_balancer as g on g.vpc_id = v.vpc_id

    -- RDS DB Instance that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_rds_db_instance' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_rds_db_instance as i
    where
      i.vpc_id  = $1

    -- RDS DB Instance  that use me - edges
    union all
    select
      i.arn as from_id,
      v.arn as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      vpc as v
      left join aws_rds_db_instance as i on i.vpc_id = v.vpc_id

    -- Redshift Cluster that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_redshift_cluster' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_redshift_cluster as c
    where
      c.vpc_id  = $1

    -- Redshift Cluster that use me - edges
    union all
    select
      c.arn as from_id,
      v.arn as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', c.arn,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      vpc as v
      left join aws_redshift_cluster as c on c.vpc_id = v.vpc_id

    -- EC2 Target Group that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      target_group_arn as id,
      title as title,
      'aws_ec2_target_group' as category,
      jsonb_build_object(
        'ARN', target_group_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_target_group as t
    where
      t.vpc_id  = $1

    -- EC2 Target Group  that use me - edges
    union all
    select
      t.target_group_arn as from_id,
      v.arn as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', t.target_group_arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      vpc as v
      left join aws_ec2_target_group as t on t.vpc_id = v.vpc_id

    -- FSX File System that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_fsx_file_system' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_fsx_file_system as f
    where
      f.vpc_id  = $1

    -- FSX File System that use me - edges
    union all
    select
      f.arn as from_id,
      v.arn as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', f.arn,
        'Account ID', f.account_id,
        'Region', f.region
      ) as properties
    from
      vpc as v
      left join aws_fsx_file_system as f on f.vpc_id = v.vpc_id

    -- S3 Access Points  that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      access_point_arn as id,
      title as title,
      'aws_vpc_endpoint' as category,
      jsonb_build_object(
        'ARN', access_point_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_s3_access_point as a
    where
      a.vpc_id  = $1

    -- S3 Access Points that use me - edges
    union all
    select
      a.access_point_arn as from_id,
      v.arn as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', a.access_point_arn,
        'Account ID', a.account_id,
        'Region', a.region
      ) as properties
    from
      vpc as v
      left join aws_s3_access_point as a on a.vpc_id = v.vpc_id

  EOQ
  param "vpc_id" {}
}