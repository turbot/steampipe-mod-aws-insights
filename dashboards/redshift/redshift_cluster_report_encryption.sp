dashboard "aws_redshift_cluster_encryption_report" {

  title = "AWS Redshift Cluster Encryption Report"

  tags = merge(local.redshift_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      sql = query.aws_redshift_cluster_count.sql
      width = 2
    }

    card {
      sql = query.aws_redshift_cluster_unencrypted_count.sql
      width = 2
    }
  }

  container {

    table {
      column "Account ID" {
        display = "none"
      }

      sql = query.aws_redshift_cluster_encryption_table.sql
    }

  }

}

query "aws_redshift_cluster_encryption_table" {
  sql = <<-EOQ
    select
      r.cluster_identifier as "Cluster",
      case when encrypted then 'Enabled' else null end as "Encryption",
      r.kms_key_id as "KMS Key ID",
      a.title as "Account",
      r.account_id as "Account ID",
      r.region as "Region",
      r.arn as "ARN"
    from
      aws_redshift_cluster as r,
      aws_account as a
    where
      r.account_id = a.account_id
    order by
      r.cluster_identifier;
  EOQ
}