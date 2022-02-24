dashboard "aws_sns_topic_encryption_report" {

  title = "AWS SNS Topic Encryption Report"

  container {

    card {
      sql   = query.aws_sns_topic_count.sql
      width = 2
    }

    card {
      sql = query.aws_sns_topic_encrypted_count.sql
      width = 2
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = <<-EOQ
      select
        r.title as "Topic",
        case when kms_master_key_id is not null then 'Enabled' else null end as "Encryption",
        r.kms_master_key_id as "KMS Key ID",
        a.title as "Account",
        r.account_id as "Account ID",
        r.region as "Region",
        r.topic_arn as "ARN"
      from
        aws_sns_topic as r,
        aws_account as a
      where
        r.account_id = a.account_id
    EOQ

  }
  
}