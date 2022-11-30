dashboard "aws_vpc_security_group_detail" {

  title         = "AWS VPC Security Group Detail"
  documentation = file("./dashboards/vpc/docs/vpc_security_group_detail.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "security_group_id" {
    title = "Select a security group:"
    query = query.aws_vpc_security_group_input
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

      with "vpcs" {
        sql = <<-EOQ
          select
            vpc_id as vpc_id
          from
            aws_vpc_security_group
          where
            group_id = $1;
        EOQ

        args = [self.input.security_group_id.value]
      }

      with "rds_clusters" {
        sql = <<-EOQ
          select
            arn as rds_db_cluster_arn
          from
            aws_rds_db_cluster,
            jsonb_array_elements(vpc_security_groups) as sg
          where
            sg ->> 'VpcSecurityGroupId' = $1;
        EOQ

        args = [self.input.security_group_id.value]
      }

      with "rds_instances" {
        sql = <<-EOQ
          select
            arn as rds_db_instance_arn
          from
            aws_rds_db_instance,
            jsonb_array_elements(vpc_security_groups) as sg
          where
            sg ->> 'VpcSecurityGroupId' = $1;
        EOQ

        args = [self.input.security_group_id.value]
      }

      with "ec2_instances" {
        sql = <<-EOQ
          select
            arn as instance_arn
          from
            aws_ec2_instance as i,
            jsonb_array_elements(security_groups) as sg
          where
            sg ->> 'GroupId' = $1;
        EOQ

        args = [self.input.security_group_id.value]
      }

      with "lambda_functions" {
        sql = <<-EOQ
          select
            arn as lambda_arn
          from
            aws_lambda_function,
            jsonb_array_elements_text(vpc_security_group_ids) as s
          where
            s = $1;
        EOQ

        args = [self.input.security_group_id.value]
      }

      with "redshift_clusters" {
        sql = <<-EOQ
          select
            arn as redshift_cluster_arn
          from
            aws_redshift_cluster,
            jsonb_array_elements(vpc_security_groups) as sg
          where
            sg ->> 'VpcSecurityGroupId' = $1;
        EOQ

        args = [self.input.security_group_id.value]
      }

      with "clbs" {
        sql = <<-EOQ
          select
            arn as clb_arn
          from
            aws_ec2_classic_load_balancer,
            jsonb_array_elements_text(security_groups) as sg
          where
            sg = $1;
        EOQ

        args = [self.input.security_group_id.value]
      }

      with "albs" {
        sql = <<-EOQ
          select
            arn as alb_arn
          from
            aws_ec2_application_load_balancer,
            jsonb_array_elements_text(security_groups) as sg
          where
            sg = $1;
        EOQ

        args = [self.input.security_group_id.value]
      }

      with "dax_clusters" {
        sql = <<-EOQ
          select
            arn as dax_cluster_arn
          from
            aws_dax_cluster,
            jsonb_array_elements(security_groups) as sg
          where
            sg ->> 'SecurityGroupIdentifier' = $1;
        EOQ

        args = [self.input.security_group_id.value]
      }

      with "elasticache_clusters" {
        sql = <<-EOQ
          select
            arn as elasticache_cluster_arn
          from
            aws_elasticache_cluster,
            jsonb_array_elements(security_groups) as sg
          where
            sg ->> 'SecurityGroupId' = $1;
        EOQ

        args = [self.input.security_group_id.value]
      }

      nodes = [
        node.vpc_security_group,
        node.vpc_vpc,
        node.aws_rds_db_cluster_nodes,
        node.aws_rds_db_instance_nodes,
        node.ec2_instance,
        node.aws_lambda_function_nodes,
        node.aws_redshift_cluster_nodes,
        node.ec2_classic_load_balancer,
        node.ec2_application_load_balancer,
        node.aws_dax_cluster_nodes,
        node.aws_elasticache_cluster_nodes,

        node.aws_vpc_security_group_dms_replication_instance_nodes,
        node.aws_vpc_security_group_ec2_launch_configuration_nodes,
        node.aws_vpc_security_group_efs_mount_target_nodes,
        node.aws_vpc_security_group_sagemaker_notebook_instance_nodes,
        node.aws_vpc_security_group_docdb_cluster_nodes
      ]

      edges = [
        edge.aws_vpc_to_vpc_security_group_edges,
        edge.aws_vpc_security_group_to_rds_db_cluster_edges,
        edge.aws_vpc_security_group_to_rds_db_instance_edges,
        edge.aws_vpc_security_group_to_ec2_instance_edges,
        edge.aws_vpc_security_group_to_lambda_function_edges,
        edge.aws_vpc_security_group_to_efs_mount_target_edges,
        edge.aws_vpc_security_group_to_redshift_cluster_edges,
        edge.aws_vpc_security_group_to_ec2_classic_load_balancer_edges,
        edge.aws_vpc_security_group_to_ec2_application_load_balancer_edges,
        edge.aws_vpc_security_group_to_ec2_launch_configuration_edges,
        edge.aws_vpc_security_group_to_dax_cluster_edges,
        edge.aws_vpc_security_group_to_dms_replication_instance_edges,
        edge.aws_vpc_security_group_to_elasticache_cluster_edges,
        edge.aws_vpc_security_group_to_sagemaker_notebook_instance_edges,
        edge.aws_vpc_security_group_to_docdb_cluster_edges
      ]

      args = {
        security_group_ids       = [self.input.security_group_id.value]
        clb_arns                 = with.clbs.rows[*].clb_arn
        alb_arns                 = with.albs.rows[*].alb_arn
        instance_arns            = with.ec2_instances.rows[*].instance_arn
        elasticache_cluster_arns = with.elasticache_clusters.rows[*].elasticache_cluster_arn
        dax_cluster_arns         = with.dax_clusters.rows[*].dax_cluster_arn
        redshift_cluster_arns    = with.redshift_clusters.rows[*].redshift_cluster_arn
        function_arns            = with.lambda_functions.rows[*].lambda_arn
        rds_db_instance_arns     = with.rds_instances.rows[*].rds_db_instance_arn
        rds_db_cluster_arns      = with.rds_clusters.rows[*].rds_db_cluster_arn
        vpc_ids                  = with.vpcs.rows[*].vpc_id
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

edge "aws_vpc_security_group_to_rds_db_cluster_edges" {
  title = "rds cluster"

  sql = <<-EOQ
    select
      security_group_ids as from_id,
      rds_db_cluster_arns as to_id
    from
      unnest($1::text[]) as rds_db_cluster_arns,
      unnest($2::text[]) as security_group_ids
  EOQ

  param "rds_db_cluster_arns" {}
  param "security_group_ids" {}
}

edge "aws_vpc_security_group_to_rds_db_instance_edges" {
  title = "rds instance"

  sql = <<-EOQ
    select
      security_group_ids as from_id,
      rds_db_instance_arns as to_id
    from
      unnest($1::text[]) as rds_db_instance_arns,
      unnest($2::text[]) as security_group_ids
  EOQ

  param "rds_db_instance_arns" {}
  param "security_group_ids" {}
}

edge "aws_vpc_security_group_to_ec2_instance_edges" {
  title = "ec2 instance"

  sql = <<-EOQ
    select
      security_group_ids as from_id,
      instance_arns as to_id
    from
      unnest($1::text[]) as instance_arns,
      unnest($2::text[]) as security_group_ids
  EOQ

  param "instance_arns" {}
  param "security_group_ids" {}
}

edge "aws_vpc_security_group_to_lambda_function_edges" {
  title = "lambda function"

  sql = <<-EOQ
    select
      security_group_ids as from_id,
      function_arns as to_id
    from
      unnest($1::text[]) as function_arns,
      unnest($2::text[]) as security_group_ids
  EOQ

  param "function_arns" {}
  param "security_group_ids" {}
}

node "aws_vpc_security_group_efs_mount_target_nodes" {
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
      vsg.group_id = any($1);
  EOQ

  param "security_group_ids" {}
}

edge "aws_vpc_security_group_to_efs_mount_target_edges" {
  title = "efs mount target"

  sql = <<-EOQ
    select
      vsg.group_id as from_id,
      mt.mount_target_id as to_id
    from
      aws_efs_mount_target as mt,
      jsonb_array_elements_text(mt.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = any($1);
  EOQ

  param "security_group_ids" {}
}

edge "aws_vpc_security_group_to_redshift_cluster_edges" {
  title = "redshift cluster"

  sql = <<-EOQ
    select
      security_group_ids as from_id,
      redshift_cluster_arns as to_id
    from
      unnest($1::text[]) as redshift_cluster_arns,
      unnest($2::text[]) as security_group_ids
  EOQ

  param "redshift_cluster_arns" {}
  param "security_group_ids" {}
}

edge "aws_vpc_security_group_to_ec2_classic_load_balancer_edges" {
  title = "classic load balancer"

  sql = <<-EOQ
    select
      security_group_ids as from_id,
      clb_arns as to_id
    from
      unnest($1::text[]) as clb_arns,
      unnest($2::text[]) as security_group_ids
  EOQ

  param "clb_arns" {}
  param "security_group_ids" {}
}

edge "aws_vpc_security_group_to_ec2_application_load_balancer_edges" {
  title = "application load balancer"

  sql = <<-EOQ
    select
      security_group_ids as from_id,
      alb_arns as to_id
    from
      unnest($1::text[]) as alb_arns,
      unnest($2::text[]) as security_group_ids
  EOQ

  param "alb_arns" {}
  param "security_group_ids" {}
}

node "aws_vpc_security_group_ec2_launch_configuration_nodes" {
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
      vsg.group_id = any($1);
  EOQ

  param "security_group_ids" {}
}

edge "aws_vpc_security_group_to_ec2_launch_configuration_edges" {
  title = "launch configuration"

  sql = <<-EOQ
    select
      vsg.group_id as from_id,
      c.launch_configuration_arn as to_id
    from
      aws_ec2_launch_configuration as c,
      jsonb_array_elements_text(c.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = any($1);
  EOQ

  param "security_group_ids" {}
}

edge "aws_vpc_security_group_to_dax_cluster_edges" {
  title = "dax cluster"

  sql = <<-EOQ
    select
      security_group_ids as from_id,
      dax_cluster_arns as to_id
    from
      unnest($1::text[]) as dax_cluster_arns,
      unnest($2::text[]) as security_group_ids
  EOQ

  param "dax_cluster_arns" {}
  param "security_group_ids" {}
}

node "aws_vpc_security_group_dms_replication_instance_nodes" {
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
      vsg.group_id = any($1);
  EOQ

  param "security_group_ids" {}
}

edge "aws_vpc_security_group_to_dms_replication_instance_edges" {
  title = "replication instance"

  sql = <<-EOQ
    select
      vsg.group_id as from_id,
      ri.arn as to_id
    from
      aws_dms_replication_instance as ri,
      jsonb_array_elements(ri.vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = any($1);
  EOQ

  param "security_group_ids" {}
}

edge "aws_vpc_security_group_to_elasticache_cluster_edges" {
  title = "elasticache cluster"

  sql = <<-EOQ
    select
      security_group_ids as from_id,
      elasticache_cluster_arns as to_id
    from
      unnest($1::text[]) as elasticache_cluster_arns,
      unnest($2::text[]) as security_group_ids
  EOQ

  param "elasticache_cluster_arns" {}
  param "security_group_ids" {}
}

node "aws_vpc_security_group_sagemaker_notebook_instance_nodes" {
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
      vsg.group_id = any($1);
  EOQ

  param "security_group_ids" {}
}

edge "aws_vpc_security_group_to_sagemaker_notebook_instance_edges" {
  title = "notebook instance"

  sql = <<-EOQ
    select
      vsg.group_id as from_id,
      ni.arn as to_id
    from
      aws_sagemaker_notebook_instance ni,
      jsonb_array_elements_text(ni.security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg
    where
      vsg.group_id = any($1);
  EOQ

  param "security_group_ids" {}
}

node "aws_vpc_security_group_docdb_cluster_nodes" {
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
      vsg.group_id = any($1);
  EOQ

  param "security_group_ids" {}
}

edge "aws_vpc_security_group_to_docdb_cluster_edges" {
  title = "docdb cluster"

  sql = <<-EOQ
    select
      vsg.group_id as from_id,
      c.arn as to_id
    from
      aws_docdb_cluster as c,
      jsonb_array_elements(c.vpc_security_groups) as sg
      join aws_vpc_security_group vsg on vsg.group_id = sg ->> 'VpcSecurityGroupId'
    where
      vsg.group_id = any($1);
  EOQ

  param "security_group_ids" {}
}
