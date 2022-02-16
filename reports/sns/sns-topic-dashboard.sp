query "aws_sns_topic_count" {
  sql = <<-EOQ
    select count(*) as "Topics" from aws_sns_topic
  EOQ
}

query "aws_sns_topic_encrypted_count" {
  sql = <<-EOQ
    select count(*) as "Unencrypted Topics" from aws_sns_topic where kms_master_key_id is null
  EOQ
}

query "aws_sns_topic_by_account" {
  sql = <<-EOQ


    select 
      a.title as "account",
      count(i.*) as "total"
    from 
      aws_sns_topic as i,
      aws_account as a 
    where 
      a.account_id = i.account_id
    group by
      account
    order by count(i.*) desc

  EOQ
}

query "aws_sns_topic_by_region" {
  sql = <<-EOQ
    select 
      region,
      count(i.*) as total
    from 
      aws_sns_topic as i
    group by
      region
  EOQ
}

query "aws_sns_topic_cost_per_month" {
  sql = <<-EOQ
    select 
       to_char(period_start, 'Mon-YY') as "Month", 
       sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from 
      aws_cost_by_service_usage_type_monthly 
    where 
      service = 'Amazon Simple Notification Service'
    group by 
      period_start
    order by 
      period_start
  EOQ
}

query "aws_sns_topic_cost_by_usage_types_12mo" {
  sql = <<-EOQ
    select 
       usage_type, 
       sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from 
      aws_cost_by_service_usage_type_monthly 
    where 
      service = 'Amazon Simple Notification Service'
      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
    group by 
      usage_type
    order by 
      sum(unblended_cost_amount) desc
  EOQ
}

query "aws_sns_topic_cost_by_usage_types_30day" {
  sql = <<-EOQ
    select 
       usage_type, 
       sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from 
      aws_cost_by_service_usage_type_daily 
    where 
      service = 'Amazon Simple Notification Service'
      --and period_end >= date_trunc('month', CURRENT_DATE::timestamp)
      and period_end >=  CURRENT_DATE - INTERVAL '30 day'

    group by 
      usage_type
    order by 
      sum(unblended_cost_amount) desc
  EOQ
}

query "aws_sns_topic_cost_by_account_30day" {
  sql = <<-EOQ
    select 
       a.title as "account",
       sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from 
      aws_cost_by_service_monthly as c,
      aws_account as a
    where 
      a.account_id = c.account_id
      and service = 'Amazon Simple Notification Service'
      and period_end >=  CURRENT_DATE - INTERVAL '30 day'
    group by 
      account
    order by 
      account
  EOQ
}

query "aws_sns_topic_cost_by_account_12mo" {
  sql = <<-EOQ
    select 
       a.title as "account",
       sum(unblended_cost_amount)::numeric::money as "Unblended Cost"
    from 
      aws_cost_by_service_monthly as c,
      aws_account as a
    where 
      a.account_id = c.account_id
      and service = 'Amazon Simple Notification Service'
      and period_end >=  CURRENT_DATE - INTERVAL '1 year'
    group by 
      account
    order by 
      account
  EOQ
}

query "aws_sns_topic_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select kms_master_key_id,
        case when kms_master_key_id is not null then
          'Enabled'
        else
          'Disabled'
        end encryption_status
      from
        aws_sns_topic) as t
    group by
      encryption_status
    order by
      encryption_status desc
  EOQ
}


query "aws_sns_topic_by_subscription_status" {
  sql = <<-EOQ
    select
      count(*)
    from (
      select subscriptions_confirmed,
        case when subscriptions_confirmed::int = 0 then
          'Alarm'
        else
          'Ok'
        end subscription_status
      from
        aws_sns_topic) as t
    group by
      subscription_status
    order by
      subscription_status desc
  EOQ
}

dashboard "aws_sns_topic_dashboard" {
    title = "AWS SNS Topic Dashboard"
    container {
        card {
            sql   = query.aws_sns_topic_count.sql
            width = 6
        }
        card {
            sql   = query.aws_sns_topic_encrypted_count.sql
            width = 6
        }
    }
    container {
        title = "Analysis"

        chart {
            title = "Topics by Account"
            sql   = query.aws_sns_topic_by_account.sql
            type  = "column"
            width = 6
        }
        chart {
            title = "Topics by Region"
            sql   = query.aws_sns_topic_by_region.sql
            type  = "line"
            width = 6
        }
    }

    container {
        title = "Costs"

    chart {
      title = "SNS Monthly Cost"
      type  = "line"
      sql   = query.aws_sns_topic_cost_per_month.sql
      width = 4
    }  
   chart {
      title = "SNS Cost by Usage Type - last 30 days"
      type  = "donut"
      sql   = query.aws_sns_topic_cost_by_usage_types_30day.sql
      width = 2
    }
    
   chart {
      title = "SNS Cost by Usage Type - Last 12 months"
      type  = "donut"
      sql   = query.aws_sns_topic_cost_by_usage_types_12mo.sql
      width = 2
    }


    chart {
      title = "By Account - MTD"
      type  = "donut"
      sql   = query.aws_sns_topic_cost_by_account_30day.sql
       width = 2
    }

    chart {
      title = "By Account - Last 12 months"
      type  = "donut"
      sql   = query.aws_sns_topic_cost_by_account_12mo.sql
      width = 2
    }
    }

    container {
      title = "Assessments"

    chart {
      title = "Encryption Status"
      sql = query.aws_sns_topic_by_encryption_status.sql
      type  = "donut"
      width = 3

      series "Enabled" {
         color = "green"
      } 
    } 
    chart {
      title = "Subscription Status"
      sql = query.aws_sns_topic_by_subscription_status.sql
      type  = "donut"
      width = 3
    }
    }
}