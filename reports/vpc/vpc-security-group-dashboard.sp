report "aws_vpc_security_group_dashboard" {
  title = "AWS VPC Security Group Dashboard"

  container {
    # Analysis
    card {
      sql = <<-EOQ
        select count(*) as "Security Groups" from aws_vpc_security_group;
      EOQ
      width = 2
    }

    # Assessments
    card {
      sql = <<-EOQ
        with associated_sg as (
          select
            sg ->> 'GroupId' as secgrp_id,
            sg ->> 'GroupName' as secgrp_name
          from
            aws_ec2_network_interface,
            jsonb_array_elements(groups) as sg
        )
        select
          count(*) as value,
          'Unassociated Security Groups' as label,
          case count(*) when 0 then 'ok' else 'alert' end as style
        from
          aws_vpc_security_group s
          left join associated_sg a on s.group_id = a.secgrp_id
        where
          a.secgrp_id is null;
      EOQ
      width = 2
    }

    card {
      sql = <<-EOQ
        with unrestricted_sg as (
          select
            count(group_id) as unrestricted_sg_count
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
                or (
                    from_port >= 3389
                    and to_port <= 3389
                )
                or (
                    from_port >= 21
                    and to_port <= 21
                )
                or (
                    from_port >= 20
                    and to_port <= 20
                )
                or (
                    from_port >= 3306
                    and to_port <= 3306
                )
                or (
                    from_port >= 4333
                    and to_port <= 4333
                )
            )
        )
        select
          unrestricted_sg_count as value,
          'Unrestricted Security Groups' as label,
          case unrestricted_sg_count when 0 then 'ok' else 'alert' end as style
        from
          unrestricted_sg;
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
      width = 3
    }
  }
}