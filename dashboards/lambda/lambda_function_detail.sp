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
      width = 3
      query = query.lambda_function_memory
      args  = [self.input.lambda_arn.value]
    }

    card {
      width = 3
      query = query.lambda_function_runtime
      args  = [self.input.lambda_arn.value]
    }

    card {
      width = 3
      query = query.lambda_function_encryption
      args  = [self.input.lambda_arn.value]
    }

    card {
      width = 3
      query = query.lambda_function_public
      args  = [self.input.lambda_arn.value]
    }

  }

  with "api_gateway_apis_for_lambda_function" {
    query = query.api_gateway_apis_for_lambda_function
    args  = [self.input.lambda_arn.value]
  }

  with "iam_roles_for_lambda_function" {
    query = query.iam_roles_for_lambda_function
    args  = [self.input.lambda_arn.value]
  }

  with "kms_keys_for_lambda_function" {
    query = query.kms_keys_for_lambda_function
    args  = [self.input.lambda_arn.value]
  }

  with "policy_std_for_lambda_function" {
    query = query.policy_std_for_lambda_function
    args  = [self.input.lambda_arn.value]
  }

  with "s3_buckets_for_lambda_function" {
    query = query.s3_buckets_for_lambda_function
    args  = [self.input.lambda_arn.value]
  }

  with "sns_topic_subscriptions_for_lambda_function" {
    query = query.sns_topic_subscriptions_for_lambda_function
    args  = [self.input.lambda_arn.value]
  }

  with "sns_topics_for_lambda_function" {
    query = query.sns_topics_for_lambda_function
    args  = [self.input.lambda_arn.value]
  }

  with "vpc_security_groups_for_lambda_function" {
    query = query.vpc_security_groups_for_lambda_function
    args  = [self.input.lambda_arn.value]
  }

  with "vpc_subnets_for_lambda_function" {
    query = query.vpc_subnets_for_lambda_function
    args  = [self.input.lambda_arn.value]
  }

  with "vpc_vpcs_for_lambda_function" {
    query = query.vpc_vpcs_for_lambda_function
    args  = [self.input.lambda_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.api_gatewayv2_api
        args = {
          api_gatewayv2_api_ids = with.api_gateway_apis_for_lambda_function.rows[*].api_id
        }
      }

      node {
        base = node.api_gatewayv2_integration
        args = {
          lambda_function_arns = [self.input.lambda_arn.value]
        }
      }

      node {
        base = node.iam_role
        args = {
          iam_role_arns = with.iam_roles_for_lambda_function.rows[*].role_arn
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys_for_lambda_function.rows[*].kms_key_arn
        }
      }

      node {
        base = node.lambda_alias
        args = {
          lambda_function_arns = [self.input.lambda_arn.value]
        }
      }

      node {
        base = node.lambda_function
        args = {
          lambda_function_arns = [self.input.lambda_arn.value]
        }
      }

      node {
        base = node.lambda_version
        args = {
          lambda_function_arns = [self.input.lambda_arn.value]
        }
      }

      node {
        base = node.s3_bucket
        args = {
          s3_bucket_arns = with.s3_buckets_for_lambda_function.rows[*].bucket_arn
        }
      }

      node {
        base = node.sns_topic
        args = {
          sns_topic_arns = with.sns_topics_for_lambda_function.rows[*].topic_arn
        }
      }

      node {
        base = node.sns_topic_subscription
        args = {
          sns_topic_subscription_arns = with.sns_topic_subscriptions_for_lambda_function.rows[*].subscription_arn
        }
      }

      node {
        base = node.vpc_security_group
        args = {
          vpc_security_group_ids = with.vpc_security_groups_for_lambda_function.rows[*].group_id
        }
      }

      node {
        base = node.vpc_subnet
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_lambda_function.rows[*].subnet_id
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_lambda_function.rows[*].vpc_id
        }
      }

      edge {
        base = edge.api_gateway_api_to_api_gateway_integration
        args = {
          api_gatewayv2_api_ids = with.api_gateway_apis_for_lambda_function.rows[*].api_id
        }
      }

      edge {
        base = edge.api_gateway_integration_to_lambda_function
        args = {
          lambda_function_arns = [self.input.lambda_arn.value]
        }
      }

      edge {
        base = edge.lambda_function_to_iam_role
        args = {
          lambda_function_arns = [self.input.lambda_arn.value]
        }
      }

      edge {
        base = edge.lambda_function_to_kms_key
        args = {
          lambda_function_arns = [self.input.lambda_arn.value]
        }
      }

      edge {
        base = edge.lambda_function_to_lambda_alias
        args = {
          lambda_function_arns = [self.input.lambda_arn.value]
        }
      }

      edge {
        base = edge.lambda_function_to_lambda_version
        args = {
          lambda_function_arns = [self.input.lambda_arn.value]
        }
      }

      edge {
        base = edge.lambda_function_to_vpc_security_group
        args = {
          lambda_function_arns = [self.input.lambda_arn.value]
        }
      }

      edge {
        base = edge.lambda_function_to_vpc_subnet
        args = {
          lambda_function_arns = [self.input.lambda_arn.value]
        }
      }

      edge {
        base = edge.s3_bucket_to_lambda_function
        args = {
          s3_bucket_arns = with.s3_buckets_for_lambda_function.rows[*].bucket_arn
        }
      }

      edge {
        base = edge.sns_subscription_to_lambda_function
        args = {
          sns_topic_subscription_arns = with.sns_topic_subscriptions_for_lambda_function.rows[*].subscription_arn
        }
      }

      edge {
        base = edge.sns_topic_to_sns_subscription
        args = {
          sns_topic_arns = with.sns_topics_for_lambda_function.rows[*].topic_arn
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_vpc
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_lambda_function.rows[*].subnet_id
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
        query = query.lambda_function_overview
        args  = [self.input.lambda_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.lambda_function_tags
        args  = [self.input.lambda_arn.value]
      }

    }

    table {
      width = 6
      title = "Last Update Status"
      query = query.lambda_function_last_update_status
      args  = [self.input.lambda_arn.value]
    }

  }

  table {
    width = 6
    title = "Security Groups"
    query = query.lambda_function_security_groups
    args  = [self.input.lambda_arn.value]
  }

  table {
    width = 6
    title = "Subnets"
    query = query.lambda_function_subnet_ids
    args  = [self.input.lambda_arn.value]
  }

  graph {
    title = "Resource Policy"
    base  = graph.iam_resource_policy_structure
    args = {
      policy_std = with.policy_std_for_lambda_function.rows[0].policy_std
    }
  }

}

