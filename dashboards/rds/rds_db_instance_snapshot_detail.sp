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
      args = {
        arn = self.input.db_snapshot_arn.value
      }
    }

    card {
      width = 2

      query = query.rds_db_snapshot_engine
      args = {
        arn = self.input.db_snapshot_arn.value
      }
    }

    card {
      width = 2

      query = query.rds_db_snapshot_status
      args = {
        arn = self.input.db_snapshot_arn.value
      }
    }

    card {
      width = 2

      query = query.rds_db_snapshot_unencrypted
      args = {
        arn = self.input.db_snapshot_arn.value
      }
    }

    card {
      width = 2

      query = query.rds_db_snapshot_iam_database_authentication_enabled
      args = {
        arn = self.input.db_snapshot_arn.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      with "rds_instances" {
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

        args = [self.input.db_snapshot_arn.value]
      }

      with "kms_keys" {
        sql = <<-EOQ
          select
            kms_key_id as key_arn
          from
            aws_rds_db_snapshot
          where
            arn = $1;
        EOQ

        args = [self.input.db_snapshot_arn.value]
      }

      nodes = [
        node.rds_db_snapshot,
        node.kms_key,
        node.rds_db_instance
      ]

      edges = [
        edge.rds_db_snapshot_to_kms_key,
        edge.rds_db_instance_to_rds_db_snapshot
      ]

      args = {
        rds_db_instance_arns = with.rds_instances.rows[*].rds_instance_arn
        kms_key_arns         = with.kms_keys.rows[*].key_arn
        rds_db_snapshot_arns = [self.input.db_snapshot_arn.value]
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
        args = {
          arn = self.input.db_snapshot_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.rds_db_snapshot_tag
        args = {
          arn = self.input.db_snapshot_arn.value
        }
      }

    }

    container {
      width = 6

      table {
        title = "Storage"
        query = query.rds_db_snapshot_storage
        args = {
          arn = self.input.db_snapshot_arn.value
        }
      }

      table {
        title = "Attributes"
        query = query.rds_db_snapshot_attribute

        args = {
          arn = self.input.db_snapshot_arn.value
        }
      }

    }

  }

}

# Card Queries
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

  param "arn" {}
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

  param "arn" {}
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

  param "arn" {}
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

  param "arn" {}
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

  param "arn" {}
}

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

  param "arn" {}
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

  param "arn" {}
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

  param "arn" {}
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

  param "arn" {}
}

node "rds_db_snapshot" {
  category = category.rds_db_snapshot

  sql = <<-EOQ
    select
      arn as id,
      title,
      jsonb_build_object(
        'ARN', arn,
        'Status', status,
        'Availability Zone', availability_zone,
        'DB Instance Identifier', db_instance_identifier,
        'Create Time', create_time,
        'Encrypted', encrypted::text,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_rds_db_snapshot
    where
      arn = any($1);
  EOQ

  param "rds_db_snapshot_arns" {}
}

edge "rds_db_snapshot_to_kms_key" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      rds_db_snapshots_arn as from_id,
      key_arn as to_id
    from
      unnest($1::text[]) as key_arn,
      unnest($2::text[]) as rds_db_snapshots_arn;
  EOQ

  param "kms_key_arns" {}
  param "rds_db_snapshot_arns" {}
}
