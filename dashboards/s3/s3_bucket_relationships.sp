dashboard "aws_s3_bucket_relationships" {
  title         = "AWS S3 Bucket Relationships"
  #documentation = file("./dashboards/ec2/docs/s3_bucket_relationships.md")
  tags = merge(local.ec2_common_tags, {
    type = "Relationships"
  })
  
  input "s3_bucket" {
    title = "Select a bucket:"
    sql   = query.aws_s3_bucket_input.sql
    width = 4
  }
  
  graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_s3_bucket_graph_to_instance
    args = {
      bucket = self.input.s3_bucket.value
    }
  }
#  
#  graph {
#    type  = "graph"
#    title = "Things that use me..."
#    query = query.aws_ec2_instance_graph_to_instance
#    args = {
#      arn = self.input.instance_arn.value
#    }
#  }
}

query "aws_s3_bucket_graph_to_instance"{
  sql = <<-EOQ
    with buckets as (select * from aws_s3_bucket where arn = $1)
    select
      null as from_id,
      null as to_id,
      arn as id,
      name as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region,
        'Logging', logging
      ) as metadata
    from
      buckets
      
    -- Cloudtrail - nodes
    union all
    select
      null as from_id,
      null as to_id,
      trail.arn as id,
      trail.name as title,
      'aws_cloudtrail_trail' as category,
      jsonb_build_object(
        'ARN', trail.arn,
        'Account ID', trail.account_id,
        'Region', trail.region
      ) as metadata
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
      null as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', trail.arn,
        'Account ID', trail.account_id,
        'Region', trail.region
      ) as metadata
    from
      aws_cloudtrail_trail as trail,
      buckets as b
    where 
      trail.s3_bucket_name = b.name
      
    -- Buckets I log to - nodes
    union all 
    select
      null as from_id,
      null as to_id,
      aws_s3_bucket.arn as id,
      aws_s3_bucket.name as title,
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
      null as title,
      'logs_to' as category,
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

    -- Buckets that log to me - nodes
    union all 
    select
      null as from_id,
      null as to_id,
      aws_s3_bucket.arn as id,
      aws_s3_bucket.name as title,
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

    -- Buckets that log to me - nodes
    union all 
    select
      buckets.arn as from_id,
      aws_s3_bucket.arn as to_id,
      null as id,
      null as title,
      'logs_to' as category,
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

    -- ALBs that log to me - nodes
    union all 
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_ec2_application_load_balancer' as category,
      jsonb_build_object(
        'Name', name,
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_application_load_balancer
    where 
      load_balancer_attributes->'access_logs'->'s3'->>'bucket' = $1

    -- ALBs that log to me - edges
    union all 
    select
      arn as from_id,
      $1 as to_id,
      null as id,
      'Logs to' as title,
      'logs_to' as category,
      jsonb_build_object(
        'Logging Enabled', load_balancer_attributes->'access_logs'->'s3'->'enabled',
        'Logging Bucket', load_balancer_attributes->'access_logs'->'s3'->'bucket',
        'Key Prefix', load_balancer_attributes->'access_logs'->'s3'->'prefix'
      ) as properties
    from
      aws_ec2_application_load_balancer
    where 
      load_balancer_attributes->'access_logs'->'s3'->>'bucket' = $1

  EOQ
  
  param "bucket" {}
}