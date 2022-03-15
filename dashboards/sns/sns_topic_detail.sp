dashboard "aws_sns_topic_detail" {

  title         = "AWS SNS Topic Detail"
  documentation = file("./dashboards/sns/docs/sns_topic_detail.md")

  tags = merge(local.sns_common_tags, {
    type = "Detail"
  })

  input "topic_arn" {
    title = "Select a topic:"
    sql   = query.aws_sns_topic_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_sns_topic_encryption_status
      args = {
        arn = self.input.topic_arn.value
      }
    }

    card {
      query = query.aws_sns_topic_subscriptions_confirmed_count
      width = 2
      args = {
        arn = self.input.topic_arn.value
      }
    }

  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.aws_sns_topic_overview
        args = {
          arn = self.input.topic_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_sns_topic_tags
        args = {
          arn = self.input.topic_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Subscriptions"
        query = query.aws_sns_topic_subscriptions
        args = {
          arn = self.input.topic_arn.value
        }
      }

    }

    container {
      width = 12

      table {
        title = "Effective Delivery Policy"
        query = query.aws_sns_topic_delivery_policy
        args = {
          arn = self.input.topic_arn.value
        }
      }

      table {
        title = "Policy"
        query = query.aws_sns_topic_policy_standard
        args = {
          arn = self.input.topic_arn.value
        }
      }
    }

  }
}

query "aws_sns_topic_input" {
  sql = <<EOQ
    select
      topic_arn as label,
      topic_arn as value
    from
      aws_sns_topic
    order by
      topic_arn;
EOQ
}

query "aws_sns_topic_encryption_status" {
  sql = <<-EOQ
    select
      case when kms_master_key_id is not null then 'Enabled' else 'Disabled' end as value,
      'Encryption' as label,
      case when kms_master_key_id is not null then 'ok' else 'alert' end as "type"
    from
      aws_sns_topic
    where
      topic_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_sns_topic_subscriptions_confirmed_count" {
  sql = <<-EOQ
    select
      subscriptions_confirmed::int as value,
      'Confirmed Subscriptions' as label,
      case when subscriptions_confirmed::int = 0 then 'alert' else 'ok' end as "type"
    from
      aws_sns_topic
    where
      topic_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_sns_topic_overview" {
  sql = <<-EOQ
    select
      display_name as "Display Name",
      owner as "Owner",
      kms_master_key_id as "KMS Key ID",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      topic_arn as "ARN"
    from
      aws_sns_topic
    where
      topic_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_sns_topic_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_sns_topic,
      jsonb_array_elements(tags_src) as tag
    where
      topic_arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_sns_topic_subscriptions" {
  sql = <<EOQ
    select
      subscriptions_confirmed as "Confirmed",
      subscriptions_deleted as "Deleted",
      subscriptions_pending as "Pending"
    from
      aws_sns_topic
    where
      topic_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_sns_topic_delivery_policy" {
  sql = <<EOQ
    select
      effective_delivery_policy -> 'http' -> 'defaultHealthyRetryPolicy' ->> 'numRetries' as "Retries",
      effective_delivery_policy -> 'http' -> 'defaultHealthyRetryPolicy' ->> 'maxDelayTarget' as "Maximum Delay Target",
      effective_delivery_policy -> 'http' -> 'defaultHealthyRetryPolicy' ->> 'minDelayTarget' as "Minimum Delay Target",
      effective_delivery_policy -> 'http' -> 'defaultHealthyRetryPolicy' ->> 'backoffFunction' as "Backoff Function",
      effective_delivery_policy -> 'http' -> 'defaultHealthyRetryPolicy' ->> 'numNoDelayRetries' as "No Delay Retries",
      effective_delivery_policy -> 'http' -> 'defaultHealthyRetryPolicy' ->> 'numMaxDelayRetries' as "Maximum Delay Retries",
      effective_delivery_policy -> 'http' -> 'defaultHealthyRetryPolicy' ->> 'numMinDelayRetries' as "Minimum Delay Retries",
      (effective_delivery_policy -> 'http' -> 'disableSubscriptionOverrides')::boolean as "Disable Subscription Overrides"
    from
      aws_sns_topic
    where
      topic_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_sns_topic_policy_standard" {
  sql = <<EOQ
    select
      statement ->> 'Sid' as "SID",
      statement ->> 'Effect' as "Effect",
      statement ->> 'Principal' as "Principal",
      statement ->> 'Action' as "Action",
      statement ->> 'Resource' as "Resource"
    from
      aws_sns_topic as t,
      jsonb_array_elements(policy_std -> 'Statement') as statement
    where
      topic_arn = $1;
  EOQ

  param "arn" {}
}
