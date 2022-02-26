dashboard "aws_ebs_volume_public_access_dashboard" {
  title = "AWS EBS Volume Public Access Report"

  tags = merge(local.ebs_common_tags, {
    type     = "Report"
    category = "Public Access"
  })

  container {

    card {
      sql   = query.aws_ebs_volume_count.sql
      width = 2
    }

    card {
      sql   = <<-EOQ
        with public_snapshots as (
          select
            snapshot_id
          from
            aws_ebs_snapshot
          where
            create_volume_permissions @> '[{"Group": "all"}]'
        ),
        public_volumes as (
          select
            v.title as volume
          from
            aws_ebs_volume as v,
            public_snapshots as s
          where
            v.snapshot_id = s.snapshot_id
        )
        select
          count(*) as value,
          'Publicly Accessible' as label,
          case count(*) when 0 then 'ok' else 'alert' end as type
        from
          public_volumes;
      EOQ
      width = 2
    }
  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = <<-EOQ
      with public_snapshots as (
        select
          snapshot_id
        from
          aws_ebs_snapshot
        where
          create_volume_permissions @> '[{"Group": "all"}]'
      )
      select
        v.tags ->> 'Name' as "Name",
        v.volume_id as "Volume",
        case when s.snapshot_id is not null then 'Enabled' else null end as "Public Access",
        a.title as "Account",
        v.account_id as "Account ID",
        v.region as "Region",
        v.arn as "ARN"
      from
        aws_ebs_volume as v
        left join public_snapshots as s on v.snapshot_id = s.snapshot_id
        left join aws_account as a on v.account_id = a.account_id;
    EOQ

  }

}
