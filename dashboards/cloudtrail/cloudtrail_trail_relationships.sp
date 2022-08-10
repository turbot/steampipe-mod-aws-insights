dashboard "aws_cloudtrail_trail_relationships" {
  title = "AWS CloudTrail Trail Relationships"
  #documentation = file("./dashboards/cloudtrail/docs/cloudtrail_trail_relationships.md")
  tags = merge(local.cloudtrail_common_tags, {
    type = "Relationships"
  })

  input "cloudtrail_trail" {
    title = "Select a trail:"
    sql   = query.aws_cloudtrail_trail_input.sql
    width = 4
  }

  /* graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_cloudtrail_trail_graph_use_me
    args = {
      bucket = self.input.cloudtrail_trail.value
    }

    category "aws_ec2_application_load_balancer" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/alb.svg"))
    }

    category "aws_ec2_network_load_balancer" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/nlb.svg"))
    }

    category "aws_cloudtrail_trail" {
      href = "${dashboard.aws_cloudtrail_trail_detail.url_path}?input.bucket_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/alb.svg"))
    }
  } */

  graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_cloudtrail_trail_graph_i_use
    args = {
      bucket = self.input.cloudtrail_trail.value
    }

    category "aws_cloudtrail_trail" {
      href = "${dashboard.aws_cloudtrail_trail_detail.url_path}?input.trail_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/ctt.svg"))
    }

    category "aws_sns_topic" {
      href = "${dashboard.aws_sns_topic_detail.url_path}?input.topic_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/sns.svg"))
    }

    category "aws_s3_bucket" {
      href = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/s3_bucket.svg"))
    }

    category "aws_kms_key" {
      href = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/kms_key.svg"))
    }

    category "aws_cloudwatch_log_group" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/cwl.svg"))
    }

  }

}

query "aws_cloudtrail_trail_graph_use_me" {
  sql = <<-EOQ
    with trails as (select * from aws_cloudtrail_trail where arn = 'arn:aws:cloudtrail:us-east-1:533793682495:trail/test-relationships-trail')
  EOQ

  param "bucket" {}
}

query "aws_cloudtrail_trail_graph_i_use" {
  sql = <<-EOQ
    with trails as (select * from aws_cloudtrail_trail where arn = 'arn:aws:cloudtrail:us-east-1:533793682495:trail/test-relationships-trail')
    select
      null as from_id,
      null as to_id,
      arn as id,
      name as title,
      'aws_cloudtrail_trail' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region,
        'Logging', is_logging::text,
        'Latest notification time', latest_notification_time
      ) as properties
    from
      trails
      
    -- S3 Buckets - nodes
    union all
    select
      null as from_id,
      null as to_id,
      bucket.arn as id,
      bucket.name as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'ARN', bucket.arn,
        'Account ID', bucket.account_id,
        'Region', bucket.region,
        'Public', bucket_policy_is_public::text
      ) as properties
    from
      aws_s3_bucket as bucket,
      trails as t
    where 
      t.s3_bucket_name = bucket.name
      
    -- S3 Buckets - edges
    union all
    select
      t.arn as from_id,
      bucket.arn as to_id,
      null as id,
      'Logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', t.arn,
        'Account ID', t.account_id,
        'Region', t.region,
        'Log Prefix', t.s3_key_prefix
      ) as properties
    from
      aws_s3_bucket as bucket,
      trails as t
    where 
      t.s3_bucket_name = bucket.name

    -- KMS key - nodes
    union all
    select
      null as from_id,
      null as to_id,
      key.arn as id,
      key.title as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', key.arn,
        'Account ID', key.account_id,
        'Region', key.region,
        'Key Manager', key_manager,
        'Enabled', enabled::text
      ) as properties
    from
      aws_kms_key as key,
      trails as t
    where 
      t.kms_key_id = key.arn

    -- KMS key - edges
    union all
    select
      t.arn as from_id,
      key.arn as to_id,
      null as id,
      'Logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', t.arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_kms_key as key,
      trails as t
    where 
      t.kms_key_id = key.arn

    -- SNS topic - nodes
    union all
    select
      null as from_id,
      null as to_id,
      topic.topic_arn as id,
      topic.title as title,
      'aws_sns_topic' as category,
      jsonb_build_object(
        'ARN', topic.topic_arn,
        'Account ID', topic.account_id,
        'Region', topic.region
      ) as properties
    from
      aws_sns_topic as topic,
      trails as t
    where 
      t.sns_topic_arn = topic.topic_arn

    -- SNS topic - edges
    union all
    select
      t.arn as from_id,
      topic.topic_arn as to_id,
      null as id,
      'Logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', t.arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_sns_topic as topic,
      trails as t
    where 
      t.sns_topic_arn = topic.topic_arn

    -- Cloudwatch log group - nodes
    union all
    select
      null as from_id,
      null as to_id,
      grp.arn as id,
      grp.title as title,
      'aws_cloudwatch_log_group' as category,
      jsonb_build_object(
        'ARN', grp.arn,
        'Account ID', grp.account_id,
        'Region', grp.region
      ) as properties
    from
      aws_cloudwatch_log_group as grp,
      trails as t
    where 
      t.log_group_arn = grp.arn

    -- Cloudwatch log group - edges
    union all
    select
      t.arn as from_id,
      grp.arn as to_id,
      null as id,
      'Logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', t.arn,
        'Account ID', t.account_id,
        'Region', t.region,
        'Logs Role ARN', t.cloudwatch_logs_role_arn,
        'Latest cloudwatch logs delivery time', t.latest_cloudwatch_logs_delivery_time,
        'Retention days', retention_in_days
      ) as properties
    from
      aws_cloudwatch_log_group as grp,
      trails as t
    where 
      t.log_group_arn = grp.arn

    order by category,id,from_id,to_id
  EOQ

  param "bucket" {}
}
