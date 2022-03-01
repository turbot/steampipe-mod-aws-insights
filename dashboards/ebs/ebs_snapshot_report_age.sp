dashboard "aws_ebs_snapshot_age_report" {

  title = "AWS EBS Snapshot Age Report"

  tags = merge(local.ebs_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      sql   = query.aws_ebs_snapshot_count.sql
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '< 24 hours' as label
        from
          aws_ebs_snapshot
        where
          start_time > now() - '1 days' :: interval;
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '1-30 Days' as label
        from
          aws_ebs_snapshot
        where
          start_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '30-90 Days' as label
        from
          aws_ebs_snapshot
        where
          start_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '90-365 Days' as label
        from
          aws_ebs_snapshot
        where
          start_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '> 1 Year' as label
        from
          aws_ebs_snapshot
        where
          start_time <= now() - '1 year' :: interval;
      EOQ
      width = 2
      type  = "info"
    }

  }

  container {

    table {

      column "Account ID" {
        display = "none"
      }

      sql = <<-EOQ
        select
          s.tags ->> 'Name' as "Name",
          s.snapshot_id as "Snapshot",
          now()::date - s.start_time::date as "Age in Days",
          s.start_time as "Create Time",
          s.state as "State",
          a.title as "Account",
          s.account_id as "Account ID",
          s.region as "Region",
          s.arn as "ARN"
        from
          aws_ebs_snapshot as s,
          aws_account as a
        where
          s.account_id = a.account_id
        order by
          s.start_time,
          s.title;
      EOQ

    }

  }

}
