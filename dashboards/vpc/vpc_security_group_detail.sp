dashboard "aws_vpc_security_group_detail" {

  title         = "AWS VPC Security Group Detail"
  documentation = file("./dashboards/vpc/docs/vpc_security_group_detail.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "security_group_id" {
    title = "Select a security group:"
    sql   = query.aws_vpc_security_group_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_vpc_security_group_ingress_rules_count
      args = {
        group_id = self.input.security_group_id.value
      }
    }

    card {
      width = 2
      query = query.aws_vpc_security_group_egress_rules_count
      args = {
        group_id = self.input.security_group_id.value
      }
    }

    card {
      width = 2
      query = query.aws_vpc_security_attached_enis_count
      args = {
        group_id = self.input.security_group_id.value
      }
    }

    card {
      width = 2
      query = query.aws_vpc_security_unrestricted_ingress
      args = {
        group_id = self.input.security_group_id.value
      }
    }

    card {
      width = 2
      query = query.aws_vpc_security_unrestricted_egress
      args = {
        group_id = self.input.security_group_id.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_vpc_security_group_node,
        node.aws_vpc_security_group_to_vpc_node,
        node.aws_vpc_security_group_from_rds_db_cluster_node,
        node.aws_vpc_security_group_from_rds_db_instance_node,
        node.aws_vpc_security_group_from_ec2_instance_node,
        node.aws_vpc_security_group_from_lambda_function_node,
        node.aws_vpc_security_group_from_efs_mount_target_node,
        node.aws_vpc_security_group_from_redshift_cluster_node,
        node.aws_vpc_security_group_from_ec2_classic_load_balancer_node,
        node.aws_vpc_security_group_from_ec2_application_load_balancer_node,
        node.aws_vpc_security_group_from_ec2_network_load_balancer_node,
        node.aws_vpc_security_group_from_ec2_gateway_load_balancer_node,
        node.aws_vpc_security_group_from_ec2_launch_configuration_node,
        node.aws_vpc_security_group_from_dax_cluster_node,
        node.aws_vpc_security_group_from_dms_replication_instance_node,
        node.aws_vpc_security_group_from_elasticache_cluster_node,
        node.aws_vpc_security_group_from_sagemaker_notebook_instance_node,
        node.aws_vpc_security_group_from_docdb_cluster_node
      ]

      edges = [
        edge.aws_vpc_security_group_to_vpc_edge,
        edge.aws_vpc_security_group_from_rds_db_cluster_edge,
        edge.aws_vpc_security_group_from_rds_db_instance_edge,
        edge.aws_vpc_security_group_from_ec2_instance_edge,
        edge.aws_vpc_security_group_from_lambda_function_edge,
        edge.aws_vpc_security_group_from_efs_mount_target_edge,
        edge.aws_vpc_security_group_from_redshift_cluster_edge,
        edge.aws_vpc_security_group_from_ec2_classic_load_balancer_edge,
        edge.aws_vpc_security_group_from_ec2_application_load_balancer_edge,
        edge.aws_vpc_security_group_from_ec2_network_load_balancer_edge,
        edge.aws_vpc_security_group_from_ec2_gateway_load_balancer_edge,
        edge.aws_vpc_security_group_from_ec2_launch_configuration_edge,
        edge.aws_vpc_security_group_from_dax_cluster_edge,
        edge.aws_vpc_security_group_from_dms_replication_instance_edge,
        edge.aws_vpc_security_group_from_elasticache_cluster_edge,
        edge.aws_vpc_security_group_from_sagemaker_notebook_instance_edge,
        edge.aws_vpc_security_group_from_docdb_cluster_edge
      ]

      args = {
        group_id = self.input.security_group_id.value
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
        query = query.aws_vpc_security_group_overview
        args = {
          group_id = self.input.security_group_id.value
        }

        column "VPC ID" {
          // cyclic dependency prevents use of url_path, hardcode for now
          // href = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.'VPC ID' | @uri}}"
          href = "/aws_insights.dashboard.aws_vpc_detail?input.vpc_id={{.'VPC ID' | @uri}}"

        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_vpc_security_group_tags
        args = {
          group_id = self.input.security_group_id.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Associated to"
        query = query.aws_vpc_security_group_assoc
        args = {
          group_id = self.input.security_group_id.value
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

  container {

    width = 6

    flow {
      base  = flow.security_group_rules_sankey
      title = "Ingress Analysis"
      query = query.aws_vpc_security_group_ingress_rule_sankey
      args = {
        group_id = self.input.security_group_id.value
      }
    }


    table {
      title = "Ingress Rules"
      query = query.aws_vpc_security_group_ingress_rules
      args = {
        group_id = self.input.security_group_id.value
      }
    }

  }

  container {

    width = 6

    flow {
      base  = flow.security_group_rules_sankey
      title = "Egress Analysis"
      query = query.aws_vpc_security_group_egress_rule_sankey
      args = {
        group_id = self.input.security_group_id.value
      }
    }

    table {
      title = "Egress Rules"
      query = query.aws_vpc_security_group_egress_rules
      args = {
        group_id = self.input.security_group_id.value
      }
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

query "aws_vpc_security_group_input" {
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

query "aws_vpc_security_group_ingress_rules_count" {
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

  param "group_id" {}
}

query "aws_vpc_security_group_egress_rules_count" {
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

  param "group_id" {}
}

query "aws_vpc_security_attached_enis_count" {
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

  param "group_id" {}
}

query "aws_vpc_security_unrestricted_ingress" {
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

  param "group_id" {}
}

query "aws_vpc_security_unrestricted_egress" {
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

  param "group_id" {}
}

query "aws_vpc_security_group_assoc" {
  sql = <<-EOQ

    -- EC2 instances
    select
      title as "Title",
      'aws_ec2_instance' as "Type",
      arn as "ARN",
      '${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn=' || arn as link
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
      '${dashboard.aws_lambda_function_detail.url_path}?input.lambda_arn=' || arn as link
    from
       aws_lambda_function,
       jsonb_array_elements_text(vpc_security_group_ids) as sg
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
      '${dashboard.aws_rds_db_instance_detail.url_path}?input.db_instance_arn=' || arn as link
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
      '${dashboard.aws_redshift_cluster_detail.url_path}?input.cluster_arn=' || arn as link
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

  param "group_id" {}

}
## TODO: Add aws_rds_db_instance / db_security_groups, ELB, ALB, elasticache, etc....

query "aws_vpc_security_group_ingress_rule_sankey" {
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

  param "group_id" {}
}

query "aws_vpc_security_group_egress_rule_sankey" {
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
  param "group_id" {}
}

query "aws_vpc_security_group_ingress_rules" {
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

  param "group_id" {}
}

query "aws_vpc_security_group_egress_rules" {
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

  param "group_id" {}
}

query "aws_vpc_security_group_overview" {
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

  param "group_id" {}
}

query "aws_vpc_security_group_tags" {
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

  param "group_id" {}
}

category "aws_vpc_security_group_no_link" {
  color = "purple"
  icon  = "heroicons-solid:lock-closed"
}

node "aws_vpc_security_group_node" {
  category = category.aws_vpc_security_group_no_link

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'Group ID', group_id,
        'Description', description,
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_security_group
    where
      group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_to_vpc_node" {
  category = category.aws_vpc

  sql = <<-EOQ
    select
      v.vpc_id as id,
      v.title as title,
      jsonb_build_object(
        'VPC ID', v.vpc_id,
        'Name', v.tags ->> 'Name',
        'CIDR Block', v.cidr_block,
        'Owner ID', v.owner_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      aws_vpc_security_group as sg,
      aws_vpc as v
    where
      sg.vpc_id = v.vpc_id
      and sg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_to_vpc_edge" {
  title = "vpc"

  sql = <<-EOQ
    select
      sg.arn as from_id,
      v.vpc_id as to_id
    from
      aws_vpc_security_group as sg,
      aws_vpc as v
    where
      sg.vpc_id = v.vpc_id
      and sg.group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_rds_db_cluster_node" {
  category = category.aws_rds_db_cluster

  sql = <<-EOQ
    select
      c.arn as id,
      c.title as title,
      jsonb_build_object(
        'ARN', c.arn,
        'Status', status,
        'Create Time', create_time,
        'Account ID', c.account_id,
        'Region', c.region ) as properties
    from
      aws_rds_db_cluster as c,
      jsonb_array_elements(vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_rds_db_cluster_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      c.arn as from_id,
      vsg.arn as to_id
    from
      aws_rds_db_cluster as c,
      jsonb_array_elements(vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_rds_db_instance_node" {
  category = category.aws_rds_db_instance

  sql = <<-EOQ
    select
      i.arn as id,
      i.title as title,
      jsonb_build_object(
        'ARN', i.arn,
        'Status', i.status,
        'Public Access', i.publicly_accessible::text,
        'Availability Zone', i.availability_zone,
        'Create Time', i.create_time,
        'Is Multi AZ', i.multi_az::text,
        'Class', i.class,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_rds_db_instance i,
      jsonb_array_elements(vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_rds_db_instance_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      i.arn as from_id,
      vsg.arn as to_id
    from
      aws_rds_db_instance i,
      jsonb_array_elements(vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_ec2_instance_node" {
  category = category.aws_ec2_instance

  sql = <<-EOQ
   select
    sg,
      i.arn as id,
      i.title as title,
      jsonb_build_object(
        'Name', i.tags ->> 'Name',
        'Instance ID', instance_id,
        'ARN', i.arn,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_ec2_instance as i,
      jsonb_array_elements(security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'GroupId'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_ec2_instance_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      i.arn as from_id,
      vsg.arn as to_id
    from
      aws_ec2_instance as i,
      jsonb_array_elements(security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'GroupId'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_lambda_function_node" {
  category = category.aws_lambda_function

  sql = <<-EOQ
    select
      l.arn as id,
      l.title as title,
      jsonb_build_object(
        'ARN', l.arn,
        'Account ID', l.account_id,
        'Region', l.region
      ) as properties
    from
      aws_lambda_function as l,
      jsonb_array_elements_text(l.vpc_security_group_ids) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_lambda_function_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      l.arn as from_id,
      vsg.arn as to_id
    from
      aws_lambda_function as l,
      jsonb_array_elements_text(l.vpc_security_group_ids) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_efs_mount_target_node" {
  category = category.aws_efs_mount_target

  sql = <<-EOQ
    select
      mt.mount_target_id as id,
      mt.title as title,
      jsonb_build_object(
        'ID', mt.mount_target_id,
        'Availability Zone', mt.availability_zone_name,
        'File System ID', mt.file_system_id,
        'IP Address', mt.ip_address,
        'Life Cycle State', mt.life_cycle_state,
        'ENI ID' ,network_interface_id,
        'Account ID', mt.account_id,
        'Region', mt.region
      ) as properties
    from
      aws_efs_mount_target as mt,
      jsonb_array_elements_text(mt.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_efs_mount_target_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      mt.mount_target_id as from_id,
      vsg.arn as to_id
    from
      aws_efs_mount_target as mt,
      jsonb_array_elements_text(mt.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_redshift_cluster_node" {
  category = category.aws_redshift_cluster

  sql = <<-EOQ
    select
      rc.arn as id,
      rc.title as title,
      jsonb_build_object(
        'ID', rc.cluster_identifier,
        'Availability Zone', rc.availability_zone,
        'Create Time', rc.cluster_create_time,
        'DB Name', rc.db_name,
        'Encrypted', rc.encrypted,
        'VPC ID' ,rc.vpc_id,
        'Account ID', rc.account_id,
        'Region', rc.region
      ) as properties
    from
      aws_redshift_cluster as rc,
      jsonb_array_elements(rc.vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_redshift_cluster_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      rc.arn as from_id,
      vsg.arn as to_id
    from
      aws_redshift_cluster as rc,
      jsonb_array_elements(rc.vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_ec2_classic_load_balancer_node" {
  category = category.aws_ec2_classic_load_balancer

  sql = <<-EOQ
    select
      elb.arn as id,
      elb.title as title,
      jsonb_build_object(
        'ARN', elb.arn,
        'VPC ID', elb.vpc_id,
        'DNS Name', elb.dns_name,
        'Created Time', elb.created_time,
        'Account ID', elb.account_id,
        'Region', elb.region
      ) as properties
    from
      aws_ec2_classic_load_balancer elb,
      jsonb_array_elements_text(elb.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_ec2_classic_load_balancer_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      elb.arn as from_id,
      vsg.arn as to_id
    from
      aws_ec2_classic_load_balancer elb,
      jsonb_array_elements_text(elb.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_ec2_application_load_balancer_node" {
  category = category.aws_ec2_application_load_balancer

  sql = <<-EOQ
    select
      alb.arn as id,
      alb.title as title,
      jsonb_build_object(
        'ARN', alb.arn,
        'VPC ID', alb.vpc_id,
        'Type', alb.type,
        'DNS Name', alb.dns_name,
        'Created Time', alb.created_time,
        'Account ID', alb.account_id,
        'Region', alb.region
      ) as properties
    from
      aws_ec2_application_load_balancer alb,
      jsonb_array_elements_text(alb.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_ec2_application_load_balancer_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      alb.arn as from_id,
      vsg.arn as to_id
    from
      aws_ec2_application_load_balancer alb,
      jsonb_array_elements_text(alb.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_ec2_network_load_balancer_node" {
  category = category.aws_ec2_network_load_balancer

  sql = <<-EOQ
     select
      nlb.arn as id,
      nlb.title as title,
      jsonb_build_object(
        'ARN', nlb.arn,
        'VPC ID', nlb.vpc_id,
        'Type', nlb.type,
        'DNS Name', nlb.dns_name,
        'Created Time', nlb.created_time,
        'Account ID', nlb.account_id,
        'Region', nlb.region
      ) as properties
    from
      aws_ec2_network_load_balancer nlb,
      jsonb_array_elements_text(nlb.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_ec2_network_load_balancer_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      nlb.arn as from_id,
      vsg.arn as to_id
    from
      aws_ec2_network_load_balancer as nlb,
      jsonb_array_elements_text(nlb.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_ec2_gateway_load_balancer_node" {
  category = category.aws_ec2_gateway_load_balancer

  sql = <<-EOQ
    select
      glb.arn as id,
      glb.title as title,
      jsonb_build_object(
        'ARN', glb.arn,
        'VPC ID', glb.vpc_id,
        'Type', glb.type,
        'DNS Name', glb.dns_name,
        'Created Time', glb.created_time,
        'Account ID', glb.account_id,
        'Region', glb.region
      ) as properties
    from
      aws_ec2_gateway_load_balancer as glb,
      jsonb_array_elements_text(glb.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_ec2_gateway_load_balancer_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      glb.arn as from_id,
      vsg.arn as to_id
    from
      aws_ec2_gateway_load_balancer glb,
      jsonb_array_elements_text(glb.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_ec2_launch_configuration_node" {
  category = category.aws_ec2_launch_configuration

  sql = <<-EOQ
    select
      c.launch_configuration_arn as id,
      c.title as title,
      jsonb_build_object(
        'ARN', c.launch_configuration_arn,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_ec2_launch_configuration as c,
      jsonb_array_elements_text(c.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_ec2_launch_configuration_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      c.launch_configuration_arn as from_id,
      vsg.arn as to_id
    from
      aws_ec2_launch_configuration as c,
      jsonb_array_elements_text(c.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_dax_cluster_node" {
  category = category.aws_dax_cluster

  sql = <<-EOQ
    select
      dc.arn as id,
      dc.title as title,
      jsonb_build_object(
        'Cluster Name', dc.cluster_name,
        'Active Nodes', dc.active_nodes,
        'Description', dc.description,
        'Status', dc.status,
        'Account ID', dc.account_id,
        'Region', dc.region
      ) as properties
    from
      aws_dax_cluster as dc,
      jsonb_array_elements(dc.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'SecurityGroupIdentifier'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_dax_cluster_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      dc.arn as from_id,
      vsg.arn as to_id
    from
      aws_dax_cluster as dc,
      jsonb_array_elements(dc.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'SecurityGroupIdentifier'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_dms_replication_instance_node" {
  category = category.aws_dms_replication_instance

  sql = <<-EOQ
    select
      ri.arn as id,
      ri.title as title,
      jsonb_build_object(
        'ID', ri.replication_instance_identifier,
        'Allocated Storage', ri.allocated_storage,
        'Availability Zone', ri.availability_zone,
        'Engine Version', ri.engine_version,
        'Publicly Accessible', ri.publicly_accessible,
        'Account ID', ri.account_id,
        'Region', ri.region
      ) as properties
    from
      aws_dms_replication_instance as ri,
      jsonb_array_elements(ri.vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_dms_replication_instance_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      ri.arn as from_id,
      vsg.arn as to_id
    from
      aws_dms_replication_instance as ri,
      jsonb_array_elements(ri.vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_elasticache_cluster_node" {
  category = category.aws_elasticache_cluster

  sql = <<-EOQ
    select
      ec.arn as id,
      ec.title as title,
      jsonb_build_object(
        'ID', ec.cache_cluster_id,
        'Auth Token Enabled', ec.auth_token_enabled,
        'Engine Version', ec.engine_version,
        'Status', ec.cache_cluster_status,
        'Node Type', ec.cache_node_type,
        'Account ID', ec.account_id,
        'Region', ec.region
      ) as properties
    from
      aws_elasticache_cluster as ec,
      jsonb_array_elements(ec.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'SecurityGroupId'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_elasticache_cluster_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      ec.arn as from_id,
      vsg.arn as to_id
    from
      aws_elasticache_cluster as ec,
      jsonb_array_elements(ec.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'SecurityGroupId'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_sagemaker_notebook_instance_node" {
  category = category.aws_sagemaker_notebook_instance

  sql = <<-EOQ
    select
      ni.arn as id,
      ni.title as title,
      jsonb_build_object(
        'ARN', ni.arn,
        'Status', ni.notebook_instance_status,
        'Instance Type', ni.instance_type,
        'Region', ni.region,
        'Account ID', ni.account_id
      ) as properties
    from
      aws_sagemaker_notebook_instance ni,
      jsonb_array_elements_text(ni.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_sagemaker_notebook_instance_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      ni.arn as from_id,
      vsg.arn as to_id
    from
      aws_sagemaker_notebook_instance ni,
      jsonb_array_elements_text(ni.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

node "aws_vpc_security_group_from_docdb_cluster_node" {
  category = category.aws_docdb_cluster

  sql = <<-EOQ
    select
      c.arn as id,
      c.title as title,
      jsonb_build_object(
        'ID', c.db_cluster_identifier,
        'Availability Zone', c.availability_zones,
        'Create Time', c.cluster_create_time,
        'Encrypted', c.storage_encrypted,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_docdb_cluster as c,
      jsonb_array_elements(c.vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}

edge "aws_vpc_security_group_from_docdb_cluster_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      c.arn as from_id,
      vsg.arn as to_id
    from
      aws_docdb_cluster as c,
      jsonb_array_elements(c.vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = $1;
  EOQ

  param "group_id" {}
}