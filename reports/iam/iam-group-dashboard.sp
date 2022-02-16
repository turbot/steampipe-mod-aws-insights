query "aws_iam_group_count" {
  sql = <<-EOQ
    select count(*) as "Groups" from aws_iam_group
  EOQ
}

query "aws_iam_group_by_account" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(g.*) as "total"
    from
      aws_iam_group as g,
      aws_account as a
    where
      a.account_id = g.account_id
    group by
      account
    order by count(g.*) desc
  EOQ
}

query "aws_iam_group_by_path" {
  sql = <<-EOQ
    select
      path,
      count(name) as "total"
    from
      aws_iam_group
    group by
      path
  EOQ
}

query "aws_iam_group_with_inline_policies_by_account" {
  sql = <<-EOQ
    select
       a.title as "account",
       count(name)::numeric as "Inline Policies"
    from
      aws_iam_group as c,
      aws_account as a
    where
      a.account_id = c.account_id and inline_policies is not null
    group by
      account
    order by
      account
  EOQ
}

query "aws_iam_groups_with_administrator_policy_by_account" {
  sql = <<-EOQ
    with groups_having_admin_access as (
      select
        name,
        account_id,
        split_part(attachments, '/', 2) as attached_policies
      from
        aws_iam_group
        cross join jsonb_array_elements_text(attached_policy_arns) as attachments
      where
        split_part(attachments, '/', 2) = 'AdministratorAccess'
    ) select
      a.title as "account",
      count(name)::numeric as "Administrator Access"
    from
      groups_having_admin_access as c,
      aws_account as a
    where
      a.account_id = c.account_id
    group by
      account
    order by
      account
  EOQ
}

query "aws_iam_group_without_users" {
  sql = <<-EOQ
    select
      a.title as "account",
      count(name)::numeric as "Groups Without Users"
    from
      aws_iam_group as c,
      aws_account as a
    where
      a.account_id = c.account_id and users is null
    group by
      account
    order by
      account
  EOQ
}

query "aws_iam_groups_by_creation_month" {
  sql = <<-EOQ
    with groups as (
      select
        title,
        create_date,
        to_char(create_date,
          'YYYY-MM') as creation_month
      from
        aws_iam_group
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
                from groups)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    groups_by_month as (
      select
        creation_month,
        count(*)
      from
        groups
      group by
        creation_month
    )
    select
      months.month,
      groups_by_month.count
    from
      months
      left join groups_by_month on months.month = groups_by_month.creation_month
    order by
      months.month desc;
  EOQ
}

report "aws_iam_group_dashboard" {

  title = "AWS IAM Group Dashboard"

  container {
    card {
      sql   = query.aws_iam_group_count.sql
      width = 2
    }
  }

  container {
    title = "Analysis"

    chart {
      title = "Groups by Account"
      sql   = query.aws_iam_group_by_account.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Groups by Path"
      sql   = query.aws_iam_group_by_path.sql
      type  = "column"
      width = 4
    }
  }


  container {
    title = "Assesments"

    chart {
      title = "Groups With No User Associated"
      sql   = query.aws_iam_group_without_users.sql
      type  = "donut"
      width = 4
    }
    chart {
      title = "Groups with inline policies by Account"
      sql   = query.aws_iam_group_with_inline_policies_by_account.sql
      type  = "donut"
      width = 4
    }
    chart {
      title = "Groups attached with Administrator policy by Account"
      sql   = query.aws_iam_groups_with_administrator_policy_by_account.sql
      type  = "donut"
      width = 4
    }
  }


  container {
    title = "Resources by Age"

    chart {
      title = "Groups by Creation Month"
      sql   = query.aws_iam_groups_by_creation_month.sql
      type  = "column"
      width = 4

      series "month" {
        color = "green"
      }
    }

    table {
      title = "Oldest Groups"
      width = 4

      sql = <<-EOQ
        select
          title as "group",
          (current_date - create_date)::text as "Age in Days",
          account_id as "Account"
        from
          aws_iam_group
        order by
          "Age in Days" desc,
          title
        limit 5
      EOQ
    }

    table {
      title = "Newest Groups"
      width = 4

      sql = <<-EOQ
        select
          title as "group",
          current_date - create_date as "Age in Days",
          account_id as "Account"
        from
          aws_iam_group
        order by
          "Age in Days" asc,
          title
        limit 5
      EOQ
    }
  }
}
