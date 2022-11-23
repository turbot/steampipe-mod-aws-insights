dashboard "aws_vpc_subnet_detail" {

  title         = "AWS VPC Subnet Detail"
  documentation = file("./dashboards/vpc/docs/vpc_subnet_detail.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "subnet_id" {
    title = "Select a subnet:"
    query = query.aws_vpc_subnet_input
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
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_vpc_subnet_node,
        node.aws_vpc_subnet_from_vpc_node,
        node.aws_vpc_subnet_to_vpc_route_table_node,
        node.aws_vpc_subnet_to_vpc_network_acl_node,
        node.aws_vpc_subnet_to_rds_db_instance_node,
        node.aws_vpc_subnet_to_ec2_instance_node,
        node.aws_vpc_subnet_to_lambda_function_node,
        node.aws_vpc_subnet_to_sagemaker_notebook_instance_node
      ]

      edges = [
        edge.aws_vpc_subnet_from_vpc_edge,
        edge.aws_vpc_subnet_to_vpc_route_table_edge,
        edge.aws_vpc_subnet_to_vpc_network_acl_edge,
        edge.aws_vpc_subnet_to_rds_db_instance_edge,
        edge.aws_vpc_subnet_to_ec2_instance_edge,
        edge.aws_vpc_subnet_to_lambda_function_edge,
        edge.aws_vpc_subnet_to_sagemaker_notebook_instance_edge
      ]

      args = {
        subnet_id = self.input.subnet_id.value
      }
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
      case when map_public_ip_on_launch then 'Enabled' else 'Disabled' end as value,
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

node "aws_vpc_subnet_node" {
  category = category.aws_vpc_subnet

  sql = <<-EOQ
    select
      subnet_id as id,
      title as title,
      jsonb_build_object(
        'Subnet ID', subnet_id,
        'ARN', subnet_arn,
        'VPC ID', vpc_id,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_subnet
    where
      subnet_id = $1;
  EOQ

  param "subnet_id" {}
}

node "aws_vpc_subnet_from_vpc_node" {
  category = category.aws_vpc

  sql = <<-EOQ
     select
      v.vpc_id as id,
      v.title as title,
      jsonb_build_object(
        'VPC ID', s.vpc_id,
        'ARN', v.arn,
        'Region', v.region,
        'CIDR Block', v.cidr_block,
        'Account ID', v.account_id
      ) as properties
    from
      aws_vpc_subnet as s
      left join aws_vpc as v on v.vpc_id = s.vpc_id
    where
      s.subnet_id = $1;
  EOQ

  param "subnet_id" {}
}

edge "aws_vpc_subnet_from_vpc_edge" {
  title = "subnet"

  sql = <<-EOQ
     select
      v.vpc_id as from_id,
      s.subnet_id as to_id
    from
      aws_vpc_subnet as s
      left join aws_vpc as v on v.vpc_id = s.vpc_id
    where
      s.subnet_id = $1;
  EOQ

  param "subnet_id" {}
}

node "aws_vpc_subnet_to_vpc_route_table_node" {
  category = category.aws_vpc_route_table

  sql = <<-EOQ
    select
      route_table_id as id,
      title as title,
      jsonb_build_object(
        'Owner ID', owner_id,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_vpc_route_table,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = $1;
  EOQ

  param "subnet_id" {}
}

edge "aws_vpc_subnet_to_vpc_route_table_edge" {
  title = "route to"

  sql = <<-EOQ
    select
      $1 as from_id,
      route_table_id as to_id
    from
      aws_vpc_route_table,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = $1;
  EOQ

  param "subnet_id" {}
}

node "aws_vpc_subnet_to_vpc_network_acl_node" {
  category = category.aws_vpc_network_acl

  sql = <<-EOQ
    select
      network_acl_id as id,
      title as title,
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
      a ->> 'SubnetId' = $1;
  EOQ

  param "subnet_id" {}
}

edge "aws_vpc_subnet_to_vpc_network_acl_edge" {
  title = "network acl"

  sql = <<-EOQ
    select
      $1 as from_id,
      network_acl_id as to_id
    from
      aws_vpc_network_acl,
      jsonb_array_elements(associations) as a
    where
      a ->> 'SubnetId' = $1;
  EOQ

  param "subnet_id" {}
}

node "aws_vpc_subnet_to_rds_db_instance_node" {
  category = category.aws_rds_db_instance

  sql = <<-EOQ
    select
      db_instance_identifier as id,
      title as title,
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
      s ->> 'SubnetIdentifier' = $1;
  EOQ

  param "subnet_id" {}
}

edge "aws_vpc_subnet_to_rds_db_instance_edge" {
  title = "subnet"

  sql = <<-EOQ
    select
      $1 as from_id,
      db_instance_identifier as to_id
    from
      aws_rds_db_instance,
      jsonb_array_elements(subnets) as s
    where
      s ->> 'SubnetIdentifier' = $1;
  EOQ

  param "subnet_id" {}
}

node "aws_vpc_subnet_to_ec2_instance_node" {
  category = category.aws_ec2_instance

  sql = <<-EOQ
    select
      instance_id as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'State', instance_state,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_ec2_instance
    where
      subnet_id = $1;
  EOQ

  param "subnet_id" {}
}

edge "aws_vpc_subnet_to_ec2_instance_edge" {
  title = "ec2 instance"

  sql = <<-EOQ
    select
      $1 as from_id,
      instance_id as to_id
    from
      aws_ec2_instance
    where
      subnet_id = $1;
  EOQ

  param "subnet_id" {}
}

node "aws_vpc_subnet_to_lambda_function_node" {
  category = category.aws_lambda_function

  sql = <<-EOQ
    select
      arn as id,
      title as title,
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
      trim((s::text ), '""') = $1;
  EOQ

  param "subnet_id" {}
}

edge "aws_vpc_subnet_to_lambda_function_edge" {
  title = "lambda function"

  sql = <<-EOQ
    select
      $1 as from_id,
      arn as to_id
    from
      aws_lambda_function,
      jsonb_array_elements(vpc_subnet_ids) as s
    where
      trim((s::text ), '""') = $1
  EOQ

  param "subnet_id" {}
}

node "aws_vpc_subnet_to_sagemaker_notebook_instance_node" {
  category = category.aws_sagemaker_notebook_instance

  sql = <<-EOQ
    select
      arn as id,
      title as title,
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
  EOQ

  param "subnet_id" {}
}

edge "aws_vpc_subnet_to_sagemaker_notebook_instance_edge" {
  title = "notebook instance"

  sql = <<-EOQ
   select
      $1 as from_id,
      arn as to_id
    from
      aws_sagemaker_notebook_instance
    where
      subnet_id = $1
  EOQ

  param "subnet_id" {}
}
