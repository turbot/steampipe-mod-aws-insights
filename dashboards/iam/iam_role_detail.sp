dashboard "aws_iam_role_detail" {

  title         = "AWS IAM Role Detail"
  documentation = file("./dashboards/iam/docs/iam_role_detail.md")

  tags = merge(local.iam_common_tags, {
    type = "Detail"
  })

  input "role_arn" {
    title = "Select a role:"
    query = query.aws_iam_role_input
    width = 2
  }

  container {

    card {
      width = 2
      query = query.aws_iam_boundary_policy_for_role
      args = {
        arn = self.input.role_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_iam_role_inline_policy_count_for_role
      args = {
        arn = self.input.role_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_iam_role_direct_attached_policy_count_for_role
      args = {
        arn = self.input.role_arn.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_iam_role_node,
        node.aws_iam_role_to_iam_policy_node,
        # node.aws_iam_role_from_kinesisanalyticsv2_application_node,
        node.aws_iam_role_from_emr_cluster_node,
        node.aws_iam_role_from_guardduty_detector_node,
        node.aws_iam_role_from_lambda_function_node,
        node.aws_iam_role_from_iam_instance_profile_node,
        node.aws_iam_role_from_ec2_instance_node
      ]

      edges = [
        edge.aws_iam_role_to_iam_policy_edge,
        # edge.aws_iam_role_from_kinesisanalyticsv2_application_edge,
        edge.aws_iam_role_from_emr_cluster_edge,
        edge.aws_iam_role_from_guardduty_detector_edge,
        edge.aws_iam_role_from_lambda_function_edge,
        edge.aws_iam_role_from_iam_instance_profile_edge,
        edge.aws_iam_role_from_ec2_instance_edge
      ]

      args = {
        arn = self.input.role_arn.value
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
        query = query.aws_iam_role_overview
        args = {
          arn = self.input.role_arn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_iam_role_tags
        args = {
          arn = self.input.role_arn.value
        }
      }
    }

    container {

      title = "AWS IAM Role Policy Analysis"

      hierarchy {
        type  = "tree"
        width = 6
        title = "Attached Policies"
        query = query.aws_iam_user_manage_policies_hierarchy
        args = {
          arn = self.input.role_arn.value
        }

        category "inline_policy" {
          color = "alert"
        }
        category "managed_policy" {
          color = "ok"
        }

      }


      table {
        title = "Policies"
        width = 6
        query = query.aws_iam_all_policies_for_role
        args = {
          arn = self.input.role_arn.value
        }
      }

    }
  }

}

query "aws_iam_role_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id
      ) as tags
    from
      aws_iam_role
    order by
      title;
  EOQ
}

query "aws_iam_boundary_policy_for_role" {
  sql = <<-EOQ
    select
      case
        when permissions_boundary_type is null then 'Not set'
        when permissions_boundary_type = '' then 'Not set'
        else substring(permissions_boundary_arn, 'arn:aws:iam::\d{12}:.+\/(.*)')
      end as value,
      'Boundary Policy' as label,
      case
        when permissions_boundary_type is null then 'alert'
        when permissions_boundary_type = '' then 'alert'
        else 'ok'
      end as type
    from
      aws_iam_role
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_role_inline_policy_count_for_role" {
  sql = <<-EOQ
    select
      case when inline_policies is null then 0 else jsonb_array_length(inline_policies) end as value,
      'Inline Policies' as label,
      case when inline_policies is null or jsonb_array_length(inline_policies) = 0 then 'ok' else 'alert' end as type
    from
      aws_iam_role
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_role_direct_attached_policy_count_for_role" {
  sql = <<-EOQ
    select
      case when attached_policy_arns is null then 0 else jsonb_array_length(attached_policy_arns) end as value,
      'Attached Policies' as label,
      case when attached_policy_arns is null or jsonb_array_length(attached_policy_arns) = 0 then 'alert' else 'ok' end as type
    from
      aws_iam_role
    where
      arn = $1
  EOQ

  param "arn" {}
}

node "aws_iam_role_node" {
  category = category.aws_iam_role

  sql = <<-EOQ
    select
      role_id as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'Create Date', create_date,
        'Max Session Duration', max_session_duration,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_role
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_iam_role_to_iam_policy_node" {
  category = category.aws_iam_policy

  sql = <<-EOQ
    select
      policy_id as id,
      name as title,
      jsonb_build_object(
        'ARN', arn,
        'AWS Managed', is_aws_managed::text,
        'Attached', is_attached::text,
        'Create Date', create_date,
        'Account ID', account_id
      ) as properties
    from
      aws_iam_policy
    where
      arn in
      (
        select
          jsonb_array_elements_text(attached_policy_arns)
        from
          aws_iam_role
        where
          arn = $1
      );
  EOQ

  param "arn" {}
}

edge "aws_iam_role_to_iam_policy_edge" {
  title = "attached"

  sql = <<-EOQ
    select
      r.role_id as from_id,
      p.policy_id as to_id
    from
      aws_iam_role as r,
      jsonb_array_elements_text(attached_policy_arns) as arns
      left join
        aws_iam_policy as p
        on p.arn = arns
    where
      r.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_iam_role_from_kinesisanalyticsv2_application_node" {
  category = category.aws_kinesisanalyticsv2_application

  sql = <<-EOQ
    select
      application_arn as id,
      application_name as title,
      jsonb_build_object(
        'ARN', application_arn,
        'Application Status', application_status,
        'Create Timestamp', create_timestamp,
        'Runtime Environment', runtime_environment,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_kinesisanalyticsv2_application
    where
      service_execution_role = $1;
  EOQ

  param "arn" {}
}

edge "aws_iam_role_from_kinesisanalyticsv2_application_edge" {
  title = "kinesis application"

  sql = <<-EOQ
    select
      application_arn as from_id,
      role_id as to_id
    from
      aws_iam_role as r,
      aws_kinesisanalyticsv2_application as a
    where
      service_execution_role = $1;
  EOQ

  param "arn" {}
}

node "aws_iam_role_from_emr_cluster_node" {
  category = category.aws_emr_cluster

  sql = <<-EOQ
    select
      id as id,
      name as title,
      jsonb_build_object(
        'ARN', cluster_arn,
        'State', state,
        'Log URI', log_uri,
        'Auto Terminate', auto_terminate::text,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_emr_cluster
    where
      service_role in
      (
        select
          name
        from
          aws_iam_role
        where
          arn = $1
      );
  EOQ

  param "arn" {}
}

edge "aws_iam_role_from_emr_cluster_edge" {
  title = "emr cluster"

  sql = <<-EOQ
    select
      c.id as from_id,
      role_id as to_id,
      jsonb_build_object(
        'Account ID', c.account_id
      ) as properties
    from
      aws_iam_role as r,
      aws_emr_cluster as c
    where
      r.arn = $1
      and r.name = c.service_role;
  EOQ

  param "arn" {}
}

node "aws_iam_role_from_guardduty_detector_node" {
  category = category.aws_guardduty_detector

  sql = <<-EOQ
    select
      detector_id as id,
      detector_id as title,
      jsonb_build_object(
        'ARN', arn,
        'Status', status,
        'Created At', created_at,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_guardduty_detector
    where
      service_role = $1;
  EOQ

  param "arn" {}
}

edge "aws_iam_role_from_guardduty_detector_edge" {
  title = "guardduty detector"

  sql = <<-EOQ
    select
      detector_id as from_id,
      role_id as to_id
    from
      aws_iam_role as r,
      aws_guardduty_detector as d
    where
      r.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_iam_role_from_lambda_function_node" {
  category = category.aws_lambda_function

  sql = <<-EOQ
    select
      arn as id,
      name as title,
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
      role = $1;
  EOQ

  param "arn" {}
}

edge "aws_iam_role_from_lambda_function_edge" {
  title = "lambda function"

  sql = <<-EOQ
    select
      f.arn as from_id,
      role_id as to_id
    from
      aws_iam_role as r,
      aws_lambda_function as f
    where
      r.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_iam_role_from_iam_instance_profile_node" {
  category = category.aws_iam_instance_profile

  sql = <<-EOQ
    select
      iam_instance_profile_arn as id,
      iam_instance_profile_arn as title,
      jsonb_build_object(
        'Instance Profile ARN', iam_instance_profile_arn
      ) as properties
    from
      aws_iam_role,
      jsonb_array_elements_text(instance_profile_arns) as iam_instance_profile_arn
    where
      arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_iam_role_from_iam_instance_profile_edge" {
  title = "instance profile"

  sql = <<-EOQ
    select
      iam_instance_profile_arn as from_id,
      role_id as to_id,
      jsonb_build_object(
        'Instance Profile ARN', iam_instance_profile_arn
      ) as properties
    from
      aws_iam_role,
      jsonb_array_elements_text(instance_profile_arns) as iam_instance_profile_arn
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_iam_role_from_ec2_instance_node" {
  category = category.aws_ec2_instance

  sql = <<-EOQ
    select
      i.instance_id as id,
      i.instance_id as title,
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
      r.arn = $1
      and instance_profile = i.iam_instance_profile_arn;
  EOQ

  param "arn" {}
}

edge "aws_iam_role_from_ec2_instance_edge" {
  title = "ec2 instance"

  sql = <<-EOQ
    select
      i.instance_id as from_id,
      i.iam_instance_profile_arn as to_id,
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
      r.arn = $1
      and instance_profile = i.iam_instance_profile_arn;
  EOQ

  param "arn" {}
}

query "aws_iam_role_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      create_date as "Create Date",
      permissions_boundary_arn as "Boundary Policy",
      role_id as "Role ID",
      arn as "ARN",
      account_id as "Account ID"
    from
      aws_iam_role
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_all_policies_for_role" {
  sql = <<-EOQ
    -- Policies (attached to groups)
    select
      p.name as "Policy",
      policy_arn as "ARN",
      'Attached to Role' as "Via"
    from
      aws_iam_role as r,
      jsonb_array_elements_text(r.attached_policy_arns) as policy_arn,
      aws_iam_policy as p
    where
      p.arn = policy_arn
      and r.arn = $1

    -- Inline Policies (defined on role)
    union select
      i ->> 'PolicyName' as "Policy",
      'N/A' as "ARN",
      'Inline' as "Via"
    from
      aws_iam_role as r,
      jsonb_array_elements(inline_policies_std) as i
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_iam_role_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_iam_role,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key'
  EOQ

  param "arn" {}
}

query "aws_iam_user_manage_policies_hierarchy" {
  sql = <<-EOQ
    select
      $1 as id,
      $1 as title,
      'role' as category,
      null as from_id

    -- Policies (attached to groups)
    union select
      policy_arn as id,
      p.name as title,
      'managed_policy' as category,
      r.arn as from_id
    from
      aws_iam_role as r,
      jsonb_array_elements_text(r.attached_policy_arns) as policy_arn,
      aws_iam_policy as p
    where
      p.arn = policy_arn
      and r.arn = $1

    -- Inline Policies (defined on role)
    union select
      concat('inline_', i ->> 'PolicyName') as id,
      i ->> 'PolicyName' as title,
      'inline_policy' as category,
      r.arn as from_id
    from
      aws_iam_role as r,
      jsonb_array_elements(inline_policies_std) as i
    where
      arn = $1
  EOQ

  param "arn" {}
}
