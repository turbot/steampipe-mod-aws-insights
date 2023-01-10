dashboard "s3_bucket_detail" {

  title         = "AWS S3 Bucket Detail"
  documentation = file("./dashboards/s3/docs/s3_bucket_detail.md")

  tags = merge(local.s3_common_tags, {
    type = "Detail"
  })

  input "bucket_arn" {
    title = "Select a bucket:"
    query = query.s3_bucket_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.s3_bucket_public
      args  = [self.input.bucket_arn.value]
    }

    card {
      width = 2
      query = query.s3_bucket_versioning
      args  = [self.input.bucket_arn.value]
    }

    card {
      query = query.s3_bucket_logging_enabled
      width = 2
      args  = [self.input.bucket_arn.value]
    }

    card {
      width = 2
      query = query.s3_bucket_encryption
      args  = [self.input.bucket_arn.value]
    }

    card {
      width = 2
      query = query.s3_bucket_cross_region_replication
      args  = [self.input.bucket_arn.value]
    }

    card {
      width = 2
      query = query.s3_bucket_https_enforce
      args  = [self.input.bucket_arn.value]
    }

  }

  with "bucket_policy_stds_for_s3_bucket" {
    query = query.bucket_policy_stds_for_s3_bucket
    args  = [self.input.bucket_arn.value]
  }

  with "cloudtrail_trails_for_s3_bucket" {
    query = query.cloudtrail_trails_for_s3_bucket
    args  = [self.input.bucket_arn.value]
  }

  with "ec2_application_load_balancers_for_s3_bucket" {
    query = query.ec2_application_load_balancers_for_s3_bucket
    args  = [self.input.bucket_arn.value]
  }

  with "ec2_classic_load_balancers_for_s3_bucket" {
    query = query.ec2_classic_load_balancers_for_s3_bucket
    args  = [self.input.bucket_arn.value]
  }

  with "ec2_network_load_balancers_for_s3_bucket" {
    query = query.ec2_network_load_balancers_for_s3_bucket
    args  = [self.input.bucket_arn.value]
  }

  with "logging_source_s3_buckets_for_s3_bucket" {
    query = query.logging_source_s3_buckets_for_s3_bucket
    args  = [self.input.bucket_arn.value]
  }

  with "kms_keys_for_s3_bucket" {
    query = query.kms_keys_for_s3_bucket
    args  = [self.input.bucket_arn.value]
  }

  with "lambda_functions_for_s3_bucket" {
    query = query.lambda_functions_for_s3_bucket
    args  = [self.input.bucket_arn.value]
  }

  with "sns_topics_for_s3_bucket" {
    query = query.sns_topics_for_s3_bucket
    args  = [self.input.bucket_arn.value]
  }

  with "sqs_queues_for_s3_bucket" {
    query = query.sqs_queues_for_s3_bucket
    args  = [self.input.bucket_arn.value]
  }

  with "logging_destination_s3_buckets_for_s3_bucket" {
    query = query.logging_destination_s3_buckets_for_s3_bucket
    args  = [self.input.bucket_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"


      node {
        base = node.cloudtrail_trail
        args = {
          cloudtrail_trail_arns = with.cloudtrail_trails_for_s3_bucket.rows[*].trail_arn
        }
      }

      node {
        base = node.ec2_application_load_balancer
        args = {
          ec2_application_load_balancer_arns = with.ec2_application_load_balancers_for_s3_bucket.rows[*].alb_arn
        }
      }

      node {
        base = node.ec2_classic_load_balancer
        args = {
          ec2_classic_load_balancer_arns = with.ec2_classic_load_balancers_for_s3_bucket.rows[*].clb_arn
        }
      }

      node {
        base = node.ec2_network_load_balancer
        args = {
          ec2_network_load_balancer_arns = with.ec2_network_load_balancers_for_s3_bucket.rows[*].nlb_arn
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys_for_s3_bucket.rows[*].key_arn
        }
      }

      node {
        base = node.lambda_function
        args = {
          lambda_function_arns = with.lambda_functions_for_s3_bucket.rows[*].function_arn
        }
      }

      node {
        base = node.s3_bucket
        args = {
          s3_bucket_arns = [self.input.bucket_arn.value]
        }
      }

      node {
        base = node.s3_bucket
        args = {
          s3_bucket_arns = with.logging_source_s3_buckets_for_s3_bucket.rows[*].bucket_arn
        }
      }

      node {
        base = node.s3_bucket
        args = {
          s3_bucket_arns = with.logging_destination_s3_buckets_for_s3_bucket.rows[*].bucket_arn
        }
      }

      node {
        base = node.sns_topic
        args = {
          sns_topic_arns = with.sns_topics_for_s3_bucket.rows[*].topic_arn
        }
      }

      node {
        base = node.sqs_queue
        args = {
          sqs_queue_arns = with.sqs_queues_for_s3_bucket.rows[*].queue_arn
        }
      }

      edge {
        base = edge.cloudtrail_trail_to_s3_bucket
        args = {
          cloudtrail_trail_arns = with.cloudtrail_trails_for_s3_bucket.rows[*].trail_arn
        }
      }

      edge {
        base = edge.ec2_application_load_balancer_to_s3_bucket
        args = {
          ec2_application_load_balancer_arns = with.ec2_application_load_balancers_for_s3_bucket.rows[*].alb_arn
        }
      }

      edge {
        base = edge.ec2_classic_load_balancer_to_s3_bucket
        args = {
          ec2_classic_load_balancer_arns = with.ec2_classic_load_balancers_for_s3_bucket.rows[*].clb_arn
        }
      }

      edge {
        base = edge.ec2_network_load_balancer_to_s3_bucket
        args = {
          ec2_network_load_balancer_arns = with.ec2_network_load_balancers_for_s3_bucket.rows[*].nlb_arn
        }
      }

      edge {
        base = edge.s3_bucket_to_kms_key
        args = {
          s3_bucket_arns = [self.input.bucket_arn.value]
        }
      }

      edge {
        base = edge.s3_bucket_to_lambda_function
        args = {
          s3_bucket_arns = [self.input.bucket_arn.value]
        }
      }

      edge {
        base = edge.s3_bucket_to_s3_bucket
        args = {
          s3_bucket_arns = [self.input.bucket_arn.value]
        }
      }

      edge {
        base = edge.s3_bucket_to_s3_bucket
        args = {
          s3_bucket_arns = with.logging_source_s3_buckets_for_s3_bucket.rows[*].bucket_arn
        }
      }

      edge {
        base = edge.s3_bucket_to_sns_topic
        args = {
          s3_bucket_arns = [self.input.bucket_arn.value]
        }
      }

      edge {
        base = edge.s3_bucket_to_sqs_queue
        args = {
          s3_bucket_arns = [self.input.bucket_arn.value]
        }
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
        query = query.s3_bucket_overview
        args  = [self.input.bucket_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.s3_bucket_tags_detail
        args  = [self.input.bucket_arn.value]
      }
    }

    container {
      width = 6

      table {
        title = "Public Access"
        query = query.s3_bucket_public_access
        args  = [self.input.bucket_arn.value]
      }

      table {
        title = "Logging"
        query = query.s3_bucket_logging
        args  = [self.input.bucket_arn.value]
      }

    }

    container {
      width = 12
      table {
        title = "Lifecycle Rules"
        query = query.s3_bucket_lifecycle_policy
        args  = [self.input.bucket_arn.value]
      }
    }

    container {
      width = 12
      table {
        title = "Server Side Encryption"
        query = query.s3_bucket_server_side_encryption
        args  = [self.input.bucket_arn.value]
      }
    }

    graph {
      title = "Resource Policy"
      base  = graph.iam_resource_policy_structure
      args = {
        policy_std = with.bucket_policy_stds_for_s3_bucket.rows[0].policy_std
      }
    }
  }

}

