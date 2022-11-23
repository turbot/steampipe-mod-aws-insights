dashboard "aws_lambda_function_detail" {

  title         = "AWS Lambda Function Detail"
  documentation = file("./dashboards/lambda/docs/lambda_function_detail.md")

  tags = merge(local.lambda_common_tags, {
    type = "Detail"
  })


  input "lambda_arn" {
    title = "Select a lambda function:"
    query = query.aws_lambda_function_input
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
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_lambda_function_node,
        node.aws_lambda_to_vpc_security_group_node,
        node.aws_lambda_vpc_subnet_node,
        node.aws_lambda_to_vpc_node,

        node.aws_lambda_to_kms_key_node,
        node.aws_lambda_to_iam_role_node,
        node.aws_lambda_from_s3_bucket_node,

        node.aws_lambda_version_node,
        node.aws_lambda_alias_node,
        node.aws_lambda_from_sns_subscription_node,
        node.aws_lambda_from_sns_topic_node,
        node.aws_lambda_from_api_gateway_integration_node,
        node.aws_lambda_from_api_gateway_node,


      ]

      edges = [
        edge.aws_lambda_to_vpc_security_group_edge,
        edge.aws_lambda_vpc_subnet_edge,
        edge.aws_lambda_to_vpc_edge,
        edge.aws_lambda_to_kms_key_edge,
        edge.aws_lambda_to_iam_role_edge,
        edge.aws_lambda_from_s3_bucket_edge,
        edge.aws_lambda_version_edge,
        edge.aws_lambda_alias_edge,
        edge.aws_lambda_sns_subscription_edge,
        edge.aws_lambda_sns_topic_edge,
        edge.aws_lambda_api_gateway_integration_edge,
        edge.aws_lambda_api_gateway_edge
      ]

      args = {
        arn = self.input.lambda_arn.value
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


//******

node "aws_lambda_function_node" {
  category = category.aws_lambda_function

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
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_lambda_to_vpc_node" {
  category = category.aws_vpc

  sql = <<-EOQ
    select
      v.vpc_id as id,
      v.title as title,
      jsonb_build_object(
        'ARN', v.arn,
        'VPC ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      aws_lambda_function as l,
      aws_vpc as v
    where
      v.vpc_id = l.vpc_id
      and l.arn = $1
  EOQ

  param "arn" {}
}

edge "aws_lambda_to_vpc_edge" {
  title = "vpc"
  # a lambda can only be in one subnet, so we
  # can assume all the vpc_subnet_ids are in the lambda's vpc
  sql = <<-EOQ
    select
      s as from_id,
      l.vpc_id as to_id
    from
      aws_lambda_function as l,
      jsonb_array_elements_text(vpc_subnet_ids) as s
    where
      l.vpc_id  is not null
      and l.vpc_id <> ''
      and l.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_lambda_to_vpc_security_group_node" {
  category = category.aws_vpc_security_group

  sql = <<-EOQ
    select
      sg.group_id as id,
      sg.title as title,
      jsonb_build_object(
        'ARN', sg.arn,
        'Group ID', sg.group_id,
        'Group Name', sg.group_name,
        'Account ID', sg.account_id,
        'Region', sg.region
      ) as properties
    from
      aws_lambda_function as l,
      jsonb_array_elements_text(vpc_security_group_ids) as s,
      aws_vpc_security_group as sg
      where
        sg.group_id = s
        and l.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_lambda_to_vpc_security_group_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      l.arn as from_id,
      s as to_id
    from
      aws_lambda_function as l,
      jsonb_array_elements_text(vpc_security_group_ids) as s
      where
        l.arn = $1;
  EOQ

  param "arn" {}
}



node "aws_lambda_vpc_subnet_node" {
  category = category.aws_vpc_subnet

  sql = <<-EOQ
    select
      subnet.subnet_id as id,
      subnet.title as title,
      jsonb_build_object(
        'ARN', subnet.subnet_arn,
        'Subnet ID', subnet.subnet_id,
        'Name', subnet.tags ->> 'Name',
        'Account ID', subnet.account_id,
        'Region', subnet.region
      ) as properties
    from
      aws_lambda_function as l,
      jsonb_array_elements_text(vpc_subnet_ids) as s,
      aws_vpc_subnet as subnet
      where
        subnet.subnet_id = s
        and l.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_lambda_vpc_subnet_edge" {
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
        l.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_lambda_to_kms_key_node" {
  category = category.aws_kms_key

  sql = <<-EOQ
    select
      k.arn as id,
      k.title as title,
      jsonb_build_object(
        'ARN', k.arn,
        'Key Manager', k.key_manager,
        'Creation Date', k.creation_date,
        'Enabled', k.enabled::text,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      aws_lambda_function as l,
      aws_kms_key as k
    where
      k.arn = l.kms_key_arn
      and l.arn = $1
  EOQ

  param "arn" {}
}

edge "aws_lambda_to_kms_key_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      l.arn as from_id,
      l.kms_key_arn as to_id
    from
      aws_lambda_function as l
    where
      l.kms_key_arn is not null
      and l.arn = $1
  EOQ

  param "arn" {}
}

node "aws_lambda_to_iam_role_node" {
  category = category.aws_iam_role

  sql = <<-EOQ
    select
      r.arn as id,
      r.title as title,
      jsonb_build_object(
        'ARN', r.arn,
        'Create Date', r.create_date,
        'Max Session Duration', r.max_session_duration,
        'Account ID', r.account_id
      ) as properties
    from
      aws_lambda_function as l,
      aws_iam_role as r
    where
      r.arn = l.role
      and l.arn = $1
  EOQ

  param "arn" {}
}

edge "aws_lambda_to_iam_role_edge" {
  title = "assumes"

  sql = <<-EOQ
    select
      l.arn as from_id,
      l.role as to_id
    from
      aws_lambda_function as l
    where
      l.role is not null
      and l.arn = $1
  EOQ

  param "arn" {}
}

node "aws_lambda_from_s3_bucket_node" {
  category = category.aws_s3_bucket

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region,
        'Public', bucket_policy_is_public::text,
        'Event Notification Configuration ID', t ->> 'Id',
        'Events Configured', t -> 'Events'
      ) as properties
     from
      aws_s3_bucket,
      jsonb_array_elements(event_notification_configuration -> 'LambdaFunctionConfigurations') as t
    where
      event_notification_configuration -> 'LambdaFunctionConfigurations' <> 'null'
      and t ->> 'LambdaFunctionArn' = $1;
  EOQ

  param "arn" {}
}

edge "aws_lambda_from_s3_bucket_edge" {
  title = "invokes"

  sql = <<-EOQ
    select
      arn as from_id,
      t ->> 'LambdaFunctionArn' as to_id,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Event Notification Configuration ID', t ->> 'Id',
        'Events Configured', t -> 'Events',
        'Region', region
      ) as properties
    from
      aws_s3_bucket,
      jsonb_array_elements(event_notification_configuration -> 'LambdaFunctionConfigurations') as t
    where
      event_notification_configuration -> 'LambdaFunctionConfigurations' <> 'null'
      and t ->> 'LambdaFunctionArn' = $1;
  EOQ

  param "arn" {}
}





node "aws_lambda_version_node" {
  category = category.aws_lambda_version

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
      and l.arn = $1

  EOQ

  param "arn" {}
}



edge "aws_lambda_version_edge" {
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
      and l.arn = $1
  EOQ

  param "arn" {}
}


node "aws_lambda_alias_node" {
  category = category.aws_lambda_alias

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
      and l.arn = $1
  EOQ

  param "arn" {}
}


edge "aws_lambda_alias_edge" {
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
      and l.arn = $1
  EOQ

  param "arn" {}
}




node "aws_lambda_from_sns_topic_node" {
  category = category.aws_sns_topic

  sql = <<-EOQ
    select
      t.topic_arn as id,
      left(t.title, 30) as title,
      jsonb_build_object(
        'ARN', t.topic_arn,
        'Region', t.region,
        'Account ID', t.account_id
      ) as properties
    from
      aws_sns_topic_subscription as s,
      aws_sns_topic as t
    where
      t.topic_arn = s.topic_arn
      and protocol = 'lambda'
      and endpoint = $1
  EOQ

  param "arn" {}
}





edge "aws_lambda_sns_topic_edge" {
  title = "subscription"

  sql = <<-EOQ
     select
      topic_arn as from_id,
      subscription_arn as to_id
    from
      aws_sns_topic_subscription
    where
      protocol = 'lambda'
      and endpoint = $1;
  EOQ

  param "arn" {}
}



node "aws_lambda_from_sns_subscription_node" {
  category = category.aws_sns_topic_subscription

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

  param "arn" {}
}





edge "aws_lambda_sns_subscription_edge" {
  title = "invokes"

  sql = <<-EOQ
     select
      subscription_arn as from_id,
      endpoint as to_id
    from
      aws_sns_topic_subscription
    where
      protocol = 'lambda'
      and (
        endpoint = $1
        or endpoint like $1 || ':%'
      )
  EOQ

  param "arn" {}
}



node "aws_lambda_from_api_gateway_integration_node" {
  category = category.aws_api_gatewayv2_integration

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
      i.integration_uri = $1
  EOQ

  param "arn" {}
}




edge "aws_lambda_api_gateway_integration_edge" {
  title = "invokes"

  sql = <<-EOQ
    select
     i.integration_id as from_id,
     i.integration_uri as to_id
    from
      aws_api_gatewayv2_integration as i
    where
      i.integration_uri = $1
  EOQ

  param "arn" {}
}


node "aws_lambda_from_api_gateway_node" {
  category = category.aws_api_gatewayv2_api

  sql = <<-EOQ
    select
      api.api_id as id,
      left(api.title, 30) as title,
      jsonb_build_object(
        'Name', api.name,
        'ID', api.api_id,
        'Endpoint', api.api_endpoint,
        'Region', api.region,
        'Account ID', api.account_id
      ) as properties
    from
      aws_api_gatewayv2_integration as i,
      aws_api_gatewayv2_api as api
    where
      i.api_id = api.api_id
      and i.integration_uri = $1
  EOQ

  param "arn" {}
}



edge "aws_lambda_api_gateway_edge" {
  title = "integration"

  sql = <<-EOQ
    select
     api.api_id as from_id,
     i.integration_id as to_id
    from
      aws_api_gatewayv2_integration as i,
      aws_api_gatewayv2_api as api
    where
      i.api_id = api.api_id
      and i.integration_uri = $1
  EOQ

  param "arn" {}
}

