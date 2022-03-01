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

query "aws_sns_topic_name" {
  sql = <<-EOQ
    select
      display_name as "Topic Name"
    from
      aws_sns_topic
    where
      topic_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_sns_topic_encryption_status" {
  sql = <<-EOQ
    select
      case when kms_master_key_id is not null then 'Enabled' else 'Disabled' end as value,
      'Encryption Status' as label,
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
      'Subscriptions Confirmed' as label,
      case when subscriptions_confirmed::int = 0 then 'alert' else 'ok' end as "type"
    from
      aws_sns_topic
    where
      topic_arn = $1;
  EOQ

  param "arn" {}
}

dashboard "aws_sns_topic_detail" {
  title = "AWS SNS Topic Detail"

  tags = merge(local.sns_common_tags, {
    type = "Detail"
  })

  input "topic_arn" {
    title = "Select a topic:"
    sql   = query.aws_sns_topic_input.sql
    width = 4
  }

  container {

    # Assessments
    card {
      width = 2

      query = query.aws_sns_topic_name
      args = {
        arn = self.input.topic_arn.value
      }
    }

    # Assessments
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

        sql = <<-EOQ
          select
            display_name as "Name",
            owner as "Owner",
            kms_master_key_id as "KMS Key ID",
            topic_arn as "ARN",
            account_id as "Account ID"
          from
            aws_sns_topic
          where
           topic_arn = $1;
        EOQ

        param "arn" {}

        args = {
          arn = self.input.topic_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6

        sql = <<-EOQ
          select
            tag ->> 'Key' as "Key",
            tag ->> 'Value' as "Value"
          from
            aws_sns_topic,
            jsonb_array_elements(tags_src) as tag
          where
            topic_arn = $1;
        EOQ

        param "arn" {}

        args = {
          arn = self.input.topic_arn.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Policies"
        sql   = <<-EOQ
          select
            display_name as "Name",
            policy_std ->> 'Id' as "Policy ID",
            policy_std ->> 'Version' as "Policy Version",
            jsonb_pretty(policy_std -> 'Statement') as "Policy Statement"
          from
            aws_sns_topic
          where
           topic_arn = $1;
        EOQ

        param "arn" {}

        args = {
          arn = self.input.topic_arn.value
        }
      }

    }

  }
}
