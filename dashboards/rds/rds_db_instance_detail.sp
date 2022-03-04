dashboard "aws_rds_db_instance_detail" {

  title = "AWS RDS DB Instance Detail"

  tags = merge(local.rds_common_tags, {
    type = "Detail"
  })

  input "db_instance_arn" {
    title = "Select a DB Instance:"
    sql   = query.aws_rds_db_instance_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_rds_db_instance_engine_type
      args  = {
        arn = self.input.db_instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_rds_db_instance_class
      args  = {
        arn = self.input.db_instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_rds_db_instance_public
      args  = {
        arn = self.input.db_instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_rds_db_instance_unencrypted
      args  = {
        arn = self.input.db_instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_rds_db_instance_deletion_protection
      args  = {
        arn = self.input.db_instance_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_rds_db_instance_in_vpc
      args  = {
        arn = self.input.db_instance_arn.value
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
        query = query.aws_rds_db_instance_overview
        args  = {
          arn = self.input.db_instance_arn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_rds_db_instance_tags
        args  = {
          arn = self.input.db_instance_arn.value
        }
      }


    }

    container {

      width = 6

      table {
        title = "DB Parameter Groups"
        query = query.aws_rds_db_instance_parameter_groups
        args  = {
          arn = self.input.db_instance_arn.value
        }
      }

      table {
        title = "Subnets"
        query = query.aws_rds_db_instance_subnets
        args  = {
          arn = self.input.db_instance_arn.value
        }
      }

    }

    container {

      width = 12

      table {
        width = 6
        title = "Storage"
        query = query.aws_rds_db_instance_storage
        args  = {
          arn = self.input.db_instance_arn.value
        }
      }

      table {
        width = 6
        title = "Logging"
        query = query.aws_rds_db_instance_logging
        args  = {
          arn = self.input.db_instance_arn.value
        }
      }

    }

    container {

      width = 12

      table {
        width = 6
        title = "Security Groups"
        query = query.aws_rds_db_instance_security_groups
        args  = {
          arn = self.input.db_instance_arn.value
        }
      }

      table {
        width = 6
        title = "DB Subnet Groups"
        query = query.aws_rds_db_instance_db_subnet_groups
        args  = {
          arn = self.input.db_instance_arn.value
        }
      }

    }

  }

}

query "aws_rds_db_instance_input" {
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

query "aws_rds_db_instance_engine_type" {
  sql = <<-EOQ
    select
      'Engine Type' as label,
      engine as value
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_class" {
  sql = <<-EOQ
    select
      'Class' as label,
      class as value
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_public" {
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

  param "arn" {}
}

query "aws_rds_db_instance_unencrypted" {
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

  param "arn" {}
}

query "aws_rds_db_instance_deletion_protection" {
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

  param "arn" {}
}

query "aws_rds_db_instance_in_vpc" {
  sql = <<-EOQ
    select
      'In VPC' as label,
      case when vpc_id is not null then 'Enabled' else 'Disabled' end as value,
      case when vpc_id is not null then 'ok' else 'alert' end as type
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_parameter_groups" {
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

  param "arn" {}
}

query "aws_rds_db_instance_subnets" {
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

  param "arn" {}
}

query "aws_rds_db_instance_storage" {
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

  param "arn" {}
}

query "aws_rds_db_instance_logging" {
  sql = <<-EOQ
    select
      enabled_cloudwatch_logs_exports as "Enabled CloudWatch Logs Exports",
      enhanced_monitoring_resource_arn as "Enhanced Monitoring Resource Arn"
    from
      aws_rds_db_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_security_groups" {
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

  param "arn" {}
}

query "aws_rds_db_instance_db_subnet_groups" {
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

  param "arn" {}
}

query "aws_rds_db_instance_overview" {
  sql   = <<-EOQ
    select
      db_instance_identifier as "DB Instance Identifier",
      create_time as "Create Time",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_rds_db_instance
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_rds_db_instance_tags" {
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

  param "arn" {}
}
