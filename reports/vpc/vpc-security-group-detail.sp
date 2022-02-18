dashboard "aws_vpc_security_group_detail" {
  title = "AWS VPC Security Group Detail"

  input "security_group_id" {
    title = "Security Group"
    sql   = <<-EOQ
      select
        group_id
      from
        aws_vpc_security_group
    EOQ
    width = 2
  }

  container {

    card {
      sql   = <<-EOQ
        select
          'Ingress Rules' as label,
          count(*) as value
        from
          aws_vpc_security_group_rule
        where
          group_id = 'sg-029cd86da723916fa'
          and not is_egress
      EOQ
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          'Egress Rules' as label,
          count(*) as value
        from
          aws_vpc_security_group_rule
        where
          group_id = 'sg-029cd86da723916fa'
          and is_egress
      EOQ
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          'Attached ENIs' as label,
          count(*) as value,
          case
            when count(*) > 0 then 'ok'
            else 'alert'
          end as type
        from
          aws_ec2_network_interface,
          jsonb_array_elements(groups) as sg
        where
          sg ->> 'GroupId' = 'sg-029cd86da723916fa'
      EOQ
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          'Unrestricted Ingress (excludes ICMP)' as label,
          count(*) as value,
          case
            when count(*) = 0 then 'ok'
            else 'alert'
          end as style
        from
          aws_vpc_security_group_rule
        where
          group_id = 'sg-029cd86da723916fa'
          and ( cidr_ipv4 = '0.0.0.0/0' or cidr_ipv6 = '::/0')
          and ip_protocol <> 'icmp'
          and (
            from_port = -1
            or (from_port = 0 and to_port = 65535)
          )
          and not is_egress
      EOQ
      width = 2
    }

    card {
      sql   = <<-EOQ
         select
          'Unrestricted Egress  (excludes ICMP)' as label,
          count(*) as value,
          case
            when count(*) = 0 then 'ok'
            else 'alert'
          end as style
        from
          aws_vpc_security_group_rule
        where
          group_id = 'sg-029cd86da723916fa'
          and ( cidr_ipv4 = '0.0.0.0/0' or cidr_ipv6 = '::/0')
          and ip_protocol <> 'icmp'
          and (
            from_port = -1
            or (from_port = 0 and to_port = 65535)
          )
          and is_egress
      EOQ
      width = 2
    }

  }

  container {
    title = "Analysis"

    container {

      container {
        width = 6

        table {
          title = "Overview"

          sql = <<-EOQ
            select
              group_name,
              group_id,
              description,
              vpc_id,
              title,
              region,
              account_id,
              arn
            from
              aws_vpc_security_group
                where
              group_id = 'sg-029cd86da723916fa'
          EOQ
        }

        table {
          title = "Tags"

          sql = <<-EOQ
            select
              tag ->> 'Key' as "Key",
              tag ->> 'Value' as "Value"
            from
              aws_vpc_security_group,
              jsonb_array_elements(tags_src) as tag
            where
              group_id = 'sg-029cd86da723916fa'
          EOQ
        }
      }

      table {
        title = "Associated To"
        sql   = query.aws_vpc_security_group_assoc.sql
        width = 6
      }
    }

    container {
      width = 6

      hierarchy {
        type  = "sankey"
        title = "Ingress Analysis"
        sql   = query.aws_vpc_security_group_ingress_rule_sankey.sql

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
        sql   = query.aws_vpc_security_group_ingress_rules.sql
      }
    }

    container {
      width = 6

      hierarchy {
        type  = "sankey"
        title = "Egress Analysis"
        sql   = query.aws_vpc_security_group_egress_rule_sankey.sql

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
        sql   = query.aws_vpc_security_group_egress_rules.sql
      }

    }
  }

}

query "aws_vpc_security_group_assoc" {
  sql = <<EOQ
   select
      title,
      'aws_ec2_instance' as type,
      arn
    from
      aws_ec2_instance,
      jsonb_array_elements(security_groups) as sg
    where
     sg ->> 'GroupId' = 'sg-029cd86da723916fa'

   union all select
      title,
      'aws_lambda_function' as type,
      arn
    from
      aws_lambda_function,
      jsonb_array_elements_text(vpc_security_group_ids) as sg
    where
     sg = 'sg-029cd86da723916fa'

    -- TODO: Add aws_rds_db_instance / db_security_groups, ELB, ALB, elasticache, etc....
  EOQ
}

query "aws_vpc_security_group_ingress_rules" {
  sql = <<EOQ
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
      group_id = 'sg-029cd86da723916fa'
      and not is_egress
  EOQ
}

query "aws_vpc_security_group_egress_rules" {
  sql = <<EOQ
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
      group_id = 'sg-029cd86da723916fa'
      and is_egress
  EOQ
}

query "aws_vpc_security_group_ingress_rule_sankey" {

  sql = <<EOQ
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
     sg ->> 'GroupId' = 'sg-029cd86da723916fa'

   union all select
      title,
      arn,
      'aws_lambda_function' as category,
      sg
    from
      aws_lambda_function,
      jsonb_array_elements_text(vpc_security_group_ids) as sg
    where
     sg = 'sg-029cd86da723916fa'
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
    group_id = 'sg-029cd86da723916fa'
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
     group_id = 'sg-029cd86da723916fa'
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
}

query "aws_vpc_security_group_egress_rule_sankey" {

  sql = <<EOQ
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
     sg ->> 'GroupId' = 'sg-029cd86da723916fa'

   union all select
      title,
      arn,
      'aws_lambda_function' as category,
      sg
    from
      aws_lambda_function,
      jsonb_array_elements_text(vpc_security_group_ids) as sg
    where
     sg = 'sg-029cd86da723916fa'
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
    group_id = 'sg-029cd86da723916fa'
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
     group_id = 'sg-029cd86da723916fa'


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
}