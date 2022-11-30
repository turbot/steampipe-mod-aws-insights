dashboard "aws_iam_policy_detail" {
  title         = "AWS IAM Policy Detail"
  documentation = file("./dashboards/iam/docs/iam_policy_detail.md")
  tags = merge(local.iam_common_tags, {
    type = "Detail"
  })

  input "policy_arn" {
    title = "Select a policy:"
    query = query.aws_iam_policy_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_iam_policy_aws_managed
      args = {
        policy_arn = self.input.policy_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_iam_policy_attached
      args = {
        policy_arn = self.input.policy_arn.value
      }
    }
  }

  container {

    graph {
      title = "Relationships"
      type  = "graph"

      with "attached_roles" {
        sql = <<-EOQ
          select
            arn as role_arn
          from
            aws_iam_role,
            jsonb_array_elements_text(attached_policy_arns) as policy_arn
          where
            policy_arn = $1;
        EOQ

        args = [self.input.policy_arn.value]
      }


      with "attached_users" {
        sql = <<-EOQ
          select
            arn as user_arn
          from
            aws_iam_user,
            jsonb_array_elements_text(attached_policy_arns) as policy_arn
          where
            policy_arn = $1;
        EOQ

        args = [self.input.policy_arn.value]
      }



      with "attached_groups" {
        sql = <<-EOQ
          select
            arn as group_arn
          from
            aws_iam_group,
            jsonb_array_elements_text(attached_policy_arns) as policy_arn
          where
            policy_arn = $1;
        EOQ

        args = [self.input.policy_arn.value]
      }


      with "policy_std" {
        sql = <<-EOQ
          select
            policy_std
          from
            aws_iam_policy
          where
            arn = $1
          limit 1;  -- aws managed policies will appear once for each connection in the aggregator, but we only need one...
        EOQ

        args = [self.input.policy_arn.value]
      }

      nodes = [
        node.iam_policy,
        node.iam_role,
        node.iam_user,
        node.iam_group,

        node.iam_policy_statement,
        node.iam_policy_statement_action_notaction,
        node.iam_policy_statement_resource_notresource,
        node.iam_policy_statement_condition,
        node.iam_policy_statement_condition_key,
        node.iam_policy_statement_condition_key_value,

      ]

      edges = [
        edge.iam_policy_from_iam_role,
        edge.iam_policy_from_iam_user,
        edge.iam_policy_from_iam_group,

        edge.iam_policy_statement,
        edge.iam_policy_statement_action,
        edge.iam_policy_statement_resource,
        edge.iam_policy_statement_notaction,
        edge.iam_policy_statement_notresource,
        edge.iam_policy_statement_condition,
        edge.iam_policy_statement_condition_key,
        edge.iam_policy_statement_condition_key_value,
      ]

      args = {
        policy_arns = [self.input.policy_arn.value]
        role_arns   = with.attached_roles.rows[*].role_arn
        user_arns   = with.attached_users.rows[*].user_arn
        group_arns  = with.attached_groups.rows[*].group_arn
        policy_std  = with.policy_std.rows[0].policy_std
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
        query = query.aws_iam_policy_overview
        args = {
          policy_arn = self.input.policy_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_iam_policy_tags
        args = {
          policy_arn = self.input.policy_arn.value
        }

      }

    }

    container {
      width = 6
      table {
        title = "Policy Statement"
        query = query.aws_iam_policy_statement
        args = {
          policy_arn = self.input.policy_arn.value
        }

        column "Action" {
          href = "/aws_insights.dashboard.aws_iam_action_glob_report?input.action_glob={{.\"Action\" | @uri}}"
        }
        column "NotAction" {
          href = "/aws_insights.dashboard.aws_iam_action_glob_report?input.action_glob={{.\"NotAction\" | @uri}}"
        }
      }

    }

  }
}

query "aws_iam_policy_input" {
  sql = <<-EOQ
    with policies as (
      select
        title as label,
        arn as value,
        json_build_object(
          'account_id', account_id
        ) as tags
      from
        aws_iam_policy
      where
        not is_aws_managed
      union all select
        distinct on (arn)
        title as label,
        arn as value,
        json_build_object(
          'account_id', 'AWS Managed'
        ) as tags
      from
        aws_iam_policy
      where
        is_aws_managed
    )
    select
      *
    from
      policies
    order by
      label;
  EOQ
}

query "aws_iam_policy_aws_managed" {
  sql = <<-EOQ
    select
      case when is_aws_managed then 'AWS' else 'Customer' end as value,
      'Managed By' as label
    from
      aws_iam_policy
    where
      arn = $1
  EOQ

  param "policy_arn" {}
}

query "aws_iam_policy_attached" {
  sql = <<-EOQ
    select
      case when is_attached then 'Attached' else 'Detached' end as value,
      'Attachment Status' as label,
      case when is_attached then 'ok' else 'alert' end as type
    from
      aws_iam_policy
    where
      arn = $1
  EOQ

  param "policy_arn" {}
}


query "aws_iam_policy_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      path as "Path",
      create_date as "Create Date",
      update_date as "Update Date",
      policy_id as "Policy ID",
      arn as "ARN",
      case is_aws_managed
        when true then 'AWS Managed'
        else account_id
      end as "Account ID"
    from
      aws_iam_policy
    where
      arn = $1
    limit 1
  EOQ

  param "policy_arn" {}
}

