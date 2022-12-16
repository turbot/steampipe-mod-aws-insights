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
      args  = [self.input.role_arn.value]
    }

    card {
      width = 2
      query = query.iam_role_inline_policy_count_for_role
      args  = [self.input.role_arn.value]
    }

    card {
      width = 2
      query = query.iam_role_direct_attached_policy_count_for_role
      args  = [self.input.role_arn.value]
    }

  }

  with "ec2_instances" {
    query = query.iam_role_ec2_instances
    args  = [self.input.role_arn.value]
  }

  with "emr_clusters" {
    query = query.iam_role_emr_clusters
    args  = [self.input.role_arn.value]
  }

  with "guardduty_detectors" {
    query = query.iam_role_guardduty_detectors
    args  = [self.input.role_arn.value]
  }

  with "iam_policies" {
    query = query.iam_role_iam_policies
    args  = [self.input.role_arn.value]
  }

  with "lambda_functions" {
    query = query.iam_role_lambda_functions
    args  = [self.input.role_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.ec2_instance
        args = {
          ec2_instance_arns = with.ec2_instances.rows[*].instance_arn
        }
      }

      node {
        base = node.emr_cluster
        args = {
          emr_cluster_arns = with.emr_clusters.rows[*].cluster_arn
        }
      }

      node {
        base = node.guardduty_detector
        args = {
          guardduty_detector_arns = with.guardduty_detectors.rows[*].guardduty_detector_arn
        }
      }

      node {
        base = node.iam_instance_profile
        args = {
          ec2_instance_arns = with.ec2_instances.rows[*].instance_arn
        }
      }

      node {
        base = node.iam_policy
        args = {
          iam_policy_arns = with.iam_policies.rows[*].policy_arn
        }
      }

      node {
        base = node.iam_role
        args = {
          iam_role_arns = [self.input.role_arn.value]
        }
      }

      node {
        base = node.iam_role_trusted_aws
        args = {
          iam_role_arns = [self.input.role_arn.value]
        }
      }

      node {
        base = node.iam_role_trusted_federated
        args = {
          iam_role_arns = [self.input.role_arn.value]
        }
      }

      node {
        base = node.iam_role_trusted_service
        args = {
          iam_role_arns = [self.input.role_arn.value]
        }
      }

      node {
        base = node.lambda_function
        args = {
          lambda_function_arns = with.lambda_functions.rows[*].function_arn
        }
      }

      edge {
        base = edge.ec2_instance_to_iam_instance_profile
        args = {
          ec2_instance_arns = with.ec2_instances.rows[*].instance_arn
        }
      }

      edge {
        base = edge.emr_cluster_to_iam_role
        args = {
          emr_cluster_arns = with.emr_clusters.rows[*].cluster_arn
        }
      }

      edge {
        base = edge.guardduty_detector_to_iam_role
        args = {
          iam_role_arns = [self.input.role_arn.value]
        }
      }

      edge {
        base = edge.iam_instance_profile_to_iam_role
        args = {
          iam_role_arns = [self.input.role_arn.value]
        }
      }

      edge {
        base = edge.iam_role_to_iam_policy
        args = {
          iam_role_arns = [self.input.role_arn.value]
        }
      }

      edge {
        base = edge.iam_role_trusted_aws
        args = {
          iam_role_arns = [self.input.role_arn.value]
        }
      }

      edge {
        base = edge.iam_role_trusted_federated
        args = {
          iam_role_arns = [self.input.role_arn.value]
        }
      }

      edge {
        base = edge.iam_role_trusted_service
        args = {
          iam_role_arns = [self.input.role_arn.value]
        }
      }

      edge {
        base = edge.lambda_function_to_iam_role
        args = {
          lambda_function_arns = with.lambda_functions.rows[*].function_arn
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
        query = query.iam_role_overview
        args  = [self.input.role_arn.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.iam_role_tags
        args  = [self.input.role_arn.value]
      }
    }

    container {

      title = "AWS IAM Role Policy Analysis"

      hierarchy {
        type  = "tree"
        width = 6
        title = "Attached Policies"
        query = query.iam_user_manage_policies_hierarchy
        args  = [self.input.role_arn.value]

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
        args  = [self.input.role_arn.value]
      }

    }
  }

}

# Input queries

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

# With queries

query "iam_role_ec2_instances" {
  sql = <<-EOQ
    select
      i.arn as instance_arn
    from
      aws_ec2_instance as i,
      aws_iam_role as r,
      jsonb_array_elements_text(instance_profile_arns) as instance_profile
    where
      r.arn = $1
      and instance_profile = i.iam_instance_profile_arn;
  EOQ
}

query "iam_role_emr_clusters" {
  sql = <<-EOQ
    select
      c.cluster_arn as cluster_arn
    from
      aws_iam_role as r,
      aws_emr_cluster as c
    where
      r.arn = $1
      and r.name = c.service_role;
  EOQ
}

query "iam_role_guardduty_detectors" {
  sql = <<-EOQ
    select
      arn as guardduty_detector_arn
    from
      aws_guardduty_detector
    where
      service_role = $1;
  EOQ
}

query "iam_role_iam_policies" {
  sql = <<-EOQ
    select
      policy_arn
    from
      aws_iam_role,
      jsonb_array_elements_text(attached_policy_arns) as policy_arn
    where
      arn = $1;
  EOQ
}

query "iam_role_lambda_functions" {
  sql = <<-EOQ
    select
      arn as function_arn
    from
      aws_lambda_function
    where
      role = $1;
  EOQ
}

# Card queries

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
}

# Other detail page queries

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
}
