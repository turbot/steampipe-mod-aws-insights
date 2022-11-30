dashboard "sqs_queue_encryption_report" {

  title         = "AWS SQS Queue Encryption Report"
  documentation = file("./dashboards/sqs/docs/sqs_queue_report_encryption.md")

  tags = merge(local.sqs_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      query = query.sqs_queue_count
      width = 2
    }

    card {
      query = query.sqs_queue_unencrypted_count
      width = 2
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "Queue" {
      href = "${dashboard.sqs_queue_detail.url_path}?input.queue_arn={{.ARN | @uri}}"
    }

    query = query.sqs_queue_encryption_table
  }

}

query "sqs_queue_encryption_table" {
  sql = <<-EOQ
    select
      q.title as "Queue",
      case when kms_master_key_id is not null or sqs_managed_sse_enabled then 'Enabled' else null end as "Encryption",
      q.kms_master_key_id as "KMS Key ID",
      q.sqs_managed_sse_enabled as "SQS Managed SSE",
      a.title as "Account",
      q.account_id as "Account ID",
      q.region as "Region",
      q.queue_arn as "ARN"
    from
      aws_sqs_queue as q,
      aws_account as a
    where
      q.account_id = a.account_id
    order by
      q.title;
  EOQ
}
