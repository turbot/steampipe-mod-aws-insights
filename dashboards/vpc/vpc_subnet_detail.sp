dashboard "aws_vpc_subnet_detail" {

  title         = "AWS VPC Subnet Detail"
  documentation = file("./dashboards/vpc/docs/vpc_subnet_detail.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "subnet_id" {
    title = "Select a subnet:"
    sql   = query.aws_vpc_subnet_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_vpc_subnet_num_ips
      args = {
        subnet_id = self.input.subnet_id.value
      }
    }

    card {
      width = 2
      query = query.aws_vpc_subnet_cidr_block
      args = {
        subnet_id = self.input.subnet_id.value
      }
    }

    card {
      width = 2
      query = query.aws_vpc_subnet_map_public_ip_on_launch_disabled
      args = {
        subnet_id = self.input.subnet_id.value
      }
    }

  }

  container {

    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_vpc_subnet_relationships_graph
      args = {
        subnet_id = self.input.subnet_id.value
      }
      category "aws_vpc_subnet" {}
    }
  }

  container {

    container {

      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.aws_vpc_subnet_overview
        args = {
          subnet_id = self.input.subnet_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_vpc_subnet_tags
        args = {
          subnet_id = self.input.subnet_id.value
        }
      }

    }
    container {

      width = 6

      table {
        title = "Launched Resources"
        query = query.aws_vpc_subnet_association
        args = {
          subnet_id = self.input.subnet_id.value
        }

        column "link" {
          display = "none"
        }

        column "Title" {
          href = "{{ .link }}"
        }

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
    with subnet as (
      select
        *
      from
        aws_vpc_subnet
      where
        subnet_id = $1
    )
    select
      null as from_id,
      null as to_id,
      subnet_id as id,
      title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'Subnet ID', subnet_id,
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
        'VPC ID', s.vpc_id,
        'ARN', v.arn,
        'Region', v.region,
        'CIDR Block', v.cidr_block,
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
      'vpc' as title,
      'vpc_subnet_to_vpc' as category,
      jsonb_build_object(
        'VPC ID', v.vpc_id,
        'ARN', v.arn,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      subnet as s
      left join aws_vpc as v on v.vpc_id = s.vpc_id

    -- To VPC route tables (node)
    union all
    select
      null as from_id,
      null as to_id,
      route_table_id as id,
      title as title,
      'aws_vpc_route_table' as category,
      jsonb_build_object(
        'Owner ID', owner_id,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_route_table,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = $1

    -- To VPC route tables (edge)
    union all
    select
      $1 as from_id,
      route_table_id as to_id,
      null as id,
      'route to' as title,
      'vpc_subnet_to_vpc_route_table' as category,
      jsonb_build_object(
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_route_table,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = $1

    -- To VPC network ACLs (node)
    union all
    select
      null as from_id,
      null as to_id,
      network_acl_id as id,
      title as title,
      'aws_vpc_network_acl' as category,
      jsonb_build_object(
        'ARN', arn,
        'Is Default', is_default,
        'Association Id', a ->> 'NetworkAclAssociationId',
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_network_acl,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = $1

    -- To VPC network ACLs (edge)
    union all
    select
      $1 as from_id,
      network_acl_id as to_id,
      null as id,
      'network acl' as title,
      'vpc_subnet_to_vpc_network_acl' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_network_acl,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = $1

    -- From RDS DB instances (node)
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
        'Engine', engine,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_rds_db_instance,
      jsonb_array_elements(subnets) as s
    where
      s ->> 'SubnetIdentifier' = $1

    -- From RDS DB instances (edge)
    union all
    select
      db_instance_identifier as from_id,
      $1 as to_id,
      null as id,
      'rds db instance' as title,
      'rds_db_instance_to_vpc_subnet' as category,
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

    -- From EC2 instances (node)
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

    -- From EC2 instances (edge)
    union all
    select
      instance_id as from_id,
      $1 as to_id,
      null as id,
      'ec2 instance' as title,
      'ec2_instance_to_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_instance
    where
      subnet_id = $1

    -- From Lambda functions (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_lambda_function' as category,
      jsonb_build_object(
        'ARN', arn,
        'Runtime', runtime,
        'Architectures', architectures,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_lambda_function,
      jsonb_array_elements(vpc_subnet_ids) as s
    where
      trim((s::text ), '""') = $1

    -- From Lambda functions (edge)
    union all
    select
      arn as from_id,
      $1 as to_id,
      null as id,
      'lambda function' as title,
      'lambda_function_to_vpc_subnet' as category,
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

    -- From Sagemaker notebook instances (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_sagemaker_notebook_instance' as category,
      jsonb_build_object(
        'ARN', arn,
        'Status', notebook_instance_status,
        'Instance Type', instance_type,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_sagemaker_notebook_instance
    where
      subnet_id = $1

    -- From Sagemaker notebook instances (edge)
    union all
    select
      arn as from_id,
      $1 as to_id,
      null as id,
      'notebook instance' as title,
      'sagemaker_notebook_instance_to_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_sagemaker_notebook_instance
    where
      subnet_id = $1

    order by
      from_id,
      to_id;
  EOQ

  param "subnet_id" {}
}

query "aws_vpc_subnet_num_ips" {
  sql = <<-EOQ
    select
      available_ip_address_count as "IP Addresses"
    from
      aws_vpc_subnet
    where
      subnet_id = $1
  EOQ

  param "subnet_id" {}
}

query "aws_vpc_subnet_cidr_block" {
  sql = <<-EOQ
    select
      cidr_block as "CIDR Block"
    from
      aws_vpc_subnet
    where
      subnet_id = $1
  EOQ

  param "subnet_id" {}
}

query "aws_vpc_subnet_map_public_ip_on_launch_disabled" {
  sql = <<-EOQ
    select
      'Map Public IP on Launch' as label,
      map_public_ip_on_launch as value,
      case when map_public_ip_on_launch then 'alert' else 'ok' end as type
    from
      aws_vpc_subnet
    where
      subnet_id = $1
  EOQ

  param "subnet_id" {}
}

query "aws_vpc_subnet_overview" {
  sql = <<-EOQ
    select
      subnet_id as "Subnet ID",
      vpc_id as "VPC ID",
      owner_id as "Owner ID",
      availability_zone as "Availability Zone",
      availability_zone_id as "Availability Zone ID",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      subnet_arn as "ARN"
    from
      aws_vpc_subnet
    where
      subnet_id = $1
  EOQ

  param "subnet_id" {}
}

query "aws_vpc_subnet_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_vpc_subnet,
      jsonb_array_elements(tags_src) as tag
    where
      subnet_id = $1
    order by
      tag ->> 'Key';
  EOQ

  param "subnet_id" {}
}

query "aws_vpc_subnet_association" {
  sql = <<-EOQ

    -- EC2 instances
    select
      title as "Title",
      'aws_ec2_instance' as "Type",
      arn as "ARN",
      '${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn=' || arn as link
    from
      aws_ec2_instance
    where
      subnet_id = $1

    -- Lambda functions
    union all
    select
      title as "Title",
      'aws_lambda_function' as "Type",
      arn as "ARN",
      '${dashboard.aws_lambda_function_detail.url_path}?input.lambda_arn=' || arn as link
    from
      aws_lambda_function,
      jsonb_array_elements(vpc_subnet_ids) as s
    where
       trim((s::text ), '""') = $1

    -- Sagemaker Notebook Instances
    union all
    select
      title as "Title",
      'aws_sagemaker_notebook_instance' as "Type",
      arn as "ARN",
      null as link
    from
      aws_sagemaker_notebook_instance
    where
      subnet_id = $1

    -- RDS DB Instances
    union all
    select
      title as "Title",
      'aws_rds_db_instance' as "Type",
      arn as "ARN",
      '${dashboard.aws_rds_db_instance_detail.url_path}?input.db_instance_arn=' || arn as link
    from
      aws_rds_db_instance,
      jsonb_array_elements(subnets) as s
    where
      s ->> 'SubnetIdentifier' = $1

    -- Network ACLs
    union all
    select
      title as "Title",
      'aws_vpc_network_acl' as "Type",
      network_acl_id as "ID",
      null as link
    from
      aws_vpc_network_acl,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = $1

    -- Route Tables
    union all
    select
      title as "Title",
      'aws_vpc_route_table' as "Type",
      route_table_id as "ID",
      null as link
   from
      aws_vpc_route_table,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = $1;
  EOQ

  param "subnet_id" {}
}