query "aws_iam_policy_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_iam_user,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key'
  EOQ

  param "policy_arn" {}
}

query "aws_iam_policy_statement" {
  sql = <<-EOQ
    with policy as (
      select
        distinct on (arn)
        *
      from
        aws_iam_policy
      where
        arn =  $1
    )
    select
      coalesce(t.stmt ->> 'Sid', concat('[', i::text, ']')) as "Statement",
      t.stmt ->> 'Effect' as "Effect",
      action as "Action",
      notaction as "NotAction",
      resource as "Resource",
      notresource as "NotResource",
      t.stmt ->> 'Condition' as "Condition"
    from
      policy as p, --aws_iam_policy as p,
      jsonb_array_elements(p.policy_std -> 'Statement') with ordinality as t(stmt,i)
      left join jsonb_array_elements_text(t.stmt -> 'Action') as action on true
      left join jsonb_array_elements_text(t.stmt -> 'NotAction') as notaction on true
      left join jsonb_array_elements_text(t.stmt -> 'Resource') as resource on true
      left join jsonb_array_elements_text(t.stmt -> 'NotResource') as notresource on true
  EOQ

  param "policy_arn" {}
}

// *** Nodes and Edges
node "iam_policy" {
  category = category.iam_policy

  sql = <<-EOQ
    select
      distinct on (arn)
      arn as id,
      name as title,
      'aws_iam_policy' as category,
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
      arn = any($1);
  EOQ

  param "policy_arns" {}
}

edge "iam_policy_from_iam_user" {
  title = "attaches"

  sql = <<-EOQ
   select
      policy_arns as to_id,
      user_arns as from_id
    from
      unnest($1::text[]) as policy_arns,
      unnest($2::text[]) as user_arns
  EOQ

  param "policy_arns" {}
  param "user_arns" {}

}

edge "iam_policy_from_iam_role" {
  title = "attaches"

  sql = <<-EOQ
   select
      policy_arns as to_id,
      role_arns as from_id
    from
      unnest($1::text[]) as policy_arns,
      unnest($2::text[]) as role_arns
  EOQ

  param "policy_arns" {}
  param "role_arns" {}
}

edge "iam_policy_from_iam_group" {
  title = "attaches"

  sql = <<-EOQ
   select
      policy_arns as to_id,
      group_arns as from_id
    from
      unnest($1::text[]) as policy_arns,
      unnest($2::text[]) as group_arns
  EOQ

  param "policy_arns" {}
  param "group_arns" {}

}

node "iam_policy_statement" {
  category = category.iam_policy_statement

  sql = <<-EOQ
    select
      concat('statement:', i) as id,
      coalesce (
        t.stmt ->> 'Sid',
        concat('[', i::text, ']')
        ) as title
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i)
  EOQ

  param "policy_std" {}
}

edge "iam_policy_statement" {
  title = "statement"

  sql = <<-EOQ

    select
      distinct on (p.arn,i)
      p.arn as from_id,
      concat('statement:', i) as to_id
    from
      aws_iam_policy as p,
      jsonb_array_elements(p.policy_std -> 'Statement') with ordinality as t(stmt,i)
    where
      p.arn = any($1)
  EOQ

  param "policy_arns" {}
}


edge "iam_policy_statement_action" {
  //title = "allows"
  sql = <<-EOQ

    select
      --distinct on (p.arn,action)
      concat('action:', action) as to_id,
      concat('statement:', i) as from_id,
      lower(t.stmt ->> 'Effect') as title,
      lower(t.stmt ->> 'Effect') as category
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_array_elements_text(t.stmt -> 'Action') as action
  EOQ

  param "policy_std" {}
}

edge "iam_policy_statement_notaction" {
  sql = <<-EOQ

    select
      --distinct on (p.arn,notaction)
      concat('action:', notaction) as to_id,
      concat('statement:', i) as from_id,
      concat(lower(t.stmt ->> 'Effect'), ' not action') as title,
      lower(t.stmt ->> 'Effect') as category
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_array_elements_text(t.stmt -> 'NotAction') as notaction
  EOQ

  param "policy_std" {}
}


edge "iam_policy_statement_resource" {
  title = "resource"

  sql = <<-EOQ
    select
      concat('action:', coalesce(action, notaction)) as from_id,
      resource as to_id,
      lower(stmt ->> 'Effect') as category
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i)
      left join jsonb_array_elements_text(stmt -> 'Action') as action on true
      left join jsonb_array_elements_text(stmt -> 'NotAction') as notaction on true
      left join jsonb_array_elements_text(stmt -> 'Resource') as resource on true
  EOQ

  param "policy_std" {}
}

