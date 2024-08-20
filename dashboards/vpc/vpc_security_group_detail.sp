dashboard "vpc_security_group_detail" {

  title         = "AWS VPC Security Group Detail"
  documentation = file("./dashboards/vpc/docs/vpc_security_group_detail.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "security_group_id" {
    title = "Select a security group:"
    query = query.vpc_security_group_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.vpc_security_group_ingress_rules_count
      args  = [self.input.security_group_id.value]
    }

    card {
      width = 2
      query = query.vpc_security_group_egress_rules_count
      args  = [self.input.security_group_id.value]
    }

    card {
      width = 2
      query = query.vpc_security_attached_enis_count
      args  = [self.input.security_group_id.value]
    }

    card {
      width = 2
      query = query.vpc_security_unrestricted_ingress
      args  = [self.input.security_group_id.value]
    }

    card {
      width = 2
      query = query.vpc_security_unrestricted_egress
      args  = [self.input.security_group_id.value]
    }

  }

  with "dax_clusters_for_vpc_security_group" {
    query = query.dax_clusters_for_vpc_security_group
    args  = [self.input.security_group_id.value]
  }

  with "ec2_application_load_balancers_for_vpc_security_group" {
    query = query.ec2_application_load_balancers_for_vpc_security_group
    args  = [self.input.security_group_id.value]
  }

  with "ec2_classic_load_balancers_for_vpc_security_group" {
    query = query.ec2_classic_load_balancers_for_vpc_security_group
    args  = [self.input.security_group_id.value]
  }

  with "ec2_instances_for_vpc_security_group" {
    query = query.ec2_instances_for_vpc_security_group
    args  = [self.input.security_group_id.value]
  }

  with "ec2_launch_configurations_for_vpc_security_group" {
    query = query.ec2_launch_configurations_for_vpc_security_group
    args  = [self.input.security_group_id.value]
  }

  with "efs_mount_targets_for_vpc_security_group" {
    query = query.efs_mount_targets_for_vpc_security_group
    args  = [self.input.security_group_id.value]
  }

  with "elasticache_clusters_for_vpc_security_group" {
    query = query.elasticache_clusters_for_vpc_security_group
    args  = [self.input.security_group_id.value]
  }

  with "lambda_functions_for_vpc_security_group" {
    query = query.lambda_functions_for_vpc_security_group
    args  = [self.input.security_group_id.value]
  }

  with "rds_db_clusters_for_vpc_security_group" {
    query = query.rds_db_clusters_for_vpc_security_group
    args  = [self.input.security_group_id.value]
  }

  with "rds_db_instances_for_vpc_security_group" {
    query = query.rds_db_instances_for_vpc_security_group
    args  = [self.input.security_group_id.value]
  }

  with "redshift_clusters_for_vpc_security_group" {
    query = query.redshift_clusters_for_vpc_security_group
    args  = [self.input.security_group_id.value]
  }

  with "sagemaker_notebook_instances_for_vpc_security_group" {
    query = query.sagemaker_notebook_instances_for_vpc_security_group
    args  = [self.input.security_group_id.value]
  }

  with "vpc_vpcs_for_vpc_security_group" {
    query = query.vpc_vpcs_for_vpc_security_group
    args  = [self.input.security_group_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.dax_cluster
        args = {
          dax_cluster_arns = with.dax_clusters_for_vpc_security_group.rows[*].dax_cluster_arn
        }
      }

      node {
        base = node.dms_replication_instance
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      node {
        base = node.docdb_cluster
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      node {
        base = node.ec2_application_load_balancer
        args = {
          ec2_application_load_balancer_arns = with.ec2_application_load_balancers_for_vpc_security_group.rows[*].alb_arn
        }
      }

      node {
        base = node.ec2_classic_load_balancer
        args = {
          ec2_classic_load_balancer_arns = with.ec2_classic_load_balancers_for_vpc_security_group.rows[*].clb_arn
        }
      }

      node {
        base = node.ec2_instance
        args = {
          ec2_instance_arns = with.ec2_instances_for_vpc_security_group.rows[*].instance_arn
        }
      }

      node {
        base = node.ec2_launch_configuration
        args = {
          ec2_launch_configuration_arns = with.ec2_launch_configurations_for_vpc_security_group.rows[*].launch_configuration_arn
        }
      }

      node {
        base = node.efs_mount_target
        args = {
          efs_mount_target_ids = with.efs_mount_targets_for_vpc_security_group.rows[*].mount_target_id
        }
      }

      node {
        base = node.elasticache_cluster_node
        args = {
          elasticache_cluster_node_arns = with.elasticache_clusters_for_vpc_security_group.rows[*].elasticache_cluster_arn
        }
      }

      node {
        base = node.lambda_function
        args = {
          lambda_function_arns = with.lambda_functions_for_vpc_security_group.rows[*].lambda_arn
        }
      }

      node {
        base = node.rds_db_cluster
        args = {
          rds_db_cluster_arns = with.rds_db_clusters_for_vpc_security_group.rows[*].rds_db_cluster_arn
        }
      }

      node {
        base = node.rds_db_instance
        args = {
          rds_db_instance_arns = with.rds_db_instances_for_vpc_security_group.rows[*].rds_db_instance_arn
        }
      }

      node {
        base = node.redshift_cluster
        args = {
          redshift_cluster_arns = with.redshift_clusters_for_vpc_security_group.rows[*].redshift_cluster_arn
        }
      }

      node {
        base = node.sagemaker_notebook_instance
        args = {
          sagemaker_notebook_instance_arns = with.sagemaker_notebook_instances_for_vpc_security_group.rows[*].notebook_instance_arn
        }
      }

      node {
        base = node.vpc_security_group
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_vpc_security_group.rows[*].vpc_id
        }
      }

      edge {
        base = edge.vpc_security_group_to_dax_cluster
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vpc_security_group_to_dms_replication_instance
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vpc_security_group_to_docdb_cluster
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vpc_security_group_to_ec2_application_load_balancer
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vpc_security_group_to_ec2_classic_load_balancer
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vpc_security_group_to_ec2_instance
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vpc_security_group_to_ec2_launch_configuration
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vpc_security_group_to_efs_mount_target
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vpc_security_group_to_elasticache_cluster
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vpc_security_group_to_lambda_function
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vpc_security_group_to_rds_db_cluster
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vpc_security_group_to_rds_db_instance
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vpc_security_group_to_redshift_cluster
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vpc_security_group_to_sagemaker_notebook_instance
        args = {
          vpc_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vpc_vpc_to_vpc_security_group
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_vpc_security_group.rows[*].vpc_id
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
        query = query.vpc_security_group_overview
        args  = [self.input.security_group_id.value]

        column "VPC ID" {
          // cyclic dependency prevents use of url_path, hardcode for now
          // href = "${dashboard.vpc_detail.url_path}?input.vpc_id={{.'VPC ID' | @uri}}"
          href = "/aws_insights.dashboard.vpc_detail?input.vpc_id={{.'VPC ID' | @uri}}"

        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.vpc_security_group_tags
        args  = [self.input.security_group_id.value]
      }

    }

    container {

      width = 6

      table {
        title = "Associated to"
        query = query.vpc_security_group_assoc
        args  = [self.input.security_group_id.value]

        column "link" {
          display = "none"
        }

        column "Title" {
          href = "{{ .link }}"
        }

      }

    }

  }

  container {

    width = 6

    flow {
      base  = flow.security_group_rules_sankey
      title = "Ingress Analysis"
      query = query.vpc_security_group_ingress_rule_sankey
      args  = [self.input.security_group_id.value]
    }


    table {
      title = "Ingress Rules"
      query = query.vpc_security_group_ingress_rules
      args  = [self.input.security_group_id.value]
    }

  }

  container {

    width = 6

    flow {
      base  = flow.security_group_rules_sankey
      title = "Egress Analysis"
      query = query.vpc_security_group_egress_rule_sankey
      args  = [self.input.security_group_id.value]
    }

    table {
      title = "Egress Rules"
      query = query.vpc_security_group_egress_rules
      args  = [self.input.security_group_id.value]
    }

  }

}

flow "security_group_rules_sankey" {
  type = "sankey"

  category "alert" {
    color = "alert"
  }

  category "ok" {
    color = "ok"
  }

}

query "vpc_security_group_input" {
  sql = <<-EOQ
    select
      title as label,
      group_id as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'group_id', group_id
      ) as tags
    from
      aws_vpc_security_group
    order by
      title;
  EOQ
}

