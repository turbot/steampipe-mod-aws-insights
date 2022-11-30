dashboard "emr_cluster_dashboard" {

  title         = "AWS EMR Cluster Dashboard"
  documentation = file("./dashboards/emr/docs/emr_cluster_dashboard.md")

  tags = merge(local.emr_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.emr_cluster_count
      width = 2
    }

    card {
      query = query.emr_cluster_logging_disbaled_count
      width = 2
    }

    card {
      query = query.emr_cluster_logging_encryption_disabled_count
      width = 2
    }

    card {
      query = query.emr_cluster_termination_protection_disabled_count
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Logging Status"
      query = query.emr_cluster_logging_status
      type  = "donut"
      width = 2

      series "count" {
        point "Enabled" {
          color = "ok"
        }
        point "Disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Logging Encryption Status"
      query = query.emr_cluster_logging_encryption_status
      type  = "donut"
      width = 2

      series "count" {
        point "Enabled" {
          color = "ok"
        }
        point "Disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Termination Protection Status"
      query = query.emr_cluster_termination_protection_status
      type  = "donut"
      width = 2

      series "count" {
        point "Enabled" {
          color = "ok"
        }
        point "Disabled" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Clusters by Account"
      query = query.emr_cluster_by_account
      type  = "column"
      width = 3
    }

    chart {
      title = "Clusters by Region"
      query = query.emr_cluster_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "Clusters by Age"
      query = query.emr_cluster_by_age
      type  = "column"
      width = 3
    }

    chart {
      title = "Clusters by Status"
      query = query.emr_cluster_by_state
      type  = "column"
      width = 3
    }
  }

}

# Card Queries

query "emr_cluster_count" {
  sql = <<-EOQ
    select count(*) as "Clusters" from aws_emr_cluster;
  EOQ
}

query "emr_cluster_logging_disbaled_count" {
  sql = <<-EOQ
    select
      'Logging Disabled' as label,
      count(*) as value,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_emr_cluster
    where
      log_uri is null;
  EOQ
}

query "emr_cluster_logging_encryption_disabled_count" {
  sql = <<-EOQ
    select
      'Logging Encryption Disabled' as label,
      count(*) as value,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_emr_cluster
    where
      log_encryption_kms_key_id is null;
  EOQ
}

query "emr_cluster_termination_protection_disabled_count" {
  sql = <<-EOQ
    select
      'Termination Protection Disabled' as label,
      count(*) as value,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_emr_cluster
    where
      not termination_protected;
  EOQ
}

# Assessments

query "emr_cluster_logging_status" {
  sql = <<-EOQ
    with clusters as (
      select
        case when log_uri is null then 'Disabled' else 'Enabled' end as logging_status
      from
        aws_emr_cluster
    )
    select
      logging_status,
      count(*)
    from
      clusters
    group by
      logging_status
  EOQ
}

query "emr_cluster_logging_encryption_status" {
  sql = <<-EOQ
    with clusters as (
      select
        case when log_encryption_kms_key_id is null then 'Disabled' else 'Enabled' end as log_encryption_status
      from
        aws_emr_cluster
    )
    select
      log_encryption_status,
      count(*)
    from
      clusters
    group by
      log_encryption_status
  EOQ
}

query "emr_cluster_termination_protection_status" {
  sql = <<-EOQ
    with clusters as (
      select
        case when termination_protected then 'Enabled' else 'Disabled' end as termination_protection_status
      from
        aws_emr_cluster
    )
    select
      termination_protection_status,
      count(*)
    from
      clusters
    group by
      termination_protection_status
  EOQ
}

# Analysis

query "emr_cluster_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(c.*) as "total"
    from
      aws_emr_cluster as c,
      aws_account as a
    where
      a.account_id = c.account_id
    group by
      account
    order by
      count(c.*) desc
  EOQ
}

query "emr_cluster_by_region" {
  sql = <<-EOQ
    select
      region,
      count(*) as total
    from
      aws_emr_cluster
    group by
      region
  EOQ
}

query "emr_cluster_by_age" {
  sql = <<-EOQ
    with clusters as (
      select
        title,
        (status -> 'Timeline' ->> 'CreationDateTime')::timestamp as created_at,
        to_char((status -> 'Timeline' ->> 'CreationDateTime')::timestamp, 'YYYY-MM') as creation_month
      from
        aws_emr_cluster
    ),
    months as (
      select
        to_char(d, 'YYYY-MM') as month
      from
        generate_series(
          date_trunc('month',
            (select min(created_at) from clusters)
          ),
          date_trunc('month', current_date),
          interval '1 month'
        ) as d
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

query "emr_cluster_by_state" {
  sql = <<-EOQ
    select
      state,
      count(state)
    from
      aws_emr_cluster
    group by
      state
  EOQ
}
