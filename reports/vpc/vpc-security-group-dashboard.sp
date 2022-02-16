dashboard "aws_vpc_security_group_dashboard" {
  title = "AWS VPC Security Group Dashboard"

  container {
    card {
      sql = <<-EOQ
        select count(*) as "Security Groups" from aws_vpc_security_group;
      EOQ
      width = 2
    }

    card {
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
          'Unassociated Security Groups' as label,
          case count(*) when 0 then 'ok' else 'alert' end as "type"
        from
          aws_vpc_security_group s
          left join associated_sg a on s.group_id = a.sg_id
        where
          a.sg_id is null;
      EOQ
      width = 2
    }

    card {
      sql = <<-EOQ
        with default_sg_with_inbound_outbound_traffic as (
          select
            group_name
          from
            aws_vpc_security_group
          where
            group_name = 'default'
            and (
              ip_permissions is not null
              or ip_permissions_egress is not null
            )
        )
        select
        count(*) as value,
        'Unrestricted Default Security Groups' as label,
        case count(*) when 0 then 'ok' else 'alert' end as "type"
        from
          default_sg_with_inbound_outbound_traffic;
      EOQ
      width = 2
    }
  }

  container {
    title = "Analysis"

    chart {
      title = "Security Groups by Account"
      sql   = <<-EOQ
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
      type  = "column"
      width = 3
    }

    chart {
      title = "Security Groups by Region"
      sql = <<-EOQ
        select
          region as "Region",
          count(*) as "security_groups"
        from
          aws_vpc_security_group
        group by region
        order by region;
      EOQ
      type  = "column"
      width = 3
    }

    chart {
      title = "Security Groups by VPC"
      sql = <<-EOQ
        select
          vpc_id as "VPC",
          count(*) as "security_groups"
        from
          aws_vpc_security_group
        group by vpc_id
        order by vpc_id;
      EOQ
      type  = "column"
      width = 5
    }
  }

  container {
    title = "Assessments"

    chart {
      title = "Default Security Group"
      type  = "donut"
      width = 2
      sql   = <<-EOQ
        with default_sg as (
          select
            group_id,
            case when group_name = 'default' then true else false end as is_default
          from
            aws_vpc_security_group
        )
        select
          case
            when is_default then 'Default'
            else 'Non-Default'
          end as default_status,
          count(*)
        from
          default_sg
        group by is_default
      EOQ
    }

    chart {
      title = "Security Group with unrestricted ingress SSH"
      type  = "donut"
      width = 3
      sql   = <<-EOQ
        with ingress_ssh_rules as (
          select
            group_id
          from
            aws_vpc_security_group_rule
          where
            type = 'ingress'
            and cidr_ipv4 = '0.0.0.0/0'
            and (
                ( ip_protocol = '-1'
                and from_port is null
                )
                or (
                    from_port >= 22
                    and to_port <= 22
                )
            )
          group by
            group_id
        ),
        sg_list as (
          select
            sg.group_id,
            case
            when ingress_ssh_rules.group_id is null then true
            else false
          end as restricted
          from
            aws_vpc_security_group as sg
            left join ingress_ssh_rules on sg.group_id = ingress_ssh_rules.group_id
        )
        select
          case
            when restricted then 'Restricted'
            else 'Unrestricted'
          end as restrict_ingress_ssh_status,
          count(*)
        from
          sg_list
        group by restricted;
      EOQ
    }

    chart {
      title = "Security Group with unrestricted ingress TCP and UDP"
      type  = "donut"
      width = 3
      sql   = <<-EOQ
        with ingress_tcp_udp_rules as (
          select
            group_id
          from
            aws_vpc_security_group_rule
          where
            type = 'ingress'
            and cidr_ipv4 = '0.0.0.0/0'
            and (
              ip_protocol in ('tcp', 'udp')
              or (
                ip_protocol = '-1'
                and from_port is null
              )
            )
          group by
            group_id
        ),
        sg_list as (
          select
            sg.group_id,
            case
            when ingress_tcp_udp_rules.group_id is null then true
            else false
          end as restricted
          from
            aws_vpc_security_group as sg
            left join ingress_tcp_udp_rules on sg.group_id = ingress_tcp_udp_rules.group_id
        )
        select
          case
            when restricted then 'Restricted'
            else 'Unrestricted'
          end as restrict_ingress_tcp_udp_status,
          count(*)
        from
          sg_list
        group by restricted;
      EOQ
    }

    chart {
      title = "Unassociated Security Group"
      type  = "donut"
      width = 3
      sql   = <<-EOQ
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
            when is_associated then 'Associated'
            else 'Not-Associated'
          end as sg_association_status,
          count(*)
        from
          sg_list
        group by is_associated;
      EOQ 
    }
  }
}
