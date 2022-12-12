dashboard "elasticache_cluster_detail" {

  title         = "AWS ElastiCache Cluster Detail"
  documentation = file("./dashboards/elasticache/docs/elasticache_cluster_detail.md")

  tags = merge(local.elasticache_common_tags, {
    type = "Detail"
  })

  input "elasticache_cluster_arn" {
    title = "Select a Cluster:"
    query = query.elasticache_cluster_input
    width = 4
  }

  container {

    card {
      query = query.elasticache_cluster_status
      width = 2
      args = {
        arn = self.input.elasticache_cluster_arn.value
      }
    }

    card {
      query = query.elasticache_cluster_node_type
      width = 2
      args = {
        arn = self.input.elasticache_cluster_arn.value
      }
    }

    card {
      query = query.elasticache_cluster_automatic_backup
      width = 2
      args = {
        arn = self.input.elasticache_cluster_arn.value
      }
    }

    card {
      query = query.elasticache_cluster_encryption_transit
      width = 2
      args = {
        arn = self.input.elasticache_cluster_arn.value
      }
    }

    card {
      query = query.elasticache_cluster_encryption_rest
      width = 2
      args = {
        arn = self.input.elasticache_cluster_arn.value
      }
    }

    card {
      query = query.elasticache_cluster_auth_token
      width = 2
      args = {
        arn = self.input.elasticache_cluster_arn.value
      }
    }

  }

  # container {

  #   graph {
  #     title     = "Relationships"
  #     type      = "graph"
  #     direction = "TD"

  #     with "elasticache_parameter_groups" {
  #       sql = <<-EOQ
  #         select
  #           g.arn as elasticache_parameter_group_arn
  #         from
  #           aws_elasticache_cluster as c,
  #           aws_elasticache_parameter_group as g
  #         where
  #           c.cache_parameter_group ->> 'CacheParameterGroupName' = g.cache_parameter_group_name
  #           and c.region = g.region
  #           and c.arn = $1;
  #       EOQ

  #       args = [self.input.elasticache_cluster_arn.value]
  #     }

  #     with "elasticache_subnet_groups" {
  #       sql = <<-EOQ
  #         select
  #           g.arn as elasticache_subnet_group_arn
  #         from
  #           aws_elasticache_cluster as c,
  #           jsonb_array_elements(security_groups) as sg,
  #           aws_elasticache_subnet_group as g
  #         where
  #           g.cache_subnet_group_name = c.cache_subnet_group_name
  #           and g.region = c.region
  #           and g.arn is not null
  #           and c.arn = $1;
  #       EOQ

  #       args = [self.input.elasticache_cluster_arn.value]
  #     }

  #     with "kms_keys" {
  #       sql = <<-EOQ
  #         select
  #           kms_key_id as kms_key_arn
  #         from
  #           aws_elasticache_cluster as c,
  #           aws_elasticache_replication_group as g
  #         where
  #           c.arn = $1
  #           and c.replication_group_id = g.replication_group_id
  #       EOQ

  #       args = [self.input.elasticache_cluster_arn.value]
  #     }

  #     with "sns_topics" {
  #       sql = <<-EOQ
  #         select
  #           notification_configuration ->> 'TopicArn' as sns_topic_arn
  #         from
  #           aws_elasticache_cluster
  #         where
  #           arn = $1
  #       EOQ

  #       args = [self.input.elasticache_cluster_arn.value]
  #     }

  #     with "vpc_security_groups" {
  #       sql = <<-EOQ
  #         select
  #           group_id as vpc_security_group_id
  #         from
  #           aws_vpc_security_group
  #         where
  #           group_id in
  #           (
  #             select
  #               sg ->> 'SecurityGroupId'
  #             from
  #               aws_elasticache_cluster,
  #               jsonb_array_elements(security_groups) as sg
  #             where
  #               arn = $1
  #           );
  #       EOQ

  #       args = [self.input.elasticache_cluster_arn.value]
  #     }

  #     with "vpc_subnets" {
  #       sql = <<-EOQ
  #         select
  #           subnet ->> 'SubnetIdentifier' as vpc_subnet_id
  #         from
  #           aws_elasticache_cluster as c,
  #           aws_elasticache_subnet_group as g,
  #           jsonb_array_elements(subnets) as subnet
  #         where
  #           g.cache_subnet_group_name = c.cache_subnet_group_name
  #           and g.region = c.region
  #           and c.arn = $1
  #       EOQ

  #       args = [self.input.elasticache_cluster_arn.value]
  #     }

  #     with "vpc_vpcs" {
  #       sql = <<-EOQ
  #         select
  #           vpc_id as vpc_vpc_id
  #         from
  #           aws_vpc
  #         where
  #           vpc_id in
  #           (
  #             select
  #               vpc_id
  #             from
  #               aws_elasticache_cluster as c,
  #               aws_elasticache_subnet_group as g
  #             where
  #               g.cache_subnet_group_name = c.cache_subnet_group_name
  #               and g.region = c.region
  #               and c.arn = $1
  #           );
  #       EOQ

  #       args = [self.input.elasticache_cluster_arn.value]
  #     }

  #     nodes = [
  #       node.elasticache_cluster,
  #       node.elasticache_parameter_group,
  #       node.elasticache_subnet_group,
  #       node.kms_key,
  #       node.sns_topic,
  #       node.vpc_security_group,
  #       node.vpc_subnet,
  #       node.vpc_vpc
  #     ]

  #     edges = [
  #       edge.elasticache_cluster_to_elasticache_parameter_group,
  #       edge.elasticache_cluster_to_kms_key,
  #       edge.elasticache_cluster_to_sns_topic,
  #       edge.elasticache_cluster_to_vpc_security_group,
  #       edge.elasticache_subnet_group_to_vpc_subnet,
  #       edge.vpc_security_group_to_elasticache_subnet_group,
  #       edge.vpc_subnet_to_vpc_vpc
  #     ]

  #     args = {
  #       elasticache_cluster_arns        = [self.input.elasticache_cluster_arn.value]
  #       elasticache_subnet_group_arns   = with.elasticache_subnet_groups.rows[*].elasticache_subnet_group_arn
  #       elsticache_parameter_group_arns = with.elasticache_parameter_groups.rows[*].elasticache_parameter_group_arn
  #       kms_key_arns                    = with.kms_keys.rows[*].kms_key_arn
  #       sns_topic_arns                  = with.sns_topics.rows[*].sns_topic_arn
  #       vpc_security_group_ids          = with.vpc_security_groups.rows[*].vpc_security_group_id
  #       vpc_subnet_ids                  = with.vpc_subnets.rows[*].vpc_subnet_id
  #       vpc_vpc_ids                     = with.vpc_vpcs.rows[*].vpc_vpc_id
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
        query = query.elasticache_cluster_overview
        args = {
          arn = self.input.elasticache_cluster_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.elasticache_cluster_tags
        args = {
          arn = self.input.elasticache_cluster_arn.value
        }

      }
    }
    container {
      width = 6

      table {
        title = "Notification Configuration"
        query = query.elasticache_cluster_notification_configuration
        args = {
          arn = self.input.elasticache_cluster_arn.value
        }
      }
    }
  }
}