# Input queries

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

# With queries

query "api_gateway_apis_for_lambda_function" {
  sql = <<-EOQ
    select
      api_id
    from
      aws_api_gatewayv2_integration
    where
      integration_uri = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "iam_roles_for_lambda_function" {
  sql = <<-EOQ
    select
      role as role_arn
    from
      aws_lambda_function
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "kms_keys_for_lambda_function" {
  sql = <<-EOQ
    select
      kms_key_arn
    from
      aws_lambda_function
    where
      kms_key_arn is not null
      and arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "policy_std_for_lambda_function" {
  sql = <<-EOQ
    select
      policy_std
    from
      aws_lambda_function
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "s3_buckets_for_lambda_function" {
  sql = <<-EOQ
    select
      arn as bucket_arn
    from
      aws_s3_bucket,
      jsonb_array_elements(event_notification_configuration -> 'LambdaFunctionConfigurations') as t
    where
      event_notification_configuration -> 'LambdaFunctionConfigurations' <> 'null'
      and t ->> 'LambdaFunctionArn' = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "sns_topic_subscriptions_for_lambda_function" {
  sql = <<-EOQ
    select
      subscription_arn as subscription_arn
    from
      aws_sns_topic_subscription
    where
      protocol = 'lambda'
      and endpoint = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "sns_topics_for_lambda_function" {
  sql = <<-EOQ
    select
      topic_arn as topic_arn
    from
      aws_sns_topic_subscription
    where
      protocol = 'lambda'
      and endpoint = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "vpc_security_groups_for_lambda_function" {
  sql = <<-EOQ
    select
      s as group_id
    from
      aws_lambda_function,
      jsonb_array_elements_text(vpc_security_group_ids) as s
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "vpc_subnets_for_lambda_function" {
  sql = <<-EOQ
    select
      s as subnet_id
    from
      aws_lambda_function,
      jsonb_array_elements_text(vpc_subnet_ids) as s
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "vpc_vpcs_for_lambda_function" {
  sql = <<-EOQ
    select
      vpc_id
    from
      aws_lambda_function
    where
      vpc_id is not null
      and arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

# Card queries

query "lambda_function_memory" {
  sql = <<-EOQ
    select
      'Memory (MB)' as label,
      memory_size as value
    from
      aws_lambda_function
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "lambda_function_runtime" {
  sql = <<-EOQ
    select
      'Runtime' as label,
      runtime as value
    from
      aws_lambda_function
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
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
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
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
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

# Other detail page queries

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
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
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
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "lambda_function_security_groups" {
  sql = <<-EOQ
    select
      p as "ID"
    from
      aws_lambda_function,
      jsonb_array_elements(vpc_security_group_ids) as p
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "lambda_function_subnet_ids" {
  sql = <<-EOQ
    select
      p as "ID"
    from
      aws_lambda_function,
      jsonb_array_elements(vpc_subnet_ids) as p
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
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
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
    EOQ
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
        and account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
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
}
