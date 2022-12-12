dashboard "iam_role_detail" {

  title         = "AWS IAM Role Detail"
  documentation = file("./dashboards/iam/docs/iam_role_detail.md")

  tags = merge(local.iam_common_tags, {
    type = "Detail"
  })

  input "role_arn" {
    title = "Select a role:"
    query = query.iam_role_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.iam_boundary_policy_for_role
      args = {
        arn = self.input.role_arn.value
      }
    }

    card {
      width = 2
      query = query.iam_role_inline_policy_count_for_role
      args = {
        arn = self.input.role_arn.value
      }
    }

    card {
      width = 2
      query = query.iam_role_direct_attached_policy_count_for_role
      args = {
        arn = self.input.role_arn.value
      }
    }

  }

  # container {

  #   graph {
  #     title     = "Relationships"
  #     type      = "graph"
  #     direction = "TD"

  #     with "ec2_instances" {
  #       sql = <<-EOQ
  #         select
  #           i.arn as instance_arn
  #         from
  #           aws_ec2_instance as i,
  #           aws_iam_role as r,
  #           jsonb_array_elements_text(instance_profile_arns) as instance_profile
  #         where
  #           r.arn = $1
  #           and instance_profile = i.iam_instance_profile_arn;
  #       EOQ

  #       args = [self.input.role_arn.value]
  #     }

  #     with "emr_clusters" {
  #       sql = <<-EOQ
  #         select
  #           c.cluster_arn as cluster_arn
  #         from
  #           aws_iam_role as r,
  #           aws_emr_cluster as c
  #         where
  #           r.arn = $1
  #           and r.name = c.service_role;
  #       EOQ

  #       args = [self.input.role_arn.value]
  #     }

  #     with "guardduty_detectors" {
  #       sql = <<-EOQ
  #         select
  #           arn as guardduty_detector_arn
  #         from
  #           aws_guardduty_detector
  #         where
  #           service_role = $1;
  #       EOQ

  #       args = [self.input.role_arn.value]
  #     }

  #     with "iam_policies" {
  #       sql = <<-EOQ
  #         select
  #           policy_arn
  #         from
  #           aws_iam_role,
  #           jsonb_array_elements_text(attached_policy_arns) as policy_arn
  #         where
  #           arn = $1;
  #       EOQ

  #       args = [self.input.role_arn.value]
  #     }

  #     with "lambda_functions" {
  #       sql = <<-EOQ
  #         select
  #           arn as function_arn
  #         from
  #           aws_lambda_function
  #         where
  #           role = $1;
  #       EOQ

  #       args = [self.input.role_arn.value]
  #     }


  #     nodes = [
  #       node.ec2_instance,
  #       node.emr_cluster,
  #       node.guardduty_detector,
  #       node.iam_instance_profile,
  #       node.iam_policy,
  #       node.iam_role,
  #       node.iam_role_trusted_aws,
  #       node.iam_role_trusted_federated,
  #       node.iam_role_trusted_service,
  #       node.lambda_function
  #     ]

  #     edges = [
  #       edge.ec2_instance_to_iam_instance_profile,
  #       edge.emr_cluster_to_iam_role,
  #       edge.guardduty_detector_to_iam_role,
  #       edge.iam_instance_profile_to_iam_role,
  #       edge.iam_role_to_iam_policy,
  #       edge.iam_role_trusted_aws,
  #       edge.iam_role_trusted_federated,
  #       edge.iam_role_trusted_service,
  #       edge.lambda_function_to_iam_role
  #     ]

  #     args = {
  #       ec2_instance_arns       = with.ec2_instances.rows[*].instance_arn
  #       emr_cluster_arns        = with.emr_clusters.rows[*].cluster_arn
  #       guardduty_detector_arns = with.guardduty_detectors.rows[*].guardduty_detector_arn
  #       iam_policy_arns         = with.iam_policies.rows[*].policy_arn
  #       iam_role_arns           = [self.input.role_arn.value]
  #       lambda_function_arns    = with.lambda_functions.rows[*].function_arn
  #     }
  #   }
  # }

  container {

    container {

      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.iam_role_overview
        args = {
          arn = self.input.role_arn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.iam_role_tags
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
        query = query.iam_user_manage_policies_hierarchy
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
        query = query.iam_all_policies_for_role
        args = {
          arn = self.input.role_arn.value
        }
      }

    }
  }

}

query "iam_role_input" {
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

query "iam_boundary_policy_for_role" {
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

query "iam_role_inline_policy_count_for_role" {
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

query "iam_role_direct_attached_policy_count_for_role" {
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

//*******

query "iam_role_overview" {
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

query "iam_all_policies_for_role" {
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

query "iam_role_tags" {
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

query "iam_user_manage_policies_hierarchy" {
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
