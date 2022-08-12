dashboard "aws_iam_role_detail" {

  title         = "AWS IAM Role Detail"
  documentation = file("./dashboards/iam/docs/iam_role_detail.md")

  tags = merge(local.iam_common_tags, {
    type = "Detail"
  })

  input "role_arn" {
    title = "Select a role:"
    sql   = query.aws_iam_role_input.sql
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
      type  = "graph"
      title = "Relationships"
      query = query.aws_iam_role_relationships_graph
      args = {
        arn = self.input.role_arn.value
      }
      category "aws_iam_role" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/iam_role_light.svg"))
      }

      category "aws_iam_policy" {
        color = "blue"
        href  = "/aws_insights.dashboard.aws_iam_policy_detail?input.policy_arn={{.properties.'ARN' | @uri}}"
      }

      category "aws_ec2_instance" {
        href = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_id={{.properties.'Instance ID' | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_instance_light.svg"))
      }

      category "aws_lambda_function" {
        href = "${dashboard.aws_lambda_function_detail.url_path}?input.lambda_arn={{.properties.ARN | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/lambda_function_light.svg"))
      }

      category "aws_guardduty_detector" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/guardduty_detector_light.svg"))
      }

      category "aws_emr_cluster" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/emr_cluster_light.svg"))
      }

      category "aws_kinesisanalyticsv2_application" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/kinesis_analytics_application_light.svg"))
      }

      category "uses" {
        color = "green"
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

query "aws_iam_role_relationships_graph" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      role_id as id,
      name as title,
      'aws_iam_role' as category,
      jsonb_build_object( 'ARN', arn, 'Create Date', create_date, 'Max Session Duration', max_session_duration, 'Account ID', account_id ) as properties
    from
      aws_iam_role
    where
      arn = $1

    -- To IAM Policies (node)
    union all
    select
      null as from_id,
      null as to_id,
      policy_id as id,
      name as title,
      'aws_iam_policy' as category,
      jsonb_build_object( 'ARN', arn, 'AWS Managed', is_aws_managed::text, 'Attached', is_attached::text, 'Create Date', create_date, 'Account ID', account_id ) as properties
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
      )

    -- To IAM Policies (edge)
    union all
    select
      r.role_id as from_id,
      p.policy_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object( 'Policy Name', p.name, 'AWS Managed', p.is_aws_managed ) as properties
    from
      aws_iam_role as r,
      jsonb_array_elements_text(attached_policy_arns) as arns
      left join
        aws_iam_policy as p
        on p.arn = arns
    where
      r.arn = $1

    -- From Kinesis Applications (node)
    union all
    select
      null as from_id,
      null as to_id,
      application_arn as id,
      application_name as title,
      'aws_kinesisanalyticsv2_application' as category,
      jsonb_build_object( 'ARN', application_arn, 'Application Status', application_status, 'Create Timestamp', create_timestamp, 'Runtime Environment', runtime_environment, 'Account ID', account_id, 'Region', region ) as properties
    from
      aws_kinesisanalyticsv2_application
    where
      service_execution_role = $1

    -- From Kinesis Applications (edge)
    union all
    select
      application_arn as from_id,
      role_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object( 'Service Execution Role', service_execution_role, 'Account ID', a.account_id ) as properties
    from
      aws_iam_role as r,
      aws_kinesisanalyticsv2_application as a
    where
      r.arn = $1
      and r.arn = a.service_execution_role

    -- From EMR Clusters (node)
    union all
    select
      null as from_id,
      null as to_id,
      id as id,
      name as title,
      'aws_emr_cluster' as category,
      jsonb_build_object( 'ARN', cluster_arn, 'State', state, 'Log URI', log_uri, 'Auto Terminate', auto_terminate::text, 'Account ID', account_id, 'Region', region ) as properties
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
      )

    -- From EMR Clusters (edge)
    union all
    select
      c.id as from_id,
      role_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object( 'Service Role', service_role, 'Account ID', c.account_id ) as properties
    from
      aws_iam_role as r,
      aws_emr_cluster as c
    where
      r.arn = $1
      and r.name = c.service_role

    -- From GuardDuty Detectors (node)
    union all
    select
      null as from_id,
      null as to_id,
      detector_id as id,
      detector_id as title,
      'aws_guardduty_detector' as category,
      jsonb_build_object( 'ARN', arn, 'Status', status, 'Created At', created_at, 'Account ID', account_id, 'Region', region ) as properties
    from
      aws_guardduty_detector
    where
      service_role = $1

    -- From GuardDuty Detectors (edge)
    union all
    select
      detector_id as from_id,
      role_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object( 'Service Role', service_role, 'Account ID', d.account_id ) as properties
    from
      aws_iam_role as r,
      aws_guardduty_detector as d
    where
      r.arn = $1
      and r.arn = d.service_role

    -- From Lambda Functions (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      name as title,
      'aws_lambda_function' as category,
      jsonb_build_object( 'ARN', arn, 'Last Modified', last_modified, 'Version', version, 'State', state, 'Account ID', account_id, 'Region', region ) as properties
    from
      aws_lambda_function
    where
      role = $1

    -- From Lambda Functions (edge)
    union all
    select
      f.arn as from_id,
      role_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object( 'Account ID', f.account_id ) as properties
    from
      aws_iam_role as r,
      aws_lambda_function as f
    where
      r.arn = $1
      and r.arn = f.role

    -- From Instance Profiles (node)
    union all
    select
      null as from_id,
      null as to_id,
      iam_instance_profile_arn as id,
      iam_instance_profile_arn as title,
      'iam_instance_profile_arn' as category,
      jsonb_build_object( 'Instance Profile ARN', iam_instance_profile_arn ) as properties
    from
      aws_iam_role,
      jsonb_array_elements_text(instance_profile_arns) as iam_instance_profile_arn
    where
      arn = $1

     -- From Instance Profiles (edge)
    union all
    select
      iam_instance_profile_arn as from_id,
      role_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object( 'Instance Profile ARN', iam_instance_profile_arn ) as properties
    from
      aws_iam_role,
      jsonb_array_elements_text(instance_profile_arns) as iam_instance_profile_arn
    where
      arn = $1

    -- From EC2 Instances (node)
    union all
    select
      null as from_id,
      null as to_id,
      i.instance_id as id,
      i.instance_id as title,
      'aws_ec2_instance' as category,
      jsonb_build_object( 'Name', i.tags ->> 'Name', 'Instance ID', instance_id, 'ARN', i.arn, 'Account ID', i.account_id, 'Region', i.region ) as properties
    from
      aws_ec2_instance as i,
      aws_iam_role as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      r.arn = $1
      and instance_profile = i.iam_instance_profile_arn

    -- From EC2 Instances (edge)
    union all
    select
      i.instance_id as from_id,
      i.iam_instance_profile_arn as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object( 'Instance ARN', i.arn, 'Instance Profile ARN', i.iam_instance_profile_arn, 'Account ID', i.account_id ) as properties
    from
      aws_ec2_instance as i,
      aws_iam_role as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      r.arn = $1
      and instance_profile = i.iam_instance_profile_arn

    order by
      category,
      from_id,
      to_id;
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
