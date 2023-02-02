dashboard "vpc_subnet_detail" {

  title         = "AWS VPC Subnet Detail"
  documentation = file("./dashboards/vpc/docs/vpc_subnet_detail.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "subnet_id" {
    title = "Select a subnet:"
    query = query.vpc_subnet_input
    width = 4
  }

  container {

    card {
      width = 3
      query = query.vpc_subnet_num_ips
      args  = [self.input.subnet_id.value]
    }

    card {
      width = 3
      query = query.vpc_subnet_cidr_block
      args  = [self.input.subnet_id.value]
    }

    card {
      width = 3
      query = query.vpc_subnet_map_public_ip_on_launch_disabled
      args  = [self.input.subnet_id.value]
    }

  }

  with "ec2_application_load_balancers_for_vpc_subnet" {
    query = query.ec2_application_load_balancers_for_vpc_subnet
    args  = [self.input.subnet_id.value]
  }

  with "ec2_classic_load_balancers_for_vpc_subnet" {
    query = query.ec2_classic_load_balancers_for_vpc_subnet
    args  = [self.input.subnet_id.value]
  }

  with "ec2_gateway_load_balancers_for_vpc_subnet" {
    query = query.ec2_gateway_load_balancers_for_vpc_subnet
    args  = [self.input.subnet_id.value]
  }

  with "ec2_instances_for_vpc_subnet" {
    query = query.ec2_instances_for_vpc_subnet
    args  = [self.input.subnet_id.value]
  }

  with "ec2_network_interfaces_for_vpc_subnet" {
    query = query.ec2_network_interfaces_for_vpc_subnet
    args  = [self.input.subnet_id.value]
  }

  with "ec2_network_load_balancers_for_vpc_subnet" {
    query = query.ec2_network_load_balancers_for_vpc_subnet
    args  = [self.input.subnet_id.value]
  }

  with "lambda_functions_for_vpc_subnet" {
    query = query.lambda_functions_for_vpc_subnet
    args  = [self.input.subnet_id.value]
  }

  with "rds_db_instances_for_vpc_subnet" {
    query = query.rds_db_instances_for_vpc_subnet
    args  = [self.input.subnet_id.value]
  }

  with "sagemaker_notebook_instances_for_vpc_subnet" {
    query = query.sagemaker_notebook_instances_for_vpc_subnet
    args  = [self.input.subnet_id.value]
  }

  with "vpc_flow_logs_for_vpc_subnet" {
    query = query.vpc_flow_logs_for_vpc_subnet
    args  = [self.input.subnet_id.value]
  }

  with "vpc_vpcs_for_vpc_subnet" {
    query = query.vpc_vpcs_for_vpc_subnet
    args  = [self.input.subnet_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.ec2_application_load_balancer
        args = {
          ec2_application_load_balancer_arns = with.ec2_application_load_balancers_for_vpc_subnet.rows[*].alb_arn
        }
      }

      node {
        base = node.ec2_classic_load_balancer
        args = {
          ec2_classic_load_balancer_arns = with.ec2_classic_load_balancers_for_vpc_subnet.rows[*].clb_arn
        }
      }

      node {
        base = node.ec2_gateway_load_balancer
        args = {
          ec2_gateway_load_balancer_arns = with.ec2_gateway_load_balancers_for_vpc_subnet.rows[*].glb_arn
        }
      }

      node {
        base = node.ec2_instance
        args = {
          ec2_instance_arns = with.ec2_instances_for_vpc_subnet.rows[*].instance_arn
        }
      }

      node {
        base = node.ec2_network_interface
        args = {
          ec2_network_interface_ids = with.ec2_network_interfaces_for_vpc_subnet.rows[*].eni_id
        }
      }

      node {
        base = node.ec2_network_load_balancer
        args = {
          ec2_network_load_balancer_arns = with.ec2_network_load_balancers_for_vpc_subnet.rows[*].nlb_arn
        }
      }

      node {
        base = node.lambda_function
        args = {
          lambda_function_arns = with.lambda_functions_for_vpc_subnet.rows[*].lambda_arn
        }
      }

      node {
        base = node.rds_db_instance
        args = {
          rds_db_instance_arns = with.rds_db_instances_for_vpc_subnet.rows[*].rds_instance_arn
        }
      }

      node {
        base = node.sagemaker_notebook_instance
        args = {
          sagemaker_notebook_instance_arns = with.sagemaker_notebook_instances_for_vpc_subnet.rows[*].notebook_instance_arn
        }
      }

      node {
        base = node.vpc_flow_log
        args = {
          vpc_flow_log_ids = with.vpc_flow_logs_for_vpc_subnet.rows[*].flow_log_id
        }
      }

      node {
        base = node.vpc_network_acl
        args = {
          vpc_subnet_ids = [self.input.subnet_id.value]
        }
      }

      node {
        base = node.vpc_route_table
        args = {
          vpc_subnet_ids = [self.input.subnet_id.value]
        }
      }

      node {
        base = node.vpc_subnet
        args = {
          vpc_subnet_ids = [self.input.subnet_id.value]
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_vpc_subnet.rows[*].vpc_id
        }
      }

      edge {
        base = edge.vpc_subnet_to_ec2_application_load_balancer
        args = {
          vpc_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_ec2_classic_load_balancer
        args = {
          vpc_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_ec2_gateway_load_balancer
        args = {
          vpc_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_ec2_instance
        args = {
          vpc_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_ec2_network_load_balancer
        args = {
          vpc_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_lambda_function
        args = {
          vpc_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_network_interface
        args = {
          vpc_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_rds_db_instance
        args = {
          vpc_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_sagemaker_notebook_instance
        args = {
          vpc_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_flow_log
        args = {
          vpc_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_network_acl
        args = {
          vpc_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_route_table
        args = {
          vpc_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.vpc_vpc_to_vpc_subnet
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_vpc_subnet.rows[*].vpc_id
        }
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
        query = query.vpc_subnet_overview
        args  = [self.input.subnet_id.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.vpc_subnet_tags
        args  = [self.input.subnet_id.value]
      }

    }
    container {

      width = 6

      table {
        title = "Launched Resources"
        query = query.vpc_subnet_association
        args  = [self.input.subnet_id.value]

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

query "vpc_subnet_input" {
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

# card queries

query "vpc_subnet_num_ips" {
  sql = <<-EOQ
    select
      available_ip_address_count as "IP Addresses"
    from
      aws_vpc_subnet
    where
      subnet_id = $1
  EOQ

}

query "vpc_subnet_cidr_block" {
  sql = <<-EOQ
    select
      cidr_block as "CIDR Block"
    from
      aws_vpc_subnet
    where
      subnet_id = $1
  EOQ

}

query "vpc_subnet_map_public_ip_on_launch_disabled" {
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

}

# with queries

query "ec2_application_load_balancers_for_vpc_subnet" {
  sql = <<-EOQ
    select
      arn as alb_arn
    from
      aws_ec2_application_load_balancer,
      jsonb_array_elements(availability_zones) as az
    where
      az ->> 'SubnetId' = $1;
  EOQ
}

query "ec2_classic_load_balancers_for_vpc_subnet" {
  sql = <<-EOQ
    select
      arn as clb_arn
    from
      aws_ec2_classic_load_balancer,
      jsonb_array_elements(availability_zones) as az
    where
      az ->> 'SubnetId' = $1;
  EOQ
}

query "ec2_gateway_load_balancers_for_vpc_subnet" {
  sql = <<-EOQ
    select
      arn as glb_arn
    from
      aws_ec2_gateway_load_balancer,
      jsonb_array_elements(availability_zones) as az
    where
      az ->> 'SubnetId' = $1;
  EOQ
}

query "ec2_instances_for_vpc_subnet" {
  sql = <<-EOQ
    select
      arn as instance_arn
    from
      aws_ec2_instance
    where
      subnet_id = $1;
  EOQ
}

query "ec2_network_interfaces_for_vpc_subnet" {
  sql = <<-EOQ
    select
      network_interface_id as eni_id
    from
      aws_ec2_network_interface
    where
      subnet_id = $1;
  EOQ
}

query "ec2_network_load_balancers_for_vpc_subnet" {
  sql = <<-EOQ
    select
      arn as nlb_arn
    from
      aws_ec2_network_load_balancer,
      jsonb_array_elements(availability_zones) as az
    where
      az ->> 'SubnetId' = $1;
  EOQ
}

query "lambda_functions_for_vpc_subnet" {
  sql = <<-EOQ
    select
      arn as lambda_arn
    from
      aws_lambda_function,
      jsonb_array_elements_text(vpc_subnet_ids) as s
    where
      s = $1;
  EOQ
}

query "rds_db_instances_for_vpc_subnet" {
  sql = <<-EOQ
    select
      arn as rds_instance_arn
    from
      aws_rds_db_instance,
      jsonb_array_elements(subnets) as s
    where
      s ->> 'SubnetIdentifier' = $1;
  EOQ
}

query "sagemaker_notebook_instances_for_vpc_subnet" {
  sql = <<-EOQ
    select
      arn as notebook_instance_arn
    from
      aws_sagemaker_notebook_instance
    where
      subnet_id = $1;
  EOQ
}

query "vpc_flow_logs_for_vpc_subnet" {
  sql = <<-EOQ
    select
      flow_log_id as flow_log_id
    from
      aws_vpc_flow_log
    where
      resource_id = $1;
  EOQ
}

query "vpc_vpcs_for_vpc_subnet" {
  sql = <<-EOQ
    select
      vpc_id as vpc_id
    from
      aws_vpc_subnet
    where
      subnet_id = $1;
  EOQ
}

# table queries

query "vpc_subnet_overview" {
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

}

query "vpc_subnet_tags" {
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

}

query "vpc_subnet_association" {
  sql = <<-EOQ

    -- EC2 instances
    select
      title as "Title",
      'aws_ec2_instance' as "Type",
      arn as "ARN",
      '${dashboard.ec2_instance_detail.url_path}?input.instance_arn=' || arn as link
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
      '${dashboard.lambda_function_detail.url_path}?input.lambda_arn=' || arn as link
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
      '${dashboard.rds_db_instance_detail.url_path}?input.db_instance_arn=' || arn as link
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

}
