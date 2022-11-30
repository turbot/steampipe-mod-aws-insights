dashboard "s3_bucket_public_access_report" {

  title = "AWS S3 Bucket Public Access Report"

  tags = merge(local.s3_common_tags, {
    type     = "Report"
    category = "Public Access"
  })

  container {

    card {
      query = query.s3_bucket_count
      width = 2
    }

    card {
      query = query.s3_bucket_public_policy_count
      width = 2
    }

    card {
      query = query.s3_bucket_block_public_acls_disabled_count
      width = 2
    }

    card {
      query = query.s3_bucket_block_public_policy_disabled_count
      width = 2
    }

    card {
      query = query.s3_bucket_ignore_public_acls_disabled_count
      width = 2
    }

    card {
      query = query.s3_bucket_restrict_public_buckets_disabled_count
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

    column "Name" {
      href = "${dashboard.s3_bucket_detail.url_path}?input.bucket_arn={{.ARN | @uri}}"
    }

    query = query.s3_bucket_public_access_table
  }

}

query "s3_bucket_public_policy_count" {
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

query "s3_bucket_block_public_acls_disabled_count" {
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

query "s3_bucket_block_public_policy_disabled_count" {
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

query "s3_bucket_ignore_public_acls_disabled_count" {
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

query "s3_bucket_restrict_public_buckets_disabled_count" {
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

query "s3_bucket_public_access_table" {
  sql = <<-EOQ
    select
      b.name as "Name",
      case when b.bucket_policy_is_public then 'Public' else 'Not public' end as "Bucket Policy Public",
      case when b.block_public_acls then 'Enabled' else null end as "Block Public ACLs",
      case when b.block_public_policy then 'Enabled' else null end as "Block Public Policy",
      case when b.ignore_public_acls then 'Enabled' else null end as "Ignore Public ACLs",
      case when b.restrict_public_buckets then 'Enabled' else null end as "Restrict Public Buckets",
      a.title as "Account",
      b.account_id as "Account ID",
      b.region as "Region",
      b.arn as "ARN"
    from
      aws_s3_bucket as b,
      aws_account as a
    where
      b.account_id = a.account_id
    order by
      b.name;
  EOQ
}
