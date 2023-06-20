dashboard "eks_cluster_age_report" {

  title         = "AWS EKS Cluster Age Report"
  documentation = file("./dashboards/eks/docs/eks_cluster_report_age.md")

  tags = merge(local.eks_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.eks_cluster_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.eks_cluster_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.eks_cluster_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.eks_cluster_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.eks_cluster_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.eks_cluster_1_year_count
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.eks_cluster_detail.url_path}?input.eks_cluster_arn={{.ARN | @uri}}"
    }
    query = query.eks_cluster_age_table
  }

}

query "eks_cluster_count" {
  sql = <<-EOQ
    select
      count(*) as "Clusters"
    from
      aws_eks_cluster;
  EOQ
}

query "eks_cluster_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_eks_cluster
    where
      created_at > now() - '1 days' :: interval;
  EOQ
}

query "eks_cluster_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_eks_cluster
    where
      created_at between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "eks_cluster_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_eks_cluster
    where
      created_at between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "eks_cluster_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_eks_cluster
    where
      created_at between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "eks_cluster_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_eks_cluster
    where
      created_at <= now() - '1 year' :: interval;
  EOQ
}

query "eks_cluster_age_table" {
  sql = <<-EOQ
    select
      e.name as "Name",
      now()::date - e.created_at::date as "Age in Days",
      e.created_at as "Created Time",
      e.status as "Status",
      a.title as "Account",
      e.account_id as "Account ID",
      e.region as "Region",
      e.arn as "ARN"
    from
      aws_eks_cluster as e,
      aws_account as a
    where
      e.account_id = a.account_id
    order by
      e.created_at,
      e.name;
  EOQ
}
