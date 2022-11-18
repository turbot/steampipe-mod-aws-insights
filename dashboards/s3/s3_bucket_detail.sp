dashboard "aws_s3_bucket_detail" {

  title         = "AWS S3 Bucket Detail"
  documentation = file("./dashboards/s3/docs/s3_bucket_detail.md")

  tags = merge(local.s3_common_tags, {
    type = "Detail"
  })

  input "bucket_arn" {
    title = "Select a bucket:"
    query = query.aws_s3_bucket_input
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
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_s3_bucket_node,
        node.aws_s3_bucket_from_cloudtrail_trail_node,
        node.aws_s3_bucket_from_s3_bucket_node,
        node.aws_s3_bucket_from_ec2_alb_node,
        node.aws_s3_bucket_from_ec2_nlb_node,
        node.aws_s3_bucket_from_ec2_clb_node,
        node.aws_s3_bucket_from_s3_access_point_node,
        node.aws_s3_bucket_to_s3_bucket_node
      ]

      edges = [
        edge.aws_s3_bucket_from_cloudtrail_trail_edge,
        edge.aws_s3_bucket_from_s3_bucket_edge,
        edge.aws_s3_bucket_from_ec2_alb_edge,
        edge.aws_s3_bucket_from_ec2_nlb_edge,
        edge.aws_s3_bucket_from_ec2_clb_edge,
        edge.aws_s3_bucket_from_s3_access_point_edge,
        edge.aws_s3_bucket_to_s3_bucket_edge
      ]

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

node "aws_s3_bucket_node" {
  category = category.aws_s3_bucket

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_s3_bucket
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_s3_bucket_from_cloudtrail_trail_node" {
  category = category.aws_cloudtrail_trail

  sql = <<-EOQ
    select
      trail.arn as id,
      trail.title as title,
      jsonb_build_object(
        'ARN', trail.arn,
        'Account ID', trail.account_id,
        'Region', trail.region,
        'Latest Delivery Time', trail.latest_delivery_time
      ) as properties
    from
      aws_cloudtrail_trail as trail,
      aws_s3_bucket as b
    where
      b.arn = $1
      and trail.s3_bucket_name = b.name;
  EOQ

  param "arn" {}
}

edge "aws_s3_bucket_from_cloudtrail_trail_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      trail.arn as from_id,
      b.arn as to_id
    from
      aws_cloudtrail_trail as trail,
      aws_s3_bucket as b
    where
      b.arn = $1
      and trail.s3_bucket_name = b.name;
  EOQ

  param "arn" {}
}

node "aws_s3_bucket_from_s3_bucket_node" {
  category = category.aws_s3_bucket

  sql = <<-EOQ
    select
      lb.arn as id,
      lb.title as title,
      jsonb_build_object(
        'Name', lb.name,
        'ARN', lb.arn,
        'Account ID', lb.account_id,
        'Region', lb.region
      ) as properties
    from
      aws_s3_bucket as lb,
      aws_s3_bucket as b
    where
      b.arn = $1
      and lb.logging ->> 'TargetBucket' = b.name;
  EOQ

  param "arn" {}
}

edge "aws_s3_bucket_from_s3_bucket_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      b.arn as to_id,
      lb.arn as from_id
    from
      aws_s3_bucket as lb,
      aws_s3_bucket as b
    where
      b.arn = $1
      and lb.logging ->> 'TargetBucket' = b.name;
  EOQ

  param "arn" {}
}

node "aws_s3_bucket_from_ec2_alb_node" {
  category = category.aws_ec2_application_load_balancer

  sql = <<-EOQ
    select
      alb.arn as id,
      alb.title as title,
      jsonb_build_object(
        'Name', alb.name,
        'ARN', alb.arn,
        'Account ID', alb.account_id,
        'Region', alb.region
      ) as properties
    from
      aws_ec2_application_load_balancer alb,
      jsonb_array_elements(alb.load_balancer_attributes) as attributes,
      aws_s3_bucket as b
    where
      b.arn = $1
      and attributes ->> 'Key' = 'access_logs.s3.bucket'
      and attributes ->> 'Value' = b.name;
  EOQ

  param "arn" {}
}

