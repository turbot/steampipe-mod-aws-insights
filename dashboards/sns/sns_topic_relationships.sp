dashboard "aws_sns_topic_relationships" {

  title         = "AWS SNS Topic Relationships"
  #documentation = file("./dashboards/sns/docs/sns_queue_detail.md")

  tags = merge(local.sns_common_tags, {
    type = "Detail"
  })


  input "topic_arn" {
    title = "Select a topic:"
    sql   = query.aws_sns_topic.sql
    width = 4
  }

   graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_sns_topic_graph_from_topic
    args = {
      arn = self.input.topic_arn.value
    }

      category "aws_sns_topic" {
        icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/Res_Amazon-Simple-Notification-Service_Topic_48_Dark.svg"))
        color = "blue"
        href  = "${dashboard.aws_sns_topic_detail.url_path}?input.topic_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_kms_key" {
        color = "orange"
        icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/Arch_AWS-Key-Management-Service_16.svg"))
        href  = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.'ARN' | @uri}}"
      }

    }

   graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_sns_topic_graph_to_topic
    args = {
      arn = self.input.topic_arn.value
    }

    category "aws_sns_topic" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/Res_Amazon-Simple-Notification-Service_Topic_48_Dark.svg"))
      color = "blue"
      href  = "${dashboard.aws_sns_topic_detail.url_path}?input.topic_arn={{.properties.'ARN' | @uri}}"
    }

    category "aws_s3_bucket" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/Res_Amazon-Simple-Storage-Service_Bucket_48_Dark.svg"))
      color = "orange"
      href  = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.properties.'ARN' | @uri}}"
    }

  }

}

query "aws_sns_topic" {
  sql = <<-EOQ
    select
      topic_arn as label,
      topic_arn as value
    from
      aws_sns_topic
    order by
      topic_arn;
EOQ
}

query "aws_sns_topic_graph_from_topic" {
  sql = <<-EOQ
    with topic as (select * from aws_sns_topic where topic_arn = 'arn:aws:sns:us-east-1:533793682495:aws-cis-handling')

    -- topic node
    select
      null as from_id,
      null as to_id,
      topic_arn as id,
      title as title,
      'aws_sns_topic' as category,
      jsonb_build_object(
        'ARN', topic_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      topic

 -- Kms key Nodes
    union all
    select
      null as from_id,
      null as to_id,
      k.arn as id,
      k.title as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      topic as q
      left join aws_kms_key as k on k.id = split_part(q.kms_master_key_id, '/', 2)
    where
      k.region = q.region

    -- Kms key Edges
    union all
    select
      k.arn as from_id,
      q.topic_arn as to_id,
      null as id,
      'Encrypted With' as title,
      'encrypted_with' as category,
      jsonb_build_object(
        'ARN', q.topic_arn,
        'Account ID', q.account_id,
        'Region', q.region
      ) as properties
    from
      topic as q
      left join aws_kms_key as k on k.id = split_part(q.kms_master_key_id, '/', 2)
    where
      k.region = q.region
  EOQ
  param "arn" {}
}

query "aws_sns_topic_graph_to_topic" {
  sql = <<-EOQ
    with topic as (select * from aws_sns_topic where topic_arn = 'arn:aws:sns:us-east-1:533793682495:aws-cis-handling')
    -- queue node
    select
      null as from_id,
      null as to_id,
      topic_arn as id,
      title as title,
      'aws_sns_topic' as category,
      jsonb_build_object(
        'ARN', topic_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      topic

  -- Buckets that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_s3_bucket,
      jsonb_array_elements(
        case jsonb_typeof(event_notification_configuration -> 'TopicConfigurations')
          when 'array' then (event_notification_configuration -> 'TopicConfigurations')
          else null end
        )
        as t
    where
      t ->> 'TopicArn'  = 'arn:aws:sns:us-east-1:533793682495:aws-cis-handling'

    -- Buckets that use me - edges
    union all
    select
      arn as from_id,
      'arn:aws:sns:us-east-1:533793682495:aws-cis-handling' as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_s3_bucket,
      jsonb_array_elements(
        case jsonb_typeof(event_notification_configuration -> 'TopicConfigurations')
          when 'array' then (event_notification_configuration -> 'TopicConfigurations')
          else null end
        )
        as t
    where
      t ->> 'TopicArn'  = 'arn:aws:sns:us-east-1:533793682495:aws-cis-handling'

  EOQ
  param "arn" {}
}