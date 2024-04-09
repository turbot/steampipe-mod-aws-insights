dashboard "ec2_instance_detail" {

  title         = "AWS EC2 Instance Detail"
  documentation = file("./dashboards/ec2/docs/ec2_instance_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "instance_arn" {
    title = "Select an instance:"
    query = query.ec2_instance_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.ec2_instance_status
      args  = [self.input.instance_arn.value]
    }

    card {
      width = 2
      query = query.ec2_instance_type
      args  = [self.input.instance_arn.value]
    }

    card {
      width = 2
      query = query.ec2_instance_total_cores_count
      args  = [self.input.instance_arn.value]
    }

    card {
      width = 2
      query = query.ec2_instance_public_access
      args  = [self.input.instance_arn.value]
    }

    card {
      width = 2
      query = query.ec2_instance_ebs_optimized
      args  = [self.input.instance_arn.value]
    }
  }

  with "ebs_volumes_for_ec2_instance" {
    query = query.ebs_volumes_for_ec2_instance
    args  = [self.input.instance_arn.value]
  }

  with "ec2_application_load_balancers_for_ec2_instance" {
    query = query.ec2_application_load_balancers_for_ec2_instance
    args  = [self.input.instance_arn.value]
  }

  with "ec2_classic_load_balancers_for_ec2_instance" {
    query = query.ec2_classic_load_balancers_for_ec2_instance
    args  = [self.input.instance_arn.value]
  }

  with "ec2_gateway_load_balancers_for_ec2_instance" {
    query = query.ec2_gateway_load_balancers_for_ec2_instance
    args  = [self.input.instance_arn.value]
  }

  with "ec2_network_interfaces_for_ec2_instance" {
    query = query.ec2_network_interfaces_for_ec2_instance
    args  = [self.input.instance_arn.value]
  }

  with "ec2_network_load_balancers_for_ec2_instance" {
    query = query.ec2_network_load_balancers_for_ec2_instance
    args  = [self.input.instance_arn.value]
  }

  with "ec2_target_groups_for_ec2_instance" {
    query = query.ec2_target_groups_for_ec2_instance
    args  = [self.input.instance_arn.value]
  }

  with "ecs_clusters_for_ec2_instance" {
    query = query.ecs_clusters_for_ec2_instance
    args  = [self.input.instance_arn.value]
  }

  with "iam_roles_for_ec2_instance" {
    query = query.iam_roles_for_ec2_instance
    args  = [self.input.instance_arn.value]
  }

  with "vpc_eips_for_ec2_instance" {
    query = query.vpc_eips_for_ec2_instance
    args  = [self.input.instance_arn.value]
  }

  with "vpc_security_groups_for_ec2_instance" {
    query = query.vpc_security_groups_for_ec2_instance
    args  = [self.input.instance_arn.value]
  }

  with "vpc_subnets_for_ec2_instance" {
    query = query.vpc_subnets_for_ec2_instance
    args  = [self.input.instance_arn.value]
  }

  with "vpc_vpcs_for_ec2_instance" {
    query = query.vpc_vpcs_for_ec2_instance
    args  = [self.input.instance_arn.value]
  }

  container {

    graph {

      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.ebs_volume
        args = {
          ebs_volume_arns = with.ebs_volumes_for_ec2_instance.rows[*].volume_arn
        }
      }

      node {
        base = node.ec2_application_load_balancer
        args = {
          ec2_application_load_balancer_arns = with.ec2_application_load_balancers_for_ec2_instance.rows[*].application_load_balancer_arn
        }
      }

      node {
        base = node.ec2_autoscaling_group
        args = {
          ec2_instance_arns = [self.input.instance_arn.value]
        }
      }


      node {
        base = node.ec2_classic_load_balancer
        args = {
          ec2_classic_load_balancer_arns = with.ec2_classic_load_balancers_for_ec2_instance.rows[*].classic_load_balancer_arn
        }
      }


      node {
        base = node.ec2_gateway_load_balancer
        args = {
          ec2_gateway_load_balancer_arns = with.ec2_gateway_load_balancers_for_ec2_instance.rows[*].gateway_load_balancer_arn
        }
      }

      node {
        base = node.ec2_instance
        args = {
          ec2_instance_arns = [self.input.instance_arn.value]
        }
      }

      node {
        base = node.ec2_key_pair
        args = {
          ec2_instance_arns = [self.input.instance_arn.value]
        }
      }


      node {
        base = node.ec2_network_interface
        args = {
          ec2_network_interface_ids = with.ec2_network_interfaces_for_ec2_instance.rows[*].network_interface_id
        }
      }

      node {
        base = node.ec2_network_load_balancer
        args = {
          ec2_network_load_balancer_arns = with.ec2_network_load_balancers_for_ec2_instance.rows[*].network_load_balancer_arn
        }
      }


      node {
        base = node.ec2_target_group
        args = {
          ec2_target_group_arns = with.ec2_target_groups_for_ec2_instance.rows[*].target_group_arn
        }
      }

      node {
        base = node.ecs_cluster
        args = {
          ecs_cluster_arns = with.ecs_clusters_for_ec2_instance.rows[*].cluster_arn
        }
      }

      node {
        base = node.iam_instance_profile
        args = {
          ec2_instance_arns = [self.input.instance_arn.value]
        }
      }

      node {
        base = node.iam_role
        args = {
          iam_role_arns = with.iam_roles_for_ec2_instance.rows[*].role_arn
        }
      }

      node {
        base = node.vpc_eip
        args = {
          vpc_eip_arns = with.vpc_eips_for_ec2_instance.rows[*].eip_arn
        }
      }

      node {
        base = node.vpc_security_group
        args = {
          vpc_security_group_ids = with.vpc_security_groups_for_ec2_instance.rows[*].security_group_id
        }
      }

      node {
        base = node.vpc_subnet
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_ec2_instance.rows[*].subnet_id
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_ec2_instance.rows[*].vpc_id
        }
      }

      edge {
        base = edge.ec2_autoscaling_group_to_ec2_instance
        args = {
          ec2_instance_arns = [self.input.instance_arn.value]
        }
      }

      edge {
        base = edge.ec2_classic_load_balancer_to_ec2_instance
        args = {
          ec2_classic_load_balancer_arns = with.ec2_classic_load_balancers_for_ec2_instance.rows[*].classic_load_balancer_arn
        }
      }

      edge {
        base = edge.ec2_instance_to_ebs_volume
        args = {
          ec2_instance_arns = [self.input.instance_arn.value]
        }
      }

      edge {
        base = edge.ec2_instance_to_ec2_key_pair
        args = {
          ec2_instance_arns = [self.input.instance_arn.value]
        }
      }

      edge {
        base = edge.ec2_instance_to_ec2_network_interface
        args = {
          ec2_instance_arns = [self.input.instance_arn.value]
        }
      }

      edge {
        base = edge.ec2_instance_to_iam_instance_profile
        args = {
          ec2_instance_arns = [self.input.instance_arn.value]
        }
      }

      edge {
        base = edge.ec2_instance_to_vpc_security_group
        args = {
          ec2_instance_arns = [self.input.instance_arn.value]
        }
      }

      edge {
        base = edge.ec2_instance_to_vpc_subnet
        args = {
          ec2_instance_arns = [self.input.instance_arn.value]
        }
      }

      edge {
        base = edge.ec2_load_balancer_to_ec2_target_group
        args = {
          ec2_instance_arns = [self.input.instance_arn.value]
        }
      }

      edge {
        base = edge.ec2_network_interface_to_vpc_eip
        args = {
          ec2_network_interface_ids = with.ec2_network_interfaces_for_ec2_instance.rows[*].network_interface_id
        }
      }

      edge {
        base = edge.ec2_target_group_to_ec2_instance
        args = {
          ec2_target_group_arns = with.ec2_target_groups_for_ec2_instance.rows[*].target_group_arn
        }
      }

      edge {
        base = edge.ecs_cluster_to_ec2_instance
        args = {
          ec2_instance_arns = [self.input.instance_arn.value]
        }
      }

      edge {
        base = edge.iam_instance_profile_to_iam_role
        args = {
          iam_role_arns = with.iam_roles_for_ec2_instance.rows[*].role_arn
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_vpc
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_ec2_instance.rows[*].subnet_id
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
        query = query.ec2_instance_overview
        args  = [self.input.instance_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.ec2_instance_tags
        args  = [self.input.instance_arn.value]
      }
    }

    container {
      width = 6

      table {
        title = "Block Device Mappings"
        query = query.ec2_instance_block_device_mapping
        args  = [self.input.instance_arn.value]

        column "Volume ARN" {
          display = "none"
        }

        column "Volume ID" {
          // cyclic dependency prevents use of url_path, hardcode for now
          href = "/aws_insights.dashboard.ebs_volume_detail?input.volume_arn={{.'Volume ARN' | @uri}}"
        }
      }
    }

  }

  container {
    width = 12

    table {
      title = "Network Interfaces"
      query = query.ec2_instance_network_interfaces
      args  = [self.input.instance_arn.value]

      column "VPC ID" {
        // cyclic dependency prevents use of url_path, hardcode for now
        href = "/aws_insights.dashboard.vpc_detail?input.vpc_id={{ .'VPC ID' | @uri }}"
      }
    }

  }

  container {
    width = 6

    table {
      title = "Security Groups"
      query = query.ec2_instance_security_groups
      args  = [self.input.instance_arn.value]

      column "Group ID" {
        // cyclic dependency prevents use of url_path, hardcode for now
        href = "/aws_insights.dashboard.vpc_security_group_detail?input.security_group_id={{.'Group ID' | @uri}}"
      }
    }

  }

  container {
    width = 6

    table {
      title = "CPU cores"
      query = query.ec2_instance_cpu_cores
      args  = [self.input.instance_arn.value]
    }

  }

}

