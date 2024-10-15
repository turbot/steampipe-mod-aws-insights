dashboard "redshift_cluster_public_access_report" {

  title         = "AWS Redshift Cluster Public Access Report"
  documentation = file("./dashboards/redshift/docs/redshift_cluster_report_public_access.md")

  tags = merge(local.redshift_common_tags, {
    type     = "Report"
    category = "Public Access"
  })

  container {

    card {
      query = query.redshift_cluster_count
      width = 3
    }

    card {
      query = query.redshift_cluster_publicly_accessible
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

    column "Cluster Identifier" {
      href = "${dashboard.redshift_cluster_detail.url_path}?input.cluster_arn={{.ARN | @uri}}"
    }

    query = query.redshift_cluster_publicly_accessible_table
  }

}

query "redshift_cluster_publicly_accessible_table" {
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
