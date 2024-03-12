graph "iam_resource_policy_structure" {
    param "policy_std" {}

    node "resource_policy" {
      category = category.iam_resource_policy

      sql = <<-EOQ
        select
          'resource_policy' as id,
          'Resource Policy' as title
      EOQ
    }

    edge "resource_policy_policy_statement" {
      title = "statement"

      sql = <<-EOQ
        select
          'resource_policy' as from_id,
          concat('statement:', i) as to_id
        from
          jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i)
      EOQ

      args = [param.policy_std]
    }

    node {
      base = node.iam_policy_statement
      args = {
        iam_policy_stds = param.policy_std
      }
    }

    node {
      base = node.iam_policy_statement_principal
      args = {
        iam_policy_stds = param.policy_std
      }
    }

    node {
      base = node.iam_policy_statement_action_notaction
      args = {
        iam_policy_stds = param.policy_std
      }
    }

    node {
      base = node.iam_policy_statement_condition
      args = {
        iam_policy_stds = param.policy_std
      }
    }

    node {
      base = node.iam_policy_statement_condition_key
      args = {
        iam_policy_stds = param.policy_std
      }
    }

    node {
      base = node.iam_policy_statement_condition_key_value
      args = {
        iam_policy_stds = param.policy_std
      }
    }

    node {
      base = node.iam_policy_statement_resource_notresource
      args = {
        iam_policy_stds = param.policy_std
      }
    }

    edge {
      base = edge.iam_policy_statement_principal
      args = {
        iam_policy_stds = param.policy_std
      }
    }

    edge {
      base = edge.iam_resource_policy_statement_action
      args = {
        iam_policy_stds = param.policy_std
      }
    }

    edge {
      base = edge.iam_resource_policy_statement_condition
      args = {
        iam_policy_stds = param.policy_std
      }
    }

    edge {
      base = edge.iam_policy_statement_condition_key
      args = {
        iam_policy_stds = param.policy_std
      }
    }

    edge {
      base = edge.iam_policy_statement_condition_key_value
      args = {
        iam_policy_stds = param.policy_std
      }
    }

    edge {
      base = edge.iam_resource_policy_statement_notaction
      args = {
        iam_policy_stds = param.policy_std
      }
    }

    edge {
      base = edge.iam_policy_statement_notresource
      args = {
        iam_policy_stds = param.policy_std
      }
    }

    edge {
      base = edge.iam_policy_statement_resource
      args = {
        iam_policy_stds = param.policy_std
      }
    }
}