# Input queries

query "ec2_instance_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'instance_id', instance_id
      ) as tags
    from
      aws_ec2_instance
    order by
      title;
  EOQ
}

# With queries

# query "ebs_volumes_for_ec2_instance" {
#   sql = <<-EOQ
#     select
#       v.arn as volume_arn
#     from
#       aws_ec2_instance as i,
#       jsonb_array_elements(block_device_mappings) as bd,
#       aws_ebs_volume as v
#     where
#       v.volume_id = bd -> 'Ebs' ->> 'VolumeId'
#       and v.region = split_part($1, ':', 4)
#       and v.account_id = split_part($1, ':', 5)
#       and i.region = split_part($1, ':', 4)
#       and i.account_id = split_part($1, ':', 5)
#       and i.arn = $1;
#   EOQ
# }

# query "ebs_volumes_for_ec2_instance" {
#   sql = <<-EOQ
#     with ec2_instances as (
#       select
#         arn,
#         block_device_mappings,
#         region,
#         account_id
#       from
#         aws_ec2_instance
#       where
#         account_id = split_part($1, ':', 5)
#         and region = split_part($1, ':', 4)
#       order by
#         arn,
#         region,
#         account_id
#     ),
#     ebs_volumes as (
#       select
#         arn,
#         volume_id,
#         region,
#         account_id
#       from
#         aws_ebs_volume
#       where
#         account_id = split_part($1, ':', 5)
#         and region = split_part($1, ':', 4)
#       order by
#         volume_id,
#         region,
#         account_id
#     )
#     select
#       v.arn as volume_arn
#     from
#       ec2_instances as i,
#       jsonb_array_elements(block_device_mappings) as bd,
#       ebs_volumes as v
#     where
#       v.volume_id = bd -> 'Ebs' ->> 'VolumeId'
#       and i.arn = $1;
#   EOQ
# }

