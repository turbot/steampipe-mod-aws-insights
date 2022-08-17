dashboard "aws_rds_db_snapshot_detail" {

  title         = "AWS RDS DB Instance Snapshot Detail"
  documentation = file("./dashboards/rds/docs/rds_db_instance_snapshot_detail.md")

  tags = merge(local.rds_common_tags, {
    type = "Detail"
  })

  input "db_snapshot_arn" {
    title = "Select a DB Snapshot:"
    sql   = query.aws_rds_db_snapshot_input.sql
    width = 4
  }

  container {
    # Assessments

    card {
      width = 2

      query = query.aws_rds_db_snapshot_type
      args = {
        arn = self.input.db_snapshot_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_rds_db_snapshot_engine
      args = {
        arn = self.input.db_snapshot_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_rds_db_snapshot_status
      args = {
        arn = self.input.db_snapshot_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_rds_db_snapshot_unencrypted
      args = {
        arn = self.input.db_snapshot_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_rds_db_snapshot_iam_database_authentication_enabled
      args = {
        arn = self.input.db_snapshot_arn.value
      }
    }

  }

  container {

    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_rds_db_snapshot_relationships_graph
      args = {
        arn = self.input.db_snapshot_arn.value
      }

      category "rds_db_snapshot" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ebs_snapshot_dark.svg"))
      }

      category "aws_rds_db_instance" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/rds_db_instance_dark.svg"))
        href = "/aws_insights.dashboard.aws_rds_db_instance_detail.url_path?input.db_instance_arn={{.properties.ARN | @uri}}"
      }

      category "kms_key" {
        href = "/aws_insights.dashboard.aws_kms_key_detail.url_path?input.key_arn={{.properties.ARN | @uri}}"
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/kms_key_dark.svg"))
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
        query = query.aws_rds_db_snapshot_overview
        args = {
          arn = self.input.db_snapshot_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_rds_db_snapshot_tag
        args = {
          arn = self.input.db_snapshot_arn.value
        }
      }

    }

    container {
      width = 6

      table {
        title = "Storage"
        query = query.aws_rds_db_snapshot_storage
        args = {
          arn = self.input.db_snapshot_arn.value
        }
      }

      table {
        title = "Attributes"
        query = query.aws_rds_db_snapshot_attribute

        args = {
          arn = self.input.db_snapshot_arn.value
        }
      }

    }

  }

}

# Card Queries
query "aws_rds_db_snapshot_input" {
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

query "aws_rds_db_snapshot_type" {
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

query "aws_rds_db_snapshot_engine" {
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

query "aws_rds_db_snapshot_status" {
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

query "aws_rds_db_snapshot_unencrypted" {
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

query "aws_rds_db_snapshot_iam_database_authentication_enabled" {
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

query "aws_rds_db_snapshot_overview" {
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

query "aws_rds_db_snapshot_tag" {
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

query "aws_rds_db_snapshot_attribute" {
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

query "aws_rds_db_snapshot_storage" {
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


query "aws_rds_db_snapshot_relationships_graph" {
  sql = <<-EOQ
    -- RDS DB instance snapshot (node)
    select
      null as from_id,
      null as to_id,
      db_snapshot_identifier as id,
      title,
      'rds_db_snapshot' as category,
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
      arn = $1

    -- To KMS Keys (node)
    union all
    select
      null as from_id,
      null as to_id,
      k.id as id,
      COALESCE(k.aliases #>> '{0,AliasName}', k.id) as title,
      'kms_key' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'Rotation Enabled', k.key_rotation_enabled::text,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      aws_rds_db_snapshot as s
      join aws_kms_key as k on s.kms_key_id = k.arn
    where
      s.arn = $1

    -- To KMS keys (edge)
    union all
    select
      s.db_snapshot_identifier as from_id,
      k.id as to_id,
      null as id,
      'encrypted with' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'DB Snapshot Identifier', s.db_snapshot_identifier,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      aws_rds_db_snapshot as s
      join aws_kms_key as k on s.kms_key_id = k.arn
    where
      s.arn = $1

    -- From RDS DB instance (node)
    union all
    select
      null as from_id,
      null as to_id,
      s.db_instance_identifier as id,
      s.title as title,
      'aws_rds_db_instance' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Status', i.status,
        'Public Access', i.publicly_accessible::text,
        'Availability Zone', i.availability_zone,
        'Create Time', i.create_time,
        'Is Multi AZ', i.multi_az::text,
        'Class', i.class,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_rds_db_snapshot as s
      join aws_rds_db_instance as i on s.db_instance_identifier = i.db_instance_identifier
        and s.account_id = i.account_id
        and s.region = i.region
    where
      s.arn = $1

    -- From RDS DB instance (edge)
    union all
    select
      i.db_instance_identifier as from_id,
      s.db_snapshot_identifier as to_id,
      null as id,
      'has snapshot' as title,
      'uses' as category,
      jsonb_build_object(
        'DB Instance Identifier', i.db_instance_identifier,
        'DB Snapshot Identifier', s.db_snapshot_identifier,
        'Account ID', s.account_id,
        'Region', s.region
      ) as properties
    from
      aws_rds_db_snapshot as s
      join aws_rds_db_instance as i on s.db_instance_identifier = i.db_instance_identifier
        and s.account_id = i.account_id
        and s.region = i.region
    where
      s.arn = $1
  EOQ

  param "arn" {}
}
