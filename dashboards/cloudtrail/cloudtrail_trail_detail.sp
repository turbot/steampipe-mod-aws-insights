dashboard "aws_cloudtrail_trail_detail" {

  title         = "AWS CloudTrail Trail Detail"
  documentation = file("./dashboards/cloudtrail/docs/cloudtrail_trail_detail.md")

  tags = merge(local.cloudtrail_common_tags, {
    type = "Detail"
  })

  input "trail_arn" {
    title = "Select a trail:"
    sql   = query.aws_cloudtrail_trail_input.sql
    width = 4
  }

  container {

    card {
      width = 2

      query = query.aws_cloudtrail_trail_regional
      args = {
        arn = self.input.trail_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_cloudtrail_trail_multi_region
      args = {
        arn = self.input.trail_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_cloudtrail_trail_unencrypted
      args = {
        arn = self.input.trail_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_cloudtrail_trail_log_file_validation
      args = {
        arn = self.input.trail_arn.value
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
        query = query.aws_cloudtrail_trail_overview
        args = {
          arn = self.input.trail_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_cloudtrail_trail_tags
        args = {
          arn = self.input.trail_arn.value
        }
      }


    }

    container {
      width = 6

      table {
        title = "Logging"
        query = query.aws_cloudtrail_trail_logging
        args = {
          arn = self.input.trail_arn.value
        }
      }

      table {
        title = "Associated S3 Trail Buckets"
        column "S3 Bucket ARN" {
          href = "{{ if .'S3 Bucket ARN' == null then null else '${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn=' + (.'S3 Bucket ARN' | @uri) end }}"
        }

        query = query.aws_cloudtrail_trail_bucket
        args = {
          arn = self.input.trail_arn.value
        }
      }

    }

  }

  container {

    graph {
      type  = "graph"
      title = "Relationship Graph"
      query = query.aws_cloudtrail_trail_relationship_graph
      args = {
        arn = self.input.trail_arn.value
      }

      category "aws_cloudtrail_trail" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/cloudtrail_trail_light.svg"))
      }

      category "aws_sns_topic" {
        # href = "${dashboard.aws_sns_topic_detail.url_path}?input.topic_arn={{.properties.'ARN' | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/sns_topic_light.svg"))
      }

      category "aws_s3_bucket" {
        href = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.properties.'ARN' | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/s3_bucket_light.svg"))
      }

      category "aws_kms_key" {
        # href = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.'ARN' | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/kms_key_light.svg"))
      }

      category "aws_cloudwatch_log_group" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/cwl.svg"))
      }

      category "aws_guardduty_detector" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/guardduty_detector_light.svg"))
      }

    }

  }

}

query "aws_cloudtrail_trail_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_cloudtrail_trail
    where
      region = home_region
    order by
      title;
  EOQ
}

query "aws_cloudtrail_trail_regional" {
  sql = <<-EOQ
    select
      case when not is_multi_region_trail then 'True' else 'False' end as value,
      'Regional' as label
    from
      aws_cloudtrail_trail
    where
      region = home_region and arn = $1;
  EOQ

  param "arn" {}
}

query "aws_cloudtrail_trail_multi_region" {
  sql = <<-EOQ
    select
      case when is_multi_region_trail then 'True' else 'False' end as value,
      'Multi-Regional' as label
    from
      aws_cloudtrail_trail
    where
      region = home_region and arn = $1;
  EOQ

  param "arn" {}
}

query "aws_cloudtrail_trail_unencrypted" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when kms_key_id is not null then 'Enabled' else 'Disabled' end as value,
      case when kms_key_id is not null then 'ok' else 'alert' end as type
    from
      aws_cloudtrail_trail
    where
      region = home_region and arn = $1;
  EOQ

  param "arn" {}
}

query "aws_cloudtrail_trail_log_file_validation" {
  sql = <<-EOQ
    select
      case when log_file_validation_enabled then 'Enabled' else 'Disabled' end as value,
      'Log File Validation' as label,
      case when log_file_validation_enabled then 'ok' else 'alert' end as type
    from
      aws_cloudtrail_trail
    where
      region = home_region and arn = $1;
  EOQ

  param "arn" {}
}

query "aws_cloudtrail_trail_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      is_organization_trail as "Organization Trail",
      title as "Title",
      home_region as "Home Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_cloudtrail_trail
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_cloudtrail_trail_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_cloudtrail_trail,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_cloudtrail_trail_logging" {
  sql = <<-EOQ
    select
      arn as "ARN",
      is_logging as "Logging"
    from
      aws_cloudtrail_trail
    where
      region = home_region and arn = $1;
  EOQ

  param "arn" {}
}

query "aws_cloudtrail_trail_bucket" {
  sql = <<-EOQ
    select
      s3_bucket_name as "S3 Bucket Name",
      s.arn as "S3 Bucket ARN"
    from
      aws_cloudtrail_trail as t left join aws_s3_bucket as s on s.name = t.s3_bucket_name
    where
      t.region = home_region and t.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_cloudtrail_trail_relationship_graph" {
  sql = <<-EOQ
    with trails as (select * from aws_cloudtrail_trail where arn = $1)
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

    -- Things that use me
    -- GuardDuty - nodes
    union all
    select
      null as from_id,
      null as to_id,
      detector.arn as id,
      detector.detector_id as title,
      'aws_guardduty_detector' as category,
      jsonb_build_object(
        'ARN', detector.arn,
        'Account ID', detector.account_id,
        'Region', detector.region,
        'Status', detector.status
      ) as properties
    from
      aws_guardduty_detector as detector,
      trails as t
    where 
      detector.status = 'ENABLED'
      and detector.data_sources is not null
      and detector.data_sources -> 'CloudTrail' ->> 'Status' = 'ENABLED'
      
    -- GuardDuty - edges
    union all
    select
      detector.arn as from_id,
      t.arn as to_id,
      null as id,
      'Uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', t.arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_guardduty_detector as detector,
      trails as t
    where 
      detector.status = 'ENABLED'
      and detector.data_sources is not null
      and detector.data_sources -> 'CloudTrail' ->> 'Status' = 'ENABLED'

    order by category,id,from_id,to_id
  EOQ

  param "arn" {}
}
