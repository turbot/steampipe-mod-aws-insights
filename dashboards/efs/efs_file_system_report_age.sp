dashboard "aws_efs_file_system_report_age" {
  title         = "AWS EFS File System Age Report"
  documentation = file("./dashboards/efs/docs/efs_file_system_report_age.md")

  tags = merge(local.efs_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.aws_efs_file_system_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.aws_efs_file_system_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.aws_efs_file_system_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.aws_efs_file_system_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.aws_efs_file_system_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.aws_efs_file_system_1_year_count
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
      href = "${dashboard.aws_efs_file_system_detail.url_path}?input.efs_file_system_arn={{.ARN | @uri}}"
    }

    query = query.aws_efs_file_system_table
  }
}

query "aws_efs_file_system_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      aws_efs_file_system
    where
      creation_time > now() - '1 days' :: interval;
  EOQ
}

query "aws_efs_file_system_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      aws_efs_file_system
    where
      creation_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "aws_efs_file_system_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      aws_efs_file_system
    where
      creation_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "aws_efs_file_system_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      aws_efs_file_system
    where
      creation_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "aws_efs_file_system_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      aws_efs_file_system
    where
      creation_time <= now() - '1 year' :: interval;
  EOQ
}

query "aws_efs_file_system_table" {
  sql = <<-EOQ
    select
      fs.arn as "ARN",
      fs.name as "Name",
      fs.file_system_id as "ID",
      now()::date - fs.creation_time::date as "Age in Days",
      fs.creation_time as "Create Time",
      acc.title as "Account",
      fs.account_id as "Account ID",
      fs.region as "Region"
    from
      aws_efs_file_system as fs,
      aws_account as acc
    where
      fs.account_id = acc.account_id
    order by
      fs.name;
  EOQ
}