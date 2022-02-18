query "aws_redshift_cluster_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_redshift_cluster
    where
      not encrypted
  EOQ
}

dashboard "aws_redshift_cluster_encryption_report" {

  title = "AWS Redshift Cluster Encryption Report"

  container {

    card {
      sql = query.aws_redshift_cluster_unencrypted_count.sql
      width = 2
    }
  }

  table {
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
    EOQ
  }
}