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
      query = query.aws_s3_bucket_public
      args = {
        arn = self.input.bucket_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_s3_bucket_versioning
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

      with "trails" {
        sql = <<-EOQ
          select
            trail.arn as trail_arn
          from
            aws_cloudtrail_trail as trail,
            aws_s3_bucket as b
          where
            b.arn = $1
            and trail.s3_bucket_name = b.name;
        EOQ

        args = [self.input.bucket_arn.value]
      }

      with "albs" {
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

        args = [self.input.bucket_arn.value]
      }

      with "nlbs" {
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

        args = [self.input.bucket_arn.value]
      }

      with "clbs" {
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

        args = [self.input.bucket_arn.value]
      }

      with "keys" {
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

        args = [self.input.bucket_arn.value]
      }

      with "functions" {
        sql = <<-EOQ
          select
            f.arn as function_arn
          from
            aws_s3_bucket as b,
            jsonb_array_elements(event_notification_configuration -> 'LambdaFunctionConfigurations') as t
            left join aws_lambda_function as f on f.arn = t ->> 'LambdaFunctionArn'
          where
            event_notification_configuration -> 'LambdaFunctionConfigurations' <> 'null'
            and b.arn = $1;
        EOQ

        args = [self.input.bucket_arn.value]
      }

      with "topics" {
        sql = <<-EOQ
          select
            q.topic_arn as topic_arn
          from
            aws_s3_bucket as b,
            jsonb_array_elements(
              case jsonb_typeof(event_notification_configuration -> 'TopicConfigurations')
                when 'array' then (event_notification_configuration -> 'TopicConfigurations')
                else null end
              )
              as t
            left join aws_sns_topic as q on q.topic_arn = t ->> 'TopicArn'
          where
            b.arn = $1;
        EOQ

        args = [self.input.bucket_arn.value]
      }

      with "queues" {
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
            b.arn = $1;
        EOQ

        args = [self.input.bucket_arn.value]
      }

      nodes = [
        node.s3_bucket,
        node.cloudtrail_trail,
        node.ec2_application_load_balancer,
        node.ec2_network_load_balancer,
        node.ec2_classic_load_balancer,
        node.kms_key,
        node.lambda_function,
        node.sns_topic,
        node.sqs_queue,
        node.s3_bucket_from_s3_bucket,
        node.s3_bucket_to_s3_bucket
        # node.s3_bucket_from_s3_access_point_node,
      ]

      edges = [
        edge.s3_bucket_from_cloudtrail_trail,
        edge.s3_bucket_from_ec2_alb,
        edge.s3_bucket_from_ec2_nlb,
        edge.s3_bucket_from_ec2_clb,
        edge.s3_bucket_to_kms_key,
        edge.s3_bucket_to_lambda_function,
        edge.s3_bucket_to_sns_topic,
        edge.s3_bucket_to_sqs_queue,
        edge.s3_bucket_from_s3_bucket,
        edge.s3_bucket_to_s3_bucket
        # #edge.s3_bucket_from_s3_access_point_edge,
      ]

      args = {
        bucket_arns   = [self.input.bucket_arn.value]
        trail_arns    = with.trails.rows[*].trail_arn
        alb_arns      = with.albs.rows[*].alb_arn
        nlb_arns      = with.nlbs.rows[*].nlb_arn
        clb_arns      = with.clbs.rows[*].clb_arn
        key_arns      = with.keys.rows[*].key_arn
        function_arns = with.functions.rows[*].function_arn
        topic_arns    = with.topics.rows[*].topic_arn
        queue_arns    = with.queues.rows[*].queue_arn
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

node "s3_bucket" {
  category = category.s3_bucket

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
      arn = any($1);
  EOQ

  param "bucket_arns" {}
}

edge "s3_bucket_from_cloudtrail_trail" {
  title = "logs to"

  sql = <<-EOQ
    select
      trail_arn as from_id,
      bucket_arn as to_id
    from
      unnest($1::text[]) as bucket_arn,
      unnest($2::text[]) as trail_arn
  EOQ

  param "bucket_arns" {}
  param "trail_arns" {}
}

edge "s3_bucket_from_ec2_alb" {
  title = "logs to"

  sql = <<-EOQ
    select
      alb_arn as from_id,
      bucket_arn as to_id
    from
      unnest($1::text[]) as bucket_arn,
      unnest($2::text[]) as alb_arn
  EOQ

  param "bucket_arns" {}
  param "alb_arns" {}
}

edge "s3_bucket_from_ec2_nlb" {
  title = "logs to"

  sql = <<-EOQ
    select
      nlb_arn as from_id,
      bucket_arn as to_id
    from
      unnest($1::text[]) as bucket_arn,
      unnest($2::text[]) as nlb_arn
  EOQ

  param "bucket_arns" {}
  param "nlb_arns" {}
}

edge "s3_bucket_from_ec2_clb" {
  title = "logs to"

  sql = <<-EOQ
    select
      clb_arn as from_id,
      bucket_arn as to_id
    from
      unnest($1::text[]) as bucket_arn,
      unnest($2::text[]) as clb_arn
  EOQ

  param "bucket_arns" {}
  param "clb_arns" {}
}

node "s3_bucket_to_lambda_function_node" {
  category = category.lambda_function

  sql = <<-EOQ
    select
      f.arn as id,
      f.title as title,
      jsonb_build_object(
        'Version', f.version,
        'ARN', f.arn,
        'Runtime', f.runtime,
        'Region', f.region,
        'Account ID', f.account_id
      ) as properties
     from
      aws_s3_bucket as b,
      jsonb_array_elements(event_notification_configuration -> 'LambdaFunctionConfigurations') as t
      left join aws_lambda_function as f on f.arn = t ->> 'LambdaFunctionArn'
    where
      event_notification_configuration -> 'LambdaFunctionConfigurations' <> 'null'
      and b.arn = $1;
  EOQ

  param "arn" {}
}

edge "s3_bucket_to_lambda_function" {
  title = "triggers"

  sql = <<-EOQ
    select
      bucket_arn as from_id,
      function_arn as to_id
    from
      unnest($1::text[]) as bucket_arn,
      unnest($2::text[]) as function_arn
  EOQ

  param "bucket_arns" {}
  param "function_arns" {}
}

edge "s3_bucket_to_sns_topic" {
  title = "notifies"

  sql = <<-EOQ
    select
      bucket_arn as from_id,
      topic_arn as to_id
    from
      unnest($1::text[]) as bucket_arn,
      unnest($2::text[]) as topic_arn
  EOQ

  param "bucket_arns" {}
  param "topic_arns" {}
}

edge "s3_bucket_to_sqs_queue" {
  title = "queues"

  sql = <<-EOQ
    select
      bucket_arn as from_id,
      queue_arn as to_id
    from
      unnest($1::text[]) as bucket_arn,
      unnest($2::text[]) as queue_arn
  EOQ

  param "bucket_arns" {}
  param "queue_arns" {}
}

edge "s3_bucket_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      bucket_arn as from_id,
      key_arn as to_id
    from
      unnest($1::text[]) as bucket_arn,
      unnest($2::text[]) as key_arn
  EOQ

  param "bucket_arns" {}
  param "key_arns" {}
}

node "s3_bucket_from_s3_bucket" {
  category = category.s3_bucket

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
      b.arn = any($1)
      and lb.logging ->> 'TargetBucket' = b.name;
  EOQ

  param "bucket_arns" {}
}

edge "s3_bucket_from_s3_bucket" {
  title = "logs to"

  sql = <<-EOQ
    select
      b.arn as to_id,
      lb.arn as from_id
    from
      aws_s3_bucket as lb,
      aws_s3_bucket as b
    where
      b.arn = any($1)
      and lb.logging ->> 'TargetBucket' = b.name;
  EOQ

  param "bucket_arns" {}
}

node "s3_bucket_to_s3_bucket" {
  category = category.s3_bucket

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
      b.arn = any($1)
      and lb.name = b.logging ->> 'TargetBucket';
  EOQ

  param "bucket_arns" {}
}

edge "s3_bucket_to_s3_bucket" {
  title = "logs to"

  sql = <<-EOQ
    select
      b.arn as from_id,
      lb.arn as to_id
    from
      aws_s3_bucket as lb,
      aws_s3_bucket as b
    where
      b.arn = any($1)
      and lb.name = b.logging ->> 'TargetBucket';
  EOQ

  param "bucket_arns" {}
}

node "s3_bucket_from_s3_access_point_node" {
  category = category.s3_access_point

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
      b.arn = any($1)
      and ap.bucket_name = b.name
      and ap.region = b.region;
  EOQ

  param "bucket_arns" {}
}

edge "s3_bucket_from_s3_access_point_edge" {
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

query "aws_s3_bucket_public" {
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
      case when s.name is not null then 'Enforced' else 'Not Enforced' end as value,
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