# card queries

query "vpc_security_group_ingress_rules_count" {
  sql = <<-EOQ
    select
      'Ingress Rules' as label,
      count(*) as value
    from
      aws_vpc_security_group_rule
    where
      not is_egress
      and group_id = $1
  EOQ

}

query "vpc_security_group_egress_rules_count" {
  sql = <<-EOQ
    select
      'Egress Rules' as label,
      count(*) as value
    from
      aws_vpc_security_group_rule
    where
      is_egress
      and group_id = $1;
  EOQ

}

query "vpc_security_attached_enis_count" {
  sql = <<-EOQ
    select
      'Attached ENIs' as label,
      count(*) as value,
      case when count(*) > 0 then 'ok' else 'alert' end as type
    from
      aws_ec2_network_interface,
      jsonb_array_elements(groups) as sg
    where
      sg ->> 'GroupId' = $1;
  EOQ

}

query "vpc_security_unrestricted_ingress" {
  sql = <<-EOQ
    select
      'Unrestricted Ingress (Excludes ICMP)' as label,
      count(*) as value,
      case
        when count(*) = 0 then 'ok'
        else 'alert'
      end as type
    from
      aws_vpc_security_group_rule
    where
      ( cidr_ipv4 = '0.0.0.0/0' or cidr_ipv6 = '::/0')
      and ip_protocol <> 'icmp'
      and (
        from_port = -1
        or (from_port = 0 and to_port = 65535)
      )
      and not is_egress
      and group_id = $1;
  EOQ

}

