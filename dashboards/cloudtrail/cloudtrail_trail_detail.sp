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
      args = {
        arn = self.input.trail_arn.value
      }
    }

    card {
      width = 2

      query = query.cloudtrail_trail_multi_region
      args = {
        arn = self.input.trail_arn.value
      }
    }

    card {
      width = 2

      query = query.cloudtrail_trail_unencrypted
      args = {
        arn = self.input.trail_arn.value
      }
    }

    card {
      width = 2

      query = query.cloudtrail_trail_log_file_validation
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

      with "cloudwatch_log_groups" {
        sql = <<-EOQ
          select
            log_group_arn as cloudwatch_log_group_arn
          from
            aws_cloudtrail_trail
          where
            log_group_arn is not null
            and arn = $1;
        EOQ

        args = [self.input.trail_arn.value]
      }

      with "guardduty_detectors" {
        sql = <<-EOQ
          select
            detector.arn as guardduty_detector_arn
          from
            aws_guardduty_detector as detector,
            aws_cloudtrail_trail as t
          where
            detector.status = 'ENABLED'
            and detector.data_sources is not null
            and detector.data_sources -> 'CloudTrail' ->> 'Status' = 'ENABLED'
            and t.arn = $1;
        EOQ

        args = [self.input.trail_arn.value]
      }

      with "kms_keys" {
        sql = <<-EOQ
          select
            kms_key_id as kms_key_arn
          from
            aws_cloudtrail_trail as t
          where
            kms_key_id is not null
            and arn = $1;
        EOQ

        args = [self.input.trail_arn.value]
      }

      with "s3_buckets" {
        sql = <<-EOQ
          select
            s.arn as s3_bucket_arn
          from
            aws_cloudtrail_trail as t,
            aws_s3_bucket as s
          where
            t.s3_bucket_name = s.name
            and s3_bucket_name is not null
            and t.arn = $1;
        EOQ

        args = [self.input.trail_arn.value]
      }

      with "sns_topics" {
        sql = <<-EOQ
          select
            sns_topic_arn
          from
            aws_cloudtrail_trail
          where
            sns_topic_arn is not null
            and arn = $1;
        EOQ

        args = [self.input.trail_arn.value]
      }

      nodes = [
        node.cloudtrail_trail,
        node.cloudwatch_log_group,
        node.guardduty_detector,
        node.kms_key,
        node.s3_bucket,
        node.sns_topic
      ]

      edges = [
        edge.cloudtrail_trail_to_cloudwatch_log_group,
        edge.cloudtrail_trail_to_kms_key,
        edge.cloudtrail_trail_to_s3_bucket,
        edge.cloudtrail_trail_to_sns_topic,
        edge.guardduty_detector_to_cloudtrail_trail
      ]

      args = {
        cloudtrail_trail_arns     = [self.input.trail_arn.value]
        cloudwatch_log_group_arns = with.cloudwatch_log_groups.rows[*].cloudwatch_log_group_arn
        guardduty_detector_arns   = with.guardduty_detectors.rows[*].guardduty_detector_arn
        kms_key_arns              = with.kms_keys.rows[*].kms_key_arn
        s3_bucket_arns            = with.s3_buckets.rows[*].s3_bucket_arn
        sns_topic_arns            = with.sns_topics.rows[*].sns_topic_arn
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
        args = {
          arn = self.input.trail_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.cloudtrail_trail_tags
        args = {
          arn = self.input.trail_arn.value
        }
      }


    }

    container {
      width = 6

      table {
        title = "Logging"
        query = query.cloudtrail_trail_logging
        args = {
          arn = self.input.trail_arn.value
        }
      }

      table {
        title = "Associated S3 Trail Buckets"
        column "S3 Bucket ARN" {
          href = "{{ if .'S3 Bucket ARN' == null then null else '${dashboard.s3_bucket_detail.url_path}?input.bucket_arn=' + (.'S3 Bucket ARN' | @uri) end }}"
        }

        query = query.cloudtrail_trail_bucket
        args = {
          arn = self.input.trail_arn.value
        }
      }

    }

  }

}

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

query "cloudtrail_trail_regional" {
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

query "cloudtrail_trail_multi_region" {
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

query "cloudtrail_trail_unencrypted" {
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

query "cloudtrail_trail_log_file_validation" {
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
      arn = $1;
  EOQ

  param "arn" {}
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
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "cloudtrail_trail_logging" {
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

query "cloudtrail_trail_bucket" {
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