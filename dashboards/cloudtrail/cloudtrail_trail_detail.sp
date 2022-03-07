dashboard "aws_cloudtrail_trail_detail" {

  title = "AWS CloudTrail Trail Detail"

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
        query = query.aws_cloudtrail_trail_bucket

        args = {
          arn = self.input.trail_arn.value
        }
      }

    }

  }

}

query "aws_cloudtrail_trail_input" {
  sql = <<EOQ
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
      arn as "ARN",
      s3_bucket_name as "S3 Bucket Name"
    from
      aws_cloudtrail_trail
    where
      region = home_region and arn = $1;
  EOQ

  param "arn" {}
}
