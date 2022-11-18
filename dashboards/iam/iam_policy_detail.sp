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
        arn = self.input.policy_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_iam_policy_attached
      args = {
        arn = self.input.policy_arn.value
      }
    }
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"


      nodes = [
        node.aws_iam_policy_node,
        node.aws_iam_policy_from_iam_role_node,
        node.aws_iam_policy_from_iam_user_node,
        node.aws_iam_policy_from_iam_group_node,

        node.aws_iam_policy_allowed_service_node,
        node.aws_iam_policy_allowed_action_node,

      ]

      edges = [
        edge.aws_iam_policy_from_iam_role_edge,
        edge.aws_iam_policy_from_iam_user_edge,
        edge.aws_iam_policy_from_iam_group_edge,

        edge.aws_iam_policy_allowed_service_edge,
        edge.aws_iam_policy_allowed_action_edge,
      ]

      args = {
        arn = self.input.policy_arn.value
      }
    }


    flow {
      title     = "Policy"
      //type      = "sankey"
      //direction = "TD"

      category "allow" {
        color = "green"
      }

      category "deny" {
        color = "red"
      }
  
      nodes = [
        node.aws_iam_policy_node,
        node.aws_iam_policy_statement_node,
        node.aws_iam_policy_statement_action_node,
        node.aws_iam_policy_statement_resource_node,
      ]

      edges = [
        edge.aws_iam_policy_statement_edge,
        edge.aws_iam_policy_statement_action_edge,
        edge.aws_iam_policy_statement_resource_edge,
      ]

      args = {
        arn = self.input.policy_arn.value
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
          arn = self.input.policy_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_iam_policy_tags
        args = {
          arn = self.input.policy_arn.value
        }
      }

    }

    container {
      width = 6
      table {
        title = "Policy Statement"
        query = query.aws_iam_policy_statement
        args = {
          arn = self.input.policy_arn.value
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

  param "arn" {}
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

  param "arn" {}
}

node "aws_iam_policy_node" {
  category = category.aws_iam_policy

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
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_iam_policy_from_iam_role_node" {
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
      aws_iam_role,
      jsonb_array_elements_text(attached_policy_arns) as arns
    where
      arns = $1;
  EOQ

  param "arn" {}
}

edge "aws_iam_policy_from_iam_role_edge" {
  title = "iam role"

  sql = <<-EOQ
    select
      r.role_id as from_id,
      p.arn as to_id
    from
      aws_iam_role as r,
      jsonb_array_elements_text(attached_policy_arns) as arns
    left join
      aws_iam_policy as p
      on p.arn = arns
    where
      p.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_iam_policy_from_iam_user_node" {
  category = category.aws_iam_user

  sql = <<-EOQ
    select
      u.name as id,
      u.name as title,
      jsonb_build_object(
        'ARN', u.arn,
        'path', path,
        'Create Date', create_date,
        'MFA Enabled', mfa_enabled::text,
        'Account ID', u.account_id 
      ) as properties
    from
      aws_iam_user as u,
      jsonb_array_elements_text(attached_policy_arns) as arns
    where
      arns = $1;
  EOQ

  param "arn" {}
}

edge "aws_iam_policy_from_iam_user_edge" {
  title = "iam user"

  sql = <<-EOQ
    select
      u.name as from_id,
      p.arn as to_id
    from
      aws_iam_user as u,
      jsonb_array_elements_text(attached_policy_arns) as arns,
      aws_iam_policy as p
    where
      p.arn = arns
      and p.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_iam_policy_from_iam_group_node" {
  category = category.aws_iam_group

  sql = <<-EOQ
    select
      g.name as id,
      g.name as title,
      jsonb_build_object(
        'ARN', arn,
        'Path', path,
        'Create Date', create_date,
        'Account ID', account_id 
      ) as properties
    from
      aws_iam_group as g,
      jsonb_array_elements_text(attached_policy_arns) as arns
    where
      arns = $1;
  EOQ

  param "arn" {}
}

edge "aws_iam_policy_from_iam_group_edge" {
  title = "iam group"

  sql = <<-EOQ
    select
      g.name as from_id,
      policy_arn as to_id
    from
      aws_iam_group as g,
      jsonb_array_elements_text(attached_policy_arns) as policy_arn
    where
      policy_arn = $1;
  EOQ

  param "arn" {}
}



//*****


node "aws_iam_policy_allowed_service_node" {
  category = category.aws_service

  sql = <<-EOQ
    with prefix as (
      select distinct prefix from aws_iam_action
    )
    select
      distinct on (a.prefix)
      -- action_glob,
      -- split_part(action_glob, ':', 1) as prefix_glob,
      a.prefix as id,
      a.prefix as title
      --stmt
    from
      aws_iam_policy as p,
      jsonb_array_elements(p.policy_std -> 'Statement') as stmt,
      jsonb_array_elements_text(stmt -> 'Action') as action_glob,
      prefix as a 
    where
      stmt ->> 'Effect' = 'Allow'
      and a.prefix like glob(split_part(action_glob, ':', 1)) 
      and p.arn = $1
  EOQ

  param "arn" {}
}

edge "aws_iam_policy_allowed_service_edge" {
  title = "allows"

  sql = <<-EOQ
    
    with prefix as (
      select distinct prefix from aws_iam_action
    )
    select
      distinct on (a.prefix)
      p.arn as from_id,
      a.prefix as to_id
    from
      aws_iam_policy as p,
      jsonb_array_elements(p.policy_std -> 'Statement') as stmt,
      jsonb_array_elements_text(stmt -> 'Action') as action_glob,
      prefix as a 
    where
      stmt ->> 'Effect' = 'Allow'
      and a.prefix like glob(split_part(action_glob, ':', 1)) 
      and p.arn = $1;
  EOQ

  param "arn" {}
}




node "aws_iam_policy_allowed_action_node" {
  category = category.aws_action

  sql = <<-EOQ
    select
      distinct on (a.action)
      a.action as id,
      a.action as title
    from
      aws_iam_policy as p,
      jsonb_array_elements(p.policy_std -> 'Statement') as stmt,
      jsonb_array_elements_text(stmt -> 'Action') as action_glob,
      aws_iam_action as a 
    where
      stmt ->> 'Effect' = 'Allow'
      and a.action like glob(action_glob)
      and p.arn = $1
  EOQ

  param "arn" {}
}

edge "aws_iam_policy_allowed_action_edge" {
  title = "action"

  sql = <<-EOQ
    
    select
      distinct on (a.action)
      a.action as to_id,
      split_part(a.action, ':', 1) as from_id
    from
      aws_iam_policy as p,
      jsonb_array_elements(p.policy_std -> 'Statement') as stmt,
      jsonb_array_elements_text(stmt -> 'Action') as action_glob,
      aws_iam_action as a 
    where
      stmt ->> 'Effect' = 'Allow'
      and a.action like glob(action_glob)
      and p.arn = $1
  EOQ

  param "arn" {}
}


//*****

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

  param "arn" {}
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

  param "arn" {}
}

query "aws_iam_policy_statement" {
  sql = <<-EOQ
    select
      p ->> 'Sid' as "Sid",
      p -> 'Action' as "Action",
      p ->> 'Effect' as "Effect",
      p -> 'Resource' as "Resource",
      p -> 'Condition' as "Condition"
    from
      aws_iam_policy,
      jsonb_array_elements(policy_std -> 'Statement') as p
    where
      arn = $1
  EOQ

  param "arn" {}
}


//*******




node "aws_iam_policy_statement_node" {
  category = category.aws_service

  sql = <<-EOQ
    select
      distinct on (p.arn,i)
      concat('statement-', i) as id,
      coalesce (
        t.stmt ->> 'Sid',
        concat('[', i::text, ']')
        ) as title
    from
      aws_iam_policy as p,
      jsonb_array_elements(p.policy_std -> 'Statement') with ordinality as t(stmt,i)
    where
      p.arn = $1
    order by 
      i
  EOQ

  param "arn" {}
}

edge "aws_iam_policy_statement_edge" {
  //title = "allows"

  sql = <<-EOQ
    
    select
      distinct on (p.arn,i)
      p.arn as from_id,
      concat('statement-', i) as to_id
    from
      aws_iam_policy as p,
      jsonb_array_elements(p.policy_std -> 'Statement') with ordinality as t(stmt,i)
    where
      p.arn = $1
  EOQ

  param "arn" {}
}



node "aws_iam_policy_statement_action_node" {
  category = category.aws_service

  sql = <<-EOQ
    select
      distinct on (p.arn,action)
      action as id,
      action as title
    from
      aws_iam_policy as p,
      jsonb_array_elements(p.policy_std -> 'Statement') as stmt,
      jsonb_array_elements_text(stmt -> 'Action') as action
    where
      p.arn = $1
  EOQ

  param "arn" {}
}


edge "aws_iam_policy_statement_action_edge" {
  //title = "allows"
  sql = <<-EOQ
    
    select
      distinct on (p.arn,action)
      action as to_id,
      concat('statement-', i) as from_id,
      t.stmt ->> 'Effect' as title,
      lower(t.stmt ->> 'Effect') as category,
      2 as depth
    from
      aws_iam_policy as p,
      jsonb_array_elements(p.policy_std -> 'Statement') with ordinality as t(stmt,i),
      jsonb_array_elements_text(t.stmt -> 'Action') as action
    where
      p.arn = $1
  EOQ

  param "arn" {}
}


node "aws_iam_policy_statement_resource_node" {
  category = category.aws_service

  sql = <<-EOQ
    select
      distinct on (p.arn,action,resource)
      resource as id,
      resource as title
    from
      aws_iam_policy as p,
      jsonb_array_elements(p.policy_std -> 'Statement') as stmt,
      jsonb_array_elements_text(stmt -> 'Action') as action,
      jsonb_array_elements_text(stmt -> 'Resource') as resource
    where
      p.arn = $1
  EOQ

  param "arn" {}
}


edge "aws_iam_policy_statement_resource_edge" {
  //title = "allows"

  sql = <<-EOQ
    select
      distinct on (p.arn,action,resource)
      action as from_id,
      resource as to_id,
      lower(stmt ->> 'Effect') as category
    from
      aws_iam_policy as p,
      jsonb_array_elements(p.policy_std -> 'Statement') as stmt,
      jsonb_array_elements_text(stmt -> 'Action') as action,
      jsonb_array_elements_text(stmt -> 'Resource') as resource
    where
      p.arn = $1
  EOQ

  param "arn" {}
}