query "ebs_volumes_for_ec2_instance" {
  sql = <<-EOQ
    with ec2_instances as (
      select
        arn,
        block_device_mappings,
        region,
        account_id
      from
        aws_ec2_instance
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and arn = $1
      order by
        arn,
        region,
        account_id
    ),
    ebs_volumes as (
      select
        arn,
        volume_id,
        region,
        account_id
      from
        aws_ebs_volume
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
      order by
        volume_id,
        region,
        account_id
    )
    select
      v.arn as volume_arn
    from
      ec2_instances as i,
      jsonb_array_elements(block_device_mappings) as bd,
      ebs_volumes as v
    where
      v.volume_id = bd -> 'Ebs' ->> 'VolumeId';
  EOQ
}

# query "ec2_application_load_balancers_for_ec2_instance" {
#   sql = <<-EOQ
#     select
#       distinct lb.arn as application_load_balancer_arn
#     from
#       aws_ec2_instance as i,
#       aws_ec2_target_group as target,
#       jsonb_array_elements(target.target_health_descriptions) as health_descriptions,
#       jsonb_array_elements_text(target.load_balancer_arns) as l,
#       aws_ec2_application_load_balancer as lb
#     where
#       health_descriptions -> 'Target' ->> 'Id' = i.instance_id
#       and l = lb.arn
#       and lb.region = split_part($1, ':', 4)
#       and lb.account_id = split_part($1, ':', 5)
#       and i.arn = $1;
#   EOQ
# }

