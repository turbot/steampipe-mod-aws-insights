dashboard "aws_s3_bucket_detail" {

  title = "AWS S3 Bucket Detail"

  tags = merge(local.s3_common_tags, {
    type = "Detail"
  })

  input "bucket_arn" {
    title = "Select a bucket:"
    sql   = query.aws_s3_bucket_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_s3_bucket_versioning
      args = {
        arn = self.input.bucket_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_s3_bucket_versioning_mfa
      args = {
        arn = self.input.bucket_arn.value
      }
    }

    card {
      query = query.aws_s3_bucket_logging_enabled
      width = 2
      args = {
        arn = self.input.bucket_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_s3_bucket_encryption
      args = {
        arn = self.input.bucket_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_s3_bucket_cross_region_replication
      args = {
        arn = self.input.bucket_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_s3_bucket_https_enforce
      args = {
        arn = self.input.bucket_arn.value
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
        query = query.aws_s3_bucket_overview
        args = {
          arn = self.input.bucket_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_s3_bucket_tags_detail
        param "arn" {}
        args = {
          arn = self.input.bucket_arn.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Public Access"
        query = query.aws_s3_bucket_public_access
        args = {
          arn = self.input.bucket_arn.value
        }
      }

      table {
        title = "Logging"
        query = query.aws_s3_bucket_logging
        args = {
          arn = self.input.bucket_arn.value
        }
      }

    }

    container {
      width = 12
      table {
        title = "Policy"
        query = query.aws_s3_bucket_policy
        args = {
          arn = self.input.bucket_arn.value
        }
      }
    }

    container {
      width = 12
      table {
        title = "Lifecycle Rules"
        query = query.aws_s3_bucket_lifecycle_policy
        args = {
          arn = self.input.bucket_arn.value
        }
      }
    }

    container {
      width = 12
      table {
        title = "Server Side Encryption"
        query = query.aws_s3_bucket_server_side_encryption
        args = {
          arn = self.input.bucket_arn.value
        }
      }
    }

  }

}
query "aws_s3_bucket_input" {
  sql = <<EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_s3_bucket
    order by
      title;
  EOQ
}

query "aws_s3_bucket_versioning" {
  sql = <<-EOQ
    select
      'Versioning' as label,
      case when versioning_enabled then 'Enabled' else 'Disabled' end as value,
      case when versioning_enabled then 'ok' else 'alert' end as type
    from
      aws_s3_bucket
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_s3_bucket_versioning_mfa" {
  sql = <<-EOQ
    select
      'Versioning MFA' as label,
      case when versioning_mfa_delete then 'Enabled' else 'Disabled' end as value,
      case when versioning_mfa_delete then 'ok' else 'alert' end as type
    from
      aws_s3_bucket
    where
      arn = $1;
  EOQ

  param "arn" {}
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
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_s3_bucket_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when server_side_encryption_configuration is not null then 'Enabled' else 'Disabled' end as value,
      case when server_side_encryption_configuration is not null then 'ok' else 'alert' end as type
    from
      aws_s3_bucket
    where
      arn = $1;
  EOQ

  param "arn" {}
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
      'Cross-Region Replication' as label,
      case when b.name = r.name and r.rep_status = 'Enabled' then 'Enabled' else 'Disabled' end as value,
      case when b.name = r.name and r.rep_status = 'Enabled' then 'ok' else 'alert' end as type
    from
      aws_s3_bucket b
      left join bucket_with_replication r  on b.name = r.name
    where
      arn = $1;
  EOQ

  param "arn" {}
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
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_s3_bucket_overview" {
  sql = <<-EOQ
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
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_s3_bucket_tags_detail" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_s3_bucket,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_s3_bucket_server_side_encryption" {
  sql = <<-EOQ
    select
      rules -> 'ApplyServerSideEncryptionByDefault' -> 'KMSMasterKeyID' as "KMS Master Key ID",
      rules -> 'ApplyServerSideEncryptionByDefault' ->> 'SSEAlgorithm' as "SSE Algorithm",
      rules -> 'BucketKeyEnabled'  as "Bucket Key Enabled"
    from
      aws_s3_bucket,
      jsonb_array_elements(server_side_encryption_configuration -> 'Rules') as rules
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_s3_bucket_logging" {
  sql = <<-EOQ
    select
      logging ->> 'TargetBucket' as "Target Bucket",
      logging ->> 'TargetPrefix' as "Target Prefix",
      logging ->> 'TargetPrefix' as "Target Grants"
    from
      aws_s3_bucket
    where
      arn = $1;
  EOQ

  param "arn" {}
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
      arn = $1;
  EOQ

  param "arn" {}
}


query "aws_s3_bucket_policy" {
  sql = <<-EOQ
    select
      p ->> 'Sid' as "SID",
      p -> 'Action' as "Action",
      p ->> 'Effect' as "Effect",
      p -> 'Principal' as "Principal",
      p -> 'Resource' as "Resource",
      p -> 'Condition' as "Condition"
    from
      aws_s3_bucket,
      jsonb_array_elements(policy_std -> 'Statement') as p
    where
      arn = $1
    order by p ->> 'SID';
  EOQ

  param "arn" {}
}

query "aws_s3_bucket_lifecycle_policy" {
  sql = <<-EOQ
    select
      r ->> 'ID' as "ID",
      r ->> 'AbortIncompleteMultipartUpload' as "Abort Incomplete Multipart Upload",
      r ->> 'Expiration' as "Expiration",
      r ->> 'Filter' as "Filter",
      r ->> 'NoncurrentVersionExpiration' as "Non-current Version Expiration",
      r ->> 'Prefix' as "Prefix",
      r ->> 'Status' as "Status",
      r ->> 'Transitions' as "Transitions"
    from
      aws_s3_bucket,
      jsonb_array_elements(lifecycle_rules) as r
    where
      arn = $1
    order by
      r ->> 'ID';
  EOQ

  param "arn" {}
}