query "vpc_security_unrestricted_egress" {
  sql = <<-EOQ
    select
      'Unrestricted Egress (Excludes ICMP)' as label,
      count(*) as value,
      case
        when count(*) = 0 then 'ok'
        else 'alert'
      end as type
    from
      aws_vpc_security_group_rule
    where
      ( cidr_ipv4 = '0.0.0.0/0' or cidr_ipv6 = '::/0')
      and ip_protocol <> 'icmp'
      and (
        from_port = -1
        or (from_port = 0 and to_port = 65535)
      )
      and is_egress
      and group_id = $1;
  EOQ

}

# with queries

query "dax_clusters_for_vpc_security_group" {
  sql = <<-EOQ
    select
      arn as dax_cluster_arn
    from
      aws_dax_cluster,
      jsonb_array_elements(security_groups) as sg
    where
      sg ->> 'SecurityGroupIdentifier' = $1;
  EOQ
}

query "ec2_application_load_balancers_for_vpc_security_group" {
  sql = <<-EOQ
    select
      arn as alb_arn
    from
      aws_ec2_application_load_balancer,
      jsonb_array_elements_text(security_groups) as sg
    where
      sg = $1;
  EOQ
}

query "ec2_classic_load_balancers_for_vpc_security_group" {
  sql = <<-EOQ
    select
      arn as clb_arn
    from
      aws_ec2_classic_load_balancer,
      jsonb_array_elements_text(security_groups) as sg
    where
      sg = $1;
  EOQ
}

query "ec2_instances_for_vpc_security_group" {
  sql = <<-EOQ
    select
      arn as instance_arn
    from
      aws_ec2_instance as i,
      jsonb_array_elements(security_groups) as sg
    where
      sg ->> 'GroupId' = $1;
  EOQ
}

query "ec2_launch_configurations_for_vpc_security_group" {
  sql = <<-EOQ
    select
      launch_configuration_arn as launch_configuration_arn
    from
      aws_ec2_launch_configuration,
      jsonb_array_elements_text(security_groups) as sg
    where
      sg = $1;
  EOQ
}

query "efs_mount_targets_for_vpc_security_group" {
  sql = <<-EOQ
    select
      mount_target_id as mount_target_id
    from
      aws_efs_mount_target,
      jsonb_array_elements_text(security_groups) as sg
    where
      sg = $1;
  EOQ
}

query "elasticache_clusters_for_vpc_security_group" {
  sql = <<-EOQ
    select
      arn as elasticache_cluster_arn
    from
      aws_elasticache_cluster,
      jsonb_array_elements(security_groups) as sg
    where
      sg ->> 'SecurityGroupId' = $1;
  EOQ 
}

