dashboard "aws_vpc_security_group_detail" {

  title = "AWS VPC Security Group Detail"
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
      args  = {
        group_id = self.input.security_group_id.value
      }
    }

    card {
      width = 2
      query = query.aws_vpc_security_group_egress_rules_count
      args  = {
        group_id = self.input.security_group_id.value
      }
    }

    card {
      width = 2
      query = query.aws_vpc_security_attached_enis_count
      args  = {
        group_id = self.input.security_group_id.value
      }
    }

    card {
      width = 2
      query = query.aws_vpc_security_unrestricted_ingress
      args  = {
        group_id = self.input.security_group_id.value
      }
    }

    card {
      width = 2
      query = query.aws_vpc_security_unrestricted_egress
      args  = {
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
        args  = {
          group_id = self.input.security_group_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_vpc_security_group_tags
        args  = {
          group_id = self.input.security_group_id.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Associated To"
        query = query.aws_vpc_security_group_assoc
        args  = {
          group_id = self.input.security_group_id.value
        }
      }

    }

  }

  container {

    width = 6

    flow {
      base = flow.security_group_rules_sankey
      title = "Ingress Analysis"
      query = query.aws_vpc_security_group_ingress_rule_sankey
      args  = {
        group_id = self.input.security_group_id.value
      }
    }


    table {
      title = "Ingress Rules"
      query = query.aws_vpc_security_group_ingress_rules
      args  = {
        group_id = self.input.security_group_id.value
      }
    }

  }

  container {

    width = 6

    flow {
      base = flow.security_group_rules_sankey
      title = "Egress Analysis"
      query = query.aws_vpc_security_group_egress_rule_sankey
      args  = {
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
      type  = "sankey"

      category "alert" {
        color = "red"
      }

      category "ok" {
        color = "green"
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
      'Unrestricted Ingress (excludes ICMP)' as label,
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
      'Unrestricted Egress  (excludes ICMP)' as label,
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
    select
      title,
      'aws_ec2_instance' as type,
      arn
     from
       aws_ec2_instance,
       jsonb_array_elements(security_groups) as sg
     where
      sg ->> 'GroupId' = $1

    union all select
      title,
      'aws_lambda_function' as type,
      arn
    from
       aws_lambda_function,
       jsonb_array_elements_text(vpc_security_group_ids) as sg
    where
      sg = $1


    -- attached ELBs
    union all select
        title,
        arn,
        'aws_ec2_classic_load_balancer' as type
      from
        aws_ec2_classic_load_balancer,
        jsonb_array_elements_text(security_groups) as sg
      where
        sg = $1

    -- attached ALBs
    union all select
        title,
        arn,
        'aws_ec2_application_load_balancer' as type
      from
        aws_ec2_application_load_balancer,
        jsonb_array_elements_text(security_groups) as sg
      where
        sg = $1

    -- attached NLBs
    union all select
        title,
        arn,
        'aws_ec2_network_load_balancer' as type
      from
        aws_ec2_network_load_balancer,
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

      -- attached ELBs
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

            
          -- TODO: Add aws_rds_db_instance / db_security_groups, etc.
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
            when ip_protocol = '-1' then 'alert'
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

      -- attached ELBs
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

            
          -- TODO: Add aws_rds_db_instance / db_security_groups, etc.
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
            when ip_protocol = '-1' then 'alert'
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


query "aws_vpc_security_group_egress_rule_sankey_DELETEME" {
  sql = <<-EOQ
    with associations as (
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


      -- attached ELBs
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

        -- TODO: Add aws_rds_db_instance / db_security_groups, etc.
    ),
    rules as (
      select
        concat(text(cidr_ipv4), text(cidr_ipv6), referenced_group_id, referenced_vpc_id,prefix_list_id) as destination,
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
          when ip_protocol = '-1' then 'alert'
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
        and is_egress
        ),
    analysis as (
      select
          group_id as from_id,
          arn as id,
          title || '(' || category || ')' as title, -- TODO: Should this be arn instead?
          0 as depth,
          category
        from
          associations
        where
        group_id = $1
      union
      select
        null as from_id,
        sg.group_id as id,
        sg.group_name as title,
        1 as depth,
        'aws_vpc_security_group' as category
      from
        aws_vpc_security_group sg
        inner join rules sgr on sg.group_id = sgr.group_id
      union
      select
        group_id as from_id,
        port_proto as id,
        port_proto as title,
        2 as depth,
        category
      from
        rules
      union
      select
        port_proto as from_id,
        destination as id,
        destination as title,
        3 as depth,
        category
      from
        rules
      )
    select
      *
    from
      analysis
    order by
      depth,
      category,
      id;
  EOQ

  param "group_id" {}
}

query "aws_vpc_security_group_ingress_rules" {
  sql = <<-EOQ
    select
      concat(text(cidr_ipv4), text(cidr_ipv6), referenced_group_id, referenced_vpc_id,prefix_list_id) as source,
      security_group_rule_id,
      case
        when ip_protocol = '-1' then 'All Traffic'
        when ip_protocol = 'icmp' then 'All ICMP'
        else ip_protocol
      end as protocol,
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
      end as ports
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
      concat(text(cidr_ipv4), text(cidr_ipv6), referenced_group_id, referenced_vpc_id,prefix_list_id) as destination,
      security_group_rule_id,
      case
        when ip_protocol = '-1' then 'All Traffic'
        when ip_protocol = 'icmp' then 'All ICMP'
        else ip_protocol
      end as protocol,
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
      end as ports
    from
      aws_vpc_security_group_rule
    where
      group_id = $1
      and is_egress
  EOQ

  param "group_id" {}
}

query "aws_vpc_security_group_overview" {
  sql   = <<-EOQ
    select
      group_name as "Group Name",
      group_id as "Group ID",
      description as "Description",
      vpc_id as  "VPC ID",
      title as "Title",
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

