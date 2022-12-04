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
            arn = $1;
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

      nodes = [
        node.lambda_function,
        node.vpc_security_group,
        node.vpc_subnet,
        node.vpc_vpc,
        node.kms_key,
        node.iam_role,
        node.s3_bucket,
        node.lambda_version,
        node.lambda_alias,
        node.sns_topic_subscription,
        node.sns_topic,
        node.api_gatewayv2_integration,
        node.api_gatewayv2_api
      ]

      edges = [
        edge.lambda_function_to_vpc_security_group,
        edge.lambda_function_to_vpc_subnet,
        edge.vpc_subnet_to_vpc_vpc,
        edge.lambda_function_to_kms_key,
        edge.lambda_function_to_iam_role,
        edge.s3_bucket_to_lambda_function,
        edge.lambda_function_to_lambda_version,
        edge.lambda_function_to_lambda_alias,
        edge.sns_subscription_to_lambda_function,
        edge.sns_topic_to_sns_subscription,
        edge.api_gateway_integration_to_lambda_function,
        edge.api_gateway_api_to_api_gateway_integration
      ]

      args = {
        lambda_function_arn    = self.input.lambda_arn.value
        lambda_function_arns   = [self.input.lambda_arn.value]
        vpc_vpc_ids            = with.vpc_vpcs.rows[*].vpc_id
        vpc_subnet_ids         = with.vpc_subnets.rows[*].subnet_id
        vpc_security_group_ids = with.vpc_security_groups.rows[*].group_id
        sns_topic_arns         = with.sns_topics.rows[*].topic_arn
        kms_key_arns           = with.kms_keys.rows[*].kms_key_arn
        iam_role_arns          = with.iam_roles.rows[*].role_arn
        s3_bucket_arns         = with.s3_buckets.rows[*].bucket_arn
        api_gatewayv2_api_ids  = with.api_gateway_apis.rows[*].api_id
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

node "lambda_function" {
  category = category.lambda_function

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Runtime', runtime,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_lambda_function
    where
      arn = any($1);
  EOQ

  param "lambda_function_arns" {}
}

edge "lambda_function_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    select
      l.arn as from_id,
      s as to_id
    from
      aws_lambda_function as l,
      jsonb_array_elements_text(vpc_security_group_ids) as s
    where
      l.arn = any($1);
  EOQ

  param "lambda_function_arns" {}
}

edge "lambda_function_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      sg as from_id,
      s as to_id
    from
      aws_lambda_function as l,
      jsonb_array_elements_text(vpc_subnet_ids) as s,
      jsonb_array_elements_text(vpc_security_group_ids) as sg
    where
      l.arn = any($1);
  EOQ

  param "lambda_function_arns" {}
}

edge "lambda_function_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      l.arn as from_id,
      l.kms_key_arn as to_id
    from
      aws_lambda_function as l
    where
      l.kms_key_arn is not null
      and l.arn = any($1);
  EOQ

  param "lambda_function_arns" {}
}

edge "lambda_function_to_iam_role" {
  title = "assumes"

  sql = <<-EOQ
    select
      l.arn as from_id,
      l.role as to_id
    from
      aws_lambda_function as l
    where
      l.role is not null
      and l.arn = any($1);
  EOQ

  param "lambda_function_arns" {}
}

node "lambda_version" {
  category = category.lambda_version

  sql = <<-EOQ
    select
      v.arn as id,
      v.title as title,
      jsonb_build_object(
        'Version', v.version,
        'ARN', v.arn,
        'Runtime', v.runtime,
        'Region', v.region,
        'Account ID', v.account_id
      ) as properties
    from
      aws_lambda_function as l,
      aws_lambda_version as v
    where
      l.name = v.function_name
      and l.account_id = v.account_id
      and l.region = v.region
      and l.arn = any($1);
  EOQ

  param "lambda_function_arns" {}
}

