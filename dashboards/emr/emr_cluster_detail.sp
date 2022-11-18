dashboard "aws_emr_cluster_detail" {
  title         = "AWS EMR Cluster Detail"
  documentation = file("./dashboards/emr/docs/emr_cluster_detail.md")

  tags = merge(local.emr_common_tags, {
    type = "Detail"
  })

  input "emr_cluster_arn" {
    title = "Select a cluster:"
    query = query.aws_emr_cluster_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_emr_cluster_auto_termination
      args = {
        arn = self.input.emr_cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_emr_cluster_state
      args = {
        arn = self.input.emr_cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_emr_cluster_logging
      args = {
        arn = self.input.emr_cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_emr_cluster_log_encryption
      args = {
        arn = self.input.emr_cluster_arn.value
      }
    }

  }

  container {
    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_emr_cluster_node,
        node.aws_emr_cluster_to_iam_role_node,
        node.aws_emr_cluster_to_s3_bucket_node,
        node.aws_emr_cluster_to_emr_instance_fleet_node,
        node.aws_emr_cluster_to_emr_instance_node,
        node.aws_emr_cluster_to_emr_instance_group_node,
        node.aws_emr_cluster_to_ec2_ami_node
      ]

      edges = [
        edge.aws_emr_cluster_to_iam_role_edge,
        edge.aws_emr_cluster_to_s3_bucket_edge,
        edge.aws_emr_cluster_to_emr_instance_fleet_edge,
        edge.aws_emr_cluster_to_emr_instance_group_edge,
        edge.aws_emr_cluster_to_ec2_ami_edge,
        edge.aws_emr_instance_group_to_emr_instance_edge,
        edge.aws_emr_instance_fleet_to_emr_instance_edge

      ]

      args = {
        arn = self.input.emr_cluster_arn.value
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
        query = query.aws_emr_cluster_overview
        args = {
          arn = self.input.emr_cluster_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_emr_cluster_tags
        args = {
          arn = self.input.emr_cluster_arn.value
        }
      }
    }
    container {
      width = 6

      table {
        title = "Status"
        query = query.aws_emr_cluster_status
        args = {
          arn = self.input.emr_cluster_arn.value
        }
      }

      table {
        title = "Instances"
        query = query.aws_emr_cluster_instance
        args = {
          arn = self.input.emr_cluster_arn.value
        }

        column "ARN" {
          display = "none"
        }

        column "EC2 Instance ID" {
          href = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn={{.'ARN' | @uri}}"
        }
      }

    }

  }

  container {
    table {
      title = "Applications"
      width = 6
      query = query.aws_emr_cluster_applications
      args = {
        arn = self.input.emr_cluster_arn.value
      }

    }

    table {
      title = "EC2 Instance Attributes"
      width = 6
      query = query.aws_emr_cluster_ec2_instance_attributes
      args = {
        arn = self.input.emr_cluster_arn.value
      }

    }
  }
}

query "aws_emr_cluster_input" {
  sql = <<-EOQ
    select
      title as label,
      cluster_arn as value,
      json_build_object(
        'id', id,
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_emr_cluster
    order by
      title;
EOQ
}

query "aws_emr_cluster_auto_termination" {
  sql = <<-EOQ
    select
      'Auto Termination' as label,
      case when auto_terminate then 'Enabled' else 'Disabled' end as value
    from
      aws_emr_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_emr_cluster_state" {
  sql = <<-EOQ
    select
      'State' as label,
      initcap(state) as value,
      case when state = 'TERMINATED_WITH_ERRORS' then 'alert' else 'ok' end as type
    from
      aws_emr_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_emr_cluster_logging" {
  sql = <<-EOQ
    select
      'Logging' as label,
      case when log_uri is null then 'Disabled' else 'Enabled' end as value,
      case when log_uri is null then 'alert' else 'ok' end as type
    from
      aws_emr_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_emr_cluster_log_encryption" {
  sql = <<-EOQ
    select
      'Log Encryption' as label,
      case when log_encryption_kms_key_id is null then 'Disabled' else 'Enabled' end as value,
      case when log_encryption_kms_key_id is null then 'alert' else 'ok' end as type
    from
      aws_emr_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

query "aws_emr_cluster_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      id as "ID",
      instance_collection_type as "Instance Collection Type",
      region as "Region",
      account_id as "Account ID",
      cluster_arn as "ARN"
    from
      aws_emr_cluster
    where
      cluster_arn = $1
  EOQ

  param "arn" {}
}

query "aws_emr_cluster_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_emr_cluster,
      jsonb_array_elements(tags_src) as tag
    where
      cluster_arn = $1
    order by
      tag ->> 'Key';
    EOQ

  param "arn" {}
}

query "aws_emr_cluster_instance" {
  sql = <<-EOQ
    select
      i.id as "ID",
      i.ec2_instance_id as "EC2 Instance ID",
      i.state as "State",
      i.instance_fleet_id as "Instance Fleet ID",
      i.instance_group_id as "Instance Group ID",
      ec2i.arn as "ARN"
    from
      aws_emr_instance as i,
      aws_emr_cluster as c,
      aws_ec2_instance as ec2i
    where
      i.cluster_id = c.id
      and i.ec2_instance_id = ec2i.instance_id
      and cluster_arn = $1;
    EOQ

  param "arn" {}
}

query "aws_emr_cluster_status" {
  sql = <<-EOQ
    select
      status -> 'StateChangeReason' ->> 'Code' as "Code",
      status -> 'StateChangeReason' ->> 'Message' as "Message",
      status -> 'Timeline' ->> 'CreationDateTime' as "Creation Time",
      status -> 'Timeline' ->> 'ReadyDateTime' as "Ready Time",
      status -> 'Timeline' ->> 'EndDateTime' as "End Time"
    from
      aws_emr_cluster
    where
      cluster_arn = $1;
    EOQ

  param "arn" {}
}

query "aws_emr_cluster_applications" {
  sql = <<-EOQ
    select
      app ->> 'Name' as "Name",
      app ->> 'Version' as "Version",
      app -> 'Args' as "Args",
      app -> 'AdditionalInfo' as "Additional Info"
    from
      aws_emr_cluster,
      jsonb_array_elements(applications) as app
    where
      cluster_arn = $1;
    EOQ

  param "arn" {}
}

query "aws_emr_cluster_ec2_instance_attributes" {
  sql = <<-EOQ
    select
      ec2_instance_attributes ->> 'Ec2KeyName' as "Ec2 Key Name",
      ec2_instance_attributes ->> 'Ec2SubnetId' as "Ec2 Subnet Id",
      ec2_instance_attributes ->> 'IamInstanceProfile' as "Iam Instance Profile",
      ec2_instance_attributes ->> 'Ec2AvailabilityZone' as "Ec2 Availability Zone",
      ec2_instance_attributes ->> 'ServiceAccessSecurityGroup' as "Service Access Security Group",
      ec2_instance_attributes ->> 'EmrManagedSlaveSecurityGroup' as "Emr Managed Slave Security Group",
      ec2_instance_attributes ->> 'EmrManagedMasterSecurityGroup' as "Emr Managed Master Security Group"
    from
      aws_emr_cluster
    where
      cluster_arn = $1;
    EOQ

  param "arn" {}
}

node "aws_emr_cluster_node" {
  category = category.aws_emr_cluster

  sql = <<-EOQ
     select
      id as id,
      title as title,
      jsonb_build_object(
        'ARN', cluster_arn,
        'State', state,
        'Log URI', log_uri,
        'Auto Terminate', auto_terminate::text,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_emr_cluster
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_emr_cluster_to_iam_role_node" {
  category = category.aws_iam_role

  sql = <<-EOQ
     select
      role_id as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Create Date', create_date,
        'Max Session Duration', max_session_duration,
        'Account ID', account_id ) as properties
    from
      aws_iam_role
    where
      name in
      (
        select
          service_role
        from
          aws_emr_cluster
        where
          cluster_arn = $1
      )
  EOQ

  param "arn" {}
}

edge "aws_emr_cluster_to_iam_role_edge" {
  title = "assumes"

  sql = <<-EOQ
     select
      c.id as from_id,
      role_id as to_id
    from
      aws_iam_role as r,
      aws_emr_cluster as c
    where
      c.cluster_arn = $1
      and r.name = c.service_role;
  EOQ

  param "arn" {}
}

node "aws_emr_cluster_to_s3_bucket_node" {
  category = category.aws_s3_bucket

  sql = <<-EOQ
     select
      arn as id,
      title as title,
      jsonb_build_object(
        'Name', name,
        'ARN', arn,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_s3_bucket
    where
      name in
      (
        select
          split_part(log_uri, '/', 3)
        from
          aws_emr_cluster
        where
          cluster_arn = $1
      )
  EOQ

  param "arn" {}
}

edge "aws_emr_cluster_to_s3_bucket_edge" {
  title = "logs to"

  sql = <<-EOQ
     select
      c.id as from_id,
      b.arn as to_id
    from
      aws_emr_cluster as c
      left join
        aws_s3_bucket as b
        on split_part(log_uri, '/', 3) = b.name
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_emr_cluster_to_emr_instance_fleet_node" {
  category = category.aws_emr_instance_fleet

  sql = <<-EOQ
     select
      id as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'State', state,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_emr_instance_fleet
    where
      cluster_id in
      (
        select
          id
        from
          aws_emr_cluster
        where
          cluster_arn = $1
      )
  EOQ

  param "arn" {}
}

edge "aws_emr_cluster_to_emr_instance_fleet_edge" {
  title = "instance fleet"

  sql = <<-EOQ
     select
      c.id as from_id,
      f.id as to_id
    from
      aws_emr_cluster as c
      left join
        aws_emr_instance_fleet as f
        on f.cluster_id = c.id
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_emr_cluster_to_emr_instance_group_node" {
  category = category.aws_emr_instance_group

  sql = <<-EOQ
     select
      id as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'State', state,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_emr_instance_group
    where
      cluster_id in
      (
        select
          id
        from
          aws_emr_cluster
        where
          cluster_arn = $1
      )
  EOQ

  param "arn" {}
}

edge "aws_emr_cluster_to_emr_instance_group_edge" {
  title = "instance group"

  sql = <<-EOQ
     select
      c.id as from_id,
      g.id as to_id
    from
      aws_emr_cluster as c
      left join
        aws_emr_instance_group as g
        on g.cluster_id = c.id
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_emr_cluster_to_ec2_ami_node" {
  category = category.aws_ec2_ami

  sql = <<-EOQ
     select
      image_id as id,
      title as title,
      jsonb_build_object(
        'Image ID', image_id,
        'Creation Date', creation_date,
        'State', state,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_ec2_ami
    where
      image_id in
      (
        select
          custom_ami_id
        from
          aws_emr_cluster
        where
          cluster_arn = $1
      )
  EOQ

  param "arn" {}
}

edge "aws_emr_cluster_to_ec2_ami_edge" {
  title = "ami"

  sql = <<-EOQ
     select
      c.id as from_id,
      image_id as to_id
    from
      aws_emr_cluster as c
      left join
        aws_ec2_ami as a
        on a.image_id = c.custom_ami_id
    where
      cluster_arn = $1;
  EOQ

  param "arn" {}
}

node "aws_emr_cluster_to_emr_instance_node" {
  category = category.aws_emr_instance

  sql = <<-EOQ
     select
      emri.id as id,
      emri.title as title,
      jsonb_build_object(
        'EC2 Instance ARN', ec2i.arn,
        'EC2 Instance ID', ec2_instance_id,
        'State', emri.state,
        'Instance Type', emri.instance_type,
        'Account ID', emri.account_id,
        'Region', emri.region ) as properties
    from
      aws_ec2_instance as ec2i,
      aws_emr_instance as emri
    where
      ec2i.instance_id = emri.ec2_instance_id
      and cluster_id in
      (
        select
          id
        from
          aws_emr_cluster
        where
          cluster_arn = $1
      )
  EOQ

  param "arn" {}
}

edge "aws_emr_instance_fleet_to_emr_instance_edge" {
  title = "ec2 instance"

  sql = <<-EOQ
     select
      instance_fleet_id as from_id,
      i.id as to_id
    from
      aws_emr_cluster as c
      left join
        aws_emr_instance as i
        on i.cluster_id = c.id
    where
      cluster_arn = $1
      and instance_fleet_id is not null
      and i.state <> 'TERMINATED';
  EOQ

  param "arn" {}
}

edge "aws_emr_instance_group_to_emr_instance_edge" {
  title = "ec2 instance"

  sql = <<-EOQ
     select
      instance_group_id as from_id,
      i.id as to_id
    from
      aws_emr_cluster as c
      left join
        aws_emr_instance as i
        on i.cluster_id = c.id
    where
      cluster_arn = $1
      and instance_group_id is not null
      and i.state <> 'TERMINATED';
  EOQ

  param "arn" {}
}
