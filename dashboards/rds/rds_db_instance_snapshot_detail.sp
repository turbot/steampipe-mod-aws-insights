dashboard "rds_db_snapshot_detail" {

  title         = "AWS RDS DB Instance Snapshot Detail"
  documentation = file("./dashboards/rds/docs/rds_db_instance_snapshot_detail.md")

  tags = merge(local.rds_common_tags, {
    type = "Detail"
  })

  input "db_snapshot_arn" {
    title = "Select a DB Snapshot:"
    query = query.rds_db_snapshot_input
    width = 4
  }

  container {
    # Assessments

    card {
      width = 2

      query = query.rds_db_snapshot_type
      args  = [self.input.db_snapshot_arn.value]
    }

    card {
      width = 2

      query = query.rds_db_snapshot_engine
      args  = [self.input.db_snapshot_arn.value]
    }

    card {
      width = 2

      query = query.rds_db_snapshot_status
      args  = [self.input.db_snapshot_arn.value]
    }

    card {
      width = 2

      query = query.rds_db_snapshot_unencrypted
      args  = [self.input.db_snapshot_arn.value]
    }

    card {
      width = 2

      query = query.rds_db_snapshot_iam_database_authentication_enabled
      args  = [self.input.db_snapshot_arn.value]
    }

  }

  with "kms_keys_for_rds_db_instance_snapshot" {
    query = query.kms_keys_for_rds_db_instance_snapshot
    args  = [self.input.db_snapshot_arn.value]
  }

  with "rds_instances_for_rds_db_instance_snapshot" {
    query = query.rds_instances_for_rds_db_instance_snapshot
    args  = [self.input.db_snapshot_arn.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys_for_rds_db_instance_snapshot.rows[*].key_arn
        }
      }

      node {
        base = node.rds_db_instance
        args = {
          rds_db_instance_arns = with.rds_instances_for_rds_db_instance_snapshot.rows[*].rds_instance_arn
        }
      }

      node {
        base = node.rds_db_snapshot
        args = {
          rds_db_snapshot_arns = [self.input.db_snapshot_arn.value]
        }
      }

      edge {
        base = edge.rds_db_instance_to_rds_db_snapshot
        args = {
          rds_db_instance_arns = with.rds_instances_for_rds_db_instance_snapshot.rows[*].rds_instance_arn
        }
      }

      edge {
        base = edge.rds_db_snapshot_to_kms_key
        args = {
          rds_db_snapshot_arns = [self.input.db_snapshot_arn.value]
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
        query = query.rds_db_snapshot_overview
        args  = [self.input.db_snapshot_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.rds_db_snapshot_tag
        args  = [self.input.db_snapshot_arn.value]
      }

    }

    container {
      width = 6

      table {
        title = "Storage"
        query = query.rds_db_snapshot_storage
        args  = [self.input.db_snapshot_arn.value]
      }

      table {
        title = "Attributes"
        query = query.rds_db_snapshot_attribute

        args = [self.input.db_snapshot_arn.value]
      }

    }

  }

}

# Input queries

query "rds_db_snapshot_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_rds_db_snapshot
    order by
      title;
  EOQ
}

# With queries

query "kms_keys_for_rds_db_instance_snapshot" {
  sql = <<-EOQ
    select
      kms_key_id as key_arn
    from
      aws_rds_db_snapshot
    where
      kms_key_id is not null
      and arn = $1;
  EOQ
}

query "rds_instances_for_rds_db_instance_snapshot" {
  sql = <<-EOQ
    select
      i.arn as rds_instance_arn
    from
      aws_rds_db_instance as i
      join aws_rds_db_snapshot as s
        on s.dbi_resource_id = i.resource_id
    where
      s.arn = $1;
  EOQ
}

# Card queries

query "rds_db_snapshot_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      type as value
    from
      aws_rds_db_snapshot
    where
      arn = $1;
  EOQ
}

query "rds_db_snapshot_engine" {
  sql = <<-EOQ
    select
      'Engine' as label,
      engine as  value
    from
      aws_rds_db_snapshot
    where
      arn = $1;
  EOQ
}

query "rds_db_snapshot_status" {
  sql = <<-EOQ
    select
      status as value,
      'Status' as label,
      case when status = 'available' then 'ok' else 'alert' end as type
    from
      aws_rds_db_snapshot
    where
      arn = $1;
  EOQ
}

query "rds_db_snapshot_unencrypted" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when encrypted then 'Enabled' else 'Disabled' end as value,
      case when encrypted then 'ok' else 'alert' end as type
    from
      aws_rds_db_snapshot
    where
      arn = $1;
  EOQ
}

query "rds_db_snapshot_iam_database_authentication_enabled" {
  sql = <<-EOQ
    select
      'IAM Database Authentication' as label,
      case when iam_database_authentication_enabled then 'Enabled' else 'Disabled' end as value,
      case when iam_database_authentication_enabled then 'ok' else 'alert' end as type
    from
      aws_rds_db_snapshot
    where
      arn = $1;
  EOQ
}

# Other detail page queries

query "rds_db_snapshot_overview" {
  sql = <<-EOQ
    select
      db_snapshot_identifier as "DB Snapshot Identifier",
      case
        when vpc_id is not null and vpc_id != '' then vpc_id
        else 'N/A'
      end as "VPC ID",
      create_time as "Create Time",
      license_model as "License Model",
      engine_version as "Engine Version",
      port as "Port",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_rds_db_snapshot
    where
      arn = $1;
  EOQ
}

query "rds_db_snapshot_tag" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_rds_db_snapshot,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
    EOQ
}

query "rds_db_snapshot_attribute" {
  sql = <<-EOQ
    select
      a ->> 'AttributeName' as "Attribute Name",
      a ->> 'AttributeValues' as "Attribute Values"
    from
      aws_rds_db_snapshot,
      jsonb_array_elements(db_snapshot_attributes) as a
    where
      arn = $1;
  EOQ
}

query "rds_db_snapshot_storage" {
  sql = <<-EOQ
    select
      storage_type as "Storage Type",
      allocated_storage as "Allocated Storage"
    from
      aws_rds_db_snapshot
    where
      arn = $1;
  EOQ
}