query "lambda_functions_for_vpc_security_group" {
  sql = <<-EOQ
    select
      arn as lambda_arn
    from
      aws_lambda_function,
      jsonb_array_elements_text(vpc_security_group_ids) as s
    where
      s = $1;
  EOQ
}

query "rds_db_clusters_for_vpc_security_group" {
  sql = <<-EOQ
    select
      arn as rds_db_cluster_arn
    from
      aws_rds_db_cluster,
      jsonb_array_elements(vpc_security_groups) as sg
    where
      sg ->> 'VpcSecurityGroupId' = $1;
  EOQ
}

query "rds_db_instances_for_vpc_security_group" {
  sql = <<-EOQ
          select
            arn as rds_db_instance_arn
          from
            aws_rds_db_instance,
            jsonb_array_elements(vpc_security_groups) as sg
          where
            sg ->> 'VpcSecurityGroupId' = $1;
        EOQ
}

query "redshift_clusters_for_vpc_security_group" {
  sql = <<-EOQ
    select
      arn as redshift_cluster_arn
    from
      aws_redshift_cluster,
      jsonb_array_elements(vpc_security_groups) as sg
    where
      sg ->> 'VpcSecurityGroupId' = $1;
  EOQ
}

query "sagemaker_notebook_instances_for_vpc_security_group" {
  sql = <<-EOQ
    select
      arn as notebook_instance_arn
    from
      aws_sagemaker_notebook_instance,
      jsonb_array_elements_text(security_groups) as sg
    where
      sg = $1;
  EOQ
}

query "vpc_vpcs_for_vpc_security_group" {
  sql = <<-EOQ
    select
      vpc_id as vpc_id
    from
      aws_vpc_security_group
    where
      group_id = $1;
  EOQ
}

# table queries