query "ec2_application_load_balancers_for_ec2_instance" {
  sql = <<-EOQ
    with aws_ec2_instances as (
      select
        instance_id,
        region,
        account_id,
        arn
      from
        aws_ec2_instance
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and arn = $1        
    ),
    aws_ec2_target_groups as (
      select
        target_health_descriptions,
        load_balancer_arns
      from 
        aws_ec2_target_group
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
    ),
    aws_ec2_application_load_balancers as (
      select
        arn
      from
        aws_ec2_application_load_balancer
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
    )
    select
      distinct lb.arn as application_load_balancer_arn
    from
      aws_ec2_instances as i,
      aws_ec2_target_groups as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions,
      jsonb_array_elements_text(target.load_balancer_arns) as l,
      aws_ec2_application_load_balancers as lb
    where
      health_descriptions -> 'Target' ->> 'Id' = i.instance_id
      and l = lb.arn;
  EOQ
}

# query "ec2_classic_load_balancers_for_ec2_instance" {
#   sql = <<-EOQ
#     select
#       distinct clb.arn as classic_load_balancer_arn
#     from
#       aws_ec2_classic_load_balancer as clb,
#       jsonb_array_elements(clb.instances) as instance,
#       aws_ec2_instance as i
#     where
#       i.arn = $1
#       and clb.region = split_part($1, ':', 4)
#       and clb.account_id = split_part($1, ':', 5)
#       and instance ->> 'InstanceId' = i.instance_id;
#   EOQ
# }

query "ec2_classic_load_balancers_for_ec2_instance" {
  sql = <<-EOQ
    with aws_ec2_instances as (
      select
        instance_id,
        account_id,
        region
      from 
        aws_ec2_instance
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and arn = $1            
    ),
    aws_ec2_classic_load_balancers as (
      select
        arn,
        instances,
        region,
        account_id
      from
        aws_ec2_classic_load_balancer
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
    )
    select
      distinct clb.arn as classic_load_balancer_arn
    from
      aws_ec2_classic_load_balancers as clb,
      jsonb_array_elements(clb.instances) as instance,
      aws_ec2_instances as i
    where
      instance ->> 'InstanceId' = i.instance_id;
  EOQ
}

# query "ec2_gateway_load_balancers_for_ec2_instance" {
#   sql = <<-EOQ
#     select
#       distinct lb.arn as gateway_load_balancer_arn
#     from
#       aws_ec2_instance as i,
#       aws_ec2_target_group as target,
#       jsonb_array_elements(target.target_health_descriptions) as health_descriptions,
#       jsonb_array_elements_text(target.load_balancer_arns) as l,
#       aws_ec2_gateway_load_balancer as lb
#     where
#       health_descriptions -> 'Target' ->> 'Id' = i.instance_id
#       and l = lb.arn
#       and lb.region = split_part($1, ':', 4)
#       and lb.account_id = split_part($1, ':', 5)
#       and i.arn = $1;
#   EOQ
# }

query "ec2_gateway_load_balancers_for_ec2_instance" {
  sql = <<-EOQ
    with aws_ec2_instances as (
      select
        arn,
        instance_id,
        account_id,
        region
      from 
        aws_ec2_instance
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and arn = $1            
    ),
    aws_ec2_target_groups as (
      select
        target_health_descriptions,
        load_balancer_arns,
        account_id,
        region
      from 
        aws_ec2_target_group
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)        
    ),
    aws_ec2_gateway_load_balancers as (
      select
        arn,
        account_id,
        region
      from 
        aws_ec2_gateway_load_balancer
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)        
    )
    select
      distinct lb.arn as gateway_load_balancer_arn
    from
      aws_ec2_instances as i,
      aws_ec2_target_groups as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions,
      jsonb_array_elements_text(target.load_balancer_arns) as l,
      aws_ec2_gateway_load_balancers as lb
    where
      health_descriptions -> 'Target' ->> 'Id' = i.instance_id
      and l = lb.arn;
  EOQ
}

