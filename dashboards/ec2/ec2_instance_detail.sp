query "aws_ec2_instance_input" {
  sql = <<EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id, 
        'region', region,
        'instance_id', instance_id
      ) as tags
    from
      aws_ec2_instance
    order by
      title;
  EOQ
}

query "aws_ec2_instance_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      instance_state as value
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}

}

query "aws_ec2_instance_type" {
  sql = <<-EOQ
    select
      'Type' as label,
      instance_type as value
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_total_cores_count" {
  sql = <<-EOQ
    select
      'Total Cores' as label,
      sum(cpu_options_core_count) as value
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_public_access" {
  sql = <<-EOQ
    select
      'Public' as label,
      case when public_ip_address is null then 'Disabled' else 'Enabled' end as value,
      case when public_ip_address is null then 'ok' else 'alert' end as type
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_ebs_optimized" {
  sql = <<-EOQ
    select
      'EBS Optimized' as label,
      case when ebs_optimized then 'Enabled' else 'Disabled' end as value,
      case when ebs_optimized then 'ok' else 'alert' end as type
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_detailed_monitoring" {
  sql = <<-EOQ
    select
      'Detailed Monitoring' as label,
      case when monitoring_state = 'enabled' then 'Enabled' else 'Disabled' end as value,
      case when ebs_optimized then 'ok' else 'alert' end as type
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_block_device_mapping" {
  sql = <<-EOQ
    select
      p ->> 'DeviceName'  as "Device Name",
      p -> 'Ebs' ->> 'AttachTime' as "Attach Time",
      p -> 'Ebs' ->> 'DeleteOnTermination' as "Delete On Termination",
      p -> 'Ebs' ->> 'Status'  as "Status",
      p -> 'Ebs' ->> 'VolumeId'  as "Volume Id"
    from
      aws_ec2_instance,
      jsonb_array_elements(block_device_mappings) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_security_groups" {
  sql = <<-EOQ
    select
      p ->> 'GroupId'  as "Group Id",
      p -> 'GroupName' ->> 'AttachTime' as "Group Name"
    from
      aws_ec2_instance,
      jsonb_array_elements(security_groups) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_network_interfaces" {
  sql = <<-EOQ
    select
      p ->> 'NetworkInterfaceId' as "Network Interface Id",
      p ->> 'InterfaceType' as "Interface Type",
      p ->> 'Status' as "Status",
      p ->> 'SubnetId' as "Subnet Id",
      p ->> 'VpcId' as "Vpc Id"
    from
      aws_ec2_instance,
      jsonb_array_elements(network_interfaces) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_ec2_instance_cpu_cores" {
  sql = <<-EOQ
    select
      cpu_options_core_count  as "CPU Options Core Count",
      cpu_options_threads_per_core  as "CPU Options Threads Per Core"
    from
      aws_ec2_instance
    where
      arn = $1;
  EOQ

  param "arn" {}
}

dashboard "aws_ec2_instance_detail" {
  title = "AWS EC2 Instance Detail"

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "instance_arn" {
    title = "Select an instance:"
    sql   = query.aws_ec2_instance_input.sql
    width = 4
  }

  container {
    # Assessments

    card {
      width = 2

      query = query.aws_ec2_instance_status
      args = {
        arn = self.input.instance_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_ec2_instance_type
      args = {
        arn = self.input.instance_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_ec2_instance_total_cores_count
      args = {
        arn = self.input.instance_arn.value
      }
    }

    card {
      width = 2

      query = query.aws_ec2_instance_public_access
      args = {
        arn = self.input.instance_arn.value
      }
    }

    card {
      query = query.aws_ec2_instance_ebs_optimized
      width = 2

      args = {
        arn = self.input.instance_arn.value
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
        sql   = <<-EOQ
          select
            tags ->> 'Name' as "Name",
            instance_id as "Instance Id",
            launch_time as "Launch Time",
            title as "Title",
            region as "Region",
            account_id as "Account Id",
            arn as "ARN"
          from
            aws_ec2_instance
          where
            arn = $1
        EOQ

        param "arn" {}

        args = {
          arn = self.input.instance_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6

        sql = <<-EOQ
          select
            tag ->> 'Key' as "Key",
            tag ->> 'Value' as "Value"
          from
            aws_ec2_instance,
            jsonb_array_elements(tags_src) as tag
          where
            arn = $1
          EOQ

        param "arn" {}

        args = {
          arn = self.input.instance_arn.value
        }
      }
    }
    container {
      width = 6

      table {
        title = "Block Device Mappings"
        query = query.aws_ec2_instance_block_device_mapping
        args = {
          arn = self.input.instance_arn.value
        }
      }
    }

  }

  container {
    width = 12

    table {
      title = "Network Interfaces"
      query = query.aws_ec2_instance_network_interfaces
      args = {
        arn = self.input.instance_arn.value
      }
    }

  }

  container {
    width = 6

    table {
      title = "Security Groups"
      query = query.aws_ec2_instance_security_groups
      args = {
        arn = self.input.instance_arn.value
      }
    }

  }

  container {
    width = 6

    table {
      title = " CPU cores"
      query = query.aws_ec2_instance_cpu_cores
      args = {
        arn = self.input.instance_arn.value
      }
    }

  }

}