query "elasticache_cluster_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_elasticache_cluster
    order by
      title;
  EOQ
}

query "elasticache_cluster_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(cache_cluster_status) as value
    from
      aws_elasticache_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "elasticache_cluster_node_type" {
  sql = <<-EOQ
    select
      'Node Type' as label,
      cache_node_type as value
    from
      aws_elasticache_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "elasticache_cluster_automatic_backup" {
  sql = <<-EOQ
    select
      'Automatic Backup' as label,
      case when snapshot_retention_limit is null then 'Disabled' else 'Enabled' end as value,
      case when snapshot_retention_limit is null then 'alert' else 'ok' end as type
    from
      aws_elasticache_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "elasticache_cluster_encryption_transit" {
  sql = <<-EOQ
    select
      'Encryption in Transit' as label,
      case when transit_encryption_enabled then 'Enabled' else 'Disabled' end as value,
      case when transit_encryption_enabled then 'ok' else 'alert' end as type
    from
      aws_elasticache_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "elasticache_cluster_encryption_rest" {
  sql = <<-EOQ
    select
      'Encryption at Rest' as label,
      case when at_rest_encryption_enabled then 'Enabled' else 'Disabled' end as value,
      case when at_rest_encryption_enabled then 'ok' else 'alert' end as type
    from
      aws_elasticache_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}

}

query "elasticache_cluster_auth_token" {
  sql = <<-EOQ
    select
      'Auth Token' as label,
      case when auth_token_enabled then 'Enabled' else 'Disabled' end as value,
      case when auth_token_enabled then 'ok' else 'alert' end as type
    from
      aws_elasticache_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}

}

query "elasticache_cluster_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      auth_token_enabled as "Auth Token Enabled",
      auto_minor_version_upgrade as "Auto Minor Version Upgrade",
      cache_cluster_create_time as "Create Time",
      cache_subnet_group_name as "Subnet Group Name",
      engine as "Engine",
      engine_version as "Engine Version",
      preferred_availability_zone as "Preferred Availability Zone",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_elasticache_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "elasticache_cluster_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_elasticache_cluster,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "elasticache_cluster_notification_configuration" {
  sql = <<-EOQ
    select
      t.title as "Topic Title",
      notification_configuration ->> 'TopicStatus' as "Topic Status"
    from
      aws_elasticache_cluster as c
      left join
        aws_sns_topic as t
        on notification_configuration ->> 'TopicArn' = topic_arn
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

