dashboard "rds_db_cluster_detail" {

  title         = "AWS RDS DB Cluster Detail"
  documentation = file("./dashboards/rds/docs/rds_db_cluster_detail.md")

  tags = merge(local.rds_common_tags, {
    type = "Detail"
  })

  input "db_cluster_arn" {
    title = "Select a cluster:"
    query = query.rds_db_cluster_input
    width = 4
  }

  container {

    card {
      query = query.rds_db_cluster_unencrypted
      width = 3
      args  = [self.input.db_cluster_arn.value]
    }

    card {
      query = query.rds_db_cluster_logging_disabled
      width = 3
      args  = [self.input.db_cluster_arn.value]
    }

    card {
      query = query.rds_db_cluster_no_deletion_protection
      width = 3
      args  = [self.input.db_cluster_arn.value]
    }

    card {
      query = query.rds_db_cluster_status
      width = 3
      args  = [self.input.db_cluster_arn.value]
    }

  }

  with "iam_roles_for_rds_db_cluster" {
    query = query.iam_roles_for_rds_db_cluster
    args  = [self.input.db_cluster_arn.value]
  }

  with "kms_keys_for_rds_db_cluster" {
    query = query.kms_keys_for_rds_db_cluster
    args  = [self.input.db_cluster_arn.value]
  }

  with "rds_db_cluster_snapshots_for_rds_db_cluster" {
    query = query.rds_db_cluster_snapshots_for_rds_db_cluster
    args  = [self.input.db_cluster_arn.value]
  }

  with "rds_db_instances_for_rds_db_cluster" {
    query = query.rds_db_instances_for_rds_db_cluster
    args  = [self.input.db_cluster_arn.value]
  }

  with "rds_db_subnet_groups_for_rds_db_cluster" {
    query = query.rds_db_subnet_groups_for_rds_db_cluster
    args  = [self.input.db_cluster_arn.value]
  }

  with "sns_topics_for_rds_db_cluster" {
    query = query.sns_topics_for_rds_db_cluster
    args  = [self.input.db_cluster_arn.value]
  }

  with "vpc_security_groups_for_rds_db_cluster" {
    query = query.vpc_security_groups_for_rds_db_cluster
    args  = [self.input.db_cluster_arn.value]
  }

  with "vpc_subnets_for_rds_db_cluster" {
    query = query.vpc_subnets_for_rds_db_cluster
    args  = [self.input.db_cluster_arn.value]
  }

  with "vpc_vpcs_for_rds_db_cluster" {
    query = query.vpc_vpcs_for_rds_db_cluster
    args  = [self.input.db_cluster_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.iam_role
        args = {
          iam_role_arns = with.iam_roles_for_rds_db_cluster.rows[*].role_arn
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys_for_rds_db_cluster.rows[*].key_arn
        }
      }

      node {
        base = node.rds_db_cluster
        args = {
          rds_db_cluster_arns = [self.input.db_cluster_arn.value]
        }
      }

      node {
        base = node.rds_db_cluster_parameter_group
        args = {
          rds_db_cluster_arns = [self.input.db_cluster_arn.value]
        }
      }

      node {
        base = node.rds_db_cluster_snapshot
        args = {
          rds_db_cluster_snapshot_arns = with.rds_db_cluster_snapshots_for_rds_db_cluster.rows[*].snapshot_arn
        }
      }

      node {
        base = node.rds_db_instance
        args = {
          rds_db_instance_arns = with.rds_db_instances_for_rds_db_cluster.rows[*].instance_arn
        }
      }

      node {
        base = node.rds_db_subnet_group
        args = {
          rds_db_subnet_group_arns = with.rds_db_subnet_groups_for_rds_db_cluster.rows[*].db_subnet_group_arn
        }
      }

      node {
        base = node.sns_topic
        args = {
          sns_topic_arns = with.sns_topics_for_rds_db_cluster.rows[*].topic_arn
        }
      }

      node {
        base = node.vpc_security_group
        args = {
          vpc_security_group_ids = with.vpc_security_groups_for_rds_db_cluster.rows[*].group_id
        }
      }

      node {
        base = node.vpc_subnet
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_rds_db_cluster.rows[*].subnet_id
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_rds_db_cluster.rows[*].vpc_id
        }
      }

      edge {
        base = edge.rds_db_cluster_to_iam_role
        args = {
          rds_db_cluster_arns = [self.input.db_cluster_arn.value]
        }
      }

      edge {
        base = edge.rds_db_cluster_to_kms_key
        args = {
          rds_db_cluster_arns = [self.input.db_cluster_arn.value]
        }
      }

      edge {
        base = edge.rds_db_cluster_to_rds_db_cluster_parameter_group
        args = {
          rds_db_cluster_arns = [self.input.db_cluster_arn.value]
        }
      }

      edge {
        base = edge.rds_db_cluster_to_rds_db_cluster_snapshot
        args = {
          rds_db_cluster_arns = [self.input.db_cluster_arn.value]
        }
      }

      edge {
        base = edge.rds_db_cluster_to_rds_db_instance
        args = {
          rds_db_cluster_arns = [self.input.db_cluster_arn.value]
        }
      }

      edge {
        base = edge.rds_db_cluster_to_sns_topic
        args = {
          rds_db_cluster_arns = [self.input.db_cluster_arn.value]
        }
      }

      edge {
        base = edge.rds_db_cluster_to_vpc_security_group
        args = {
          rds_db_cluster_arns = [self.input.db_cluster_arn.value]
        }
      }

      edge {
        base = edge.rds_db_subnet_group_to_vpc_subnet
        args = {
          rds_db_subnet_group_arns = with.rds_db_subnet_groups_for_rds_db_cluster.rows[*].db_subnet_group_arn
        }
      }

      edge {
        base = edge.vpc_security_group_to_rds_db_subnet_group
        args = {
          rds_db_subnet_group_arns = with.rds_db_subnet_groups_for_rds_db_cluster.rows[*].db_subnet_group_arn
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_vpc
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_rds_db_cluster.rows[*].subnet_id
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
        query = query.rds_db_cluster_overview
        args  = [self.input.db_cluster_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.rds_db_cluster_tags
        args  = [self.input.db_cluster_arn.value]

      }
    }

  }
}

