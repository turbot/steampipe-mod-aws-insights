dashboard "aws_dynamodb_table_encryption_report" {
  title = "AWS DynamoDB Table Encryption Report"

  container {
    card {
      sql = <<-EOQ
        select
          count(*) as value,
          'Encrypted with Default Key' as label
        from
          aws_dynamodb_table
        where
          sse_description is null
          or sse_description ->> 'SSEType' is null;
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql = <<-EOQ
        select
          count(*) as value,
          'Encrypted with AWS Managed Key' as label
        from
          aws_dynamodb_table as t,
          aws_kms_key as k
        where
          k.arn = t.sse_description ->> 'KMSMasterKeyArn'
          and sse_description is not null
          and sse_description ->> 'SSEType' = 'KMS'
          and k.key_manager = 'AWS';
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql = <<-EOQ
        select
          count(*) as value,
          'Encrypted with CMK' as label
        from
          aws_dynamodb_table as t,
          aws_kms_key as k
        where
          k.arn = t.sse_description ->> 'KMSMasterKeyArn'
          and sse_description is not null
          and sse_description ->> 'SSEType' = 'KMS'
          and k.key_manager = 'CUSTOMER';
      EOQ
      width = 2
      type  = "info"
    }
  }

  table {
    sql = <<-EOQ
      select
        t.name as "Name",
        case
          when t.sse_description ->> 'SSEType' = 'KMS' and k.key_manager = 'AWS' then 'AWS Managed'
          when t.sse_description ->> 'SSEType' = 'KMS' and k.key_manager = 'CUSTOMER' then 'Customer Managed'
          else 'DEFAULT'
        end as "Type",
        t.sse_description ->> 'KMSMasterKeyArn' as "Key ARN",
        t.account_id as "Account",
        t.region as "Region",
        t.arn as "ARN"
      from
        aws_dynamodb_table as t
        left join aws_kms_key as k on t.sse_description ->> 'KMSMasterKeyArn' = k.arn;
    EOQ
  }
}