edge "aws_s3_bucket_from_ec2_alb_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      alb.arn as from_id,
      b.arn as to_id,
      jsonb_build_object(
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
      aws_s3_bucket as b
    where
      b.arn = $1
      and attributes ->> 'Key' = 'access_logs.s3.bucket'
      and attributes ->> 'Value' = b.name;
  EOQ

  param "arn" {}
}

node "aws_s3_bucket_from_ec2_nlb_node" {
  category = category.aws_ec2_network_load_balancer

  sql = <<-EOQ
    select
      nlb.arn as id,
      nlb.title as title,
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
      aws_s3_bucket as b
    where
      b.arn = $1
      and attributes ->> 'Key' = 'access_logs.s3.bucket'
      and attributes ->> 'Value' = b.name;
  EOQ

  param "arn" {}
}

edge "aws_s3_bucket_from_ec2_nlb_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      nlb.arn as from_id,
      b.arn as to_id,
      jsonb_build_object(
        'Log Prefix', (
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
      aws_s3_bucket as b
    where
      b.arn = $1
      and attributes ->> 'Key' = 'access_logs.s3.bucket'
      and attributes ->> 'Value' = b.name;
  EOQ

  param "arn" {}
}

node "aws_s3_bucket_from_ec2_clb_node" {
  category = category.aws_ec2_classic_load_balancer

  sql = <<-EOQ
    select
      clb.arn as id,
      clb.title as title,
      jsonb_build_object(
        'Name', clb.name,
        'ARN', clb.arn,
        'Account ID', clb.account_id,
        'Region', clb.region,
        'Log Prefix', clb.access_log_s3_bucket_prefix
      ) as properties
    from
      aws_ec2_classic_load_balancer clb,
      aws_s3_bucket as b
    where
      b.arn = $1
      and clb.access_log_s3_bucket_name = b.name;
  EOQ

  param "arn" {}
}

edge "aws_s3_bucket_from_ec2_clb_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      clb.arn as from_id,
      b.arn as to_id,
      jsonb_build_object(
        'Log Prefix', clb.access_log_s3_bucket_prefix
      ) as properties
    from
      aws_ec2_classic_load_balancer clb,
      aws_s3_bucket as b
    where
      b.arn = $1
      and clb.access_log_s3_bucket_name = b.name
  EOQ

  param "arn" {}
}

node "aws_s3_bucket_from_s3_access_point_node" {
  category = category.aws_s3_access_point

  sql = <<-EOQ
    select
      ap.access_point_arn as id,
      ap.title as title,
      jsonb_build_object(
        'Name', ap.name,
        'ARN', ap.access_point_arn,
        'Account ID', ap.account_id,
        'Region', ap.region
      ) as properties
    from
      aws_s3_access_point ap,
      aws_s3_bucket as b
    where
      b.arn = $1
      and ap.bucket_name = b.name
      and ap.region = b.region;
  EOQ

  param "arn" {}
}

edge "aws_s3_bucket_from_s3_access_point_edge" {
  title = "access point"

  sql = <<-EOQ
    select
      ap.access_point_arn as from_id,
      b.arn as to_id
    from
      aws_s3_access_point ap,
      aws_s3_bucket as b
    where
      b.arn = $1
      and ap.bucket_name = b.name
      and ap.region = b.region;
  EOQ

  param "arn" {}
}

node "aws_s3_bucket_to_s3_bucket_node" {
  category = category.aws_s3_bucket

  sql = <<-EOQ
    select
      lb.arn as id,
      lb.title as title,
      jsonb_build_object(
        'Name', lb.name,
        'ARN', lb.arn,
        'Account ID', lb.account_id,
        'Region', lb.region
      ) as properties
    from
      aws_s3_bucket as lb,
      aws_s3_bucket as b
    where
      b.arn = $1
      and lb.name = b.logging ->> 'TargetBucket';
  EOQ

  param "arn" {}
}

edge "aws_s3_bucket_to_s3_bucket_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      b.arn as from_id,
      lb.arn as to_id
    from
      aws_s3_bucket as lb,
      aws_s3_bucket as b
    where
      b.arn = $1
      and lb.name = b.logging ->> 'TargetBucket';
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
