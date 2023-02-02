dashboard "rds_db_instace_snapshot_encryption_report" {

  title         = "AWS RDS DB Instance Snapshot Encryption Report"
  documentation = file("./dashboards/rds/docs/rds_db_instance_snapshot_report_encryption.md")

  tags = merge(local.rds_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      query = query.rds_db_instance_snapshot_count
      width = 3
    }

    card {
      query = query.rds_db_instance_snapshot_unencrypted_count
      width = 3
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "DB Snapshot Identifier" {
      href = "${dashboard.rds_db_snapshot_detail.url_path}?input.db_snapshot_arn={{.ARN | @uri}}"
    }

    query = query.rds_db_instance_snapshot_encryption_table
  }

}

query "rds_db_instance_snapshot_encryption_table" {
  sql = <<-EOQ
    select
      s.db_snapshot_identifier as "DB Snapshot Identifier",
      case when encrypted then 'Enabled' else null end as "Encryption",
      s.kms_key_id as "KMS Key ID",
      a.title as "Account",
      s.account_id as "Account ID",
      s.region as "Region",
      s.arn as "ARN"
    from
      aws_rds_db_snapshot as s,
      aws_account as a
    where
      s.account_id = a.account_id
    order by
      s.db_snapshot_identifier;
  EOQ
}
