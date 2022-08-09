dashboard "aws_iam_role_relationships" {
  title = "AWS IAM Role Relationships"
  #documentation = file("./dashboards/iam/docs/iam_role_relationships.md")
  tags = merge(local.iam_common_tags, {
    type = "Relationships"
  })

  input "role_arn" {
    title = "Select a role:"
    query = query.aws_iam_role_input
    width = 4
  }

  graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_iam_role_graph_from_role
    args = {
      arn = self.input.role_arn.value
    }
    category "aws_iam_role" {
      href = "${dashboard.aws_iam_role_detail.url_path}?input.role_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_iam_role.svg"))
    }

    category "aws_iam_policy" {
      color = "blue"
    }

    category "uses" {
      color = "green"
    }
  }

  graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_iam_role_graph_to_role
    args = {
      arn = self.input.role_arn.value
    }
    category "aws_iam_role" {
      href = "${dashboard.aws_iam_role_detail.url_path}?input.role_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_iam_role.svg"))
    }

    category "aws_ec2_instance" {
      href = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_id={{.properties.'Instance ID' | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_ec2_instance.svg"))
    }

    category "aws_lambda_function" {
      href = "${dashboard.aws_lambda_function_detail.url_path}?input.lambda_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_lambda_function.svg"))
    }

    category "uses" {
      color = "green"
    }
  }
}

query "aws_iam_role_graph_from_role" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      role_id as id,
      name as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'ARN', arn,
        'Create Date', create_date,
        'Max Session Duration', max_session_duration,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_role
    where
      arn = $1

    -- Attached Policies - nodes
    union all
    select
      null as from_id,
      null as to_id,
      policy_id as id,
      name as title,
      'aws_iam_policy' as category,
      jsonb_build_object(
        'ARN', arn,
        'AWS Managed', is_aws_managed,
        'Attached', is_attached,
        'Create Date', create_date,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_policy
    where
      arn in (select jsonb_array_elements_text(attached_policy_arns) from aws_iam_role where arn = $1)

    -- Attached Policies - Edges
    union all
    select
      r.role_id as from_id,
      p.policy_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Policy Name', p.name,
        'AWS Managed', p.is_aws_managed
      ) as properties
    from
      aws_iam_role as r,
      jsonb_array_elements_text(attached_policy_arns) as arns
      left join aws_iam_policy as p on p.arn = arns
    where
      r.arn = $1
    order by
      category,from_id,to_id;
  EOQ

  param "arn" {}
}

query "aws_iam_role_graph_to_role" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      role_id as id,
      name as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'ARN', arn,
        'Create Date', create_date,
        'Max Session Duration', max_session_duration,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_role
    where
      arn = $1

    -- Lambda Function - nodes
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      name as title,
      'aws_lambda_function' as category,
      jsonb_build_object(
        'ARN', arn,
        'Last Modified', last_modified,
        'Version', version,
        'State', state,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_lambda_function
    where
      role = $1

    -- Lambda Function  - Edges
    union all
    select
      f.arn as from_id,
      role_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Account ID', f.account_id
      ) as properties
    from
      aws_iam_role as r,
      aws_lambda_function as f
    where
      r.arn = $1 and r.arn = f.role

    -- Instance Profile - nodes
    union all
    select
      null as from_id,
      null as to_id,
      iam_instance_profile_arn as id,
      iam_instance_profile_arn as title,
      'iam_instance_profile_arn' as category,
      jsonb_build_object(
        'Instance Profile ARN', iam_instance_profile_arn
      ) as properties
    from
      aws_iam_role,
      jsonb_array_elements_text(instance_profile_arns) as iam_instance_profile_arn
    where
      arn = $1

     -- Instance Profile  - Edges
    union all
    select
      iam_instance_profile_arn as from_id,
      role_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Instance Profile ARN', iam_instance_profile_arn
      ) as properties
    from
      aws_iam_role,
      jsonb_array_elements_text(instance_profile_arns) as iam_instance_profile_arn
    where
      arn = $1

    -- Instance for Instance Profile - nodes
    union all
    select
      null as from_id,
      null as to_id,
      i.instance_id as id,
      i.instance_id as title,
      'aws_ec2_instance' as category,
      jsonb_build_object(
        'Name', i.tags ->> 'Name',
        'Instance ID', instance_id,
        'ARN', i.arn,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_ec2_instance as i,
      aws_iam_role as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      r.arn = $1 and instance_profile = i.iam_instance_profile_arn

    -- Instance for Instance Profile  - Edges
    union all
    select
      i.instance_id as from_id,
      i.iam_instance_profile_arn as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'Instance ARN', i.arn,
        'Instance Profile ARN', i.iam_instance_profile_arn,
        'Account ID', i.account_id
      ) as properties
    from
      aws_ec2_instance as i,
      aws_iam_role as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      r.arn = $1 and instance_profile = i.iam_instance_profile_arn
    order by
      category,from_id,to_id
  EOQ

  param "arn" {}
}
