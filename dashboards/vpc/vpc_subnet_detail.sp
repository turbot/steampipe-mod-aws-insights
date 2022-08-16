dashboard "aws_vpc_subnet_detail" {

  title         = "AWS VPC Subnet Detail"
  #documentation = file("./dashboards/vpc/docs/vpc_subnet_relationships.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "subnet_id" {
    title = "Select a Subnet:"
    sql   = query.aws_vpc_subnet_input.sql
    width = 4
  }

  container {

    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_vpc_subnet_relationships_graph
      args = {
        subnet_id = self.input.subnet_id.value
      }

      category "aws_vpc_route_table" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_router_light.svg"))
      }

      category "aws_vpc" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_light.svg"))
        href  = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.'ID' | @uri}}"
      }

      category "aws_vpc_network_acl" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_network_acl_light.svg"))
      }

      category "aws_rds_db_instance" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/rds_db_instance_light.svg"))
        href  = "${dashboard.aws_rds_db_instance_detail.url_path}?input.db_instance_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_ec2_instance" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_instance_light.svg"))
        href  = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_lambda_function" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/lambda_function_light.svg"))
        href  = "${dashboard.aws_lambda_function_detail.url_path}?input.lambda_arn={{.properties.'ARN' | @uri}}"
      }

    }
  }

}

query "aws_vpc_subnet_input" {
  sql = <<-EOQ
    select
      title as label,
      subnet_id as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'subnet_id', subnet_id
      ) as tags
    from
      aws_vpc_subnet
    order by
      title;
  EOQ
}

query "aws_vpc_subnet_relationships_graph" {
  sql = <<-EOQ

  with subnet as (select * from aws_vpc_subnet where subnet_id = $1)

    select
      null as from_id,
      null as to_id,
      subnet_id as id,
      title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', subnet_arn,
        'VPC ID', vpc_id,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      subnet

    -- To VPC (node)
    union all
    select
      null as from_id,
      null as to_id,
      v.vpc_id as id,
      v.title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'Region', v.region,
        'Account ID', v.account_id
      ) as properties
    from
      subnet as s
      left join aws_vpc as v on v.vpc_id = s.vpc_id

    -- To VPC (edge)
    union all
    select
      $1 as from_id,
      v.vpc_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      subnet as s
      left join aws_vpc as v on v.vpc_id = s.vpc_id

    -- To Route Tables (node)
    union all
    select
      null as from_id,
      null as to_id,
      route_table_id as id,
      title as title,
      'aws_vpc_route_table' as category,
      jsonb_build_object(
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_route_table,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = $1

    -- To Route Tables (edge)
    union all
    select
      $1 as from_id,
      route_table_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_route_table,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = $1

    -- To Network Acls (node)
    union all
    select
      null as from_id,
      null as to_id,
      network_acl_id as id,
      title as title,
      'aws_vpc_network_acl' as category,
      jsonb_build_object(
        'ARN', arn,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_network_acl,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = $1

    --  To Network Acls (edge)
    union all
    select
      $1 as from_id,
      network_acl_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Association Id', a ->> 'NetworkAclAssociationId',
        'Region', region
      ) as properties
    from
      aws_vpc_network_acl,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = $1

    -- From RDS DB Instances (node)
    union all
    select
      null as from_id,
      null as to_id,
      db_instance_identifier as id,
      title as title,
      'aws_rds_db_instance' as category,
      jsonb_build_object(
        'ARN', arn,
        'Status', status,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_rds_db_instance,
      jsonb_array_elements(subnets) as s
    where
      s ->> 'SubnetIdentifier' = $1

    -- From RDS DB Instances (edge)
    union all
    select
      db_instance_identifier as from_id,
      $1 as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_rds_db_instance,
      jsonb_array_elements(subnets) as s
    where
      s ->> 'SubnetIdentifier' = $1

    -- From EC2 Instance (node)
    union all
    select
      null as from_id,
      null as to_id,
      instance_id as id,
      title as title,
      'aws_ec2_instance' as category,
      jsonb_build_object(
        'ARN', arn,
        'State', instance_state,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_ec2_instance
    where
      subnet_id = $1

    -- From EC2 Instances (edge)
    union all
    select
      instance_id as from_id,
      $1 as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_instance
    where
      subnet_id = $1

    -- From Lambda Functions (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_lambda_function' as category,
      jsonb_build_object(
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_lambda_function,
      jsonb_array_elements(vpc_subnet_ids) as s
    where
       trim((s::text ), '""') = $1

    -- From Lambda Functions (edge)
    union all
    select
      arn as from_id,
      $1 as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_lambda_function,
      jsonb_array_elements(vpc_subnet_ids) as s
    where
      trim((s::text ), '""') = $1

    -- From Sagemaker Notebook Instances (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_sagemaker_notebook_instance' as category,
      jsonb_build_object(
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_sagemaker_notebook_instance
    where
      subnet_id = $1

    -- From Sagemaker Notebook Instances (edge)
    union all
    select
      arn as from_id,
      $1 as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_sagemaker_notebook_instance
    where
      subnet_id = $1

  EOQ
  param "subnet_id" {}

}