# Input queries

query "s3_bucket_input" {
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

# With queries

query "cloudtrail_trails_for_s3_bucket" {
  sql = <<-EOQ
    select
      distinct trail.arn as trail_arn
    from
      aws_cloudtrail_trail as trail,
      aws_s3_bucket as b
    where
      b.arn = $1
      and trail.s3_bucket_name = b.name;
  EOQ
}

query "ec2_application_load_balancers_for_s3_bucket" {
  sql = <<-EOQ
    select
      alb.arn as alb_arn
    from
      aws_ec2_application_load_balancer as alb,
      jsonb_array_elements(alb.load_balancer_attributes) as attributes,
      aws_s3_bucket as b
    where
      b.arn = $1
      and attributes ->> 'Key' = 'access_logs.s3.bucket'
      and attributes ->> 'Value' = b.name;
  EOQ
}

query "ec2_classic_load_balancers_for_s3_bucket" {
  sql = <<-EOQ
    select
      clb.arn as clb_arn
    from
      aws_ec2_classic_load_balancer clb,
      aws_s3_bucket as b
    where
      b.arn = $1
      and clb.access_log_s3_bucket_name = b.name;
  EOQ
}

query "ec2_network_load_balancers_for_s3_bucket" {
  sql = <<-EOQ
    select
      nlb.arn as nlb_arn
    from
      aws_ec2_network_load_balancer as nlb,
      jsonb_array_elements(nlb.load_balancer_attributes) as attributes,
      aws_s3_bucket as b
    where
      b.arn = $1
      and attributes ->> 'Key' = 'access_logs.s3.bucket'
      and attributes ->> 'Value' = b.name;
  EOQ
}

query "logging_source_s3_buckets_for_s3_bucket" {
  sql = <<-EOQ
    select
      lb.arn as bucket_arn
    from
      aws_s3_bucket as lb,
      aws_s3_bucket as b
    where
      b.arn = $1
      and lb.logging ->> 'TargetBucket' = b.name;
  EOQ
}

query "kms_keys_for_s3_bucket" {
  sql = <<-EOQ
    select
      k.arn as key_arn
    from
      aws_s3_bucket as b
      cross join jsonb_array_elements(server_side_encryption_configuration -> 'Rules') as r
      join aws_kms_key as k
      on k.arn = r -> 'ApplyServerSideEncryptionByDefault' ->> 'KMSMasterKeyID'
    where
      b.arn = $1;
  EOQ
}

query "lambda_functions_for_s3_bucket" {
  sql = <<-EOQ
    select
      t ->> 'LambdaFunctionArn' as function_arn
    from
      aws_s3_bucket as b,
      jsonb_array_elements(event_notification_configuration -> 'LambdaFunctionConfigurations') as t
    where
      event_notification_configuration -> 'LambdaFunctionConfigurations' <> 'null'
      and b.arn = $1;
  EOQ
}

query "bucket_policy_stds_for_s3_bucket" {
  sql = <<-EOQ
    select
      policy_std
    from
      aws_s3_bucket
    where
      arn = $1;
  EOQ
}

query "sns_topics_for_s3_bucket" {
  sql = <<-EOQ
    select
      t ->> 'TopicArn' as topic_arn
    from
      aws_s3_bucket as b,
      jsonb_array_elements(
        case jsonb_typeof(event_notification_configuration -> 'TopicConfigurations')
          when 'array' then (event_notification_configuration -> 'TopicConfigurations')
          else null end
        )
        as t
    where
      b.arn = $1;
  EOQ
}

query "sqs_queues_for_s3_bucket" {
  sql = <<-EOQ
    select
      q.queue_arn as queue_arn
    from
      aws_s3_bucket as b,
      jsonb_array_elements(
        case jsonb_typeof(event_notification_configuration -> 'QueueConfigurations')
          when 'array' then (event_notification_configuration -> 'QueueConfigurations')
          else null end
        )
        as t
      left join aws_sqs_queue as q on q.queue_arn = t ->> 'QueueArn'
    where
      q.queue_arn is not null
      and b.arn = $1;
  EOQ
}

query "logging_destination_s3_buckets_for_s3_bucket" {
  sql = <<-EOQ
    select
      lb.arn as bucket_arn
    from
      aws_s3_bucket as lb,
      aws_s3_bucket as b
    where
      b.arn = $1
      and lb.name = b.logging ->> 'TargetBucket';
  EOQ
}

# Card queries

query "s3_bucket_versioning" {
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
}

query "s3_bucket_public" {
  sql = <<-EOQ
    select
      'Public Access' as label,
      case when block_public_acls and block_public_policy and ignore_public_acls and restrict_public_buckets then 'Disabled' else 'Enabled' end as value,
      case when block_public_acls and block_public_policy and ignore_public_acls and restrict_public_buckets then 'ok' else 'alert' end as type
    from
      aws_s3_bucket
    where
      arn = $1;
  EOQ
}

query "s3_bucket_logging_enabled" {
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
}

query "s3_bucket_encryption" {
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
}

query "s3_bucket_cross_region_replication" {
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
}

query "s3_bucket_https_enforce" {
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
      case when s.name is not null then 'Enforced' else 'Not Enforced' end as value,
      case when s.name is not null then 'ok' else 'alert' end as type
    from
      aws_s3_bucket as b
      left join ssl_ok as s on s.name = b.name
    where
      arn = $1;
  EOQ
}

# Other detail page queries

query "s3_bucket_overview" {
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
}

query "s3_bucket_tags_detail" {
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
}

query "s3_bucket_server_side_encryption" {
  sql = <<-EOQ
    select
      rules -> 'ApplyServerSideEncryptionByDefault' ->> 'KMSMasterKeyID' as "KMS Master Key ID",
      rules -> 'ApplyServerSideEncryptionByDefault' ->> 'SSEAlgorithm' as "SSE Algorithm",
      rules -> 'BucketKeyEnabled'  as "Bucket Key Enabled"
    from
      aws_s3_bucket,
      jsonb_array_elements(server_side_encryption_configuration -> 'Rules') as rules
    where
      arn = $1;
  EOQ
}

query "s3_bucket_logging" {
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
}

query "s3_bucket_public_access" {
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
}

query "s3_bucket_lifecycle_policy" {
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
}
