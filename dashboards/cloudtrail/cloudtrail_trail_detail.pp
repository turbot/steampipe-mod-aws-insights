dashboard "cloudtrail_trail_detail" {

  title         = "AWS CloudTrail Trail Detail"
  documentation = file("./dashboards/cloudtrail/docs/cloudtrail_trail_detail.md")

  tags = merge(local.cloudtrail_common_tags, {
    type = "Detail"
  })

  input "trail_arn" {
    title = "Select a trail:"
    query = query.cloudtrail_trail_input
    width = 4
  }

  container {

    card {
      width = 2

      query = query.cloudtrail_trail_regional
      args  = [self.input.trail_arn.value]
    }

    card {
      width = 2

      query = query.cloudtrail_trail_multi_region
      args  = [self.input.trail_arn.value]
    }

    card {
      width = 2

      query = query.cloudtrail_trail_unencrypted
      args  = [self.input.trail_arn.value]
    }

    card {
      width = 2

      query = query.cloudtrail_trail_log_file_validation
      args  = [self.input.trail_arn.value]
    }

    card {
      width = 2

      query = query.cloudtrail_trail_logging
      args  = [self.input.trail_arn.value]
    }

  }

  with "cloudwatch_log_groups_for_cloudtrail_trail" {
    query = query.cloudwatch_log_groups_for_cloudtrail_trail
    args  = [self.input.trail_arn.value]
  }

  with "guardduty_detectors_for_cloudtrail_trail" {
    query = query.guardduty_detectors_for_cloudtrail_trail
    args  = [self.input.trail_arn.value]
  }

  with "kms_keys_for_cloudtrail_trail" {
    query = query.kms_keys_for_cloudtrail_trail
    args  = [self.input.trail_arn.value]
  }

  with "s3_buckets_for_cloudtrail_trail" {
    query = query.s3_buckets_for_cloudtrail_trail
    args  = [self.input.trail_arn.value]
  }

  with "sns_topics_for_cloudtrail_trail" {
    query = query.sns_topics_for_cloudtrail_trail
    args  = [self.input.trail_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.cloudtrail_trail
        args = {
          cloudtrail_trail_arns = [self.input.trail_arn.value]
        }
      }

      node {
        base = node.cloudwatch_log_group
        args = {
          cloudwatch_log_group_arns = with.cloudwatch_log_groups_for_cloudtrail_trail.rows[*].cloudwatch_log_group_arn
        }
      }

      node {
        base = node.guardduty_detector
        args = {
          guardduty_detector_arns = with.guardduty_detectors_for_cloudtrail_trail.rows[*].guardduty_detector_arn
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys_for_cloudtrail_trail.rows[*].kms_key_arn
        }
      }

      node {
        base = node.s3_bucket
        args = {
          s3_bucket_arns = with.s3_buckets_for_cloudtrail_trail.rows[*].s3_bucket_arn
        }
      }

      node {
        base = node.sns_topic
        args = {
          sns_topic_arns = with.sns_topics_for_cloudtrail_trail.rows[*].sns_topic_arn
        }
      }

      edge {
        base = edge.cloudtrail_trail_to_cloudwatch_log_group
        args = {
          cloudtrail_trail_arns = [self.input.trail_arn.value]
        }
      }

      edge {
        base = edge.cloudtrail_trail_to_kms_key
        args = {
          cloudtrail_trail_arns = [self.input.trail_arn.value]
        }
      }

      edge {
        base = edge.cloudtrail_trail_to_s3_bucket
        args = {
          cloudtrail_trail_arns = [self.input.trail_arn.value]
        }
      }

      edge {
        base = edge.cloudtrail_trail_to_sns_topic
        args = {
          cloudtrail_trail_arns = [self.input.trail_arn.value]
        }
      }

      edge {
        base = edge.guardduty_detector_to_cloudtrail_trail
        args = {
          guardduty_detector_arns = with.guardduty_detectors_for_cloudtrail_trail.rows[*].guardduty_detector_arn
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
        query = query.cloudtrail_trail_overview
        args  = [self.input.trail_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.cloudtrail_trail_tags
        args  = [self.input.trail_arn.value]
      }

    }

    container {
      width = 6

      table {
        title = "Associated S3 Trail Buckets"
        column "S3 Bucket ARN" {
          href = "{{ if .'S3 Bucket ARN' == null then null else '${dashboard.s3_bucket_detail.url_path}?input.bucket_arn=' + (.'S3 Bucket ARN' | @uri) end }}"
        }

        query = query.cloudtrail_trail_bucket
        args  = [self.input.trail_arn.value]
      }

    }

  }

}

# Input queries

query "cloudtrail_trail_input" {
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

# With queries

query "cloudwatch_log_groups_for_cloudtrail_trail" {
  sql = <<-EOQ
    select
      log_group_arn as cloudwatch_log_group_arn
    from
      aws_cloudtrail_trail
    where
      region = home_region
      and log_group_arn is not null
      and arn = $1;
  EOQ
}

query "guardduty_detectors_for_cloudtrail_trail" {
  sql = <<-EOQ
    select
      detector.arn as guardduty_detector_arn
    from
      aws_guardduty_detector as detector,
      aws_cloudtrail_trail as t
    where
      t.account_id = detector.account_id
      and t.region = detector.region
      and detector.status = 'ENABLED'
      and detector.data_sources is not null
      and detector.data_sources -> 'CloudTrail' ->> 'Status' = 'ENABLED'
      and t.arn = $1;
  EOQ
}

query "kms_keys_for_cloudtrail_trail" {
  sql = <<-EOQ
    select
      kms_key_id as kms_key_arn
    from
      aws_cloudtrail_trail as t
    where
      region = home_region
      and kms_key_id is not null
      and arn = $1;
  EOQ
}

query "s3_buckets_for_cloudtrail_trail" {
  sql = <<-EOQ
    select
      s.arn as s3_bucket_arn
    from
      aws_cloudtrail_trail as t,
      aws_s3_bucket as s
    where
      t.region = t.home_region
      and t.s3_bucket_name = s.name
      and s3_bucket_name is not null
      and t.arn = $1;
  EOQ
}

query "sns_topics_for_cloudtrail_trail" {
  sql = <<-EOQ
    select
      sns_topic_arn
    from
      aws_cloudtrail_trail
    where
      region = home_region
      and sns_topic_arn is not null
      and arn = $1;
  EOQ
}

# Card queries

query "cloudtrail_trail_regional" {
  sql = <<-EOQ
    select
      case when not is_multi_region_trail then 'True' else 'False' end as value,
      'Regional' as label
    from
      aws_cloudtrail_trail
    where
      region = home_region
      and arn = $1;
  EOQ
}

query "cloudtrail_trail_multi_region" {
  sql = <<-EOQ
    select
      case when is_multi_region_trail then 'True' else 'False' end as value,
      'Multi-Regional' as label
    from
      aws_cloudtrail_trail
    where
      region = home_region
      and arn = $1;
  EOQ
}

query "cloudtrail_trail_unencrypted" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when kms_key_id is not null then 'Enabled' else 'Disabled' end as value,
      case when kms_key_id is not null then 'ok' else 'alert' end as type
    from
      aws_cloudtrail_trail
    where
      region = home_region
      and arn = $1;
  EOQ
}

query "cloudtrail_trail_log_file_validation" {
  sql = <<-EOQ
    select
      case when log_file_validation_enabled then 'Enabled' else 'Disabled' end as value,
      'Log File Validation' as label,
      case when log_file_validation_enabled then 'ok' else 'alert' end as type
    from
      aws_cloudtrail_trail
    where
      region = home_region
      and arn = $1;
  EOQ
}

query "cloudtrail_trail_logging" {
  sql = <<-EOQ
    select
      'Logging' as label,
      case when is_logging then 'Enabled' else 'Disabled' end as value,
      case when is_logging then 'ok' else 'alert' end as type
    from
      aws_cloudtrail_trail
    where
      region = home_region
      and arn = $1;
  EOQ
}

# Other detail page queries

query "cloudtrail_trail_overview" {
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
      region = home_region
      and arn = $1;
  EOQ
}

query "cloudtrail_trail_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_cloudtrail_trail,
      jsonb_array_elements(tags_src) as tag
    where
      region = home_region
      and arn = $1
    order by
      tag ->> 'Key';
  EOQ
}

query "cloudtrail_trail_bucket" {
  sql = <<-EOQ
    select
      s3_bucket_name as "S3 Bucket Name",
      s.arn as "S3 Bucket ARN"
    from
      aws_cloudtrail_trail as t left join aws_s3_bucket as s on s.name = t.s3_bucket_name
    where
      t.region = home_region
      and t.arn = $1;
  EOQ
}
