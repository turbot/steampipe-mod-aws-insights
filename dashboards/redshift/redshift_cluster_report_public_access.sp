dashboard "aws_redshift_cluster_public_access_report" {

  title = "AWS Redshift Cluster Public Access Report"

  tags = merge(local.redshift_common_tags, {
    type     = "Report"
    category = "Public Access"
  })

  container {

    card {
      sql = query.aws_redshift_cluster_count.sql
      width = 2
    }

    card {
      sql = query.aws_redshift_cluster_publicly_accessible.sql
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

    sql = query.aws_redshift_cluster_publicly_accessible_table.sql
  }

}

query "aws_redshift_cluster_publicly_accessible_table" {
  sql = <<-EOQ
   select
      c.cluster_identifier as "Cluster Identifier",
      case when publicly_accessible then 'Public' else 'Not public' end as "Public Access State",
      c.cluster_status as "Cluster Status",
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