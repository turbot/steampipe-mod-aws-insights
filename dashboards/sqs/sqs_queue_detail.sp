dashboard "aws_sqs_queue_detail" {
  title = "AWS SQS Queue Detail"

  tags = merge(local.sqs_common_tags, {
    type = "Detail"
  })


  input "queue_arn" {
    title = "Select a Queue:"
    sql   = query.aws_sqs_queue_input.sql
    width = 4
  }

  container {

    card {
      width = 2

      query = query.aws_sqs_queue_encryption
      args = {
        queue_arn = self.input.queue_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_sqs_queue_content_based_deduplication
      args = {
        queue_arn = self.input.queue_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_sqs_queue_delay_seconds
      args = {
        queue_arn = self.input.queue_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_sqs_queue_message_retention_seconds
      args = {
        queue_arn = self.input.queue_arn.value
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
        query = query.aws_sqs_queue_overview
        args = {
          queue_arn = self.input.queue_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_sqs_queue_tags_detail
        args = {
          queue_arn = self.input.queue_arn.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Message Details"
        query = query.aws_sqs_queue_message
        args = {
          queue_arn = self.input.queue_arn.value
        }
      }

      table {
        title = "Encryption Details"
        query = query.aws_sqs_queue_encryption_details
        args = {
          queue_arn = self.input.queue_arn.value
        }
      }
    }

  }

  container {
    width = 12

    table {
      title = "Policy"
      query = query.aws_sqs_queue_policy
      args = {
        queue_arn = self.input.queue_arn.value
      }
    }

  }

}
query "aws_sqs_queue_input" {
  sql = <<EOQ
    select
      title as label,
      queue_arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_sqs_queue
    order by
      title;
  EOQ
}

query "aws_sqs_queue_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when kms_master_key_id is not null then 'Enabled' else 'Disabled' end as value,
      case when kms_master_key_id is not null then 'ok' else 'alert' end as "type"
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_content_based_deduplication" {
  sql = <<-EOQ
    select
      'Content Based Deduplication' as label,
      content_based_deduplication as value
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_delay_seconds" {
  sql = <<-EOQ
    select
      'Delay Seconds' as label,
      delay_seconds as value
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_message_retention_seconds" {
  sql = <<-EOQ
    select
      'Message Retention Seconds' as label,
      message_retention_seconds as value
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_overview" {
  sql = <<-EOQ
    select
      queue_url as "Queue URL",
      title as "Title",
      region as "Region",
      account_id as "Account Id",
      queue_arn as "ARN"
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_tags_detail" {
  sql = <<-EOQ
    select
      js.key,
      js.value
    from
      aws_sqs_queue,
      jsonb_each(tags) as js
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_policy" {
  sql = <<-EOQ
    select
      p -> 'Action'  as "Action",
      p ->> 'Effect' as "Effect",
      p -> 'Principal' as "Principal",
      p -> 'Resource' as "Resource",
      p ->> 'Sid' as "Sid"
    from
      aws_sqs_queue,
      jsonb_array_elements(policy_std -> 'Statement') as p
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_message" {
  sql = <<-EOQ
    select
      max_message_size  as "Max Message Size",
      message_retention_seconds as "Message Retention Seconds",
      visibility_timeout_seconds as "Visibility Timeout Seconds"
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}

query "aws_sqs_queue_encryption_details" {
  sql = <<-EOQ
    select
       case when kms_master_key_id is not null then 'Enabled' else 'Disabled' end as "Encryption",
       kms_master_key_id as "KMS Master Key ID"
    from
      aws_sqs_queue
    where
      queue_arn = $1;
  EOQ

  param "queue_arn" {}
}
