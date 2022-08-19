dashboard "aws_s3_bucket_detail" {

  title         = "AWS S3 Bucket Detail"
  documentation = file("./dashboards/s3/docs/s3_bucket_detail.md")

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

    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_s3_bucket_relationships
      args = {
        arn = self.input.bucket_arn.value
      }
      category "aws_s3_bucket" {
        icon = local.aws_s3_bucket_icon
        href = "/aws_insights.dashboard.aws_s3_bucket_detail?input.bucket_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_cloudtrail_trail" {
        icon = local.aws_cloudtrail_trail_icon
        href = "/aws_insights.dashboard.aws_cloudtrail_trail_detail?input.trail_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_ec2_application_load_balancer" {
        icon = local.aws_ec2_application_load_balancer_icon
        href = "/aws_insights.dashboard.aws_ec2_application_load_balancer_detail?input.arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_ec2_network_load_balancer" {
        icon = local.aws_ec2_application_load_balancer_icon
        href = "/aws_insights.dashboard.aws_ec2_network_load_balancer_detail?input.arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_ec2_classic_load_balancer" {
        icon = local.aws_ec2_classic_load_balancer_icon
        href = "/aws_insights.dashboard.aws_ec2_classic_load_balancer_detail?input.arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_s3_access_point" {
        icon = local.aws_s3_access_point_icon
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
  sql = <<-EOQ
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

query "aws_s3_bucket_relationships_graph" {
  sql = <<-EOQ
    with buckets as
    (
      select
        *
      from
        aws_s3_bucket
      where
        arn = $1
    )
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'Name', buckets.name,
        'ARN', buckets.arn,
        'Account ID', buckets.account_id,
        'Region', buckets.region
      ) as properties
    from
      buckets

    -- Cloudtrail (node)
    union all
    select
      null as from_id,
      null as to_id,
      trail.arn as id,
      trail.title as title,
      'aws_cloudtrail_trail' as category,
      jsonb_build_object(
        'ARN', trail.arn,
        'Account ID', trail.account_id,
        'Region', trail.region,
        'Latest Delivery Time', trail.latest_delivery_time
      ) as properties
    from
      aws_cloudtrail_trail as trail,
      buckets as b
    where
      trail.s3_bucket_name = b.name

    -- Cloudtrail - edges
    union all
    select
      trail.arn as from_id,
      b.arn as to_id,
      null as id,
      'logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', trail.arn,
        'Account ID', trail.account_id,
        'Region', trail.region,
        'Log Prefix', trail.s3_key_prefix,
        'Latest Delivery Time', trail.latest_delivery_time
      ) as properties
    from
      aws_cloudtrail_trail as trail,
      buckets as b
    where
      trail.s3_bucket_name = b.name

    -- S3 Buckets that log to me (node)
    union all
    select
      null as from_id,
      null as to_id,
      aws_s3_bucket.arn as id,
      aws_s3_bucket.title as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'Name', aws_s3_bucket.name,
        'ARN', aws_s3_bucket.arn,
        'Account ID', aws_s3_bucket.account_id,
        'Region', aws_s3_bucket.region
      ) as properties
    from
      aws_s3_bucket,
      buckets
    where
      aws_s3_bucket.logging ->> 'TargetBucket' = buckets.name

    -- Buckets that log to me - edges
    union all
    select
      aws_s3_bucket.arn as to_id,
      buckets.arn as from_id,
      null as id,
      'logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'Name', aws_s3_bucket.name,
        'ARN', aws_s3_bucket.arn,
        'Account ID', aws_s3_bucket.account_id,
        'Region', aws_s3_bucket.region
      ) as properties
    from
      aws_s3_bucket,
      buckets
    where
      aws_s3_bucket.logging ->> 'TargetBucket' = buckets.name

    -- EC2 Application LB (node)
    union all
    select
      null as from_id,
      null as to_id,
      alb.arn as id,
      alb.title as title,
      'aws_ec2_application_load_balancer' as category,
      jsonb_build_object(
        'Name', alb.name,
        'ARN', alb.arn,
        'Account ID', alb.account_id,
        'Region', alb.region
      ) as properties
    from
      aws_ec2_application_load_balancer alb,
      jsonb_array_elements(alb.load_balancer_attributes) as attributes,
      buckets
    where
      attributes ->> 'Key' = 'access_logs.s3.bucket'
      and attributes ->> 'Value' = buckets.name

    -- ALBs that log to me - edges
    union all
    select
      alb.arn as from_id,
      buckets.arn as to_id,
      null as id,
      'logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'Name', alb.name,
        'ARN', alb.arn,
        'Account ID', alb.account_id,
        'Region', alb.region,
        'Log to', attributes ->> 'Value',
        'Log Prefix', (
          select
            a ->> 'Value'
          from
            jsonb_array_elements(alb.load_balancer_attributes) as a
          where
            a ->> 'Key' = 'access_logs.s3.prefix'
        )
      ) as properties
    from
      aws_ec2_application_load_balancer alb,
      jsonb_array_elements(alb.load_balancer_attributes) as attributes,
      buckets
    where
      attributes ->> 'Key' = 'access_logs.s3.bucket'
      and attributes ->> 'Value' = buckets.name

    -- EC2 Network LB (node)
    union all
    select
      null as from_id,
      null as to_id,
      nlb.arn as id,
      nlb.title as title,
      'aws_ec2_network_load_balancer' as category,
      jsonb_build_object(
        'Name', nlb.name,
        'ARN', nlb.arn,
        'Account ID', nlb.account_id,
        'Region', nlb.region,
        'Log to', attributes ->> 'Value'
      ) as properties
    from
      aws_ec2_network_load_balancer nlb,
      jsonb_array_elements(nlb.load_balancer_attributes) as attributes,
      buckets
    where
      attributes ->> 'Key' = 'access_logs.s3.bucket'
      and attributes ->> 'Value' = buckets.name

    -- NLBs that log to me - edges
    union all
    select
      nlb.arn as from_id,
      buckets.arn as to_id,
      null as id,
      'logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'Name', nlb.name,
        'ARN', nlb.arn,
        'Account ID', nlb.account_id,
        'Region', nlb.region,
        'logs to', attributes ->> 'Value', 'Log Prefix',
      (
        select
          a ->> 'Value'
        from
          jsonb_array_elements(nlb.load_balancer_attributes) as a
        where
          a ->> 'Key' = 'access_logs.s3.prefix'
      )
      ) as properties
    from
      aws_ec2_network_load_balancer nlb,
      jsonb_array_elements(nlb.load_balancer_attributes) as attributes,
      buckets
    where
      attributes ->> 'Key' = 'access_logs.s3.bucket'
      and attributes ->> 'Value' = buckets.name

    -- EC2 Classic LB (node)
    union all
    select
      null as from_id,
      null as to_id,
      clb.arn as id,
      clb.title as title,
      'aws_ec2_classic_load_balancer' as category,
      jsonb_build_object(
        'Name', clb.name,
        'ARN', clb.arn,
        'Account ID', clb.account_id,
        'Region', clb.region,
        'Log Prefix', clb.access_log_s3_bucket_prefix
      ) as properties
    from
      aws_ec2_classic_load_balancer clb,
      buckets
    where
      clb.access_log_s3_bucket_name = buckets.name

    -- CLBs that log to me - edges
    union all
    select
      clb.arn as from_id,
      buckets.arn as to_id,
      null as id,
      'logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'Name', clb.name,
        'ARN', clb.arn,
        'Account ID', clb.account_id,
        'Region', clb.region,
        'Log Prefix', clb.access_log_s3_bucket_prefix
      ) as properties
    from
      aws_ec2_classic_load_balancer clb,
      buckets
    where
      clb.access_log_s3_bucket_name = buckets.name

    -- S3 Access Points (node)
    union all
    select
      null as from_id,
      null as to_id,
      ap.access_point_arn as id,
      ap.title as title,
      'aws_s3_access_point' as category,
      jsonb_build_object(
        'Name', ap.name,
        'ARN', ap.access_point_arn,
        'Account ID', ap.account_id,
        'Region', ap.region
      ) as properties
    from
      aws_s3_access_point ap,
      buckets
    where
      ap.bucket_name = buckets.name
      and ap.region = buckets.region

    -- Access Point that come to me - edges
    union all
    select
      ap.access_point_arn as from_id,
      buckets.arn as to_id,
      null as id,
      'accesses' as title,
      'uses' as category,
      jsonb_build_object(
        'Name', ap.name,
        'ARN', ap.access_point_arn,
        'Account ID', ap.account_id,
        'Region', ap.region
      ) as properties
    from
      aws_s3_access_point ap,
      buckets
    where
      ap.bucket_name = buckets.name
      and ap.region = buckets.region

    -- S3 Buckets (node)
    union all
    select
      null as from_id,
      null as to_id,
      aws_s3_bucket.arn as id,
      aws_s3_bucket.title as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'Name', aws_s3_bucket.name,
        'ARN', aws_s3_bucket.arn,
        'Account ID', aws_s3_bucket.account_id,
        'Region', aws_s3_bucket.region
      ) as properties
    from
      aws_s3_bucket,
      buckets
    where
      aws_s3_bucket.name = buckets.logging ->> 'TargetBucket'

    -- Buckets I log to - edges
    union all
    select
      buckets.arn as from_id,
      aws_s3_bucket.arn as to_id,
      null as id,
      'logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'Name', aws_s3_bucket.name,
        'ARN', aws_s3_bucket.arn,
        'Account ID', aws_s3_bucket.account_id,
        'Region', aws_s3_bucket.region
      ) as properties
    from
      aws_s3_bucket,
      buckets
    where
      aws_s3_bucket.name = buckets.logging ->> 'TargetBucket'
    order by
      category,
      id,
      from_id,
      to_id

  EOQ

  param "arn" {}
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
      account_id as "Account ID",
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
      block_public_acls as "Block New Public ACLs",
      block_public_policy as "Block New Public Bucket Policies",
      ignore_public_acls as "Public ACLs Ignored",
      restrict_public_buckets as "Public Bucket Policies Restricted"
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
