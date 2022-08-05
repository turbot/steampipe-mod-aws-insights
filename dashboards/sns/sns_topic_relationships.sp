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
        icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_sns_topic.svg"))
        color = "blue"
        href  = "${dashboard.aws_sns_topic_detail.url_path}?input.topic_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_kms_key" {
        color = "orange"
        icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_kms_key.svg"))
        href  = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_sns_topic_subscription" {
        color = "green"
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
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_sns_topic.svg"))
      color = "blue"
      href  = "${dashboard.aws_sns_topic_detail.url_path}?input.topic_arn={{.properties.'ARN' | @uri}}"
    }

    category "aws_s3_bucket" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_s3_bucket.svg"))
      color = "orange"
      href  = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.properties.'ARN' | @uri}}"
    }

     category "aws_rds_db_instance" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_rds_db_instance.svg"))
      color = "orange"
      href  = "${dashboard.aws_rds_db_instance_detail.url_path}?input.db_instance_arn={{.properties.'ARN' | @uri}}"
    }

     category "aws_redshift_cluster" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_redshift_cluster.svg"))
      color = "orange"
      href  = "${dashboard.aws_redshift_cluster_detail.url_path}?input.cluster_arn={{.properties.'ARN' | @uri}}"
    }

      category "aws_cloudtrail_trail" {
      # icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_s3_bucket.svg"))
      color = "red"
      href  = "${dashboard.aws_cloudtrail_trail_detail.url_path}?input.trail_arn={{.properties.'ARN' | @uri}}"
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
    with topic as (select * from aws_sns_topic where topic_arn = $1)

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
      q.topic_arn as from_id,
      k.arn as to_id,
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

    -- Subscription topic Nodes
    union all
    select
      null as from_id,
      null as to_id,
      subscription_arn as id,
      title as title,
      'aws_sns_topic_subscription' as category,
      jsonb_build_object(
        'ARN', subscription_arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_sns_topic_subscription
    where topic_arn = $1

    -- Subscription topic Edges
    union all
    select
      q.topic_arn as from_id,
      s.subscription_arn as to_id,
      null as id,
      'Subscibe To' as title,
      'subscibe_to' as category,
      jsonb_build_object(
        'ARN', q.topic_arn,
        'Account ID', q.account_id,
        'Region', q.region
      ) as properties
    from
      topic as q
    left join aws_sns_topic_subscription as s on s.topic_arn = q.topic_arn

  EOQ
  param "arn" {}
}

query "aws_sns_topic_graph_to_topic" {
  sql = <<-EOQ
    with topic as (select * from aws_sns_topic where topic_arn = $1)

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
      t ->> 'TopicArn'  = $1

    -- Buckets that use me - edges
    union all
    select
      arn as from_id,
      $1 as to_id,
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
      t ->> 'TopicArn'  = $1

    -- RDS DB INSTANCE that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      i.arn as id,
      i.title as title,
      'aws_rds_db_instance' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Event Categories List', case when event_categories_list is null then '["ALL"]' else event_categories_list end,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_rds_db_instance as i,
      aws_rds_db_event_subscription as e,
      jsonb_array_elements(
        case jsonb_typeof(source_ids_list)
          when 'array' then (source_ids_list)
          else null end
      ) s
    where
      e.source_type = 'db-instance'
      and (source_ids_list is null or i.db_instance_identifier = trim((s::text ), '""'))
      and e.sns_topic_arn = $1


    -- RDS DB INSTANCE  that use me - edges
    union all
    select
      i.arn as from_id,
      t.topic_arn as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', t.topic_arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      topic as t,
      aws_rds_db_instance as i,
      aws_rds_db_event_subscription as e,
      jsonb_array_elements(
        case jsonb_typeof(e.source_ids_list)
          when 'array' then (e.source_ids_list)
          else null end
      ) as s
    where
      e.source_type = 'db-instance'
      and (e.source_ids_list is null or i.db_instance_identifier = trim((s::text ), '""'))
      and t.topic_arn = e.sns_topic_arn

-- Redshift cluster that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      c.arn as id,
      c.title as title,
      'aws_redshift_cluster' as category,
      jsonb_build_object(
        'ARN', c.arn,
        'Event Categories List', case when event_categories_list is null then '["ALL"]' else event_categories_list end,
        'Account ID', c.account_id,
        'Region', c.region
      ) as properties
    from
      aws_redshift_cluster as c,
      aws_redshift_event_subscription as e,
      jsonb_array_elements(
        case jsonb_typeof(source_ids_list)
          when 'array' then (source_ids_list)
          else null end
      ) s
    where
      (e.source_type = 'cluster' or e.source_type is null)
      and (source_ids_list is null or c.cluster_identifier = trim((s::text ), '""'))
      and e.sns_topic_arn = $1

     -- Redshift cluster  that use me - edges
    union all
    select
      c.arn as from_id,
      t.topic_arn as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', t.topic_arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      topic as t,
      aws_redshift_cluster as c,
      aws_redshift_event_subscription as e,
      jsonb_array_elements(
        case jsonb_typeof(e.source_ids_list)
          when 'array' then (e.source_ids_list)
          else null end
      ) as s
    where
      (e.source_type = 'cluster' or e.source_type is null)
      and (e.source_ids_list is null or c.cluster_identifier = trim((s::text ), '""'))
      and t.topic_arn = e.sns_topic_arn

     -- Cloudtrail that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_cloudtrail_trail' as category,
      jsonb_build_object(
        'ARN', t.arn,
        'Account ID',t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_cloudtrail_trail as t
    where
      t.sns_topic_arn  = $1

    -- Cloudtrail that use me - edges
    union all
    select
      c.arn as from_id,
      $1 as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', t.topic_arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      topic as t
      left join aws_cloudtrail_trail as c on t.topic_arn = c.sns_topic_arn

    --  Clouformation Stack that use me - nodes
    union all
    select
      null as from_id,
      null as to_id,
      s.id as id,
      s.title as title,
      'aws_cloudformation_stack' as category,
      jsonb_build_object(
        'ARN', s.id,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_cloudformation_stack as s,
      jsonb_array_elements(
        case jsonb_typeof(notification_arns)
          when 'array' then (notification_arns)
          else null end
      ) n
    where
      trim((n::text ), '""') = $1

     -- Clouformation Stack  that use me - edges
    union all
    select
      s.id as from_id,
      t.topic_arn as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', t.topic_arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      topic as t,
      aws_cloudformation_stack as s,
      jsonb_array_elements(
        case jsonb_typeof(notification_arns)
          when 'array' then (notification_arns)
          else null end
      ) n
    where
      t.topic_arn = trim((n::text ), '""')

  EOQ
  param "arn" {}
}