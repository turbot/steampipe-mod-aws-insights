dashboard "dynamodb_table_encryption_report" {

  title         = "AWS DynamoDB Table Encryption Report"
  documentation = file("./dashboards/dynamodb/docs/dynamodb_table_report_encryption.md")

  tags = merge(local.dynamodb_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      query = query.dynamodb_table_count
      width = 3
    }

    card {
      query = query.dynamodb_table_default_encryption
      width = 3
    }

    card {
      query = query.dynamodb_table_aws_managed_key_encryption
      width = 3
    }

    card {
      query = query.dynamodb_table_customer_managed_key_encryption
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

    column "Name" {
      href = "${dashboard.dynamodb_table_detail.url_path}?input.table_arn={{.ARN | @uri}}"
    }

    query = query.dynamodb_table_encryption_table
  }

}

query "dynamodb_table_default_encryption" {
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
}

query "dynamodb_table_aws_managed_key_encryption" {
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
}

query "dynamodb_table_customer_managed_key_encryption" {
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
}

query "dynamodb_table_encryption_table" {
  sql = <<-EOQ
    select
      t.name as "Name",
      case
        when t.sse_description ->> 'SSEType' = 'KMS' and k.key_manager = 'AWS' then 'AWS Managed'
        when t.sse_description ->> 'SSEType' = 'KMS' and k.key_manager = 'CUSTOMER' then 'Customer Managed'
        else 'Default'
      end as "Type",
      t.sse_description ->> 'KMSMasterKeyArn' as "Key ARN",
      a.title as "Account",
      t.account_id as "Account ID",
      t.region as "Region",
      t.arn as "ARN"
    from
      aws_dynamodb_table as t
      left join aws_kms_key as k on t.sse_description ->> 'KMSMasterKeyArn' = k.arn
      left join aws_account as a on t.account_id = a.account_id
    order by
      t.name;
  EOQ
}
