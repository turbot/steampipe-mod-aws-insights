dashboard "rds_db_instance_detail" {

  title         = "AWS RDS DB Instance Detail"
  documentation = file("./dashboards/rds/docs/rds_db_instance_detail.md")

  tags = merge(local.rds_common_tags, {
    type = "Detail"
  })

  input "db_instance_arn" {
    title = "Select a DB Instance:"
    query = query.rds_db_instance_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.rds_db_instance_engine_type
      args  = [self.input.db_instance_arn.value]
    }

    card {
      width = 2
      query = query.rds_db_instance_class
      args  = [self.input.db_instance_arn.value]
    }

    card {
      width = 2
      query = query.rds_db_instance_public
      args  = [self.input.db_instance_arn.value]
    }

    card {
      width = 2
      query = query.rds_db_instance_unencrypted
      args  = [self.input.db_instance_arn.value]
    }

    card {
      width = 2
      query = query.rds_db_instance_deletion_protection
      args  = [self.input.db_instance_arn.value]
    }

  }

  with "kms_keys_for_rds_db_instance" {
    query = query.kms_keys_for_rds_db_instance
    args  = [self.input.db_instance_arn.value]
  }

  with "rds_db_clusters_for_rds_db_instance" {
    query = query.rds_db_clusters_for_rds_db_instance
    args  = [self.input.db_instance_arn.value]
  }

  with "rds_db_snapshots_for_rds_db_instance" {
    query = query.rds_db_snapshots_for_rds_db_instance
    args  = [self.input.db_instance_arn.value]
  }

  with "rds_db_subnet_groups_for_rds_db_instance" {
    query = query.rds_db_subnet_groups_for_rds_db_instance
    args  = [self.input.db_instance_arn.value]
  }

  with "sns_topics_for_rds_db_instance" {
    query = query.sns_topics_for_rds_db_instance
    args  = [self.input.db_instance_arn.value]
  }

  with "vpc_security_groups_for_rds_db_instance" {
    query = query.vpc_security_groups_for_rds_db_instance
    args  = [self.input.db_instance_arn.value]
  }

  with "vpc_subnets_for_rds_db_instance" {
    query = query.vpc_subnets_for_rds_db_instance
    args  = [self.input.db_instance_arn.value]
  }

  with "vpc_vpcs_for_rds_db_instance" {
    query = query.vpc_vpcs_for_rds_db_instance
    args  = [self.input.db_instance_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "top-down"

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys_for_rds_db_instance.rows[*].key_arn
        }
      }

      node {
        base = node.rds_db_cluster
        args = {
          rds_db_cluster_arns = with.rds_db_clusters_for_rds_db_instance.rows[*].cluster_arn
        }
      }

      node {
        base = node.rds_db_instance
        args = {
          rds_db_instance_arns = [self.input.db_instance_arn.value]
        }
      }

      node {
        base = node.rds_db_parameter_group
        args = {
          rds_db_instance_arns = [self.input.db_instance_arn.value]
        }
      }

      node {
        base = node.rds_db_snapshot
        args = {
          rds_db_snapshot_arns = with.rds_db_snapshots_for_rds_db_instance.rows[*].snapshot_arn
        }
      }

      node {
        base = node.rds_db_subnet_group
        args = {
          rds_db_subnet_group_arns = with.rds_db_subnet_groups_for_rds_db_instance.rows[*].db_subnet_group_arn
        }
      }

      node {
        base = node.sns_topic
        args = {
          sns_topic_arns = with.sns_topics_for_rds_db_instance.rows[*].sns_topic_arn
        }
      }

      node {
        base = node.vpc_security_group
        args = {
          vpc_security_group_ids = with.vpc_security_groups_for_rds_db_instance.rows[*].security_group_id
        }
      }

      node {
        base = node.vpc_subnet
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_rds_db_instance.rows[*].subnet_id
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_rds_db_instance.rows[*].vpc_id
        }
      }

      edge {
        base = edge.rds_db_cluster_to_rds_db_instance
        args = {
          rds_db_cluster_arns = with.rds_db_clusters_for_rds_db_instance.rows[*].cluster_arn
        }
      }

      edge {
        base = edge.rds_db_instance_to_kms_key
        args = {
          rds_db_instance_arns = [self.input.db_instance_arn.value]
        }
      }

      edge {
        base = edge.rds_db_instance_to_rds_db_parameter_group
        args = {
          rds_db_instance_arns = [self.input.db_instance_arn.value]
        }
      }

      edge {
        base = edge.rds_db_instance_to_rds_db_snapshot
        args = {
          rds_db_instance_arns = [self.input.db_instance_arn.value]
        }
      }

      edge {
        base = edge.rds_db_instance_to_sns_topic
        args = {
          rds_db_instance_arns = [self.input.db_instance_arn.value]
        }
      }

      edge {
        base = edge.rds_db_instance_to_vpc_security_group
        args = {
          rds_db_instance_arns = [self.input.db_instance_arn.value]
        }
      }

      edge {
        base = edge.rds_db_subnet_group_to_vpc_subnet
        args = {
          rds_db_subnet_group_arns = with.rds_db_subnet_groups_for_rds_db_instance.rows[*].db_subnet_group_arn
        }
      }

      edge {
        base = edge.vpc_security_group_to_rds_db_subnet_group
        args = {
          rds_db_subnet_group_arns = with.rds_db_subnet_groups_for_rds_db_instance.rows[*].db_subnet_group_arn
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_vpc
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_rds_db_instance.rows[*].subnet_id
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
        query = query.rds_db_instance_overview
        args  = [self.input.db_instance_arn.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.rds_db_instance_tags
        args  = [self.input.db_instance_arn.value]
      }

    }

    container {

      width = 6

      table {
        title = "DB Parameter Groups"
        query = query.rds_db_instance_parameter_groups
        args  = [self.input.db_instance_arn.value]
      }

      table {
        title = "Subnets"
        query = query.rds_db_instance_subnets
        args  = [self.input.db_instance_arn.value]
      }

    }

    container {

      width = 12

      table {
        width = 6
        title = "Storage"
        query = query.rds_db_instance_storage
        args  = [self.input.db_instance_arn.value]
      }

      table {
        width = 6
        title = "Logging"
        query = query.rds_db_instance_logging
        args  = [self.input.db_instance_arn.value]
      }

    }

    container {

      width = 12

      table {
        width = 6
        title = "Security Groups"
        query = query.rds_db_instance_security_groups
        args  = [self.input.db_instance_arn.value]
      }

      table {
        width = 6
        title = "DB Subnet Groups"
        query = query.rds_db_instance_db_subnet_groups
        args  = [self.input.db_instance_arn.value]
      }

    }

  }

}