edge "lambda_function_to_lambda_version" {
  title = "version"

  sql = <<-EOQ
    select
      l.arn as from_id,
      v.arn as to_id
    from
      aws_lambda_function as l,
      aws_lambda_version as v
    where
      l.name = v.function_name
      and l.account_id = v.account_id
      and l.region = v.region
      and l.arn = any($1);
  EOQ

  param "lambda_function_arns" {}
}

node "lambda_alias" {
  category = category.lambda_alias

  sql = <<-EOQ
    select
      a.alias_arn as id,
      a.title as title,
      jsonb_build_object(
        'Name', a.name,
        'Description', a.description,
        'ARN', a.alias_arn,
        'Region', a.region,
        'Account ID', a.account_id
      ) as properties
    from
      aws_lambda_function as l,
      aws_lambda_alias as a
    where
      a.function_name = l.name
      and a.account_id = l.account_id
      and a.region = l.region
      and l.arn = any($1);
  EOQ

  param "lambda_function_arns" {}
}

edge "lambda_function_to_lambda_alias" {
  title = "alias"

  sql = <<-EOQ
    select
      concat(l.arn, ':', a.function_version) as from_id,
      a.alias_arn as to_id
    from
      aws_lambda_function as l,
      aws_lambda_alias as a
    where
      a.function_name = l.name
      and a.account_id = l.account_id
      and a.region = l.region
      and l.arn = any($1);
  EOQ

  param "lambda_function_arns" {}
}

edge "sns_topic_to_sns_subscription" {
  title = "subscription"

  sql = <<-EOQ
     select
      topic_arn as from_id,
      subscription_arn as to_id
    from
      aws_sns_topic_subscription
    where
      protocol = 'lambda'
      and topic_arn = any($1);
  EOQ

  param "sns_topic_arns" {}
}

node "sns_topic_subscription" {
  category = category.sns_topic_subscription

  sql = <<-EOQ
    select
      subscription_arn as id,
      split_part(title, '-', 1) as title,
      jsonb_build_object(
        'ARN', subscription_arn,
        'Endpoint', endpoint,
        'Region', region,
        'Account ID', account_id
      ) as properties
    from
      aws_sns_topic_subscription
    where
      protocol = 'lambda'
      and (
        endpoint = $1
        or endpoint like $1 || ':%'
      )

  EOQ

  param "lambda_function_arn" {}
}

edge "sns_subscription_to_lambda_function" {
  title = "triggers"

  sql = <<-EOQ
     select
      subscription_arn as from_id,
      endpoint as to_id
    from
      aws_sns_topic_subscription
    where
      protocol = 'lambda'
      and (
        endpoint = any($1)
        or endpoint like any($1) || ':%'
      )
  EOQ

  param "lambda_function_arns" {}
}

node "api_gatewayv2_integration" {
  category = category.api_gatewayv2_integration

  sql = <<-EOQ
    select
      i.integration_id as id,
      i.title as title,
      jsonb_build_object(
        'ID', i.integration_id,
        'ARN', i.arn,
        'Integration Method', i.integration_method,
        'Integration Type', i.integration_type,
        'Integration URI', i.integration_URI,
        'Region', i.region,
        'Account ID', i.account_id
      ) as properties
    from
      aws_api_gatewayv2_integration as i
    where
      i.integration_uri = any($1);
  EOQ

  param "lambda_function_arns" {}
}

edge "api_gateway_integration_to_lambda_function" {
  title = "invokes"

  sql = <<-EOQ
    select
     i.integration_id as from_id,
     i.integration_uri as to_id
    from
      aws_api_gatewayv2_integration as i
    where
      i.integration_uri = any($1);
  EOQ

  param "lambda_function_arns" {}
}

edge "api_gateway_api_to_api_gateway_integration" {
  title = "integration"

  sql = <<-EOQ
    select
     api_id as from_id,
     integration_id as to_id
    from
      aws_api_gatewayv2_integration
    where
      api_id = any($1);
  EOQ

  param "api_gatewayv2_api_ids" {}
}

