dashboard aws_s3_bucket_detail {

  title = "AWS S3 Bucket Detail"

  tags = merge(local.s3_common_tags, {
    type = "Detail"
  })

  input "bucket_name" {
    title = "S3"
    sql   = <<-EOQ
      select
        name
      from
        aws_s3_bucket
    EOQ
    width = 2
  }

  container {
    # Analysis
    card {
      #title = "Size"
      sql   = query.aws_s3_bucket_access_points_count.sql
      width = 2
    }

    card {
      #title = "Size"
      sql   = query.aws_s3_bucket_versioning_enabled.sql
      width = 2
    }

    card {
      #title = "Size"
      sql   = query.aws_s3_bucket_logging_enabled.sql
      width = 2
    }

    card {
      #title = "Size"
      sql   = query.aws_s3_bucket_versioning_mfa_enabled.sql
      width = 2
    }

    card {
      #title = "Size"
      sql   = query.aws_s3_bucket_encryption_enabled.sql
      width = 2
    }

    card {
      #title = "Size"
      sql   = query.aws_s3_bucket_cross_region_replication.sql
      width = 2
    }

    card {
      #title = "Size"
      sql   = query.aws_s3_bucket_https_enforce.sql
      width = 2
    }

}

container {
    # title = "Overiew"

    container {

      table {
        title = "Overview"
        width = 6
        sql   = <<-EOQ
          select
            name as "Name",
            creation_date as "Creation Date",
            title as "Title",
            region as "Region",
            account_id as "Account Id",
            arn as "ARN"
          from
            aws_s3_bucket
              where
            name = 'aab-saea1-1t8oayt4mlkjv'
        EOQ
      }


      table {
        title = "Tags"
        width = 6

        sql   = <<-EOQ
        select
          tag ->> 'Key' as "Key",
          tag ->> 'Value' as "Value"
        from
          aws_s3_bucket,
          jsonb_array_elements(tags_src) as tag
        where
          name = 'aab-saea1-1t8oayt4mlkjv'
        EOQ
      }
    }
  }


   container {

    table {
      title = "Server Side Encryption"
      sql   = query.aws_s3_bucket_server_side_encryption.sql
      width = 6
    }

    table {
      title = "Public Access"
      sql   = query.aws_s3_bucket_public_access.sql
      width = 6
    }
  }

  container {
    table {
      title = "Policy"
      sql   = query.aws_s3_bucket_policy.sql
      width = 12
    }
  }

   container {
    table {
      title = "Lifecycle Rules"
      sql   = query.aws_s3_bucket_lifecycle_policy.sql
      width = 12
    }
  }

  container {
    table {
      title = "Logging"
      sql   = query.aws_s3_bucket_logging.sql
      width = 6
    }
  }
}

query "aws_s3_bucket_access_points_count" {
  sql = <<-EOQ
    select
      'Access Points' as label,
      count(*) as value,
      case when count(*) > 0 then 'ok' else 'alert' end as type
    from
      aws_s3_access_point
    where
      bucket_name = 'aws-cloudtrail-logs-533793682495-21293883'
  EOQ
}

query "aws_s3_bucket_versioning_enabled" {
    sql = <<-EOQ
      select
        'Versioning' as label,
        case when versioning_enabled then 'Enabled' else 'Disabled' end as value,
        case when versioning_enabled then 'ok' else 'alert' end as type
      from
        aws_s3_bucket
      where
        name = 'aab-saea1-1t8oayt4mlkjv'
  EOQ
}

query "aws_s3_bucket_logging_enabled" {
  sql = <<-EOQ
    select
      'Logging' as label,
      case when (logging -> 'TargetBucket') is not null then 'Enabled' else 'Disabled' end as value,
      case when (logging -> 'TargetBucket') is not null then 'ok' else 'alert' end as type
    from
      aws_s3_bucket
    where
      name = 'aab-saea1-1t8oayt4mlkjv'
 EOQ
}

query "aws_s3_bucket_versioning_mfa_enabled" {
  sql = <<-EOQ
    select
      'Versioning MFA' as label,
      case when versioning_mfa_delete then 'Enabled' else 'Disabled' end as value,
      case when versioning_mfa_delete then 'ok' else 'alert' end as type
    from
      aws_s3_bucket
    where
      name = 'aab-saea1-1t8oayt4mlkjv'
  EOQ
}

query "aws_s3_bucket_encryption_enabled" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when server_side_encryption_configuration is not null then 'Enabled' else 'Disabled' end as value,
      case when server_side_encryption_configuration is not null then 'ok' else 'alert' end as type
    from
      aws_s3_bucket
    where
      name = 'aab-saea1-1t8oayt4mlkjv'
  EOQ
}

