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

      with "vpcs" {
        sql = <<-EOQ
          select
            vpc_id as vpc_id
          from
            aws_vpc_subnet
          where
            subnet_id = $1;
        EOQ

        args = [self.input.subnet_id.value]
      }

      with "rds_db_instances" {
        sql = <<-EOQ
          select
            arn as rds_instance_arn
          from
            aws_rds_db_instance,
            jsonb_array_elements(subnets) as s
          where
            s ->> 'SubnetIdentifier' = $1;
        EOQ

        args = [self.input.subnet_id.value]
      }

      with "ec2_instances" {
        sql = <<-EOQ
          select
            arn as instance_arn
          from
            aws_ec2_instance
          where
            subnet_id = $1;
        EOQ

        args = [self.input.subnet_id.value]
      }

      with "lambda_functions" {
        sql = <<-EOQ
          select
            arn as lambda_arn
          from
            aws_lambda_function,
            jsonb_array_elements_text(vpc_subnet_ids) as s
          where
            s = $1;
        EOQ

        args = [self.input.subnet_id.value]
      }

      with "flow_logs" {
        sql = <<-EOQ
          select
            flow_log_id as flow_log_id
          from
            aws_vpc_flow_log
          where
            resource_id = $1;
        EOQ

        args = [self.input.subnet_id.value]
      }

      with "enis" {
        sql = <<-EOQ
          select
            network_interface_id as eni_id
          from
            aws_ec2_network_interface
          where
            subnet_id = $1;
        EOQ

        args = [self.input.subnet_id.value]
      }

      nodes = [
        node.vpc_subnet,
        node.vpc,
        node.aws_rds_db_instance_nodes,
        node.aws_ec2_instance_nodes,
        node.aws_lambda_function_nodes,
        node.aws_vpc_flow_log_nodes,
        node.aws_ec2_network_interface_nodes,

        node.aws_vpc_subnet_vpc_route_table_nodes,
        node.aws_vpc_subnet_vpc_network_acl_nodes,
        node.aws_vpc_subnet_sagemaker_notebook_instance_nodes,
      ]

      edges = [
        edge.aws_vpc_to_vpc_subnet_edges,
        edge.aws_vpc_subnet_to_flow_log_edges,
        edge.aws_vpc_subnet_to_vpc_route_table_edges,
        edge.aws_vpc_subnet_to_vpc_network_acl_edges,
        edge.aws_vpc_subnet_to_rds_db_instance_edges,
        edge.aws_vpc_subnet_to_ec2_instance_edges,
        edge.aws_vpc_subnet_to_lambda_function_edges,
        edge.aws_vpc_subnet_to_sagemaker_notebook_instance_edges,
        edge.aws_vpc_subnet_to_network_interface_edges
      ]

      args = {
        vpc_subnet_ids       = [self.input.subnet_id.value]
        eni_ids              = with.enis.rows[*].eni_id
        flow_log_ids         = with.flow_logs.rows[*].flow_log_id
        function_arns        = with.lambda_functions.rows[*].lambda_arn
        ec2_instance_arns    = with.ec2_instances.rows[*].instance_arn
        rds_db_instance_arns = with.rds_db_instances.rows[*].rds_instance_arn
        vpc_vpc_ids          = with.vpcs.rows[*].vpc_id
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

node "vpc_subnet" {
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
      subnet_id = any($1 ::text[]);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "aws_vpc_to_vpc_subnet_edges" {
  title = "subnet"

  sql = <<-EOQ
     select
      vpc_id as from_id,
      vpc_subnet_id as to_id
    from
      unnest($1::text[]) as vpc_vpc_id,
      unnest($2::text[]) as vpc_subnet_id;
  EOQ

  param "vpc_vpc_ids" {}
  param "vpc_subnet_ids" {}
}

node "aws_vpc_subnet_vpc_route_table_nodes" {
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
      a ->> 'SubnetId' = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "aws_vpc_subnet_to_vpc_route_table_edges" {
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

node "aws_vpc_subnet_vpc_network_acl_nodes" {
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
      a ->> 'SubnetId' = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "aws_vpc_subnet_to_vpc_network_acl_edges" {
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


edge "aws_vpc_subnet_to_rds_db_instance_edges" {
  title = "rds db instance"

  sql = <<-EOQ
    select
      vpc_subnet_id as from_id,
      rds_db_instance_arns as to_id
    from
      unnest($1::text[]) as rds_db_instance_arns,
      unnest($2::text[]) as vpc_subnet_id;
  EOQ

  param "rds_db_instance_arns" {}
  param "vpc_subnet_ids" {}
}



edge "aws_vpc_subnet_to_ec2_instance_edges" {
  title = "ec2 instance"

  sql = <<-EOQ
    select
      vpc_subnet_id as from_id,
      ec2_instance_arn as to_id
    from
      unnest($1::text[]) as ec2_instance_arn,
      unnest($2::text[]) as vpc_subnet_id;
  EOQ

  param "ec2_instance_arns" {}
  param "vpc_subnet_ids" {}
}

edge "aws_vpc_subnet_to_lambda_function_edges" {
  title = "lambda function"

  sql = <<-EOQ
    select
      vpc_subnet_id as from_id,
      function_arns as to_id
    from
      unnest($1::text[]) as function_arns,
      unnest($2::text[]) as vpc_subnet_id;
  EOQ

  param "function_arns" {}
  param "vpc_subnet_ids" {}
}

node "aws_vpc_subnet_sagemaker_notebook_instance_nodes" {
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
      subnet_id = any($1);
  EOQ

  param "vpc_subnet_ids" {}
}

edge "aws_vpc_subnet_to_sagemaker_notebook_instance_edges" {
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

edge "aws_vpc_subnet_to_flow_log_edges" {
  title = "flow log"

  sql = <<-EOQ
   select
      vpc_subnet_id as from_id,
      flow_log_ids as to_id
    from
      unnest($1::text[]) as flow_log_ids,
      unnest($2::text[]) as vpc_subnet_id;
  EOQ

  param "flow_log_ids" {}
  param "vpc_subnet_ids" {}
}

edge "aws_vpc_subnet_to_network_interface_edges" {
  title = "eni"

  sql = <<-EOQ
   select
      vpc_subnet_id as from_id,
      eni_ids as to_id
    from
      unnest($1::text[]) as eni_ids,
      unnest($2::text[]) as vpc_subnet_id;
  EOQ

  param "eni_ids" {}
  param "vpc_subnet_ids" {}
}


