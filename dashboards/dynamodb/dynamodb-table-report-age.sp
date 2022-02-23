dashboard "aws_dynamodb_table_age_report" {
  title = "AWS DynamoDB Table Age Report"

   container {
    card {
      sql   = query.aws_dynamodb_table_count.sql
      width = 2
    }

    card {
      width = 2
      type  = "info"
      sql   = <<-EOQ
        select
          count(*) as value,
          '< 24 hours' as label
        from
          aws_dynamodb_table
        where
          creation_date_time > now() - '1 days' :: interval;
      EOQ
    }

    card {
      width = 2
      type  = "info"
      sql   = <<-EOQ
        select
          count(*) as value,
          '1-30 Days' as label
        from
          aws_dynamodb_table
        where
          creation_date_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
      EOQ
    }

    card {
      width = 2
      type  = "info"
      sql   = <<-EOQ
        select
          count(*) as value,
          '30-90 Days' as label
        from
          aws_dynamodb_table
        where
          creation_date_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
      EOQ
    }

    card {
      width = 2
      type  = "info"
      sql   = <<-EOQ
        select
          count(*) as value,
          '90-365 Days' as label
        from
          aws_dynamodb_table
        where
          creation_date_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
      EOQ
    }

    card {
      width = 2
      type  = "info"
      sql   = <<-EOQ
        select
          count(*) as value,
          '> 1 Year' as label
        from
          aws_dynamodb_table
        where
          creation_date_time <= now() - '1 year' :: interval;
      EOQ
    }
  }

  container {
    table {
      column "Account ID" {
        display = "none"
      }

      sql = <<-EOQ
        select
          v.name as "Name",
          now()::date - v.creation_date_time::date as "Age in Days",
          v.creation_date_time as "Create Time",
          v.table_status as "State",
          a.title as "Account",
          v.account_id as "Account ID",
          v.region as "Region",
          v.arn as "ARN"
        from
          aws_dynamodb_table as v,
          aws_account as a
        where
          v.account_id = a.account_id
        order by
          v.creation_date_time,
          v.title;
      EOQ
    }
  }
}