query "vpc_security_group_assoc" {
  sql = <<-EOQ

    -- EC2 instances
    select
      title as "Title",
      'aws_ec2_instance' as "Type",
      arn as "ARN",
      '${dashboard.ec2_instance_detail.url_path}?input.instance_arn=' || arn as link
    from
      aws_ec2_instance,
      jsonb_array_elements(security_groups) as sg
    where
      sg ->> 'GroupId' = $1

    -- Lambda functions
    union all select
      title as "Title",
      'aws_lambda_function' as "Type",
      arn as "ARN",
      '${dashboard.lambda_function_detail.url_path}?input.lambda_arn=' || arn as link
    from
      aws_lambda_function,
      jsonb_array_elements_text(vpc_security_group_ids) as sg
    where
      sg = $1

    -- ECS services
    union all select
      title as "Title",
      'aws_ecs_service' as "Type",
      arn as "ARN",
      '${dashboard.ecs_service_detail.url_path}?input.service_arn=' || arn as link
    from
      aws_ecs_service,
      jsonb_array_elements_text(network_configuration['AwsvpcConfiguration']['SecurityGroups']) as sg
    where
      sg = $1

    -- ECS tasks
    union all select
      tasks."group" as "Title",
      'aws_ecs_task' as "Type",
      tasks.task_definition_arn as "ARN",
      '${dashboard.ecs_task_definition_detail.url_path}?input.task_definition_arn=' || tasks.task_definition_arn as link
    from
      (
        select
          network_interface_id,
          jsonb_array_elements(groups)->>'GroupId' as security_group
        from
          aws_ec2_network_interface
      ) as interfaces
    join
      (
        select
          task_definition_arn,
          "group",
          details->>'Value' as network_interface_id
        from
          aws_ecs_task,
          jsonb_array_elements(attachments->0->'Details') as details
        where
          details->>'Name' = 'networkInterfaceId'
      ) as tasks
      on
        interfaces.network_interface_id = tasks.network_interface_id
    where
      security_group = $1
    group by "ARN", "Title"

    -- Amazon MQ brokers
    union all select
      title as "Title",
      'aws_mq_broker' as "Type",
      arn as "ARN",
      NULL as link
    from
      aws_mq_broker,
      jsonb_array_elements_text(security_groups) as sg
    where
      sg = $1

    -- attached ELBs
    union all select
      title as "Title",
      'aws_ec2_classic_load_balancer' as "Type",
      arn as "ARN",
      null as link
    from
      aws_ec2_classic_load_balancer,
      jsonb_array_elements_text(security_groups) as sg
    where
      sg = $1

    -- attached ALBs
    union all select
      title as "Title",
      'aws_ec2_application_load_balancer' as "Type",
      arn as "ARN",
      null as link
    from
      aws_ec2_application_load_balancer,
      jsonb_array_elements_text(security_groups) as sg
    where
      sg = $1

    -- attached NLBs
    union all select
      title as "Title",
      'aws_ec2_network_load_balancer' as "Type",
      arn as "ARN",
      null as link
    from
      aws_ec2_network_load_balancer,
      jsonb_array_elements_text(security_groups) as sg
    where
      sg = $1


    -- attached GWLBs
    union all select
        title as "Title",
        'aws_ec2_gateway_load_balancer' as "Type",
        arn as "ARN",
        null as link
      from
        aws_ec2_gateway_load_balancer,
        jsonb_array_elements_text(security_groups) as sg
      where
        sg = $1


    -- attached aws_ec2_launch_configuration
    union all select
        title as "Title",
        'aws_ec2_launch_configuration' as "Type",
        launch_configuration_arn as "ARN",
        null as link
      from
        aws_ec2_launch_configuration,
        jsonb_array_elements_text(security_groups) as sg
      where
        sg = $1


    -- attached DAX Cluster
    union all select
        title as "Title",
        'aws_dax_cluster' as "Type",
        arn as "ARN",
        null as link
      from
        aws_dax_cluster,
        jsonb_array_elements(security_groups) as sg
      where
        sg ->> 'SecurityGroupIdentifier' = $1

    -- attached aws_dms_replication_instance
    union all select
        title as "Title",
        'aws_dms_replication_instance' as "Type",
        arn as "ARN",
        null as link
      from
        aws_dms_replication_instance,
        jsonb_array_elements(vpc_security_groups) as sg
      where
        sg ->> 'VpcSecurityGroupId' = $1

    -- attached aws_efs_mount_target
    union all select
        title as "Title",
        'aws_efs_mount_target' as "Type",
        mount_target_id as "ARN",
        null as link
      from
        aws_efs_mount_target,
        jsonb_array_elements_text(security_groups) as sg
      where
        sg = $1

    -- attached aws_elasticache_cluster
    union all select
        title as "Title",
        'aws_elasticache_cluster' as "Type",
        arn as "ARN",
        null as link
      from
        aws_elasticache_cluster,
        jsonb_array_elements(security_groups) as sg
      where
        sg ->> 'SecurityGroupId' = $1


    -- attached aws_rds_db_cluster
    union all select
        title as "Title",
        'aws_rds_db_cluster' as "Type",
        arn as "ARN",
        null as link
      from
        aws_rds_db_cluster,
        jsonb_array_elements(vpc_security_groups) as sg
      where
        sg ->> 'SecurityGroupId' = $1

    -- attached aws_rds_db_instance
    union all select
        title as "Title",
        'aws_rds_db_instance' as "Type",
        arn as "ARN",
      '${dashboard.rds_db_instance_detail.url_path}?input.db_instance_arn=' || arn as link
      from
        aws_rds_db_instance,
        jsonb_array_elements(vpc_security_groups) as sg
      where
        sg ->> 'VpcSecurityGroupId' = $1


    -- attached aws_redshift_cluster
    union all select
        title as "Title",
        'aws_redshift_cluster' as "Type",
        arn as "ARN",
      '${dashboard.redshift_cluster_detail.url_path}?input.cluster_arn=' || arn as link
      from
        aws_redshift_cluster,
        jsonb_array_elements(vpc_security_groups) as sg
      where
        sg ->> 'VpcSecurityGroupId' = $1


    -- attached aws_sagemaker_notebook_instance
    union all select
        title as "Title",
        'aws_sagemaker_notebook_instance' as "Type",
        arn as "ARN",
        null as link
      from
        aws_sagemaker_notebook_instance,
        jsonb_array_elements_text(security_groups) as sg
      where
        sg = $1

  EOQ

}
## TODO: Add aws_rds_db_instance / db_security_groups, ELB, ALB, elasticache, etc....

