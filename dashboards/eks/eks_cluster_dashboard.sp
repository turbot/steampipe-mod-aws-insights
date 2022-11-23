dashboard "aws_eks_cluster_dashboard" {

  title         = "AWS EKS Cluster Dashboard"
  documentation = file("./dashboards/eks/docs/eks_cluster_dashboard.md")

  tags = merge(local.eks_common_tags, {
    type = "Dashboard"
  })

  #cards

  container {

    card {
      query = query.aws_eks_cluster_count
      width = 2
    }

    #Assessments
    card {
      query = query.aws_eks_cluster_secrets_encryption_disabled
      width = 2
    }

    card {
      query = query.aws_eks_cluster_endpoint_endpoint_public_access_disabled
      width = 2
    }

    card {
      query = query.aws_eks_cluster_audit_logging_disabled
      width = 2
    }

  }

  # Assessments

  container {

    title = "Assessments"
    width = 6

    chart {
      title = "Secrets Encryption Status"
      query = query.aws_eks_cluster_secrets_encryption_status
      type  = "donut"
      width = 4

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Endpoint Public Access Status"
      query = query.aws_eks_cluster_endpoint_public_access_status
      type  = "donut"
      width = 4

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Audit Logging Status"
      query = query.aws_eks_cluster_audit_logging_status
      type  = "donut"
      width = 4

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }
  }

  container {

    title = "Cost"
    width = 6

    table {
      width = 6
      title = "Forecast"
      query = query.aws_eks_monthly_forecast_table
    }

    chart {
      width = 6
      type  = "column"
      title = "Monthly Cost - 12 Months"
      query = query.aws_eks_cost_per_month
    }

  }

  # Analysis

  container {

    title = "Analysis"

    chart {
      title = "Clusters by Account"
      query = query.aws_eks_cluster_by_account
      type  = "column"
      width = 4
    }

    chart {
      title = "Clusters by Region"
      query = query.aws_eks_cluster_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Clusters by Status"
      query = query.aws_eks_cluster_by_status
      type  = "column"
      width = 4
    }

    chart {
      title = "Clusters by Creation Month"
      query = query.aws_eks_cluste_by_creation_month
      type  = "column"
      width = 4
    }

    chart {
      title = "Clusters by Platform Version"
      query = query.aws_eks_cluster_by_platform_version
      type  = "column"
      width = 4
    }

    chart {
      title = "Clusters by IP Family"
      query = query.aws_eks_cluster_by_ip_family
      type  = "column"
      width = 4
    }

  }

}


# Card Queries

query "aws_eks_cluster_secrets_encryption_disabled" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Secret Encryption Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_eks_cluster
    where
      encryption_config is null;
  EOQ
}

query "aws_eks_cluster_endpoint_endpoint_public_access_disabled" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Endpoint Public Access Disabled' as label,
      case count(*) when 0 then 'alert' else 'ok' end as "type"
    from
      aws_eks_cluster
    where
      resources_vpc_config -> 'EndpointPublicAccess' = 'true';
  EOQ
}

query "aws_eks_cluster_audit_logging_disabled" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Cluster Audit Logging Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_eks_cluster,
      jsonb_array_elements(logging -> 'ClusterLogging') as l,
      jsonb_array_elements_text(l -> 'Types') as t
    where
      l->'Enabled'= 'false' and t ='audit';
  EOQ
}

# Assessment Queries

query "aws_eks_cluster_secrets_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select encryption_config,
        case when encryption_config is not null then
          'enabled'
        else
          'disabled'
        end encryption_status
      from
        aws_eks_cluster) as t
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}

query "aws_eks_cluster_endpoint_public_access_status" {
  sql = <<-EOQ
    select
      endpoint_public_access_status,
      count(*)
    from (
      select resources_vpc_config -> 'EndpointPublicAccess',
        case when resources_vpc_config -> 'EndpointPublicAccess' = 'true' then
          'enabled'
        else
          'disabled'
        end endpoint_public_access_status
      from
        aws_eks_cluster) as t
    group by
      endpoint_public_access_status
    order by
      endpoint_public_access_status desc;
  EOQ
}

query "aws_eks_cluster_audit_logging_status" {
  sql = <<-EOQ
    select
      audit_logging_status,
      count(*)
    from (
      select
        case when l->'Enabled'= 'false' then
          'disabled'
        else
          'enabled'
        end audit_logging_status
      from
        aws_eks_cluster,
        jsonb_array_elements(logging -> 'ClusterLogging') as l,
        jsonb_array_elements_text(l -> 'Types') as t
      where
        t ='audit'
      ) as e
    group by
      audit_logging_status
    order by
      audit_logging_status desc;
  EOQ
}