query "ec2_network_interfaces_for_ec2_instance" {
  sql = <<-EOQ
    select
      network_interface ->> 'NetworkInterfaceId' as network_interface_id
    from
      aws_ec2_instance as i,
      jsonb_array_elements(network_interfaces) as network_interface
    where
      i.arn = $1
      and i.region = split_part($1, ':', 4)
      and i.account_id = split_part($1, ':', 5);
  EOQ
}

# query "ec2_network_load_balancers_for_ec2_instance" {
#   sql = <<-EOQ
#     select
#       distinct lb.arn as network_load_balancer_arn
#     from
#       aws_ec2_instance as i,
#       aws_ec2_target_group as target,
#       jsonb_array_elements(target.target_health_descriptions) as health_descriptions,
#       jsonb_array_elements_text(target.load_balancer_arns) as l,
#       aws_ec2_network_load_balancer as lb
#     where
#       health_descriptions -> 'Target' ->> 'Id' = i.instance_id
#       and l = lb.arn
#       and lb.region = split_part($1, ':', 4)
#       and lb.account_id = split_part($1, ':', 5)
#       and i.arn = $1;
#   EOQ
# }

query "ec2_network_load_balancers_for_ec2_instance" {
  sql = <<-EOQ
    with aws_ec2_instances as (
      select
        arn,
        instance_id,
        account_id,
        region
      from 
        aws_ec2_instance
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and arn = $1            
    ),
    aws_ec2_target_groups as (
      select
        target_health_descriptions,
        load_balancer_arns,
        account_id,
        region
      from 
        aws_ec2_target_group
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)        
    ),
    aws_ec2_network_load_balancers as (
      select
        arn,
        account_id,
        region
      from 
        aws_ec2_network_load_balancer
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)        
    )
    select
      distinct lb.arn as gateway_load_balancer_arn
    from
      aws_ec2_instances as i,
      aws_ec2_target_groups as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions,
      jsonb_array_elements_text(target.load_balancer_arns) as l,
      aws_ec2_network_load_balancers as lb
    where
      health_descriptions -> 'Target' ->> 'Id' = i.instance_id
      and l = lb.arn;
  EOQ
}

# query "ec2_target_groups_for_ec2_instance" {
#   sql = <<-EOQ
#     select
#       target.target_group_arn
#     from
#       aws_ec2_instance as i,
#       aws_ec2_target_group as target,
#       jsonb_array_elements(target.target_health_descriptions) as health_descriptions
#     where
#       i.arn = $1
#       and target.region = split_part($1, ':', 4)
#       and target.account_id = split_part($1, ':', 5)
#       and health_descriptions -> 'Target' ->> 'Id' = i.instance_id;
#   EOQ
# }

query "ec2_target_groups_for_ec2_instance" {
  sql = <<-EOQ
    with aws_ec2_instances as (
      select
        instance_id,
        account_id,
        region
      from 
        aws_ec2_instance
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and arn = $1            
    ),
    aws_ec2_target_groups as (
      select
        target_group_arn,
        target_health_descriptions,
        account_id,
        region
      from 
        aws_ec2_target_group
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)        
    )
    select
      target.target_group_arn
    from
      aws_ec2_instances as i,
      aws_ec2_target_groups as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions
    where
      health_descriptions -> 'Target' ->> 'Id' = i.instance_id;
  EOQ
}

# query "ecs_clusters_for_ec2_instance" {
#   sql = <<-EOQ
#     select
#       distinct cluster.cluster_arn as cluster_arn
#     from
#       aws_ec2_instance as i,
#       aws_ecs_container_instance as ci,
#       aws_ecs_cluster as cluster
#     where
#       ci.ec2_instance_id = i.instance_id
#       and ci.cluster_arn = cluster.cluster_arn
#       and cluster.account_id = split_part($1, ':', 5)
#       and cluster.region = split_part($1, ':', 5)
#       and i.arn = $1;
#   EOQ
# }

