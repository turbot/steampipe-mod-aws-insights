dashboard "lambda_function_relationships" {

  title         = "AWS Lambda Function Relationships"
  #documentation = file("./dashboards/lambda/docs/lambda_function_detail.md")

  tags = merge(local.lambda_common_tags, {
    type = "Detail"
  })


  input "lambda_arn" {
    title = "Select a lambda function:"
    sql   = query.aws_lambda_function.sql
    width = 4
  }

  graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_lambda_function_graph_from_function
    args = {
      arn = self.input.lambda_arn.value
    }

    category "aws_lambda_function" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_lambda_function.svg"))
      color = "blue"
      href  = "${dashboard.aws_lambda_function_detail.url_path}?input.lambda_arn={{.properties.'ARN' | @uri}}"
    }

    category "aws_vpc" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_vpc.svg"))
      color = "orange"
      href  = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.'ID' | @uri}}"
    }

    category "aws_vpc_security_group" {
      # icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_vpc.svg"))
      color = "red"
      href  = "${dashboard.aws_vpc_security_group_detail.url_path}?input.security_group_id={{.properties.'ID' | @uri}}"
    }

    category "aws_kms_key" {
      color = "green"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_kms_key.svg"))
      href  = "${dashboard.aws_kms_key_detail.url_path}?input.key_arn={{.properties.'ARN' | @uri}}"
    }

    category "aws_iam_role" {
      color = "pink"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_iam_role.svg"))
      href  = "${dashboard.aws_iam_role_detail.url_path}?input.role_arn={{.properties.'ARN' | @uri}}"
    }

  }

    graph {
      type  = "graph"
      title = "Things that use me..."
      query = query.aws_lambda_function_graph_to_function
      args = {
        arn = self.input.lambda_arn.value
      }

      category "aws_lambda_function" {
        icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_lambda_function.svg"))
        color = "blue"
        href  = "${dashboard.aws_lambda_function_detail.url_path}?input.lambda_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_s3_bucket" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_s3_bucket.svg"))
      color = "orange"
      href  = "${dashboard.aws_s3_bucket_detail.url_path}?input.bucket_arn={{.properties.'ARN' | @uri}}"
    }

  }

}

query "aws_lambda_function" {
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

query "aws_lambda_function_graph_from_function" {
  sql = <<-EOQ
    with lambda as (select * from aws_lambda_function where arn = $1)

    -- lambda node
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_lambda_function' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      lambda

     -- VPC  Nodes
    union all
    select
      null as from_id,
      null as to_id,
      v.arn as id,
      v.title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      lambda as l
      left join aws_vpc as v on v.vpc_id = l.vpc_id

    -- VPC Edges
    union all
    select
      l.arn as from_id,
      v.arn as to_id,
      null as id,
      'Uses' as title,
      'Uses' as category,
      jsonb_build_object(
        'ARN', l.arn,
        'Account ID', l.account_id,
        'Region', l.region
      ) as properties
    from
      lambda as l
      left join aws_vpc as v on v.vpc_id = l.vpc_id

    -- Security Group Nodes
    union all
    select
      null as from_id,
      null as to_id,
      sg.arn as id,
      sg.group_id as title,
      'aws_vpc_security_group' as category,
      jsonb_build_object(
        'ID', sg.group_id,
        'Account ID', sg.account_id,
        'Region', sg.region
      ) as properties
    from
      lambda as l,
      jsonb_array_elements_text(vpc_security_group_ids) as s
      left join aws_vpc_security_group as sg on sg.group_id = s

    -- Security Group Edges
    union all
    select
      l.arn as from_id,
      sg.arn as to_id,
      null as id,
      'Uses' as title,
      'Uses' as category,
      jsonb_build_object(
        'ARN', l.arn,
        'Account ID', l.account_id,
        'Region', l.region
      ) as properties
    from
      lambda as l,
      jsonb_array_elements_text(vpc_security_group_ids) as s
      left join aws_vpc_security_group as sg on sg.group_id = s

  -- Kms key Nodes
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

    -- Kms key Edges
    union all
    select
      l.arn as from_id,
      k.arn as to_id,
      null as id,
      'Encrypted With' as title,
      'encrypted_with' as category,
      jsonb_build_object(
        'ARN', l.arn,
        'Account ID', l.account_id,
        'Region', l.region
      ) as properties
    from
      lambda as l
      left join aws_kms_key as k on k.arn = l.kms_key_arn


    -- IAM Role Nodes
    union all
    select
      null as from_id,
      null as to_id,
      r.arn as id,
      r.title as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'ARN', l.arn,
        'Account ID', l.account_id,
        'Region', l.region
      ) as properties
    from
      lambda as l
      left join aws_iam_role as r on r.arn = l.role

    -- IAM Role Edges
    union all
    select
      l.arn as from_id,
      r.arn as to_id,
      null as id,
      'Attached To' as title,
      'attached_to' as category,
      jsonb_build_object(
        'ARN', l.arn,
        'Account ID', l.account_id,
        'Region', l.region
      ) as properties
    from
      lambda as l
      left join aws_iam_role as r on r.arn = l.role

  EOQ
  param "arn" {}
}

query "aws_lambda_function_graph_to_function" {
  sql = <<-EOQ
    with lambda as (select * from aws_lambda_function where arn = $1)

    -- lambda node
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_lambda_function' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      lambda

    -- Buckets that use me - nodes
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
        case jsonb_typeof(event_notification_configuration -> 'LambdaFunctionConfigurations')
          when 'array' then (event_notification_configuration -> 'LambdaFunctionConfigurations')
          else null end
        )
        as t
    where
      t ->> 'LambdaFunctionArn'  = $1

    -- Buckets that use me - edges
    union all
    select
      arn as from_id,
      $1 as to_id,
      null as id,
      'Used By' as title,
      'used_by' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_s3_bucket,
      jsonb_array_elements(
        case jsonb_typeof(event_notification_configuration -> 'LambdaFunctionConfigurations')
          when 'array' then (event_notification_configuration -> 'LambdaFunctionConfigurations')
          else null end
        )
        as t
    where
      t ->> 'LambdaFunctionArn'  = $1

  EOQ
  param "arn" {}
}
