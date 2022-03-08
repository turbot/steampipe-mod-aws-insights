dashboard "aws_redshift_cluster_encryption_report" {

  title         = "AWS Redshift Cluster Encryption Report"
  documentation = file("./dashboards/redshift/docs/redshift_cluster_report_encryption.md")

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


  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "Cluster Identifier" {
      href = "/aws_insights.dashboard.aws_redshift_cluster_detail?input.cluster_arn={{.ARN|@uri}}"
    }

    sql = query.aws_redshift_cluster_encryption_table.sql
  }

}

query "aws_redshift_cluster_encryption_table" {
  sql = <<-EOQ
    select
      c.cluster_identifier as "Cluster Identifier",
      case when encrypted then 'Enabled' else null end as "Encryption",
      c.kms_key_id as "KMS Key ID",
      a.title as "Account",
      c.account_id as "Account ID",
      c.region as "Region",
      c.arn as "ARN"
    from
      aws_redshift_cluster as c,
      aws_account as a
    where
      c.account_id = a.account_id
    order by
      c.cluster_identifier;
  EOQ
}