# Input queries

query "rds_db_instance_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_rds_db_instance
    order by
      title;
  EOQ
}

# With queries

query "kms_keys_for_rds_db_instance" {
  sql = <<-EOQ
    select
      rdb.kms_key_id as key_arn
    from
      aws_rds_db_instance rdb
    where
      rdb.arn = $1
      and kms_key_id is not null;
  EOQ
}

query "rds_db_clusters_for_rds_db_instance" {
  sql = <<-EOQ
    select
      c.arn as cluster_arn
    from
      aws_rds_db_instance as i
      join
        aws_rds_db_cluster as c
        on i.db_cluster_identifier = c.db_cluster_identifier
    where
      i.arn = $1;
  EOQ
}

query "rds_db_snapshots_for_rds_db_instance" {
  sql = <<-EOQ
    select
      s.arn as snapshot_arn
    from
      aws_rds_db_instance as i
      join aws_rds_db_snapshot as s
        on s.dbi_resource_id = i.resource_id
    where
      i.arn = $1;
  EOQ
}

query "rds_db_subnet_groups_for_rds_db_instance" {
  sql = <<-EOQ
    select
      g.arn as db_subnet_group_arn
    from
      aws_rds_db_instance as i,
      aws_rds_db_subnet_group g
    where
      i.db_subnet_group_name = g.name
      and i.region = g.region
      and i.account_id = g.account_id
      and i.arn = $1;
  EOQ
}

query "sns_topics_for_rds_db_instance" {
  sql = <<-EOQ
    select
      s.sns_topic_arn
    from
      aws_rds_db_event_subscription as s,
      jsonb_array_elements_text(source_ids_list) as ids
      join aws_rds_db_instance as i
      on ids = i.db_instance_identifier
    where
      i.arn = $1;
  EOQ
}

