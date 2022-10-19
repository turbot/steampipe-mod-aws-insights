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

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_cloudtrail_trail_node,
        node.aws_cloudtrail_trail_to_s3_bucket_node,
        node.aws_cloudtrail_trail_to_kms_key_node,
        node.aws_cloudtrail_trail_to_sns_topic_node,
        node.aws_cloudtrail_trail_to_cloudwatch_log_group_node,
        node.aws_cloudtrail_trail_from_guardduty_detector_node
      ]

      edges = [
        edge.aws_cloudtrail_trail_to_s3_bucket_edge,
        edge.aws_cloudtrail_trail_to_kms_key_edge,
        edge.aws_cloudtrail_trail_to_sns_topic_edge,
        edge.aws_cloudtrail_trail_to_cloudwatch_log_group_edge,
        edge.aws_cloudtrail_trail_from_guardduty_detector_edge
      ]

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

node "aws_cloudtrail_trail_node" {
  category = category.aws_cloudtrail_trail

  sql = <<-EOQ
    select
      arn as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'Logging', is_logging::text,
        'Latest notification time', latest_notification_time,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_cloudtrail_trail
    where
      arn = $1
  EOQ

  param "arn" {}
}

node "aws_cloudtrail_trail_to_s3_bucket_node" {
  category = category.aws_s3_bucket

  sql = <<-EOQ
    select
      b.arn as id,
      b.name as title,
      jsonb_build_object(
        'ARN', b.arn,
        'Public', bucket_policy_is_public::text,
        'Account ID', b.account_id,
        'Region', b.region
      ) as properties
    from
      aws_s3_bucket as b
      right join aws_cloudtrail_trail as t on t.s3_bucket_name = b.name
    where
      t.arn = $1
  EOQ

  param "arn" {}
}

edge "aws_cloudtrail_trail_to_s3_bucket_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      t.arn as from_id,
      b.arn as to_id,
      jsonb_build_object(
        'ARN', t.arn,
        'Log Prefix', t.s3_key_prefix,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_s3_bucket as b
      right join aws_cloudtrail_trail as t on t.s3_bucket_name = b.name
    where
      t.arn = $1
  EOQ

  param "arn" {}
}

node "aws_cloudtrail_trail_to_kms_key_node" {
  category = category.aws_kms_key

  sql = <<-EOQ
    select
      k.arn as id,
      k.title as title,
      jsonb_build_object(
        'ARN', k.arn,
        'Key Manager', key_manager,
        'Enabled', enabled::text,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      aws_kms_key as k
      right join aws_cloudtrail_trail as t on t.kms_key_id = k.arn
    where
      t.arn = $1
  EOQ

  param "arn" {}
}

edge "aws_cloudtrail_trail_to_kms_key_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      t.arn as from_id,
      k.arn as to_id,
      jsonb_build_object(
        'ARN', t.arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_kms_key as k
      right join aws_cloudtrail_trail as t on t.kms_key_id = k.arn
    where
      t.arn = $1
  EOQ

  param "arn" {}
}

node "aws_cloudtrail_trail_to_sns_topic_node" {
  category = category.aws_sns_topic

  sql = <<-EOQ
    select
      st.topic_arn as id,
      st.title as title,
      jsonb_build_object(
        'ARN', st.topic_arn,
        'Account ID', st.account_id,
        'Region', st.region
      ) as properties
    from
      aws_sns_topic as st
      right join aws_cloudtrail_trail as t on t.sns_topic_arn = st.topic_arn
    where
      t.arn = $1
  EOQ

  param "arn" {}
}

edge "aws_cloudtrail_trail_to_sns_topic_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      t.arn as from_id,
      st.topic_arn as to_id,
      jsonb_build_object(
        'ARN', t.arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_sns_topic as st
      right join aws_cloudtrail_trail as t on t.sns_topic_arn = st.topic_arn
    where
      t.arn = $1
  EOQ

  param "arn" {}
}

node "aws_cloudtrail_trail_to_cloudwatch_log_group_node" {
  category = category.aws_cloudwatch_log_group

  sql = <<-EOQ
    select
      g.arn as id,
      g.title as title,
      jsonb_build_object(
        'ARN', g.arn,
        'Account ID', g.account_id,
        'Region', g.region
      ) as properties
    from
      aws_cloudwatch_log_group as g
      right join aws_cloudtrail_trail as t on t.log_group_arn = g.arn
    where
      t.arn = $1
  EOQ

  param "arn" {}
}

edge "aws_cloudtrail_trail_to_cloudwatch_log_group_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      t.arn as from_id,
      g.arn as to_id,
      jsonb_build_object(
        'ARN', t.arn,
        'Account ID', t.account_id,
        'Region', t.region,
        'Logs Role ARN', t.cloudwatch_logs_role_arn,
        'Latest cloudwatch logs delivery time', t.latest_cloudwatch_logs_delivery_time,
        'Retention days', retention_in_days
      ) as properties
   from
      aws_cloudwatch_log_group as g
      right join aws_cloudtrail_trail as t on t.log_group_arn = g.arn
    where
      t.arn = $1
  EOQ

  param "arn" {}
}

node "aws_cloudtrail_trail_from_guardduty_detector_node" {
  category = category.aws_guardduty_detector

  sql = <<-EOQ
    select
      detector.arn as id,
      detector.detector_id as title,
      jsonb_build_object(
        'ARN', detector.arn,
        'Account ID', detector.account_id,
        'Region', detector.region,
        'Status', detector.status
      ) as properties
    from
      aws_guardduty_detector as detector,
      aws_cloudtrail_trail as t
    where
      detector.status = 'ENABLED'
      and detector.data_sources is not null
      and detector.data_sources -> 'CloudTrail' ->> 'Status' = 'ENABLED'
      and t.arn = $1
  EOQ

  param "arn" {}
}

edge "aws_cloudtrail_trail_from_guardduty_detector_edge" {
  title = "guardduty detector"

  sql = <<-EOQ
    select
      detector.arn as from_id,
      t.arn as to_id,
      jsonb_build_object(
        'ARN', t.arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_guardduty_detector as detector,
      aws_cloudtrail_trail as t
    where
      detector.status = 'ENABLED'
      and detector.data_sources is not null
      and detector.data_sources -> 'CloudTrail' ->> 'Status' = 'ENABLED'
      and t.arn = $1
  EOQ

  param "arn" {}
}
