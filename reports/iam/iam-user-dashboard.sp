query "aws_iam_user_count" {
  sql = <<-EOQ
    select count(*) as "Users" from aws_iam_user
  EOQ
}

query "aws_iam_mfa_not_enabled_users_count" {
  sql = <<-EOQ
  select count(*) as "MFA Not Enabled Users" from aws_iam_user where not mfa_enabled
  EOQ
}

query "aws_iam_user_access_key_age_gt_90_days" {
  sql = <<-EOQ
  select
    count(distinct user_name) as "Users With Active Key Age > 90 Days"
  from
    aws_iam_access_key
  where
    create_date > now() - interval '90 days' and
    status = 'Active'
  EOQ
}


query "aws_iam_user_not_attached_to_groups" {
  sql = <<-EOQ
  select
    count(name) as "Users Not Attached to Groups"
  from
    aws_iam_user
  where
    groups is null
  EOQ
}

query "aws_iam_users_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(i.*) as "total"
    from
      aws_iam_user as i,
      aws_account as a
    where
      a.account_id = i.account_id
    group by
      account
    order by count(i.*) desc
  EOQ
}

query "aws_iam_user_by_path" {
  sql = <<-EOQ
    select
      path,
      count(name) as "total"
    from
      aws_iam_user
    group by
      path
  EOQ
}

query "aws_iam_user_password_last_used_gt_90_days" {
  sql = <<-EOQ
  select
    count(name) as "Password Not Used for 90 days and more"
  from
    aws.aws_iam_user
  where
    password_last_used is not null or
    password_last_used < now() - interval '90 days'
  EOQ
}

query "aws_iam_users_by_creation_month" {
  sql = <<-EOQ
    with users as (
      select
        title,
        create_date,
        to_char(create_date,
          'YYYY-MM') as creation_month
      from
        aws_iam_user
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(create_date)
                from users)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    users_by_month as (
      select
        creation_month,
        count(*)
      from
        users
      group by
        creation_month
    )
    select
      months.month,
      users_by_month.count
    from
      months
      left join users_by_month on months.month = users_by_month.creation_month
    order by
      months.month desc;
  EOQ
}

query "aws_iam_user_mfa_enabled_by_account" {
  sql = <<-EOQ
    select
       a.title as "account",
       count(name)::numeric as "MFA Enabled"
    from
      aws_iam_user as c,
      aws_account as a
    where
      a.account_id = c.account_id and mfa_enabled
    group by
      account
    order by
      account
  EOQ
}

query "aws_iam_user_with_inline_policies_by_account" {
  sql = <<-EOQ
    select
       a.title as "account",
       count(name)::numeric as "Inline Policies Enabled"
    from
      aws_iam_user as c,
      aws_account as a
    where
      a.account_id = c.account_id and inline_policies is not null
    group by
      account
    order by
      account
  EOQ
}

query "aws_iam_user_having_administrator_access_by_account" {
  sql = <<-EOQ
    with users_having_admin_access as (
      select
        name,
        account_id,
        split_part(attachments, '/', 2) as attached_policies
      from
        aws_iam_user
        cross join jsonb_array_elements_text(attached_policy_arns) as attachments
      where
        split_part(attachments, '/', 2) = 'AdministratorAccess'
    ) select
      a.title as "account",
      count(name)::numeric as "Administrator Access"
    from
      users_having_admin_access as c,
      aws_account as a
    where
      a.account_id = c.account_id
    group by
      account
    order by
      account
  EOQ
}


report "aws_iam_user_dashboard" {

  title = "AWS IAM User Dashboard"

  container {

    # Analysis
    card {
      sql   = query.aws_iam_user_count.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_mfa_not_enabled_users_count.sql
      width = 2
    }

    # Assessments
    card {
      sql   = query.aws_iam_user_not_attached_to_groups.sql
      width = 2
    }

    card {
      sql   = query.aws_iam_user_access_key_age_gt_90_days.sql
      width = 3
    }

    card {
      sql   = query.aws_iam_user_password_last_used_gt_90_days.sql
      width = 3
    }
  }

  container {
    title = "Analysis"

    chart {
      title = "Users by Account"
      sql   = query.aws_iam_users_by_account.sql
      type  = "column"
      width = 4
    }
    chart {
      title = "Users by Path"
      sql   = query.aws_iam_user_by_path.sql
      type  = "column"
      width = 4
    }
  }

  container {
    title = "Assesments"

    chart {
      title = "MFA Enabled Users by Account"
      sql   = query.aws_iam_user_mfa_enabled_by_account.sql
      type  = "donut"
      width = 4
    }
    chart {
      title = "Users with inline policies by Account"
      sql   = query.aws_iam_user_with_inline_policies_by_account.sql
      type  = "donut"
      width = 4
    }
    chart {
      title = "Users having Administrator access by Account"
      sql   = query.aws_iam_user_having_administrator_access_by_account.sql
      type  = "donut"
      width = 4
    }
  }

  container {
    title = "Resources by Age"

    chart {
      title = "Users by Creation Month"
      sql   = query.aws_iam_users_by_creation_month.sql
      type  = "column"
      width = 4

      series "month" {
        color = "green"
      }
    }

    table {
      title = "Oldest Users"
      width = 4

      sql = <<-EOQ
        select
          title as "user",
          (current_date - create_date)::text as "Age in Days",
          account_id as "Account"
        from
          aws_iam_user
        order by
          "Age in Days" desc,
          title
        limit 5
      EOQ
    }

    table {
      title = "Newest Users"
      width = 4

      sql = <<-EOQ
        select
          title as "user",
          current_date - create_date as "Age in Days",
          account_id as "Account"
        from
          aws_iam_user
        order by
          "Age in Days" asc,
          title
        limit 5
      EOQ
    }
  }
}
