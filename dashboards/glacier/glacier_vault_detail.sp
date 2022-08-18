dashboard "aws_glacier_vault_detail" {

  title         = "AWS Glacier Vault Detail"
  documentation = file("./dashboards/glacier/docs/glacier_vault_detail.md")

  tags = merge(local.glacier_common_tags, {
    type = "Detail"
  })

  input "vault_arn" {
    title = "Select a vault:"
    query = query.aws_glacier_vault_input
    width = 4
  }

  container {

    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_glacier_vault_relationships_graph
      args = {
        arn = self.input.vault_arn.value
      }

      category "glacier_vault" {
        icon = local.aws_glacier_vault_icon
      }

      category "sns_topic" {
        href = "/aws_insights.dashboard.aws_sns_topic_detail.url_path?input.topic_arn={{.properties.ARN | @uri}}"
        icon = local.aws_sns_topic_icon
      }
    }
  }
}

query "aws_glacier_vault_input" {
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

query "aws_glacier_vault_relationships_graph" {
  sql = <<-EOQ
    with vault as(
      select
        *
      from
        aws_glacier_vault
      where
        vault_arn = $1
    )
    -- Glacier vault vault (node)
    select
      null as from_id,
      null as to_id,
      vault_arn as id,
      title,
      'glacier_vault' as category,
      jsonb_build_object(
        'Vault Name', vault_name,
        'Create Time', creation_date,
        'Account ID', account_id
      ) as properties
    from
      vault

    -- To SNS topic - nodes
    union all
    select
      null as from_id,
      null as to_id,
      topic.topic_arn as id,
      topic.title as title,
      'sns_topic' as category,
      jsonb_build_object(
        'ARN', topic.topic_arn,
        'Account ID', topic.account_id,
        'Region', topic.region
      ) as properties
    from
      aws_sns_topic as topic,
      vault as v
    where
      v.vault_notification_config is not null
      and v.vault_notification_config ->> 'SNSTopic' = topic.topic_arn

    -- To SNS topic - edges
    union all
    select
      v.vault_arn as from_id,
      topic.topic_arn as to_id,
      null as id,
      'Logs to' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', v.vault_arn,
        'Account ID', v.account_id,
        'Region', v.region,
        'Events', v.vault_notification_config ->> 'Events'
      ) as properties
    from
      aws_sns_topic as topic,
      vault as v
    where
      v.vault_notification_config is not null
      and v.vault_notification_config ->> 'SNSTopic' = topic.topic_arn

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}
