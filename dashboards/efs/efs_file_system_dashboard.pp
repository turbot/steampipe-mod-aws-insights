dashboard "efs_file_system_dashboard" {

  title         = "AWS EFS File System Dashboard"
  documentation = file("./dashboards/efs/docs/efs_file_system_dashboard.md")

  tags = merge(local.efs_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis

    card {
      query = query.efs_file_system_count
      width = 3
    }

    card {
      query = query.efs_file_system_encryption_disabled_count
      width = 3
    }

    card {
      query = query.efs_file_system_automatic_backup_disabled_count
      width = 3
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "File System Encryption Status"
      query = query.efs_file_system_by_encryption_status
      type  = "donut"
      width = 3

      series "count" {
        point "Encrypted" {
          color = "ok"
        }
        point "Not Encrypted" {
          color = "alert"
        }
      }
    }

    chart {
      title = "File System Automatic Backup Status"
      query = query.efs_file_system_by_automatic_backup_status
      type  = "donut"
      width = 3

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
      title = "File Systems by Account"
      query = query.efs_file_system_by_account
      type  = "column"
      width = 3
    }

    chart {
      title = "File Systems by Region"
      query = query.efs_file_system_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "File Systems by State"
      query = query.efs_file_system_by_state
      type  = "column"
      width = 3
    }

    chart {
      title = "File Systems by Age"
      query = query.efs_file_system_by_age
      type  = "column"
      width = 3
    }

    chart {
      title = "File Systems by Performance Mode"
      query = query.efs_file_system_by_performance_mode
      type  = "column"
      width = 3
    }

    chart {
      title = "File Systems by Throughput Mode"
      query = query.efs_file_system_by_throughput_mode
      type  = "column"
      width = 3
    }

  }

}

# Card Queries

query "efs_file_system_count" {
  sql = <<-EOQ
    select
      count(*) as "File Systems"
    from
      aws_efs_file_system
  EOQ
}

query "efs_file_system_encryption_disabled_count" {
  sql = <<-EOQ
    select
      'Encryption Disabled' as label,
      count(*) as value,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_efs_file_system
    where
      not encrypted;
  EOQ
}

query "efs_file_system_automatic_backup_disabled_count" {
  sql = <<-EOQ
    select
      'Automatic Backup Disabled' as label,
      count(*) as value,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      aws_efs_file_system
    where
      automatic_backups <> 'enabled';
  EOQ
}

# Assessments Queries

query "efs_file_system_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select
        case when encrypted then 'Encrypted' else 'Not Encrypted' end encryption_status
      from
        aws_efs_file_system
    ) as t
    group by
      encryption_status
    order by
      encryption_status;
  EOQ
}

query "efs_file_system_by_automatic_backup_status" {
  sql = <<-EOQ
    select
      automatic_backup_status,
      count(*)
    from (
      select
        case when automatic_backups = 'enabled' then 'Enabled' else 'Disabled' end automatic_backup_status
      from
        aws_efs_file_system
    ) as t
    group by
      automatic_backup_status
    order by
      automatic_backup_status;
  EOQ
}

# Analysis Queries

query "efs_file_system_by_account" {
  sql = <<-EOQ
    select
      a.title as "Account",
      count(fs.*)
    from
      aws_efs_file_system as fs,
      aws_account as a
    where
      a.account_id = fs.account_id
    group by
      a.title
    order by
      a.title;
  EOQ
}

query "efs_file_system_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*)
    from
      aws_efs_file_system
    group by
      region
    order by
      region;
  EOQ
}

query "efs_file_system_by_state" {
  sql = <<-EOQ
    select
      life_cycle_state as "State",
      count(life_cycle_state)
    from
      aws_efs_file_system
    group by
      life_cycle_state
    order by
      life_cycle_state;
  EOQ
}

query "efs_file_system_by_age" {
  sql = <<-EOQ
    with file_systems as (
      select
        title,
        creation_time,
        to_char(creation_time, 'YYYY-MM') as creation_month
      from
        aws_efs_file_system
    ),
    months as (
      select
        to_char(d, 'YYYY-MM') as month
      from
        generate_series(
          date_trunc('month',
            (
              select
                min(creation_time)
              from file_systems
            )
          ),
          date_trunc('month', current_date),
          interval '1 month'
        ) as d
    ),
    file_systems_by_month as (
      select
        creation_month,
        count(*)
      from
        file_systems
      group by
        creation_month
    )
    select
      months.month,
      file_systems_by_month.count
    from
      months
      left join file_systems_by_month on months.month = file_systems_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "efs_file_system_by_performance_mode" {
  sql = <<-EOQ
    select
      performance_mode as "Performance Mode",
      count(performance_mode)
    from
      aws_efs_file_system
    group by
      performance_mode
    order by
      performance_mode;
  EOQ
}

query "efs_file_system_by_throughput_mode" {
  sql = <<-EOQ
    select
      throughput_mode as "Throughput Mode",
      count(throughput_mode)
    from
      aws_efs_file_system
    group by
      throughput_mode
    order by
      throughput_mode;
  EOQ
}
