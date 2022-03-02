dashboard "aws_s3_bucket_public_access_report" {

  title = "AWS S3 Bucket Public Access Report"

  tags = merge(local.s3_common_tags, {
    type     = "Report"
    category = "Public Access"
  })

  container {

    card {
      sql   = query.aws_s3_bucket_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_public_policy_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_block_public_acls_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_block_public_policy_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_ignore_public_acls_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.aws_s3_bucket_restrict_public_buckets_disabled_count.sql
      width = 2
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = query.aws_s3_bucket_public_access_table.sql

  }

}

query "aws_s3_bucket_public_policy_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Has Public Bucket Policy' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_s3_bucket
    where
    -- if true then bucket is public
      bucket_policy_is_public;
  EOQ
}

query "aws_s3_bucket_block_public_acls_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'New Public ACLs Allowed' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_s3_bucket
    where
      not block_public_acls;
  EOQ
}

query "aws_s3_bucket_block_public_policy_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'New Public Bucket Policies Allowed' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_s3_bucket
    where
      not block_public_policy;
  EOQ
}

query "aws_s3_bucket_ignore_public_acls_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public ACLs Not Ignored' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_s3_bucket
    where
      not ignore_public_acls;
  EOQ
}

query "aws_s3_bucket_restrict_public_buckets_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public Bucket Policies Unrestricted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_s3_bucket
    where
      not restrict_public_buckets;
  EOQ
}

query "aws_s3_bucket_public_access_table" {
  sql = <<-EOQ
    select
      v.name as "Name",
      case when v.bucket_policy_is_public then 'Public' else 'Not public' end as "Bucket Policy Public",
      case when v.block_public_acls then 'Enabled' else null end as "Block Public ACLs",
      case when v.block_public_policy then 'Enabled' else null end as "Block Public Policy",
      case when v.ignore_public_acls then 'Enabled' else null end as "Ignore Public ACLs",
      case when v.restrict_public_buckets then 'Enabled' else null end as "Restrict Public Buckets",
      a.title as "Account",
      v.account_id as "Account ID",
      v.region as "Region",
      v.arn as "ARN"
    from
      aws_s3_bucket as v,
      aws_account as a
    where
      v.account_id = a.account_id;
  EOQ
}
