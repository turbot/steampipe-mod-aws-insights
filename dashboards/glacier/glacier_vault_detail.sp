dashboard "glacier_vault_detail" {

  title         = "AWS Glacier Vault Detail"
  documentation = file("./dashboards/glacier/docs/glacier_vault_detail.md")

  tags = merge(local.glacier_common_tags, {
    type = "Detail"
  })

  input "vault_arn" {
    title = "Select a vault:"
    query = query.glacier_vault_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.glacier_vault_archives_count
      args = {
        arn = self.input.vault_arn.value
      }
    }

    card {
      width = 2
      query = query.glacier_vault_size
      args = {
        arn = self.input.vault_arn.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.glacier_vault_node,
        node.glacier_vault_to_sns_topic_node
      ]

      edges = [
        edge.glacier_vault_to_sns_topic_edge
      ]

      args = {
        arn = self.input.vault_arn.value
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
        query = query.glacier_vault_overview
        args = {
          arn = self.input.vault_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.glacier_vault_tags
        args = {
          arn = self.input.vault_arn.value
        }
      }
    }

    container {
      width = 6
      table {
        title = "Policy"
        query = query.glacier_vault_public_access_table
        args = {
          arn = self.input.vault_arn.value
        }
      }

      table {
        title = "Vault Lock Policy"
        query = query.glacier_vault_lock_public_policy
        args = {
          arn = self.input.vault_arn.value
        }
      }
    }
  }
}

query "glacier_vault_input" {
  sql = <<-EOQ
    select
      title as label,
      vault_arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_glacier_vault
    order by
      vault_arn;
  EOQ
}

query "glacier_vault_archives_count" {
  sql = <<-EOQ
    select
      'Archives Count' as label,
      number_of_archives as  value
    from
      aws_glacier_vault
    where
      vault_arn = $1;
  EOQ

  param "arn" {}
}

query "glacier_vault_size" {
  sql = <<-EOQ
    select
      'Size (bytes)' as label,
      size_in_bytes as  value
    from
      aws_glacier_vault
    where
      vault_arn = $1;
  EOQ

  param "arn" {}
}

query "glacier_vault_overview" {
  sql = <<-EOQ
    select
      vault_name as "Name",
      creation_date as "Created Date",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      vault_arn as "ARN"
    from
      aws_glacier_vault
    where
      vault_arn = $1
  EOQ

  param "arn" {}
}

query "glacier_vault_tags" {
  sql = <<-EOQ
    with jsondata as (
    select
      tags::json as tags
    from
      aws_glacier_vault
    where
      vault_arn = $1
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags);
    EOQ

  param "arn" {}
}

query "glacier_vault_public_access_table" {
  sql = <<-EOQ
    select
      v.vault_name as "Name",
      case
        when
        statement ->> 'Effect' = 'Allow'
        and (statement -> 'Principal' ->> 'AWS' = '["*"]')
        then 'Public' else 'Private' end as "Public/Private",
      statement ->> 'Action' as "Action"
    from
      aws_glacier_vault as v,
      jsonb_array_elements(policy_std -> 'Statement') as statement
    order by
      v.vault_name;
  EOQ
}

query "glacier_vault_lock_public_policy" {
  sql = <<-EOQ
    select
      v.vault_name as "Name",
      case
        when
        statement ->> 'Effect' = 'Allow'
        and (statement -> 'Principal' ->> 'AWS' = '["*"]')
        then 'Public' else 'Private' end as "Public/Private",
      statement ->> 'Action' as "Action"
    from
      aws_glacier_vault as v,
      jsonb_array_elements(vault_lock_policy_std -> 'Statement') as statement
    order by
      v.vault_name;
  EOQ
}

node "glacier_vault_node" {
  category = category.glacier_vault

  sql = <<-EOQ
    select
      vault_arn as id,
      title,
      jsonb_build_object(
        'Vault Name', vault_name,
        'Create Time', creation_date,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_glacier_vault
    where
      vault_arn = $1;
  EOQ

  param "arn" {}
}

node "glacier_vault_to_sns_topic_node" {
  category = category.sns_topic

  sql = <<-EOQ
    select
      t.topic_arn as id,
      t.title as title,
      jsonb_build_object(
        'ARN', t.topic_arn,
        'Account ID', t.account_id,
        'Region', t.region
      ) as properties
    from
      aws_sns_topic as t,
      aws_glacier_vault as v
    where
      v.vault_notification_config is not null
      and v.vault_notification_config ->> 'SNSTopic' = t.topic_arn
      and v.vault_arn = $1

  EOQ

  param "arn" {}
}

edge "glacier_vault_to_sns_topic_edge" {
  title = "notifies"

  sql = <<-EOQ
    select
      v.vault_arn as from_id,
      topic.topic_arn as to_id
    from
      aws_sns_topic as topic,
      aws_glacier_vault as v
    where
      v.vault_notification_config is not null
      and v.vault_notification_config ->> 'SNSTopic' = topic.topic_arn
      and v.vault_arn = $1
  EOQ

  param "arn" {}
}
