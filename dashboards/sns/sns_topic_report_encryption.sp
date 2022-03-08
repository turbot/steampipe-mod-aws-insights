dashboard "aws_sns_topic_encryption_report" {

  title         = "AWS SNS Topic Encryption Report"
  documentation = file("./dashboards/sns/docs/sns_topic_report_encryption.md")

  tags = merge(local.sns_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      sql   = query.aws_sns_topic_count.sql
      width = 2
    }

    card {
      sql   = query.aws_sns_topic_encrypted_count.sql
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

    sql = query.aws_sns_topic_encryption_table.sql
  }

}

query "aws_sns_topic_encryption_table" {
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
