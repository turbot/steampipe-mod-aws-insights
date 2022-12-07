dashboard "lambda_function_detail" {

  title         = "AWS Lambda Function Detail"
  documentation = file("./dashboards/lambda/docs/lambda_function_detail.md")

  tags = merge(local.lambda_common_tags, {
    type = "Detail"
  })


  input "lambda_arn" {
    title = "Select a lambda function:"
    query = query.lambda_function_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.lambda_function_memory
      args = {
        arn = self.input.lambda_arn.value
      }
    }

    card {
      width = 2
      query = query.lambda_function_runtime
      args = {
        arn = self.input.lambda_arn.value
      }
    }

    card {
      width = 2
      query = query.lambda_function_encryption
      args = {
        arn = self.input.lambda_arn.value
      }
    }

    card {
      width = 2
      query = query.lambda_function_public
      args = {
        arn = self.input.lambda_arn.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "api_gateway_apis" {
        sql = <<-EOQ
          select
            api_id
          from
            aws_api_gatewayv2_integration
          where
            integration_uri = $1;
        EOQ

        args = [self.input.lambda_arn.value]
      }

      with "iam_roles" {
        sql = <<-EOQ
          select
            role as role_arn
          from
            aws_lambda_function
          where
            arn = $1;
        EOQ

        args = [self.input.lambda_arn.value]
      }

      with "kms_keys" {
        sql = <<-EOQ
          select
            kms_key_arn
          from
            aws_lambda_function
          where
            kms_key_arn is not null
            and arn = $1;
        EOQ

        args = [self.input.lambda_arn.value]
      }

      with "s3_buckets" {
        sql = <<-EOQ
          select
            arn as bucket_arn
          from
            aws_s3_bucket,
            jsonb_array_elements(event_notification_configuration -> 'LambdaFunctionConfigurations') as t
          where
            event_notification_configuration -> 'LambdaFunctionConfigurations' <> 'null'
            and t ->> 'LambdaFunctionArn' = $1;
        EOQ

        args = [self.input.lambda_arn.value]
      }

      with "sns_topics" {
        sql = <<-EOQ
          select
            topic_arn as topic_arn
          from
            aws_sns_topic_subscription
          where
            protocol = 'lambda'
            and (
              endpoint = $1
              or endpoint like $1 || ':%'
            )
        EOQ

        args = [self.input.lambda_arn.value]
      }
      
      with "vpc_security_groups" {
        sql = <<-EOQ
          select
            s as group_id
          from
            aws_lambda_function,
            jsonb_array_elements_text(vpc_security_group_ids) as s
          where
            arn = $1;
        EOQ

        args = [self.input.lambda_arn.value]
      }

      with "vpc_subnets" {
        sql = <<-EOQ
          select
            s as subnet_id
          from
            aws_lambda_function,
            jsonb_array_elements_text(vpc_subnet_ids) as s
          where
            arn = $1;
        EOQ

        args = [self.input.lambda_arn.value]
      }

      with "vpc_vpcs" {
        sql = <<-EOQ
          select
            vpc_id
          from
            aws_lambda_function
          where
            vpc_id is not null
            and arn = $1;
        EOQ

        args = [self.input.lambda_arn.value]
      }

      nodes = [
        node.api_gatewayv2_api,
        node.api_gatewayv2_integration,
        node.iam_role,
        node.kms_key,
        node.lambda_alias,
        node.lambda_function,
        node.lambda_function_sns_topic_subscription,
        node.lambda_version,
        node.s3_bucket,
        node.sns_topic,
        node.vpc_security_group,
        node.vpc_subnet,
        node.vpc_vpc
      ]

      edges = [
        edge.api_gateway_api_to_api_gateway_integration,
        edge.api_gateway_integration_to_lambda_function,
        edge.lambda_function_to_iam_role,
        edge.lambda_function_to_kms_key,
        edge.lambda_function_to_lambda_alias,
        edge.lambda_function_to_lambda_version,
        edge.lambda_function_to_vpc_security_group,
        edge.lambda_function_to_vpc_subnet,
        edge.s3_bucket_to_lambda_function,
        edge.sns_subscription_to_lambda_function,
        edge.sns_topic_to_sns_subscription,
        edge.vpc_subnet_to_vpc_vpc
      ]

      args = {
        api_gatewayv2_api_ids  = with.api_gateway_apis.rows[*].api_id
        iam_role_arns          = with.iam_roles.rows[*].role_arn
        kms_key_arns           = with.kms_keys.rows[*].kms_key_arn
        lambda_function_arn    = self.input.lambda_arn.value
        lambda_function_arns   = [self.input.lambda_arn.value]
        s3_bucket_arns         = with.s3_buckets.rows[*].bucket_arn
        sns_topic_arns         = with.sns_topics.rows[*].topic_arn
        vpc_security_group_ids = with.vpc_security_groups.rows[*].group_id
        vpc_subnet_ids         = with.vpc_subnets.rows[*].subnet_id
        vpc_vpc_ids            = with.vpc_vpcs.rows[*].vpc_id
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
        query = query.lambda_function_overview
        args = {
          arn = self.input.lambda_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.lambda_function_tags
        args = {
          arn = self.input.lambda_arn.value
        }
      }

    }

    table {
      width = 6
      title = "Last Update Status"
      query = query.lambda_function_last_update_status
      args = {
        arn = self.input.lambda_arn.value
      }
    }

  }

  table {
    title = "Policy"
    query = query.lambda_function_policy
    args = {
      arn = self.input.lambda_arn.value
    }
  }

  table {
    width = 6
    title = "Security Groups"
    query = query.lambda_function_security_groups
    args = {
      arn = self.input.lambda_arn.value
    }
  }

  table {
    width = 6
    title = "Subnets"
    query = query.lambda_function_subnet_ids
    args = {
      arn = self.input.lambda_arn.value
    }
  }

}

query "lambda_function_input" {
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

query "lambda_function_memory" {
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

query "lambda_function_runtime" {
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

query "lambda_function_public" {
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

query "lambda_function_encryption" {
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

query "lambda_function_last_update_status" {
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

query "lambda_function_policy" {
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

query "lambda_function_security_groups" {
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

query "lambda_function_subnet_ids" {
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

query "lambda_function_overview" {
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

query "lambda_function_tags" {
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


//******

