dashboard "sns_topic_encryption_report" {

  title         = "AWS SNS Topic Encryption Report"
  documentation = file("./dashboards/sns/docs/sns_topic_report_encryption.md")

  tags = merge(local.sns_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      query = query.sns_topic_count
      width = 3
    }

    card {
      query = query.sns_topic_encrypted_count
      width = 3
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    column "ARN" {
      display = "none"
    }

    column "Topic" {
      href = "${dashboard.sns_topic_detail.url_path}?input.topic_arn={{.ARN | @uri}}"
    }

    query = query.sns_topic_encryption_table
  }

}

query "sns_topic_encryption_table" {
  sql = <<-EOQ
    select
      t.title as "Topic",
      case when kms_master_key_id is not null then 'Enabled' else null end as "Encryption",
      t.kms_master_key_id as "KMS Key ID",
      a.title as "Account",
      t.account_id as "Account ID",
      t.region as "Region",
      t.topic_arn as "ARN"
    from
      aws_sns_topic as t,
      aws_account as a
    where
      t.account_id = a.account_id
    order by
      t.title;
  EOQ
}
