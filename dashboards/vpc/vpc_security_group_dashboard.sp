dashboard "aws_vpc_security_group_dashboard" {

  title         = "AWS VPC Security Group Dashboard"
  documentation = file("./dashboards/vpc/docs/vpc_security_group_dashboard.md")

  tags = merge(local.vpc_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.aws_vpc_security_group_count
      width = 2
    }

    card {
      query = query.aws_vpc_security_group_unassociated_count
      width = 2
    }

    card {
      query = query.aws_vpc_security_unrestricted_ingress_count
      width = 2
    }


    card {
      query = query.aws_vpc_security_unrestricted_egress_count
      width = 2
    }

  }

  container {

    title = "Assessment"

    chart {
      title = "Association Status"
      type  = "donut"
      width = 3
      query = query.aws_vpc_security_group_unassociated_status

      series "count" {
        point "associated" {
          color = "ok"
        }
        point "unassociated" {
          color = "alert"
        }
      }
    }

    chart {
      title = "With Unrestricted Ingress (Excludes ICMP)"
      type  = "donut"
      width = 3
      query = query.aws_vpc_security_group_unrestricted_ingress_status

      series "count" {
        point "restricted" {
          color = "ok"
        }
        point "unrestricted" {
          color = "alert"
        }
      }
    }

    chart {
      title = "With Unrestricted Egress (Excludes ICMP)"
      type  = "donut"
      width = 3
      query = query.aws_vpc_security_group_unrestricted_egress_status

      series "count" {
        point "restricted" {
          color = "ok"
        }
        point "unrestricted" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Default Security Group"
      type  = "donut"
      width = 3
      query = query.aws_vpc_default_security_group_status

      series "count" {
        point "default" {
          color = "ok"
        }
        point "non-default" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Security Groups by Account"
      query = query.aws_vpc_security_group_by_acount
      type  = "column"
      width = 4
    }

    chart {
      title = "Security Groups by Region"
      query = query.aws_vpc_security_group_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Security Groups by VPC"
      query = query.aws_vpc_security_group_by_vpc
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "aws_vpc_security_group_count" {
  sql = <<-EOQ
    select count(*) as "Security Groups" from aws_vpc_security_group;
  EOQ
}

query "aws_vpc_security_group_unassociated_count" {
  sql = <<-EOQ
    with associated_sg as (
      select
        sg ->> 'GroupId' as sg_id,
        sg ->> 'GroupName' as sg_name
      from
        aws_ec2_network_interface,
        jsonb_array_elements(groups) as sg
    )
    select
      count(*) as value,
      'Unassociated' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_vpc_security_group s
      left join associated_sg a on s.group_id = a.sg_id
    where
      a.sg_id is null;
  EOQ
}

query "aws_vpc_security_unrestricted_ingress_count" {
  sql = <<-EOQ
    with ingress_sg as (
      select
        group_id,
        count(*)
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
        group by group_id
    )
    select
      'Unrestricted Ingress (Excludes ICMP)' as label,
      count(*) as value,
      case
        when count(*) = 0 then 'ok'
        else 'alert'
      end as type
    from
      aws_vpc_security_group as sg
      where sg.group_id in (select group_id from ingress_sg )
  EOQ
}

query "aws_vpc_security_unrestricted_egress_count" {
  sql = <<-EOQ
    with egress_sg as (
      select
        group_id,
        count(*)
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
      group by group_id
    )
    select
      'Unrestricted Egress (Excludes ICMP)' as label,
      count(*) as value,
      case
        when count(*) = 0 then 'ok'
        else 'alert'
      end as type
    from
      aws_vpc_security_group as sg
      where sg.group_id in (select group_id from egress_sg )
  EOQ
}

# Assessment Queries

query "aws_vpc_security_group_unassociated_status" {
  sql = <<-EOQ
    with associated_sg as (
      select
        sg ->> 'GroupId' as sg_id,
        sg ->> 'GroupName' as sg_name
      from
        aws_ec2_network_interface,
        jsonb_array_elements(groups) as sg
    ),
    sg_list as (
      select
        s.group_id,
        case
          when a.sg_id is null then false
          else true
        end as is_associated
      from
        aws_vpc_security_group as s
        left join associated_sg a on s.group_id = a.sg_id
    )
    select
      case
        when is_associated then 'associated'
        else 'unassociated'
      end as sg_association_status,
        count(*)
    from
      sg_list
    group by is_associated;
  EOQ
}


query "aws_vpc_security_group_unrestricted_ingress_status" {
  sql = <<-EOQ
    with ingress_sg as (
      select
        group_id
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
      group by
        group_id
    )
    select
     case when isg.group_id is null then 'restricted' else 'unrestricted' end as status,
     count(*)
    from
      aws_vpc_security_group as sg left join ingress_sg as isg on sg.group_id = isg.group_id
    group by
      status;
  EOQ
}

query "aws_vpc_security_group_unrestricted_egress_status" {
  sql = <<-EOQ
    with egress_sg as (
      select
        group_id,
        count(*)
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
      group by group_id
    )
    select
      case when esg.group_id is null then 'restricted' else 'unrestricted' end as status,
      count(*)
    from
      aws_vpc_security_group as sg left join egress_sg as esg on sg.group_id = esg.group_id
    group by
      status;
  EOQ
}

query "aws_vpc_default_security_group_status" {
  sql = <<-EOQ
    with default_sg as (
      select
        group_id,
        case when group_name = 'default' then true else false end as is_default
      from
        aws_vpc_security_group
    )
    select
      case
        when is_default then 'default'
        else 'non-default'
      end as default_status,
      count(*)
    from
      default_sg
    group by is_default;
  EOQ
}

# Analysis Queries

query "aws_vpc_security_group_by_acount" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(s.*) as "security_groups"
    from
      aws_vpc_security_group as s,
      aws_account as a
    where
      a.account_id = s.account_id
    group by
      account
    order by
      account;
  EOQ
}

query "aws_vpc_security_group_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "security_groups"
    from
      aws_vpc_security_group
    group by
      region
    order by
      region;
  EOQ
}

query "aws_vpc_security_group_by_vpc" {
  sql = <<-EOQ
    select
      vpc_id as "VPC",
      count(*) as "security_groups"
    from
      aws_vpc_security_group
    group by
      vpc_id
    order by
      vpc_id;
  EOQ
}