query "vpc_security_group_ingress_rule_sankey" {
  sql = <<-EOQ

    with associations as (

      -- attached ec2 instances
      select
          title,
          arn,
          'aws_ec2_instance' as category,
          sg ->> 'GroupId' as group_id
        from
          aws_ec2_instance,
          jsonb_array_elements(security_groups) as sg
      where
        sg ->> 'GroupId' = $1


      -- attached lambda functions
      union all select
          title,
          arn,
          'aws_lambda_function' as category,
          sg
        from
          aws_lambda_function,
          jsonb_array_elements_text(vpc_security_group_ids) as sg
        where
          sg = $1

      -- attached Classic ELBs
      union all select
          title,
          arn,
          'aws_ec2_classic_load_balancer' as category,
          sg
        from
          aws_ec2_classic_load_balancer,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1

      -- attached ALBs
      union all select
          title,
          arn,
          'aws_ec2_application_load_balancer' as category,
          sg
        from
          aws_ec2_application_load_balancer,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1

      -- attached NLBs
      union all select
          title,
          arn,
          'aws_ec2_network_load_balancer' as category,
          sg
        from
          aws_ec2_network_load_balancer,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1


      -- attached GWLBs
      union all select
          title,
          arn,
          'aws_ec2_gateway_load_balancer' as category,
          sg
        from
          aws_ec2_gateway_load_balancer,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1


      -- attached aws_ec2_launch_configuration
      union all select
          title,
          launch_configuration_arn,
          'aws_ec2_launch_configuration' as category,
          sg
        from
          aws_ec2_launch_configuration,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1



      -- attached DAX Cluster
      union all select
          title,
          arn,
          'aws_dax_cluster' as category,
          sg
        from
          aws_dax_cluster,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1

      -- attached aws_dms_replication_instance
      union all select
          title,
          arn,
          'aws_dms_replication_instance' as category,
          sg
        from
          aws_dms_replication_instance,
          jsonb_array_elements_text(vpc_security_groups) as sg
        where
          sg = $1

      -- attached aws_efs_mount_target
      union all select
          title,
          mount_target_id,
          'aws_efs_mount_target' as category,
          sg
        from
          aws_efs_mount_target,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1

      -- attached aws_elasticache_cluster
      union all select
          title,
          arn,
          'aws_elasticache_cluster' as category,
          sg
        from
          aws_elasticache_cluster,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1


      -- attached aws_rds_db_cluster
      union all select
          title,
          arn,
          'aws_rds_db_cluster' as category,
          sg
        from
          aws_rds_db_cluster,
          jsonb_array_elements_text(vpc_security_groups) as sg
        where
          sg = $1

      -- attached aws_rds_db_instance
      union all select
          title,
          arn,
          'aws_rds_db_instance' as category,
          sg
        from
          aws_rds_db_instance,
          jsonb_array_elements_text(vpc_security_groups) as sg
        where
          sg = $1


      -- attached aws_redshift_cluster
      union all select
          title,
          arn,
          'aws_redshift_cluster' as category,
          sg
        from
          aws_redshift_cluster,
          jsonb_array_elements_text(vpc_security_groups) as sg
        where
          sg = $1


      -- attached aws_sagemaker_notebook_instance
      union all select
          title,
          arn,
          'aws_sagemaker_notebook_instance' as category,
          sg
        from
          aws_sagemaker_notebook_instance,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1

      ),
      rules as (
        select
          concat(text(cidr_ipv4), text(cidr_ipv6), referenced_group_id, referenced_vpc_id,prefix_list_id) as source,
          security_group_rule_id,
          case
            when ip_protocol = '-1' then 'All Traffic'
            when ip_protocol = 'icmp' then 'All ICMP'
            when from_port is not null
            and to_port is not null
            and from_port = to_port then concat(from_port, '/', ip_protocol)
            else concat(
              from_port,
              '-',
              to_port,
              '/',
              ip_protocol
            )
          end as port_proto,
          type,
          case
            when ( cidr_ipv4 = '0.0.0.0/0' or cidr_ipv6 = '::/0')
                and ip_protocol <> 'icmp'
                and (
                  from_port = -1
                  or (from_port = 0 and to_port = 65535)
                ) then 'alert'
            else 'ok'
          end as category,
          group_id
        from
          aws_vpc_security_group_rule
        where
          group_id = $1
          and type = 'ingress'
          )

      -- Nodes  ---------

      select
        distinct concat('src_',source) as id,
        source as title,
        0 as depth,
        'source' as category,
        null as from_id,
        null as to_id
      from
        rules

      union
      select
        distinct port_proto as id,
        port_proto as title,
        1 as depth,
        'port_proto' as category,
        null as from_id,
        null as to_id
      from
        rules

      union
      select
        distinct sg.group_id as id,
        sg.group_name as title,
        2 as depth,
        'security_group' as category,
        null as from_id,
        null as to_id
      from
        aws_vpc_security_group sg
        inner join rules sgr on sg.group_id = sgr.group_id

      union
      select
          distinct arn as id,
          title || '(' || category || ')' as title, -- TODO: Should this be arn instead?
          3 as depth,
          category,
          group_id as from_id,
          null as to_id
        from
          associations

      -- Edges  ---------
      union select
        null as id,
        null as title,
        null as depth,
        category,
        concat('src_',source) as from_id,
        port_proto as to_id
      from
        rules

      union select
        null as id,
        null as title,
        null as depth,
        category,
        port_proto as from_id,
        group_id as to_id
      from
        rules
  EOQ

}