query "vpc_security_groups_for_rds_db_instance" {
  sql = <<-EOQ
    select
      dsg ->> 'VpcSecurityGroupId' as security_group_id
    from
      aws_rds_db_instance as di,
      jsonb_array_elements(di.vpc_security_groups) as dsg
    where
      di.arn = $1;
  EOQ
}

query "vpc_subnets_for_rds_db_instance" {
  sql = <<-EOQ
    select
      subnet ->> 'SubnetIdentifier' as subnet_id
    from
      aws_rds_db_instance as rdb,
      jsonb_array_elements(subnets) as subnet
    where
      rdb.arn = $1;
  EOQ
}

query "vpc_vpcs_for_rds_db_instance" {
  sql = <<-EOQ
    select
      vpc_id
    from
      aws_rds_db_instance as di
    where
      di.arn = $1;
  EOQ
}

# Card queries

query "rds_db_instance_engine_type" {
  sql = <<-EOQ
    select
      'Engine Type' as label,
      engine as value
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ
}

query "rds_db_instance_class" {
  sql = <<-EOQ
    select
      'Class' as label,
      class as value
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ
}

query "rds_db_instance_public" {
  sql = <<-EOQ
    select
      'Public Access' as label,
      case when not publicly_accessible then 'Disabled' else 'Enabled' end as value,
      case when not  publicly_accessible then 'ok' else 'alert' end as type
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ
}

query "rds_db_instance_unencrypted" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when storage_encrypted then 'Enabled' else 'Disabled' end as value,
      case when storage_encrypted then 'ok' else 'alert' end as type
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ
}

query "rds_db_instance_deletion_protection" {
  sql = <<-EOQ
    select
      'Deletion Protection' as label,
      case when deletion_protection then 'Enabled' else 'Disabled' end as value,
      case when deletion_protection then 'ok' else 'alert' end as type
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ
}

# Other detail page queries

query "rds_db_instance_parameter_groups" {
  sql = <<-EOQ
    select
      p ->> 'DBParameterGroupName' as "DB Parameter Group Name",
      p ->> 'ParameterApplyStatus' as "Parameter Apply Status"
    from
      aws_rds_db_instance,
      jsonb_array_elements(db_parameter_groups) as p
    where
      arn = $1;
  EOQ
}

query "rds_db_instance_subnets" {
  sql = <<-EOQ
    select
      p ->> 'SubnetIdentifier' as "Subnet Identifier",
      p -> 'SubnetAvailabilityZone' ->> 'Name' as "Subnet Availability Zone",
      p ->> 'SubnetStatus'  as "Subnet Status"
    from
      aws_rds_db_instance,
      jsonb_array_elements(subnets) as p
    where
      arn = $1;
  EOQ
}

query "rds_db_instance_storage" {
  sql = <<-EOQ
    select
      storage_type as "Storage Type",
      allocated_storage as "Allocated Storage",
      max_allocated_storage  as "Max Allocated Storage",
      storage_encrypted as "Storage Encrypted"
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ
}

query "rds_db_instance_logging" {
  sql = <<-EOQ
    select
      enabled_cloudwatch_logs_exports as "Enabled CloudWatch Logs Exports",
      enhanced_monitoring_resource_arn as "Enhanced Monitoring Resource Arn"
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ
}

query "rds_db_instance_security_groups" {
  sql = <<-EOQ
    select
      s ->> 'VpcSecurityGroupId' as "VPC Security Group ID",
      s ->> 'Status' as "Status"
    from
      aws_rds_db_instance,
      jsonb_array_elements(vpc_security_groups) as s
    where
      arn = $1;
  EOQ
}

query "rds_db_instance_db_subnet_groups" {
  sql = <<-EOQ
    select
      db_subnet_group_name as "DB Subnet Group Name",
      db_subnet_group_arn as "DB Subnet Group ARN",
      db_subnet_group_status as "DB Subnet Group Status"
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ
}

query "rds_db_instance_overview" {
  sql = <<-EOQ
    select
      db_instance_identifier as "DB Instance Identifier",
      case
        when vpc_id is not null and vpc_id != '' then vpc_id
        else 'N/A'
      end as "VPC ID",
      create_time as "Create Time",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ
}

query "rds_db_instance_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_rds_db_instance,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
    EOQ
}
