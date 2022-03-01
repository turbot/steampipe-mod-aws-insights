query "aws_vpc_security_group_input" {
  sql = <<EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
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
      and group_id = reverse(split_part(reverse($1), '/', 1))
  EOQ

  param "arn" {}
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
      and group_id = reverse(split_part(reverse($1), '/', 1));
  EOQ

  param "arn" {}
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
      sg ->> 'GroupId' = reverse(split_part(reverse('hdhbhha/ahdsh'), '/', 1));
  EOQ

  param "arn" {}
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
      and group_id = reverse(split_part(reverse($1), '/', 1));
  EOQ

  param "arn" {}
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
      and group_id = reverse(split_part(reverse($1), '/', 1));
  EOQ

  param "arn" {}
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
      sg ->> 'GroupId' = (reverse(split_part(reverse($1), '/', 1)))
    union all select
      title,
      'aws_lambda_function' as type,
      arn
    from
       aws_lambda_function,
       jsonb_array_elements_text(vpc_security_group_ids) as sg
    where
      sg = (reverse(split_part(reverse($1), '/', 1)));
  EOQ

  param "arn" {}

}
## TODO: Add aws_rds_db_instance / db_security_groups, ELB, ALB, elasticache, etc....

query "aws_vpc_security_group_ingress_rule_sankey" {

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
      sg ->> 'GroupId' = reverse(split_part(reverse($1), '/', 1))

    union all select
        title,
        arn,
        'aws_lambda_function' as category,
        sg
      from
        aws_lambda_function,
        jsonb_array_elements_text(vpc_security_group_ids) as sg
      where
      sg = reverse(split_part(reverse($1), '/', 1))
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
      group_id = reverse(split_part(reverse($1), '/', 1))
      and type = 'ingress'
      ),

  analysis as (
    select
      port_proto as parent,
      source as id,
      source as name,
      0 as depth,
      category
    from
      rules

    union
    select
      group_id as parent,
      port_proto as id,
      port_proto as name,
      1 as depth,
      category
    from
      rules

    union
    select
      null as parent,
      sg.group_id as id,
      sg.group_name as name,
      2 as depth,
      'aws_vpc_security_group' as category
    from
      aws_vpc_security_group sg
      inner join rules sgr on sg.group_id = sgr.group_id

    union
    select
        group_id as parent,
        arn as id,
        title || '(' || category || ')' as name, -- TODO: Should this be arn instead?
        3 as depth,
        category
      from
        associations
      where
      group_id = reverse(split_part(reverse($1), '/', 1))
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

  param "arn" {}
}

query "aws_vpc_security_group_egress_rule_sankey" {

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
        sg ->> 'GroupId' = reverse(split_part(reverse($1), '/', 1))

      union all select
          title,
          arn,
          'aws_lambda_function' as category,
          sg
        from
          aws_lambda_function,
          jsonb_array_elements_text(vpc_security_group_ids) as sg
        where
        sg = reverse(split_part(reverse($1), '/', 1))
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
        group_id = reverse(split_part(reverse($1), '/', 1))
        and is_egress
        ),

    analysis as (
      select
          group_id as parent,
          arn as id,
          title || '(' || category || ')' as name, -- TODO: Should this be arn instead?
          0 as depth,
          category
        from
          associations
        where
        group_id = reverse(split_part(reverse($1), '/', 1))


      union select
        null as parent,
        sg.group_id as id,
        sg.group_name as name,
        1 as depth,
        'aws_vpc_security_group' as category
      from
        aws_vpc_security_group sg
        inner join rules sgr on sg.group_id = sgr.group_id

      union select
        group_id as parent,
        port_proto as id,
        port_proto as name,
        2 as depth,
        category
      from
        rules

      union select
        port_proto as parent,
        destination as id,
        destination as name,
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

  param "arn" {}
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
      group_id = reverse(split_part(reverse($1), '/', 1))
      and not is_egress
  EOQ

  param "arn" {}
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
      group_id = reverse(split_part(reverse($1), '/', 1))
      and is_egress
  EOQ

  param "arn" {}
}

dashboard "aws_vpc_security_group_detail" {
  title = "AWS VPC Security Group Detail"

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "security_group_arn" {
    title = "Select a security group:"
    sql   = query.aws_vpc_security_group_input.sql
    width = 4
  }

  container {
    # Assessments

    card {
      width = 2

      query = query.aws_vpc_security_group_ingress_rules_count
      args = {
        arn = self.input.security_group_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_vpc_security_group_egress_rules_count
      args = {
        arn = self.input.security_group_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_vpc_security_attached_enis_count
      args = {
        arn = self.input.security_group_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_vpc_security_unrestricted_ingress
      args = {
        arn = self.input.security_group_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_vpc_security_unrestricted_egress
      args = {
        arn = self.input.security_group_arn.value
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
        sql   = <<-EOQ
            select
              group_name as "Group Name",
              group_id as "Group Id",
              description as "Description",
              vpc_id as  "VPC Id",
              title as "Title",
              region as "Region",
              account_id as "Account Id",
              arn as "ARN"
            from
              aws_vpc_security_group
            where
              arn = $1
          EOQ

        param "arn" {}

        args = {
          arn = self.input.security_group_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6

        sql = <<-EOQ
          select
            tag ->> 'Key' as "Key",
            tag ->> 'Value' as "Value"
          from
            aws_vpc_security_group,
            jsonb_array_elements(tags_src) as tag
          where
            arn = $1
          EOQ

        param "arn" {}

        args = {
          arn = self.input.security_group_arn.value
        }
      }
    }
    container {
      width = 6

      table {
        title = "Associated To"
        query = query.aws_vpc_security_group_assoc
        args = {
          arn = self.input.security_group_arn.value
        }
      }
    }

  }

  container {
    width = 6

    hierarchy {
      type  = "sankey"
      title = "Ingress Analysis"
      query = query.aws_vpc_security_group_ingress_rule_sankey
      args = {
        arn = self.input.security_group_arn.value
      }

      category "aws_ec2_isntance" {
        color = "orange"
      }

      category "aws_lambda_function" {
        color = "yellow"
      }

      category "alert" {
        color = "red"
      }

      category "ok" {
        color = "green"
      }

    }

    table {
      title = "Ingress Rules"
      query = query.aws_vpc_security_group_ingress_rules
      args = {
        arn = self.input.security_group_arn.value
      }
    }
  }

  container {
    width = 6

    hierarchy {
      type  = "sankey"
      title = "Egress Analysis"
      query = query.aws_vpc_security_group_egress_rule_sankey
      args = {
        arn = self.input.security_group_arn.value
      }

      category "aws_ec2_isntance" {
        color = "orange"
      }

      category "aws_lambda_function" {
        color = "yellow"
      }

      category "alert" {
        color = "red"
      }

      category "ok" {
        color = "green"
      }

    }

    table {
      title = "Egress Rules"
      query = query.aws_vpc_security_group_egress_rules
      args = {
        arn = self.input.security_group_arn.value
      }
    }

  }

}