query "vpc_security_group_egress_rule_sankey" {
  sql = <<-EOQ


    with associations as (

      -- attached ec2 instances
      select
          title,
          arn,
          'aws_ec2_instance' as category,
          sg ->> 'GroupId' as group_id
        from
          aws_ec2_instance,
          jsonb_array_elements(security_groups) as sg
      where
        sg ->> 'GroupId' = $1


      -- attached lambda functions
      union all select
          title,
          arn,
          'aws_lambda_function' as category,
          sg
        from
          aws_lambda_function,
          jsonb_array_elements_text(vpc_security_group_ids) as sg
        where
          sg = $1

      -- attached Classic ELBs
      union all select
          title,
          arn,
          'aws_ec2_classic_load_balancer' as category,
          sg
        from
          aws_ec2_classic_load_balancer,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1

      -- attached ALBs
      union all select
          title,
          arn,
          'aws_ec2_application_load_balancer' as category,
          sg
        from
          aws_ec2_application_load_balancer,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1

      -- attached NLBs
      union all select
          title,
          arn,
          'aws_ec2_network_load_balancer' as category,
          sg
        from
          aws_ec2_network_load_balancer,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1


      -- attached GWLBs
      union all select
          title,
          arn,
          'aws_ec2_gateway_load_balancer' as category,
          sg
        from
          aws_ec2_gateway_load_balancer,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1


      -- attached aws_ec2_launch_configuration
      union all select
          title,
          launch_configuration_arn,
          'aws_ec2_launch_configuration' as category,
          sg
        from
          aws_ec2_launch_configuration,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1



      -- attached DAX Cluster
      union all select
          title,
          arn,
          'aws_dax_cluster' as category,
          sg
        from
          aws_dax_cluster,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1

      -- attached aws_dms_replication_instance
      union all select
          title,
          arn,
          'aws_dms_replication_instance' as category,
          sg
        from
          aws_dms_replication_instance,
          jsonb_array_elements_text(vpc_security_groups) as sg
        where
          sg = $1

      -- attached aws_efs_mount_target
      union all select
          title,
          mount_target_id,
          'aws_efs_mount_target' as category,
          sg
        from
          aws_efs_mount_target,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1

      -- attached aws_elasticache_cluster
      union all select
          title,
          arn,
          'aws_elasticache_cluster' as category,
          sg
        from
          aws_elasticache_cluster,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1


      -- attached aws_rds_db_cluster
      union all select
          title,
          arn,
          'aws_rds_db_cluster' as category,
          sg
        from
          aws_rds_db_cluster,
          jsonb_array_elements_text(vpc_security_groups) as sg
        where
          sg = $1

      -- attached aws_rds_db_instance
      union all select
          title,
          arn,
          'aws_rds_db_instance' as category,
          sg
        from
          aws_rds_db_instance,
          jsonb_array_elements_text(vpc_security_groups) as sg
        where
          sg = $1


      -- attached aws_redshift_cluster
      union all select
          title,
          arn,
          'aws_redshift_cluster' as category,
          sg
        from
          aws_redshift_cluster,
          jsonb_array_elements_text(vpc_security_groups) as sg
        where
          sg = $1


      -- attached aws_sagemaker_notebook_instance
      union all select
          title,
          arn,
          'aws_sagemaker_notebook_instance' as category,
          sg
        from
          aws_sagemaker_notebook_instance,
          jsonb_array_elements_text(security_groups) as sg
        where
          sg = $1

      ),
      rules as (
        select
          concat(text(cidr_ipv4), text(cidr_ipv6), referenced_group_id, referenced_vpc_id,prefix_list_id) as source,
          security_group_rule_id,
          case
            when ip_protocol = '-1' then 'All Traffic'
            when ip_protocol = 'icmp' then 'All ICMP'
            when from_port is not null
            and to_port is not null
            and from_port = to_port then concat(from_port, '/', ip_protocol)
            else concat(
              from_port,
              '-',
              to_port,
              '/',
              ip_protocol
            )
          end as port_proto,
          type,
          case
            when ( cidr_ipv4 = '0.0.0.0/0' or cidr_ipv6 = '::/0')
                and ip_protocol <> 'icmp'
                and (
                  from_port = -1
                  or (from_port = 0 and to_port = 65535)
                ) then 'alert'
            else 'ok'
          end as category,
          group_id
        from
          aws_vpc_security_group_rule
        where
          group_id = $1
          and type = 'egress'
          )

      -- Nodes  ---------

      select
        distinct concat('src_',source) as id,
        source as title,
        3 as depth,
        'source' as category,
        null as from_id,
        null as to_id
      from
        rules

      union
      select
        distinct port_proto as id,
        port_proto as title,
        2 as depth,
        'port_proto' as category,
        null as from_id,
        null as to_id
      from
        rules

      union
      select
        distinct sg.group_id as id,
        sg.group_name as title,
        1 as depth,
        'security_group' as category,
        null as from_id,
        null as to_id
      from
        aws_vpc_security_group sg
        inner join rules sgr on sg.group_id = sgr.group_id

      union
      select
          distinct arn as id,
          title || '(' || category || ')' as title, -- TODO: Should this be arn instead?
          0 as depth,
          category,
          group_id as from_id,
          null as to_id
        from
          associations

      -- Edges  ---------
      union select
        null as id,
        null as title,
        null as depth,
        category,
        concat('src_',source) as from_id,
        port_proto as to_id
      from
        rules

      union select
        null as id,
        null as title,
        null as depth,
        category,
        port_proto as from_id,
        group_id as to_id
      from
        rules
  EOQ
}

