dashboard "aws_ec2_instance_detail" {

  title         = "AWS EC2 Instance Detail"
  documentation = file("./dashboards/ec2/docs/ec2_instance_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "instance_arn" {
    title = "Select an instance:"
    query = query.aws_ec2_instance_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_ec2_instance_status
      args = {
        arn = self.input.instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_ec2_instance_type
      args = {
        arn = self.input.instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_ec2_instance_total_cores_count
      args = {
        arn = self.input.instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_ec2_instance_public_access
      args = {
        arn = self.input.instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_ec2_instance_ebs_optimized
      args = {
        arn = self.input.instance_arn.value
      }
    }
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "ebs_volumes" {
        sql = <<-EOQ
          select
            v.arn as volume_arn
          from
            aws_ec2_instance as i,
            jsonb_array_elements(block_device_mappings) as bd,
            aws_ebs_volume as v
          where
            v.volume_id = bd -> 'Ebs' ->> 'VolumeId'
            and i.arn = $1;
        EOQ

        args = [self.input.instance_arn.value]
      }

      with "enis" {
        sql = <<-EOQ
          select
            eni ->> 'NetworkInterfaceId' as eni_id
          from
            aws_ec2_instance as i,
            jsonb_array_elements(network_interfaces) as eni
          where
            i.arn = $1;
        EOQ

        args = [self.input.instance_arn.value]
      }

      with "subnets" {
        sql = <<-EOQ
          select
            subnet_id as subnet_id
          from
            aws_ec2_instance as i
          where
            arn = $1;
        EOQ

        args = [self.input.instance_arn.value]
      }

      with "security_groups" {
        sql = <<-EOQ
          select
            sg ->> 'GroupId' as security_group_id
          from
            aws_ec2_instance as i,
            jsonb_array_elements(security_groups) as sg
          where
            arn = $1;
        EOQ

        args = [self.input.instance_arn.value]
      }

      with "eips" {
        sql = <<-EOQ
          select
            e.arn as eip_arn
          from
            aws_vpc_eip as e,
            aws_ec2_instance as i
          where
            e.instance_id = i.instance_id
            and i.arn = $1;
        EOQ

        args = [self.input.instance_arn.value]
      }

      with "vpcs" {
        sql = <<-EOQ
          select
            vpc_id as vpc_id
          from
            aws_ec2_instance
          where
            arn = $1;
        EOQ

        args = [self.input.instance_arn.value]
      }

      with "clbs" {
        sql = <<-EOQ
          select
            distinct clb.arn as clb_arn
          from
            aws_ec2_classic_load_balancer as clb,
            jsonb_array_elements(clb.instances) as instance,
            aws_ec2_instance as i
          where
            i.arn = $1
            and instance ->> 'InstanceId' = i.instance_id;
        EOQ

        args = [self.input.instance_arn.value]
      }

      with "albs" {
        sql = <<-EOQ
          select
            distinct lb.arn as alb_arn
          from
            aws_ec2_instance as i,
            aws_ec2_target_group as target,
            jsonb_array_elements(target.target_health_descriptions) as health_descriptions,
            jsonb_array_elements_text(target.load_balancer_arns) as l,
            aws_ec2_application_load_balancer as lb
          where
            health_descriptions -> 'Target' ->> 'Id' = i.instance_id
            and l = lb.arn
            and i.arn = $1;
        EOQ

        args = [self.input.instance_arn.value]
      }

      with "nlbs" {
        sql = <<-EOQ
          select
            distinct lb.arn as nlb_arn
          from
            aws_ec2_instance as i,
            aws_ec2_target_group as target,
            jsonb_array_elements(target.target_health_descriptions) as health_descriptions,
            jsonb_array_elements_text(target.load_balancer_arns) as l,
            aws_ec2_network_load_balancer as lb
          where
            health_descriptions -> 'Target' ->> 'Id' = i.instance_id
            and l = lb.arn
            and i.arn = $1;
        EOQ

        args = [self.input.instance_arn.value]
      }

      with "glbs" {
        sql = <<-EOQ
          select
            distinct lb.arn as nlb_arn
          from
            aws_ec2_instance as i,
            aws_ec2_target_group as target,
            jsonb_array_elements(target.target_health_descriptions) as health_descriptions,
            jsonb_array_elements_text(target.load_balancer_arns) as l,
            aws_ec2_gateway_load_balancer as lb
          where
            health_descriptions -> 'Target' ->> 'Id' = i.instance_id
            and l = lb.arn
            and i.arn = $1;
        EOQ

        args = [self.input.instance_arn.value]
      }

      with "ecs_clusters" {
        sql = <<-EOQ
          select
            distinct cluster.cluster_arn as cluster_arn
          from
            aws_ec2_instance as i,
            aws_ecs_container_instance as ci,
            aws_ecs_cluster as cluster
          where
            ci.ec2_instance_id = i.instance_id
            and ci.cluster_arn = cluster.cluster_arn
            and i.arn = $1;
        EOQ

        args = [self.input.instance_arn.value]
      }

      with "iam_roles" {
        sql = <<-EOQ
          select
            distinct r.arn as role_arn
          from
            aws_ec2_instance as i,
            aws_iam_role as r,
            jsonb_array_elements_text(instance_profile_arns) as instance_profile
          where
            instance_profile = i.iam_instance_profile_arn
            and i.arn = $1;
        EOQ

        args = [self.input.instance_arn.value]
      }

      nodes = [
        node.aws_ec2_instance_nodes,
        node.ebs_volume,
        node.aws_ec2_network_interface_nodes,
        node.vpc_security_group,
        node.vpc_subnet,
        node.vpc,
        node.aws_vpc_eip_nodes,
        node.aws_ec2_classic_load_balancer_nodes,
        node.aws_ec2_application_load_balancer_nodes,
        node.aws_ec2_network_load_balancer_nodes,
        node.aws_ec2_gateway_load_balancer_nodes,
        node.aws_ecs_cluster_nodes,
        node.aws_iam_role_nodes,

        node.aws_ec2_instance_iam_instance_profile_nodes,
        node.aws_ec2_instance_ec2_key_pair_nodes,
        node.aws_ec2_instance_ec2_autoscaling_group_nodes,
        node.aws_ec2_instance_ec2_target_group_nodes,

      ]

      edges = [
        edge.aws_ec2_network_interface_to_vpc_eip_edges,
        edge.aws_ec2_instance_to_ebs_volume_edges,
        edge.aws_ec2_instance_to_ec2_network_interface_edges,
        edge.aws_ec2_instance_to_vpc_security_group_edges,
        edge.aws_ec2_instance_to_vpc_subnet_edges,
        edge.aws_ec2_instance_vpc_subnet_to_vpc_edges,
        edge.aws_ec2_instance_to_iam_profile_edges,
        edge.aws_ec2_instance_to_iam_role_edges,
        edge.aws_ec2_instance_to_ec2_key_pair_edges,
        edge.aws_ec2_instance_from_ec2_autoscaling_group_edges,
        edge.aws_ec2_instance_from_ec2_classic_load_balancer_edges,
        edge.aws_ec2_instance_from_ec2_application_load_balancer_edges,
        edge.aws_ec2_instance_from_ec2_network_load_balancer_edges,
        edge.aws_ec2_instance_from_ec2_gateway_load_balancer_edges,
        edge.aws_ec2_instance_from_ec2_target_group_edges,

        edge.aws_ec2_instance_lb_target_group_edges,
        edge.aws_ec2_instance_from_cluster_edges
      ]

      args = {
        volume_arns        = with.ebs_volumes.rows[*].volume_arn
        eni_ids            = with.enis.rows[*].eni_id
        subnet_ids         = with.subnets.rows[*].subnet_id
        security_group_ids = with.security_groups.rows[*].security_group_id
        vpc_ids            = with.vpcs.rows[*].vpc_id
        clb_arns           = with.clbs.rows[*].clb_arn
        eip_arns           = with.eips.rows[*].eip_arn
        alb_arns           = with.albs.rows[*].alb_arn
        nlb_arns           = with.nlbs.rows[*].nlb_arn
        glb_arns           = with.glbs.rows[*].glb_arn
        ecs_cluster_arns   = with.ecs_clusters.rows[*].cluster_arn
        role_arns          = with.iam_roles.rows[*].role_arn
        instance_arns      = [self.input.instance_arn.value]
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
        query = query.aws_ec2_instance_overview
        args = {
          arn = self.input.instance_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_ec2_instance_tags
        args = {
          arn = self.input.instance_arn.value
        }
      }
    }
    container {
      width = 6

      table {
        title = "Block Device Mappings"
        query = query.aws_ec2_instance_block_device_mapping
        args = {
          arn = self.input.instance_arn.value
        }

        column "Volume ARN" {
          display = "none"
        }

        column "Volume ID" {
          // cyclic dependency prevents use of url_path, hardcode for now
          href = "/aws_insights.dashboard.aws_ebs_volume_detail?input.volume_arn={{.'Volume ARN' | @uri}}"
        }
      }
    }

  }

  container {
    width = 12

    table {
      title = "Network Interfaces"
      query = query.aws_ec2_instance_network_interfaces
      args = {
        arn = self.input.instance_arn.value
      }

      column "VPC ID" {
        // cyclic dependency prevents use of url_path, hardcode for now
        href = "/aws_insights.dashboard.aws_vpc_detail?input.vpc_id={{ .'VPC ID' | @uri }}"
      }
    }

  }

  container {
    width = 6

    table {
      title = "Security Groups"
      query = query.aws_ec2_instance_security_groups
      args = {
        arn = self.input.instance_arn.value
      }

      column "Group ID" {
        // cyclic dependency prevents use of url_path, hardcode for now
        href = "/aws_insights.dashboard.aws_vpc_security_group_detail?input.security_group_id={{.'Group ID' | @uri}}"
      }
    }

  }

  container {
    width = 6

    table {
      title = "CPU cores"
      query = query.aws_ec2_instance_cpu_cores
      args = {
        arn = self.input.instance_arn.value
      }
    }

  }

}

query "aws_ec2_instance_input" {
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

query "aws_ec2_instance_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(instance_state) as value
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}

}

query "aws_ec2_instance_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      instance_type as value
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_total_cores_count" {
  sql = <<-EOQ
    select
      'Total Cores' as label,
      sum(cpu_options_core_count) as value
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_public_access" {
  sql = <<-EOQ
    select
      'Public IP Address' as label,
      case when public_ip_address is null then 'Disabled' else host(public_ip_address) end as value,
      case when public_ip_address is null then 'ok' else 'alert' end as type
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_ebs_optimized" {
  sql = <<-EOQ
    select
      'EBS Optimized' as label,
      case when ebs_optimized then 'Enabled' else 'Disabled' end as value,
      case when ebs_optimized then 'ok' else 'alert' end as type
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_ec2_instance_to_ebs_volume_edges" {
  title = "mounts"

  sql = <<-EOQ
    select
      instance_arns as from_id,
      volume_arns as to_id
    from
      unnest($1::text[]) as instance_arns,
      unnest($2::text[]) as volume_arns
  EOQ

  param "instance_arns" {}
  param "volume_arns" {}
}

edge "aws_ec2_instance_to_ec2_network_interface_edges" {
  title = "eni"

  sql = <<-EOQ
    select
      instance_arns as from_id,
      eni_ids as to_id
    from
      unnest($1::text[]) as instance_arns,
      unnest($2::text[]) as eni_ids
  EOQ

  param "instance_arns" {}
  param "eni_ids" {}
}

edge "aws_ec2_instance_to_vpc_security_group_edges" {
  title = "security groups"

  sql = <<-EOQ
    select
      coalesce(
        eni_ids,
        instance_arns
      ) as from_id,
      security_group_ids as to_id
    from
      unnest($1::text[]) as instance_arns,
      unnest($2::text[]) as eni_ids,
      unnest($3::text[]) as security_group_ids
  EOQ

  param "instance_arns" {}
  param "eni_ids" {}
  param "security_group_ids" {}
}

edge "aws_ec2_instance_to_vpc_subnet_edges" {
  title = "subnet"

  sql = <<-EOQ
    select
      security_group_ids as from_id,
      subnet_ids as to_id
    from
      unnest($1::text[]) as security_group_ids,
      unnest($2::text[]) as subnet_ids
  EOQ

  param "security_group_ids" {}
  param "subnet_ids" {}
}

edge "aws_ec2_instance_vpc_subnet_to_vpc_edges" {
  title = "vpc"

  sql = <<-EOQ
    select
      subnet_ids as from_id,
      vpc_ids as to_id
    from
      unnest($1::text[]) as subnet_ids,
      unnest($2::text[]) as vpc_ids
  EOQ

  param "subnet_ids" {}
  param "vpc_ids" {}
}

node "aws_ec2_instance_iam_instance_profile_nodes" {
  category = category.aws_iam_instance_profile

  sql = <<-EOQ
    select
      iam_instance_profile_arn as id,
      split_part(iam_instance_profile_arn, ':instance-profile/',2) as title,
      jsonb_build_object(
        'Instance Profile ARN', iam_instance_profile_arn,
        'Instance Profile ID', iam_instance_profile_id
      ) as properties
    from
      aws_ec2_instance as i
    where
      iam_instance_profile_arn is not null
      and i.arn = any($1);
  EOQ

  param "instance_arns" {}
}

edge "aws_ec2_instance_to_iam_profile_edges" {
  title = "runs as"

  sql = <<-EOQ
    select
      arn as from_id,
      iam_instance_profile_arn as to_id
    from
      aws_ec2_instance as i
    where
      iam_instance_profile_arn is not null
      and i.arn = any($1);
  EOQ

  param "instance_arns" {}
}

edge "aws_ec2_instance_to_iam_role_edges" {
  title = "assumes"

  sql = <<-EOQ
    select
      i.iam_instance_profile_arn as from_id,
      role_arns as to_id
    from
      aws_ec2_instance as i,
      unnest($2::text[]) as role_arns
    where
      iam_instance_profile_arn is not null
      and i.arn = any($1);
  EOQ

  param "instance_arns" {}
  param "role_arns" {}
}

node "aws_ec2_instance_ec2_key_pair_nodes" {
  category = category.aws_ec2_key_pair

  sql = <<-EOQ
    select
      k.key_name as id,
      k.title as title,
      jsonb_build_object(
        'Name', k.key_name,
        'ID', k.key_pair_id,
        'Fingerprint', key_fingerprint
      ) as properties
    from
      aws_ec2_instance as i,
      aws_ec2_key_pair as k
    where
      i.key_name = k.key_name
      and i.account_id = k.account_id
      and i.region = k.region
      and i.arn = any($1);
  EOQ

  param "instance_arns" {}
}

edge "aws_ec2_instance_to_ec2_key_pair_edges" {
  title = "key pair"

  sql = <<-EOQ
    select
      arn as from_id,
      key_name as to_id
    from
      aws_ec2_instance as i
    where
      key_name is not null
      and i.arn = any($1);
  EOQ

  param "instance_arns" {}
}

node "aws_ec2_instance_ec2_autoscaling_group_nodes" {
  category = category.aws_ec2_autoscaling_group

  sql = <<-EOQ
    select
      k.autoscaling_group_arn as id,
      k.name as title,
      jsonb_build_object(
        'instance', group_instance ->> 'InstanceId',
        'i', i.instance_id,
        'asg', group_instance
      ) as properties
    from
      aws_ec2_autoscaling_group as k,
      jsonb_array_elements(k.instances) as group_instance,
      aws_ec2_instance as i
    where
      i.arn = any($1)
      and group_instance ->> 'InstanceId' = i.instance_id;
  EOQ

  param "instance_arns" {}
}

edge "aws_ec2_instance_from_ec2_autoscaling_group_edges" {
  title = "launches"

  sql = <<-EOQ
    select
      k.autoscaling_group_arn as from_id,
      i.arn as to_id
    from
      aws_ec2_autoscaling_group as k,
      jsonb_array_elements(k.instances) as group_instance,
      aws_ec2_instance as i
    where
      i.arn = any($1)
      and group_instance ->> 'InstanceId' = i.instance_id;
  EOQ

  param "instance_arns" {}
}

edge "aws_ec2_instance_from_ec2_classic_load_balancer_edges" {
  title = "routes to"

  sql = <<-EOQ
    select
      clb_arns as from_id,
      instance_arns as to_id
    from
     unnest($1::text[]) as clb_arns,
     unnest($2::text[]) as instance_arns
  EOQ

  param "clb_arns" {}
  param "instance_arns" {}
}

edge "aws_ec2_instance_from_ec2_application_load_balancer_edges" {
  title = "routes to"

  sql = <<-EOQ
    select
      alb_arns as from_id,
      instance_arns as to_id
    from
     unnest($1::text[]) as alb_arns,
     unnest($2::text[]) as instance_arns
  EOQ

  param "alb_arns" {}
  param "instance_arns" {}
}

edge "aws_ec2_instance_from_ec2_network_load_balancer_edges" {
  title = "routes to"

  sql = <<-EOQ
    select
      nlb_arns as from_id,
      instance_arns as to_id
    from
     unnest($1::text[]) as nlb_arns,
     unnest($2::text[]) as instance_arns
  EOQ

  param "nlb_arns" {}
  param "instance_arns" {}
}

edge "aws_ec2_instance_from_ec2_gateway_load_balancer_edges" {
  title = "routes to"

  sql = <<-EOQ
    select
      glb_arns as from_id,
      instance_arns as to_id
    from
     unnest($1::text[]) as glb_arns,
     unnest($2::text[]) as instance_arns
  EOQ

  param "glb_arns" {}
  param "instance_arns" {}
}

node "aws_ec2_instance_ec2_target_group_nodes" {
  category = category.aws_ec2_target_group

  sql = <<-EOQ
    select
      target.target_group_arn as id,
      target.target_group_name as title,
      jsonb_build_object(
        'Name', target.target_group_name,
        'ARN', target.target_group_arn,
        'Health Check Enabled', target.health_check_enabled,
        'Region', target.region,
        'Account ID', target.account_id
      ) as properties
    from
      aws_ec2_instance as i,
      aws_ec2_target_group as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions
    where
      i.arn = any($1)
      and health_descriptions -> 'Target' ->> 'Id' = i.instance_id
  EOQ

  param "instance_arns" {}
}

edge "aws_ec2_instance_from_ec2_target_group_edges" {
  title = "routes to"

  sql = <<-EOQ
    select
      target.target_group_arn as from_id,
      i.arn as to_id
    from
      aws_ec2_instance as i,
      aws_ec2_target_group as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions
    where
      i.arn = any($1)
      and health_descriptions -> 'Target' ->> 'Id' = i.instance_id;
  EOQ

  param "instance_arns" {}
}

edge "aws_ec2_instance_lb_target_group_edges" {
  title = "target group"

  sql = <<-EOQ
    select
      l as from_id,
      target.target_group_arn as to_id
    from
      aws_ec2_instance as i,
      aws_ec2_target_group as target,
      jsonb_array_elements(target.target_health_descriptions) as health_descriptions,
      jsonb_array_elements_text(target.load_balancer_arns) as l
    where
      health_descriptions -> 'Target' ->> 'Id' = i.instance_id
      and i.arn = any($1);
  EOQ

  param "instance_arns" {}
}

edge "aws_ec2_instance_from_cluster_edges" {
  title = "container instance"

  sql = <<-EOQ
    select
      cluster_arns as from_id,
      instance_arns as to_id
    from
      unnest($1::text[]) as cluster_arns,
     unnest($2::text[]) as instance_arns
  EOQ

  param "ecs_cluster_arns" {}
  param "instance_arns" {}
}
//***********


query "aws_ec2_instance_overview" {
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
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ec2_instance,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
    EOQ

  param "arn" {}
}

query "aws_ec2_instance_block_device_mapping" {
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

  param "arn" {}
}

query "aws_ec2_instance_security_groups" {
  sql = <<-EOQ
    select
      p ->> 'GroupId'  as "Group ID",
      p ->> 'GroupName' as "Group Name"
    from
      aws_ec2_instance,
      jsonb_array_elements(security_groups) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_network_interfaces" {
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
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_cpu_cores" {
  sql = <<-EOQ
    select
      cpu_options_core_count  as "CPU Options Core Count",
      cpu_options_threads_per_core  as "CPU Options Threads Per Core"
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}
