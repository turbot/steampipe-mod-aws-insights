dashboard "aws_ebs_volume_public_access_dashboard" {
  title = "AWS EBS Volume Public Access Report"

  container {

    card {
      sql = <<-EOQ
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
        title as "Volume",
        case when s.snapshot_id is not null then 'Enabled' else null end as "Public Access",
        account_id as "Account",
        region as "Region",
        arn as "ARN"
      from
        aws_ebs_volume as v
        left join public_snapshots as s on v.snapshot_id = s.snapshot_id;
    EOQ
  }

}
