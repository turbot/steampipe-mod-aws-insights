dashboard "aws_lambda_function_detail" {

  title         = "AWS Lambda Function Detail"
  documentation = file("./dashboards/lambda/docs/lambda_function_detail.md")

  tags = merge(local.lambda_common_tags, {
    type = "Detail"
  })


  input "lambda_arn" {
    title = "Select a lambda function:"
    sql   = query.aws_lambda_function_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_lambda_function_memory
      args = {
        arn = self.input.lambda_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_lambda_function_runtime
      args = {
        arn = self.input.lambda_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_lambda_function_encryption
      args = {
        arn = self.input.lambda_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_lambda_function_public
      args = {
        arn = self.input.lambda_arn.value
      }
    }

  }

  container {

    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_lambda_function_relationships_graph
      args = {
        arn = self.input.lambda_arn.value
      }
      category "aws_lambda_function" {
        icon = local.aws_lambda_function_icon
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
        query = query.aws_lambda_function_overview
        args = {
          arn = self.input.lambda_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_lambda_function_tags
        args = {
          arn = self.input.lambda_arn.value
        }
      }

    }

    table {
      width = 6
      title = "Last Update Status"
      query = query.aws_lambda_function_last_update_status
      args = {
        arn = self.input.lambda_arn.value
      }
    }

  }

  table {
    title = "Policy"
    query = query.aws_lambda_function_policy
    args = {
      arn = self.input.lambda_arn.value
    }
  }

  table {
    width = 6
    title = "Security Groups"
    query = query.aws_lambda_function_security_groups
    args = {
      arn = self.input.lambda_arn.value
    }
  }

  table {
    width = 6
    title = "Subnets"
    query = query.aws_lambda_function_subnet_ids
    args = {
      arn = self.input.lambda_arn.value
    }
  }

}

query "aws_lambda_function_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_lambda_function
    order by
      title;
  EOQ
}

query "aws_lambda_function_memory" {
  sql = <<-EOQ
    select
      'Memory (MB)' as label,
      memory_size as value
    from
      aws_lambda_function
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_runtime" {
  sql = <<-EOQ
    select
      'Runtime' as label,
      runtime as value
    from
      aws_lambda_function
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_public" {
  sql = <<-EOQ
    select
      'Public Access' as label,
      case when
        policy_std -> 'Statement' ->> 'Effect' = 'Allow'
          and ( policy_std -> 'Statement' ->> 'Prinipal' = '*'
          or ( policy_std -> 'Principal' -> 'AWS' ) :: text = '*'
        ) then 'Enabled' else 'Disabled' end as value,
      case
      when
        policy_std -> 'Statement' ->> 'Effect' = 'Allow'
          and ( policy_std -> 'Statement' ->> 'Prinipal' = '*'
          or ( policy_std -> 'Principal' -> 'AWS' ) :: text = '*'
        ) then 'ok' else 'alert' end as type
    from
      aws_lambda_function
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when kms_key_arn is not null then 'Enabled' else 'Disabled' end as value,
      case when kms_key_arn is not null then 'ok' else 'alert' end as type
    from
      aws_lambda_function
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_last_update_status" {
  sql = <<-EOQ
    select
      last_modified as "Last Modified",
      last_update_status as "Last Update Status",
      last_update_status_reason as "Last Update Status Reason",
      last_update_status_reason_code as "Last Update Status Reason Code"
    from
      aws_lambda_function
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_policy" {
  sql = <<-EOQ
    select
      p ->> 'Sid' as "Sid",
      p ->> 'Effect' as "Effect",
      p -> 'Principal' as "Principal",
      p -> 'Action' as "Action",
      p -> 'Resource' as "Resource"
    from
      aws_lambda_function,
      jsonb_array_elements(policy_std -> 'Statement') as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_security_groups" {
  sql = <<-EOQ
    select
      p as "ID"
    from
      aws_lambda_function,
      jsonb_array_elements(vpc_security_group_ids) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_subnet_ids" {
  sql = <<-EOQ
    select
      p as "ID"
    from
      aws_lambda_function,
      jsonb_array_elements(vpc_subnet_ids) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_lambda_function_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      case
        when vpc_id is not null and vpc_id != '' then vpc_id
        else 'N/A'
      end as "VPC ID",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_lambda_function
    where
      arn = $1;
    EOQ

  param "arn" {}
}

query "aws_lambda_function_tags" {
  sql = <<-EOQ
    with jsondata as (
      select
        tags::json as tags
      from
        aws_lambda_function
      where
        arn = $1
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags)
    order by
      key;
    EOQ

  param "arn" {}
}

query "aws_lambda_function_relationships_graph" {
  sql = <<-EOQ
    with lambda as (
      select
        *
      from
        aws_lambda_function
      where
        arn = $1
    )
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_lambda_function' as category,
      jsonb_build_object(
        'ARN', arn,
        'Runtime', runtime,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      lambda

    -- To VPC (node)
    union all
    select
      null as from_id,
      null as to_id,
      v.arn as id,
      v.title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'VPC ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      lambda as l
      left join aws_vpc as v on v.vpc_id = l.vpc_id

    -- To VPC (edge)
    union all
    select
      l.arn as from_id,
      v.arn as to_id,
      null as id,
      'launched in' as title,
      'lambda_function_to_vpc' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      lambda as l
      left join aws_vpc as v on v.vpc_id = l.vpc_id

    -- To VPC security groups (node)
    union all
    select
      null as from_id,
      null as to_id,
      sg.arn as id,
      sg.group_id as title,
      'aws_vpc_security_group' as category,
      jsonb_build_object(
        'ARN', sg.arn,
        'Group ID', sg.group_id,
        'Account ID', sg.account_id,
        'Region', sg.region
      ) as properties
    from
      lambda as l,
      jsonb_array_elements_text(vpc_security_group_ids) as s
      left join aws_vpc_security_group as sg on sg.group_id = s

    -- To VPC security groups (edge)
    union all
    select
      l.arn as from_id,
      sg.arn as to_id,
      null as id,
      'attached to' as title,
      'lambda_function_to_vpc_security_group' as category,
      jsonb_build_object(
        'ARN', sg.arn, 'Account ID',
        sg.account_id,
        'Region', sg.region
      ) as properties
    from
      lambda as l,
      jsonb_array_elements_text(vpc_security_group_ids) as s
      left join aws_vpc_security_group as sg on sg.group_id = s

    -- To KMS keys (node)
    union all
    select
      null as from_id,
      null as to_id,
      k.arn as id,
      k.title as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      lambda as l
      left join aws_kms_key as k on k.arn = l.kms_key_arn

    -- To KMS keys (edge)
    union all
    select
      l.arn as from_id,
      k.arn as to_id,
      null as id,
      'encrypts with' as title,
      'lambda_function_to_kms_key' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      lambda as l
      left join aws_kms_key as k on k.arn = l.kms_key_arn

    -- To IAM roles (node)
    union all
    select
      null as from_id,
      null as to_id,
      r.arn as id,
      r.title as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'ARN', r.arn,
        'Account ID', r.account_id
      ) as properties
    from
      lambda as l
      left join
        aws_iam_role as r
        on r.arn = l.role

    -- To IAM roles (edge)
    union all
    select
      l.arn as from_id,
      r.arn as to_id,
      null as id,
      'assumes' as title,
      'lambda_function_to_iam_role' as category,
      jsonb_build_object(
        'ARN', r.arn,
        'Account ID', r.account_id
      ) as properties
    from
      lambda as l
      left join aws_iam_role as r on r.arn = l.role

    -- From S3 buckets (node)
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
      case
        jsonb_typeof(event_notification_configuration -> 'LambdaFunctionConfigurations')
        when
          'array'
        then (event_notification_configuration -> 'LambdaFunctionConfigurations')
        else
          null
      end
      ) as t
    where
      t ->> 'LambdaFunctionArn' = $1

    -- From S3 buckets (edge)
    union all
    select
      arn as from_id,
      $1 as to_id,
      null as id,
      'event notification' as title,
      's3_bucket_to_lambda_function' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Event Notification Configuration ID', t ->> 'Id',
        'Events Configured', t -> 'Events',
        'Region', region
      ) as properties
    from
      aws_s3_bucket,
      jsonb_array_elements(
      case
        jsonb_typeof(event_notification_configuration -> 'LambdaFunctionConfigurations')
        when
          'array'
        then (event_notification_configuration -> 'LambdaFunctionConfigurations')
        else
          null
      end
      ) as t
    where
      t ->> 'LambdaFunctionArn' = $1

    order by
      from_id,
      to_id;
  EOQ

  param "arn" {}
}