# Input queries

query "rds_db_cluster_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_rds_db_cluster
    order by
      arn;
  EOQ
}

# With queries

query "iam_roles_for_rds_db_cluster" {
  sql = <<-EOQ
    select
      roles ->> 'RoleArn' as role_arn
    from
      aws_rds_db_cluster
      cross join jsonb_array_elements(associated_roles) as roles
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "kms_keys_for_rds_db_cluster" {
  sql = <<-EOQ
    select
      kms_key_id as key_arn
    from
      aws_rds_db_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "rds_db_cluster_snapshots_for_rds_db_cluster" {
  sql = <<-EOQ
    with rds_db_cluster as (
      select
        arn,
        db_cluster_identifier,
        region,
        account_id
      from
        aws_rds_db_cluster
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and arn = $1
      order by
        arn,
        db_cluster_identifier,
        region,
        account_id
    ), rds_db_cluster_snapshot as (
      select
        arn,
        db_cluster_identifier,
        region,
        account_id
      from
        aws_rds_db_cluster_snapshot
      order by
        arn,
        db_cluster_identifier,
        region,
        account_id
    )
    select
      s.arn as snapshot_arn
    from
      rds_db_cluster as c
      join rds_db_cluster_snapshot as s
      on s.db_cluster_identifier = c.db_cluster_identifier;
  EOQ
}

query "rds_db_instances_for_rds_db_cluster" {
  sql = <<-EOQ
    with rds_db_cluster as (
      select
        arn,
        db_cluster_identifier,
        region,
        account_id
      from
        aws_rds_db_cluster
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and arn = $1
      order by
        arn,
        db_cluster_identifier,
        region,
        account_id
    ), rds_db_instance as (
      select
        arn,
        db_cluster_identifier,
        region,
        account_id
      from
        aws_rds_db_instance
      order by
        arn,
        db_cluster_identifier,
        region,
        account_id
    )
    select
      i.arn as instance_arn
    from
      rds_db_instance as i
      join rds_db_cluster as c on i.db_cluster_identifier = c.db_cluster_identifier
  EOQ
}

query "rds_db_subnet_groups_for_rds_db_cluster" {
  sql = <<-EOQ
    with rds_db_instance as (
      select
        arn,
        db_subnet_group,
        region,
        account_id
      from
        aws_rds_db_cluster
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
        and arn = $1
      order by
        arn,
        db_subnet_group,
        region,
        account_id
    ), rds_db_subnet_group as (
      select
        arn,
        name,
        region,
        account_id
      from
        aws_rds_db_subnet_group
      where
        account_id = split_part($1, ':', 5)
        and region = split_part($1, ':', 4)
      order by
        arn,
        name,
        region,
        account_id
    )
    select
      g.arn as db_subnet_group_arn
    from
      aws_rds_db_cluster as c,
      aws_rds_db_subnet_group g
    where
      c.db_subnet_group = g.name
  EOQ
}

query "sns_topics_for_rds_db_cluster" {
  sql = <<-EOQ
    select
      s.sns_topic_arn as topic_arn
    from
      aws_rds_db_event_subscription as s,
      jsonb_array_elements_text(source_ids_list) as ids
      join aws_rds_db_cluster as c
      on ids = c.db_cluster_identifier
    where
      c.arn = $1
      and c.account_id = split_part($1, ':', 5)
      and c.region = split_part($1, ':', 4);
  EOQ
}

query "vpc_security_groups_for_rds_db_cluster" {
  sql = <<-EOQ
    select
      csg ->> 'VpcSecurityGroupId' as group_id
    from
      aws_rds_db_cluster as c,
      jsonb_array_elements(c.vpc_security_groups) as csg
    where
      c.arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "vpc_subnets_for_rds_db_cluster" {
  sql = <<-EOQ
    select
      vs ->> 'SubnetIdentifier' as subnet_id
    from
      aws_rds_db_cluster as rdc
      left join
        aws_rds_db_subnet_group as rdsg
        on rdc.db_subnet_group = rdsg.name
        and rdc.region = rdsg.region
        and rdc.account_id = rdsg.account_id
      cross join
        jsonb_array_elements(rdsg.subnets) as vs
    where
      rdc.arn = $1;
  EOQ
}

query "vpc_vpcs_for_rds_db_cluster" {
  sql = <<-EOQ
    select
      distinct avs.vpc_id as vpc_id
    from
      aws_rds_db_cluster as rdc
      join
        aws_rds_db_subnet_group as rdsg
        on rdc.db_subnet_group = rdsg.name
        and rdc.region = rdsg.region
        and rdc.account_id = rdsg.account_id
      cross join
        jsonb_array_elements(rdsg.subnets) as vs
      join
        aws_vpc_subnet as avs
        on avs.subnet_id = vs ->> 'SubnetIdentifier'
        and avs.account_id = rdsg.account_id
        and avs.region = rdsg.region
    where
      rdc.arn = $1;
  EOQ
}

# Card queries

query "rds_db_cluster_unencrypted" {
  sql = <<-EOQ
    select
      case when storage_encrypted then 'Enabled' else 'Disabled' end as value,
      'Encryption' as label,
      case when storage_encrypted then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster
    where
      arn = $1;
  EOQ
}

query "rds_db_cluster_logging_disabled" {
  sql = <<-EOQ
    select
      case when enabled_cloudwatch_logs_exports is not null then 'Enabled' else 'Disabled' end as value,
      'Logging' as label,
      case when enabled_cloudwatch_logs_exports is not null then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster
    where
      arn = $1;
  EOQ
}

query "rds_db_cluster_no_deletion_protection" {
  sql = <<-EOQ
    select
      case when deletion_protection then 'Enabled' else 'Disabled' end as value,
      'Deletion Protection' as label,
      case when deletion_protection then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_cluster
    where
      arn = $1;
  EOQ
}

query "rds_db_cluster_status" {
  sql = <<-EOQ
    select
      initcap(status) as value,
      'Status' as label,
      case when status = 'available' then 'ok' else 'alert' end as type
    from
      aws_rds_db_cluster
    where
      arn = $1;
  EOQ
}

# Other detail page queries

query "rds_db_cluster_overview" {
  sql = <<-EOQ
    select
      db_cluster_identifier as "Cluster Name",
      title as "Title",
      create_time as "Create Date",
      engine_version as "Engine Version",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_rds_db_cluster
    where
      arn = $1;
  EOQ
}

query "rds_db_cluster_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_rds_db_cluster,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ
}