query "ecs_clusters_for_ec2_instance" {
  sql = <<-EOQ
    with aws_ec2_instances as (
      select
        instance_id,
        account_id,
        region
      from 
        aws_ec2_instance
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and arn = $1            
    ),
    aws_ecs_container_instances as (
      select
        ec2_instance_id,
        cluster_arn,
        account_id,
        region
      from 
        aws_ecs_container_instance
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)           
    ),
    aws_ecs_clusters as (
      select
        cluster_arn,
        account_id,
        region
      from 
        aws_ecs_cluster
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)          
    )
    select
      distinct cluster.cluster_arn as cluster_arn
    from
      aws_ec2_instances as i,
      aws_ecs_container_instances as ci,
      aws_ecs_clusters as cluster
    where
      ci.ec2_instance_id = i.instance_id
      and ci.cluster_arn = cluster.cluster_arn;
  EOQ
}

# query "iam_roles_for_ec2_instance" {
#   sql = <<-EOQ
#     select
#       distinct r.arn as role_arn
#     from
#       aws_ec2_instance as i,
#       aws_iam_role as r,
#       jsonb_array_elements_text(instance_profile_arns) as instance_profile
#     where
#       instance_profile = i.iam_instance_profile_arn
#       and r.account_id = split_part($1, ':', 5)
#       and i.account_id = split_part($1, ':', 5)
#       and r.region = split_part($1, ':', 4)
#       and i.region = split_part($1, ':', 4)
#       and i.arn = $1;
#   EOQ
# }

query "iam_roles_for_ec2_instance" {
  sql = <<-EOQ
    with aws_ec2_instances as (
      select
        instance_id,
        iam_instance_profile_arn,
        account_id,
        region
      from 
        aws_ec2_instance
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and arn = $1            
    ),
    aws_iam_roles as (
      select
        instance_profile_arns,
        arn,
        account_id,
        region
      from 
        aws_iam_role
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)           
    )
    select
      distinct r.arn as role_arn
    from
      aws_ec2_instances as i,
      aws_iam_roles as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      instance_profile = i.iam_instance_profile_arn;
  EOQ
}

# query "vpc_eips_for_ec2_instance" {
#   sql = <<-EOQ
#     select
#       e.arn as eip_arn
#     from
#       aws_vpc_eip as e,
#       aws_ec2_instance as i
#     where
#       e.instance_id = i.instance_id
#       and i.account_id = split_part($1, ':', 5)
#       and e.account_id = split_part($1, ':', 5)
#       and i.region = split_part($1, ':', 4)
#       and e.region = split_part($1, ':', 4 )
#       and i.arn = $1;
#   EOQ
# }

query "vpc_eips_for_ec2_instance" {
  sql = <<-EOQ
    with aws_ec2_instances as (
      select
        instance_id,
        account_id,
        region
      from 
        aws_ec2_instance
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and arn = $1            
    ),
    aws_vpc_eips as (
      select
        instance_id,
        arn,
        account_id,
        region
      from 
        aws_vpc_eip
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)           
    )
    select
      e.arn as eip_arn
    from
      aws_vpc_eips as e,
      aws_ec2_instances as i
    where
      e.instance_id = i.instance_id;
  EOQ
}

query "vpc_security_groups_for_ec2_instance" {
  sql = <<-EOQ
    select
      sg ->> 'GroupId' as security_group_id
    from
      aws_ec2_instance as i,
      jsonb_array_elements(security_groups) as sg
    where
      i.account_id = split_part($1, ':', 5)
      and i.region = split_part($1, ':', 4)
      and arn = $1;
  EOQ
}

query "vpc_subnets_for_ec2_instance" {
  sql = <<-EOQ
    select
      subnet_id as subnet_id
    from
      aws_ec2_instance as i
    where
      i.account_id = split_part($1, ':', 5)
      and i.region = split_part($1, ':', 4)
      and arn = $1;
  EOQ
}

query "vpc_vpcs_for_ec2_instance" {
  sql = <<-EOQ
    select
      vpc_id as vpc_id
    from
      aws_ec2_instance
    where
      aws_ec2_instance.account_id = split_part($1, ':', 5)
      and aws_ec2_instance.region = split_part($1, ':', 4)
      and arn = $1;
  EOQ
}