// # Cost Queries

query "aws_eks_monthly_forecast_table" {
  sql = <<-EOQ
    with monthly_costs as (
      select
        period_start,
        period_end,
        case
          when date_trunc('month', period_start) = date_trunc('month', CURRENT_DATE::timestamp) then 'Month to Date'
          when date_trunc('month', period_start) = date_trunc('month', CURRENT_DATE::timestamp - interval '1 month') then 'Previous Month'
          else to_char (period_start, 'Month')
        end as period_label,
        period_end::date - period_start::date as days,
        sum(unblended_cost_amount)::numeric::money as unblended_cost_amount,
        (sum(unblended_cost_amount) / (period_end::date - period_start::date ) )::numeric::money as average_daily_cost,
        date_part('days', date_trunc ('month', period_start) + '1 MONTH'::interval  - '1 DAY'::interval ) as days_in_month,
        sum(unblended_cost_amount) / (period_end::date - period_start::date ) * date_part('days', date_trunc ('month', period_start) + '1 MONTH'::interval  - '1 DAY'::interval )::numeric::money  as forecast_amount
      from
        aws_cost_by_service_usage_type_monthly as c
      where
        service = 'Amazon Elastic Container Service for Kubernetes'
        and usage_type like '%AmazonEKS%'
        and date_trunc('month', period_start) >= date_trunc('month', CURRENT_DATE::timestamp - interval '1 month')
      group by
        period_start,
        period_end
    )
    select
      period_label as "Period",
      unblended_cost_amount as "Cost",
      average_daily_cost as "Daily Avg Cost"
    from
      monthly_costs
    union all
    select
      'This Month (Forecast)' as "Period",
      (select forecast_amount from monthly_costs where period_label = 'Month to Date') as "Cost",
      (select average_daily_cost from monthly_costs where period_label = 'Month to Date') as "Daily Avg Cost";
  EOQ
}

query "aws_eks_cost_per_month" {
  sql = <<-EOQ
    select
      to_char(period_start, 'Mon-YY') as "Month",
      sum(unblended_cost_amount) as "Unblended Cost"
    from
      aws_cost_by_service_usage_type_monthly
    where
      service = 'Amazon Elastic Container Service for Kubernetes'
      and usage_type like '%AmazonEKS%'
    group by
      period_start
    order by
      period_start;
  EOQ
}

// # Analysis Queries

query "aws_eks_cluster_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(c.*) as "clusters"
    from
      aws_eks_cluster as c,
      aws_account as a
    where
      a.account_id = c.account_id
    group by
      account
    order by
      account;
  EOQ
}

query "aws_eks_cluster_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "clusters"
    from
      aws_eks_cluster
    group by
      region
    order by
      region;
  EOQ
}

query "aws_eks_cluster_by_status" {
  sql = <<-EOQ
    select
      status as "Status",
      count(*) as "clusters"
    from
      aws_eks_cluster
    group by
      status
    order by
      status;
  EOQ
}

query "aws_eks_cluster_by_platform_version" {
  sql = <<-EOQ
    select
      platform_version as "Platform Version",
      count(*) as "clusters"
    from
      aws_eks_cluster
    group by
      platform_version
    order by
      platform_version;
  EOQ
}

query "aws_eks_cluster_by_ip_family" {
  sql = <<-EOQ
    select
      kubernetes_network_config -> 'IpFamily' as "IP Family",
      count(*) as "clusters"
    from
      aws_eks_cluster
    group by
      kubernetes_network_config -> 'IpFamily'
    order by
      kubernetes_network_config -> 'IpFamily';
  EOQ
}

query "aws_eks_cluste_by_creation_month" {
  sql = <<-EOQ
    with clusters as (
      select
        title,
        created_at,
        to_char(created_at,
          'YYYY-MM') as creation_month
      from
        aws_eks_cluster
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(created_at)
                from clusters)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    clusters_by_month as (
      select
        creation_month,
        count(*)
      from
        clusters
      group by
        creation_month
    )
    select
      months.month,
      clusters_by_month.count
    from
      months
      left join clusters_by_month on months.month = clusters_by_month.creation_month
    order by
      months.month;
  EOQ
}