query "vpc_security_group_ingress_rules" {
  sql = <<-EOQ
    select
      concat(text(cidr_ipv4), text(cidr_ipv6), referenced_group_id, referenced_vpc_id,prefix_list_id) as "Source",
      security_group_rule_id as "Security Group Rule ID",
      case
        when ip_protocol = '-1' then 'All Traffic'
        when ip_protocol = 'icmp' then 'All ICMP'
        else ip_protocol
      end as "Protocol",
      case
        when from_port = -1 then 'All'
        when from_port is not null
          and to_port is not null
          and from_port = to_port then from_port::text
        else concat(
          from_port,
          '-',
          to_port
        )
      end as "Ports"
    from
      aws_vpc_security_group_rule
    where
      group_id = $1
      and not is_egress
  EOQ

}

query "vpc_security_group_egress_rules" {
  sql = <<-EOQ
    select
      concat(text(cidr_ipv4), text(cidr_ipv6), referenced_group_id, referenced_vpc_id,prefix_list_id) as "Destination",
      security_group_rule_id as "Security Group Rule ID",
      case
        when ip_protocol = '-1' then 'All Traffic'
        when ip_protocol = 'icmp' then 'All ICMP'
        else ip_protocol
      end as "Protocol",
      case
        when from_port = -1 then 'All'
        when from_port is not null
          and to_port is not null
          and from_port = to_port then from_port::text
        else concat(
          from_port,
          '-',
          to_port
        )
      end as "Ports"
    from
      aws_vpc_security_group_rule
    where
      group_id = $1
      and is_egress
  EOQ

}

query "vpc_security_group_overview" {
  sql = <<-EOQ
    select
      group_name as "Group Name",
      group_id as "Group ID",
      description as "Description",
      vpc_id as  "VPC ID",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_vpc_security_group
    where
      group_id = $1
    EOQ

}

query "vpc_security_group_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_vpc_security_group,
      jsonb_array_elements(tags_src) as tag
    where
      group_id = $1
    order by
      tag ->> 'Key';
    EOQ

}