# Card queries

query "ec2_instance_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(instance_state) as value
    from
      aws_ec2_instance
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and arn = $1;
  EOQ
}

query "ec2_instance_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      instance_type as value
    from
      aws_ec2_instance
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and arn = $1;
  EOQ
}

query "ec2_instance_total_cores_count" {
  sql = <<-EOQ
    select
      'Total Cores' as label,
      sum(cpu_options_core_count) as value
    from
      aws_ec2_instance
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and arn = $1;
  EOQ
}

query "ec2_instance_public_access" {
  sql = <<-EOQ
    select
      'Public IP Address' as label,
      case when public_ip_address is null then 'Disabled' else host(public_ip_address) end as value,
      case when public_ip_address is null then 'ok' else 'alert' end as type
    from
      aws_ec2_instance
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and arn = $1;
  EOQ
}

query "ec2_instance_ebs_optimized" {
  sql = <<-EOQ
    select
      'EBS Optimized' as label,
      case when ebs_optimized then 'Enabled' else 'Disabled' end as value,
      case when ebs_optimized then 'ok' else 'alert' end as type
    from
      aws_ec2_instance
    where
      account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
      and arn = $1;
  EOQ
}

# Misc queries

query "ec2_instance_overview" {
  sql = <<-EOQ
    select
      tags ->> 'Name' as "Name",
      instance_id as "Instance ID",
      launch_time as "Launch Time",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_ec2_instance
    where
      arn = $1
      and region = split_part($1, ':', 4)
      and account_id = split_part($1, ':', 5);
  EOQ
}

query "ec2_instance_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ec2_instance,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
    order by
      tag ->> 'Key';
    EOQ
}

query "ec2_instance_block_device_mapping" {
  sql = <<-EOQ
    with volume_details as (
    select
      p -> 'Ebs' ->> 'VolumeId'  as "Volume ID",
      p ->> 'DeviceName'  as "Device Name",
      p -> 'Ebs' ->> 'AttachTime' as "Attach Time",
      p -> 'Ebs' ->> 'DeleteOnTermination' as "Delete On Termination",
      p -> 'Ebs' ->> 'Status'  as "Status",
      arn
    from
      aws_ec2_instance,
      jsonb_array_elements(block_device_mappings) as p
    where
      arn = $1
    )
    select
      "Volume ID",
      "Device Name",
      "Attach Time",
      "Delete On Termination",
      "Status",
      v.arn as "Volume ARN"
    from
      volume_details as vd
      left join aws_ebs_volume v on v.volume_id = vd."Volume ID"
    where
      v.volume_id in (select "Volume ID" from volume_details)
  EOQ
}

query "ec2_instance_security_groups" {
  sql = <<-EOQ
    select
      p ->> 'GroupId'  as "Group ID",
      p ->> 'GroupName' as "Group Name"
    from
      aws_ec2_instance,
      jsonb_array_elements(security_groups) as p
    where
      region = split_part($1, ':', 4)
      and account_id = split_part($1, ':', 5)
      and arn = $1;
  EOQ
}

query "ec2_instance_network_interfaces" {
  sql = <<-EOQ
    select
      p ->> 'NetworkInterfaceId' as "Network Interface ID",
      p ->> 'InterfaceType' as "Interface Type",
      ips -> 'Association' ->> 'PublicIp' as "Public IP Address",
      ips ->> 'PrivateIpAddress' as "Private IP Address",
      p ->> 'Status' as "Status",
      p ->> 'SubnetId' as "Subnet ID",
      p ->> 'VpcId' as "VPC ID"
    from
      aws_ec2_instance,
      jsonb_array_elements(network_interfaces) as p,
      jsonb_array_elements(p -> 'PrivateIpAddresses') as ips
    where
      region = split_part($1, ':', 4)
      and account_id = split_part($1, ':', 5)
      and arn = $1;
  EOQ
}

query "ec2_instance_cpu_cores" {
  sql = <<-EOQ
    select
      cpu_options_core_count  as "CPU Options Core Count",
      cpu_options_threads_per_core  as "CPU Options Threads Per Core"
    from
      aws_ec2_instance
    where
      region = split_part($1, ':', 4)
      and account_id = split_part($1, ':', 5)
      and arn = $1;
  EOQ
}