edge "iam_policy_statement_notresource" {
  title = "not resource"

  sql = <<-EOQ
    select
      concat('action:', coalesce(action, notaction)) as from_id,
      notresource as to_id,
      lower(stmt ->> 'Effect') as category
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i)
      left join jsonb_array_elements_text(stmt -> 'Action') as action on true
      left join jsonb_array_elements_text(stmt -> 'NotAction') as notaction on true
      left join jsonb_array_elements_text(stmt -> 'NotResource') as notresource on true
  EOQ

  param "policy_std" {}
}

node "iam_policy_statement_condition" {
  category = category.iam_policy_condition

  sql = <<-EOQ
    select
      condition.key as title,
      concat('statement:', i, ':condition:', condition.key  ) as id,
      condition.value as properties
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_each(t.stmt -> 'Condition') as condition
    where
      stmt -> 'Condition' <> 'null'
  EOQ

  param "policy_std" {}
}

edge "iam_policy_statement_condition" {
  title = "condition"
  sql   = <<-EOQ

    select
      concat('statement:', i, ':condition:', condition.key) as to_id,
      concat('statement:', i) as from_id
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_each(t.stmt -> 'Condition') as condition
    where
      stmt -> 'Condition' <> 'null'
  EOQ

  param "policy_std" {}
}

node "iam_policy_statement_condition_key" {
  category = category.iam_policy_condition_key

  sql = <<-EOQ
    select
      condition_key.key as title,
      concat('statement:', i, ':condition:', condition.key, ':', condition_key.key  ) as id,
      condition_key.value as properties
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_each(t.stmt -> 'Condition') as condition,
      jsonb_each(condition.value) as condition_key
    where
      stmt -> 'Condition' <> 'null'
  EOQ

  param "policy_std" {}
}

edge "iam_policy_statement_condition_key" {
  title = "all of"
  sql   = <<-EOQ
    select
      concat('statement:', i, ':condition:', condition.key, ':', condition_key.key  ) as to_id,
      concat('statement:', i, ':condition:', condition.key) as from_id
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_each(t.stmt -> 'Condition') as condition,
      jsonb_each(condition.value) as condition_key
    where
      stmt -> 'Condition' <> 'null'
  EOQ

  param "policy_std" {}
}

node "iam_policy_statement_condition_key_value" {
  category = category.iam_policy_condition_value

  sql = <<-EOQ
    select
      condition_value as title,
      concat('statement:', i, ':condition:', condition.key, ':', condition_key.key, ':', condition_value  ) as id
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_each(t.stmt -> 'Condition') as condition,
      jsonb_each(condition.value) as condition_key,
      jsonb_array_elements_text(condition_key.value) as condition_value
    where
      stmt -> 'Condition' <> 'null'
  EOQ

  param "policy_std" {}
}

edge "iam_policy_statement_condition_key_value" {
  title = "any of"
  sql   = <<-EOQ
    select
      concat('statement:', i, ':condition:', condition.key, ':', condition_key.key, ':', condition_value  ) as to_id,
      concat('statement:', i, ':condition:', condition.key, ':', condition_key.key  ) as from_id
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_each(t.stmt -> 'Condition') as condition,
      jsonb_each(condition.value) as condition_key,
      jsonb_array_elements_text(condition_key.value) as condition_value
    where
      stmt -> 'Condition' <> 'null'
  EOQ

  param "policy_std" {}
}

node "iam_policy_statement_action_notaction" {
  category = category.iam_policy_action

  sql = <<-EOQ

    select
      concat('action:', action) as id,
      action as title
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_array_elements_text(coalesce(t.stmt -> 'Action','[]'::jsonb) || coalesce(t.stmt -> 'NotAction','[]'::jsonb)) as action
  EOQ

  param "policy_std" {}
}

node "iam_policy_statement_resource_notresource" {
  category = category.iam_policy_resource

  sql = <<-EOQ
    select
      resource as id,
      resource as title
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_array_elements_text(coalesce(t.stmt -> 'Action','[]'::jsonb) || coalesce(t.stmt -> 'NotAction','[]'::jsonb)) as action,
      jsonb_array_elements_text(coalesce(t.stmt -> 'Resource','[]'::jsonb) || coalesce(t.stmt -> 'NotResource','[]'::jsonb)) as resource
  EOQ

  param "policy_std" {}
}

node "iam_policy_globbed_notaction" {
  category = category.iam_policy_notaction

  sql = <<-EOQ
    select
      distinct on (a.action)
      concat ('action:', a.action) as id,
      a.action as title
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') as stmt,
      jsonb_array_elements_text(stmt -> 'NotAction') as action_glob,
      aws_iam_action as a
    where
      a.action not like glob(action_glob)
  EOQ

  param "policy_std" {}
}

edge "iam_policy_globbed_notaction" {

  sql = <<-EOQ

    select
      distinct on (a.action)
      concat('action:', a.action) as to_id,
      concat('statement:', i) as from_id,
      lower(t.stmt ->> 'Effect') as category,
      t.stmt ->> 'Effect' as title
    from
      jsonb_array_elements(($1 :: jsonb) ->  'Statement') with ordinality as t(stmt,i),
      jsonb_array_elements_text(t.stmt -> 'NotAction') as action_glob,
      aws_iam_action as a
    where
      a.action not like glob(action_glob)
  EOQ

  param "policy_std" {}
}