query "aws_s3_bucket_logging" {
  sql = <<-EOQ
    select
      logging -> 'TargetBucket' as "Target Bucket",
      logging -> 'TargetPrefix' as "Target Prefix",
      logging -> 'TargetPrefix' as "Target Grants"
    from
      aws_s3_bucket
    where
      name = 'aab-saea1-1t8oayt4mlkjv'
  EOQ
}

query "aws_s3_bucket_cross_region_replication" {
  sql = <<-EOQ
    with bucket_with_replication as (
      select
        name,
        r ->> 'Status' as rep_status
      from
        aws_s3_bucket,
        jsonb_array_elements(replication -> 'Rules' ) as r
    )
    select
      'Cross Region Replication' as label,
      case when b.name = r.name and r.rep_status = 'Enabled' then 'Enabled' else 'Disabled' end as value,
      case when b.name = r.name and r.rep_status = 'Enabled' then 'ok' else 'alert' end as type
    from
      aws_s3_bucket b
      left join bucket_with_replication r  on b.name = r.name
    where
      b.name = 'aab-saea1-1t8oayt4mlkjv'
  EOQ
}

query "aws_s3_bucket_server_side_encryption" {
  sql = <<-EOQ
    select
      rules -> 'ApplyServerSideEncryptionByDefault' -> 'KMSMasterKeyID' as "KMSMasterKeyID",
      rules -> 'ApplyServerSideEncryptionByDefault' -> 'SSEAlgorithm' as "SSEAlgorithm",
      rules -> 'BucketKeyEnabled'  as "BucketKeyEnabled"
    from
      aws_s3_bucket,
      jsonb_array_elements(server_side_encryption_configuration -> 'Rules') as rules
    where
      name = 'cf-templates-wm0ztvc2sh3w-us-west-1'
  EOQ
}

query "aws_s3_bucket_public_access" {
  sql = <<-EOQ
    select
      bucket_policy_is_public as "Has Public Bucket Policy",
      block_public_acls as "New Public ACLs Allowed",
      block_public_policy as "New Public Bucket Policies Allowed",
      ignore_public_acls as "Public ACLs Not Ignored",
      restrict_public_buckets as "Unrestricted Public Bucket Policies"
    from
      aws_s3_bucket
    where
      name = 'cf-templates-wm0ztvc2sh3w-us-west-1'
  EOQ
}

query "aws_s3_bucket_https_enforce" {
    sql = <<-EOQ
    with ssl_ok as (
      select
        distinct name
      from
        aws_s3_bucket,
        jsonb_array_elements(policy_std -> 'Statement') as s,
        jsonb_array_elements_text(s -> 'Principal' -> 'AWS') as p,
        jsonb_array_elements_text(s -> 'Action') as a,
        jsonb_array_elements_text(s -> 'Resource') as r,
        jsonb_array_elements_text(
          s -> 'Condition' -> 'Bool' -> 'aws:securetransport'
        ) as ssl
      where
        p = '*'
        and s ->> 'Effect' = 'Deny'
        and ssl :: bool = false
    )
    select
      'HTTPS' as label,
      case when s.name is not null then 'Enabled' else 'Disabled' end as value,
      case when s.name is not null then 'ok' else 'alert' end as type
    from
      aws_s3_bucket as b
      left join ssl_ok as s on s.name = b.name
    where
      b.name = 'aab-saea1-1t8oayt4mlkjv'
  EOQ
}

query "aws_s3_bucket_policy" {
  sql = <<-EOQ
    select
      p -> 'Action'  as "Action",
      p -> 'Condition' as "Condition",
      p -> 'Effect'  as "Effect",
      p -> 'Principal'  as "Principal",
      p -> 'Resource'  as "Resource",
      p -> 'Sid'  as "Sid"
    from
      aws_s3_bucket,
      jsonb_array_elements(policy_std -> 'Statement') as p
    where
      name = 'codepipeline-ap-south-1-237305900706'
  EOQ
}

query "aws_s3_bucket_lifecycle_policy" {
  sql = <<-EOQ
    select
      r -> 'ID'  as "ID",
      r -> 'AbortIncompleteMultipartUpload'  as "AbortIncompleteMultipartUpload",
      r -> 'Expiration' as "Expiration",
      r -> 'Filter'  as "Filter",
      r -> 'NoncurrentVersionExpiration'  as "NoncurrentVersionExpiration",
      r -> 'Prefix'  as "Prefix",
      r -> 'Status'  as "Status",
      r -> 'Transitions'  as "Transitions"
    from
      aws_s3_bucket,
      jsonb_array_elements(lifecycle_rules) as r
    where
      name = 'aab-saea1-1t8oayt4mlkjv'
  EOQ
}
