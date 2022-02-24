dashboard "aws_redshift_cluster_public_access_dashboard" {
  title = "AWS Redshift Cluster Public Access Report"

  container {

    card {
      sql = query.aws_redshift_cluster_count.sql
      width = 2
    }

    card {
      sql = <<-EOQ
        select count(*) as value,
        'Publicly Accessible Clusters' as label ,
        case count(*) when 0 then 'ok' else 'alert' end as "type"
        from
          aws_redshift_cluster
        where
          publicly_accessible
      EOQ
      width = 2
    }

  }

  table {

    column "Account ID" {
        display = "none"
    }

    sql = <<-EOQ
      select
        r.title as "Cluster",
        case when publicly_accessible then 'Public' else 'Not public' end as "Public Access State",
        r.cluster_status as "Cluster Status",
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