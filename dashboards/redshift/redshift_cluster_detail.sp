dashboard "aws_redshift_cluster_detail" {

  title         = "AWS Redshift Cluster Detail"
  documentation = file("./dashboards/redshift/docs/redshift_cluster_detail.md")

  tags = merge(local.redshift_common_tags, {
    type = "Detail"
  })

  input "cluster_arn" {
    title = "Select a Cluster:"
    query = query.aws_redshift_cluster_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_redshift_cluster_status
      args = {
        arn = self.input.cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_redshift_cluster_version
      args = {
        arn = self.input.cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_redshift_cluster_node_type
      args = {
        arn = self.input.cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_redshift_cluster_number_of_nodes
      args = {
        arn = self.input.cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_redshift_cluster_public
      args = {
        arn = self.input.cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_redshift_cluster_encryption
      args = {
        arn = self.input.cluster_arn.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"


      nodes = [
        node.aws_redshift_cluster_node,
        node.aws_redshift_cluster_to_redshift_subnet_group_node,
        node.aws_redshift_cluster_to_vpc_subnet_node,
        node.aws_redshift_cluster_to_vpc_node,
        node.aws_redshift_cluster_to_vpc_security_group_node,
        node.aws_redshift_cluster_to_kms_key_node,
        node.aws_redshift_cluster_to_iam_role_node,
        node.aws_redshift_cluster_to_vpc_eip_node,
        node.aws_redshift_cluster_to_cloudwatch_log_group_node,
        node.aws_redshift_cluster_to_s3_bucket_node,
        node.aws_redshift_cluster_to_redshift_parameter_group_node,
        node.aws_redshift_cluster_from_redshift_snapshot_node
      ]

      edges = [
        edge.aws_redshift_cluster_to_redshift_subnet_group_edge,
        edge.aws_redshift_cluster_to_vpc_subnet_edge,
        edge.aws_redshift_cluster_subnet_to_vpc_edge,
        edge.aws_redshift_cluster_vpc_security_group_to_vpc_edge,
        edge.aws_redshift_cluster_to_vpc_security_group_edge,
        edge.aws_redshift_cluster_to_kms_key_edge,
        edge.aws_redshift_cluster_to_iam_role_edge,
        edge.aws_redshift_cluster_to_vpc_eip_edge,
        edge.aws_redshift_cluster_to_cloudwatch_log_group_edge,
        edge.aws_redshift_cluster_to_s3_bucket_edge,
        edge.aws_redshift_cluster_to_redshift_parameter_group_edge,
        edge.aws_redshift_cluster_from_redshift_snapshot_edge
      ]

      args = {
        arn = self.input.cluster_arn.value
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
        query = query.aws_redshift_cluster_overview
        args = {
          arn = self.input.cluster_arn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_redshift_cluster_tags
        args = {
          arn = self.input.cluster_arn.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Cluster Nodes"
        query = query.aws_redshift_cluster_nodes
        args = {
          arn = self.input.cluster_arn.value
        }
      }

      table {
        title = "Cluster Parameter Groups"
        query = query.aws_redshift_cluster_parameter_groups
        args = {
          arn = self.input.cluster_arn.value
        }
      }

    }

    table {

      title = "Logging"
      query = query.aws_redshift_cluster_logging
      args = {
        arn = self.input.cluster_arn.value
      }
    }

    table {
      title = "Scheduled Actions"
      query = query.aws_redshift_cluster_scheduled_actions
      args = {
        arn = self.input.cluster_arn.value
      }
    }

  }

}

query "aws_redshift_cluster_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_redshift_cluster
    order by
      title;
  EOQ
}

query "aws_redshift_cluster_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      cluster_status as  value
    from
      aws_redshift_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_cluster_version" {
  sql = <<-EOQ
    select
      'Version' as label,
      cluster_version as  value
    from
      aws_redshift_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_cluster_node_type" {
  sql = <<-EOQ
    select
      'Node Type' as label,
      node_type as  value
    from
      aws_redshift_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_cluster_number_of_nodes" {
  sql = <<-EOQ
    select
      'Number Of Nodes' as label,
      number_of_nodes as  value
    from
      aws_redshift_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_cluster_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when encrypted then 'Enabled' else 'Disabled' end as value,
      case when encrypted then 'ok' else 'alert' end as "type"
    from
      aws_redshift_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_cluster_public" {
  sql = <<-EOQ
    select
      'Public Access' as label,
      case when publicly_accessible then 'Enabled' else 'Disabled' end as value,
      case when not publicly_accessible then 'ok' else 'alert' end as "type"
    from
      aws_redshift_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_cluster_nodes" {
  sql = <<-EOQ
    select
      p ->> 'NodeRole' as "Node Role",
      p ->> 'PrivateIPAddress' as "PrivateIP Address",
      p ->> 'PublicIPAddress' as "PublicIP Address"
    from
      aws_redshift_cluster,
      jsonb_array_elements(cluster_nodes) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_cluster_parameter_groups" {
  sql = <<-EOQ
    select
      p -> 'ClusterParameterStatusList' as "Cluster Parameter Status List",
      p ->> 'ParameterApplyStatus' as "Parameter Apply Status",
      p ->> 'ParameterGroupName'  as "Parameter Group Name"
    from
      aws_redshift_cluster,
      jsonb_array_elements(cluster_parameter_groups) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_cluster_scheduled_actions" {
  sql = <<-EOQ
    select
      p ->> 'EndTime' as "End Time",
      p ->> 'IamRole' as "IAM Role",
      p ->> 'NextInvocations'  as "Next Invocations",
      p ->> 'Schedule' as "Schedule",
      p ->> 'ScheduledActionDescription' as "Scheduled Action Description",
      p ->> 'ScheduledActionName' as "Scheduled Action Name",
      p ->> 'StartTime' as "Start Time",
      p ->> 'State' as "State",
      p ->> 'TargetAction' as "Target Action"
    from
      aws_redshift_cluster,
      jsonb_array_elements(scheduled_actions) as p
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_cluster_logging" {
  sql = <<-EOQ
    select
      logging_status  ->> 'BucketName' as "Bucket Name",
      logging_status  ->> 'S3KeyPrefix' as "S3 Key Prefix",
      logging_status  ->> 'LoggingEnabled' as "Logging Enabled",
      logging_status  ->> 'LastFailureTime' as "Last Failure Time",
      logging_status  ->> 'LastFailureMessage' as "Last Failure Message",
      logging_status  ->> 'LastSuccessfulDeliveryTime' as "Last Successful Delivery Time"
    from
      aws_redshift_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_cluster_security_groups" {
  sql = <<-EOQ
    select
      s -> 'VpcSecurityGroupId' as "VPC Security Group ID",
      s -> 'Status' as "Status"
    from
      aws_redshift_cluster,
      jsonb_array_elements(vpc_security_groups) as s
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_redshift_cluster_overview" {
  sql = <<-EOQ
    select
      cluster_identifier as "Cluster Identifier",
      cluster_namespace_arn as "Cluster Namespace ARN",
      db_name  as "DB Name",
      vpc_id as "VPC ID",
      kms_key_id as "KMS Key ID",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_redshift_cluster
    where
      arn = $1
    EOQ

  param "arn" {}
}

query "aws_redshift_cluster_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_redshift_cluster,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
    EOQ

  param "arn" {}
}

node "aws_redshift_cluster_node" {
  category = category.aws_redshift_cluster

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region,
        'Cluster Status', cluster_status,
        'Cluster Version', cluster_version,
        'Public', publicly_accessible::text,
        'Encrypted', encrypted::text
      ) as properties
    from
      aws_redshift_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_redshift_cluster_to_redshift_subnet_group_node" {
  category = category.aws_redshift_subnet_group

  sql = <<-EOQ
    select
      s.cluster_subnet_group_name as id,
      s.cluster_subnet_group_name as title,
      jsonb_build_object(
        'AKAS', s.akas,
        'Description', s.description,
        'Status', s.subnet_group_status,
        'Vpc ID', s.vpc_id
      ) as properties
    from
      aws_redshift_cluster as c
      left join
        aws_redshift_subnet_group as s
        on c.vpc_id = s.vpc_id
        and c.cluster_subnet_group_name = s.cluster_subnet_group_name
        and c.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_redshift_cluster_to_redshift_subnet_group_edge" {
  title = "subnet group"

  sql = <<-EOQ
    select
      c.arn as from_id,
      s.cluster_subnet_group_name as to_id
    from
      aws_redshift_cluster as c
      left join
        aws_redshift_subnet_group as s
        on c.vpc_id = s.vpc_id
        and c.cluster_subnet_group_name = s.cluster_subnet_group_name
        and c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_redshift_cluster_to_vpc_subnet_node" {
  category = category.aws_vpc_subnet

  sql = <<-EOQ
    select
      subnet ->>  'SubnetIdentifier' as id,
      subnet ->>  'SubnetIdentifier' as title,
      jsonb_build_object(
        'Subnet ID', subnet ->>  'SubnetIdentifier',
        'Subnet Availability Zone', subnet -> 'SubnetAvailabilityZone' ->> 'Name',
        'Subnet Status', subnet ->> 'SubnetStatus',
        'Vpc ID', s.vpc_id
      ) as properties
    from
      aws_redshift_cluster as c
      left join
        aws_redshift_subnet_group as s
        on c.vpc_id = s.vpc_id
        and c.cluster_subnet_group_name = s.cluster_subnet_group_name
        and c.arn = $1,
      jsonb_array_elements(s.subnets) subnet;
  EOQ

  param "arn" {}
}

edge "aws_redshift_cluster_to_vpc_subnet_edge" {
  title = "subnet"

  sql = <<-EOQ
    select
      s.cluster_subnet_group_name as from_id,
      subnet ->> 'SubnetIdentifier' as to_id
    from
      aws_redshift_cluster as c
      left join
        aws_redshift_subnet_group as s
        on c.vpc_id = s.vpc_id
        and c.cluster_subnet_group_name = s.cluster_subnet_group_name
        and c.arn = $1,
      jsonb_array_elements(s.subnets) subnet;
  EOQ

  param "arn" {}
}

node "aws_redshift_cluster_to_vpc_node" {
  category = category.aws_vpc

  sql = <<-EOQ
    select
      v.arn as id,
      v.title as title,
      jsonb_build_object(
        'ARN', v.arn,
        'VPC ID', v.vpc_id,
        'Default', is_default::text,
        'State', state
      ) as properties
    from
      aws_redshift_cluster as c
      left join
        aws_vpc as v
        on v.vpc_id = c.vpc_id
        and c.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_redshift_cluster_subnet_to_vpc_edge" {
  title = "vpc"

  sql = <<-EOQ
    select
      subnet ->> 'SubnetIdentifier' as from_id,
      v.arn as to_id
    from
      aws_redshift_cluster as c
      left join
        aws_redshift_subnet_group as s
        on c.vpc_id = s.vpc_id
        and c.cluster_subnet_group_name = s.cluster_subnet_group_name
      left join
        aws_vpc as v
        on v.vpc_id = c.vpc_id,
      jsonb_array_elements(s.subnets) as subnet
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_redshift_cluster_vpc_security_group_to_vpc_edge" {
  title = "vpc"

  sql = <<-EOQ
    select
      sg.arn as from_id,
      v.arn as to_id
    from
      aws_redshift_cluster as c
      left join
        aws_vpc as v
        on v.vpc_id = c.vpc_id,
      jsonb_array_elements(c.vpc_security_groups) as s
      left join
        aws_vpc_security_group as sg
        on sg.group_id = s ->> 'VpcSecurityGroupId'
    where
      c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_redshift_cluster_to_vpc_security_group_node" {
  category = category.aws_vpc_security_group

  sql = <<-EOQ
    select
      sg.arn as id,
      sg.group_id as title,
      jsonb_build_object(
        'ARN', sg.arn,
        'Group ID', sg.group_id,
        'Account ID', sg.account_id,
        'Region', sg.region,
        'Status', s ->> 'Status'
      ) as properties
    from
      aws_redshift_cluster as c,
      jsonb_array_elements(vpc_security_groups) as s
      left join
        aws_vpc_security_group as sg
        on sg.group_id = s ->> 'VpcSecurityGroupId'
      where
        c.arn = $1
  EOQ

  param "arn" {}
}

edge "aws_redshift_cluster_to_vpc_security_group_edge" {
  title = "security group"

  sql = <<-EOQ
    select
      c.arn as from_id,
      sg.arn as to_id
    from
      aws_redshift_cluster as c,
      jsonb_array_elements(vpc_security_groups) as s
      left join
        aws_vpc_security_group as sg
        on sg.group_id = s ->> 'VpcSecurityGroupId'
      where
          c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_redshift_cluster_to_kms_key_node" {
  category = category.aws_kms_key

  sql = <<-EOQ
    select
      k.arn as id,
      k.title as title,
      jsonb_build_object(
        'ARN', k.arn,
        'Account ID', k.account_id,
        'Region', k.region,
        'Key Manager', k.key_manager,
        'Enabled', enabled::text
      ) as properties
    from
      aws_redshift_cluster as c
      left join
        aws_kms_key as k
        on k.arn = c.kms_key_id
        and c.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_redshift_cluster_to_kms_key_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      c.arn as from_id,
      k.arn as to_id
    from
      aws_redshift_cluster as c
      left join
        aws_kms_key as k
        on k.arn = c.kms_key_id
        and c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_redshift_cluster_to_iam_role_node" {
  category = category.aws_iam_role

  sql = <<-EOQ
    select
      r.arn as id,
      r.title as title,
      jsonb_build_object(
        'ARN', r.arn,
        'Role ID', r.role_id,
        'Account ID', r.account_id,
        'Description', r.description
      ) as properties
    from
      aws_redshift_cluster as c,
      jsonb_array_elements(iam_roles) as ir
      left join
        aws_iam_role as r
        on r.arn = ir ->> 'IamRoleArn'
      where
        c.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_redshift_cluster_to_iam_role_edge" {
  title = "assumes"

  sql = <<-EOQ
    select
      c.arn as from_id,
      r.arn as to_id
    from
      aws_redshift_cluster as c,
      jsonb_array_elements(iam_roles) as ir
      left join
        aws_iam_role as r
        on r.arn = ir ->> 'IamRoleArn'
      where
        c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_redshift_cluster_to_vpc_eip_node" {
  category = category.aws_vpc_eip

  sql = <<-EOQ
    select
      e.arn as id,
      e.title as title,
      jsonb_build_object(
        'ARN', e.arn,
        'Elastic IP', c.elastic_ip_status ->> 'ElasticIp',
        'Private IP', e.private_ip_address
      ) as properties
    from
      aws_redshift_cluster as c
      left join
        aws_vpc_eip as e
        on e.public_ip = (c.elastic_ip_status ->> 'ElasticIp')::inet
    where
      c.elastic_ip_status is not null
      and c.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_redshift_cluster_to_vpc_eip_edge" {
  title = "eip"

  sql = <<-EOQ
    select
      c.arn as from_id,
      e.arn as to_id
    from
      aws_redshift_cluster as c
      left join
        aws_vpc_eip as e
        on e.public_ip = (c.elastic_ip_status ->> 'ElasticIp')::inet
    where
      c.elastic_ip_status is not null
      and c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_redshift_cluster_to_cloudwatch_log_group_node" {
  category = category.aws_cloudwatch_log_group

  sql = <<-EOQ
    select
      g.arn as id,
      g.title as title,
      jsonb_build_object(
        'ARN', g.arn,
        'Retention days', g.retention_in_days
      ) as properties
    from
      aws_redshift_cluster as c
      left join
        aws_cloudwatch_log_group as g
        on g.title like '%' || c.title || '%'
        and c.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_redshift_cluster_to_cloudwatch_log_group_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      c.arn as from_id,
      g.arn as to_id
    from
      aws_redshift_cluster as c
      left join
        aws_cloudwatch_log_group as g
        on g.title like '%' || c.title || '%'
        and c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_redshift_cluster_to_s3_bucket_node" {
  category = category.aws_s3_bucket

  sql = <<-EOQ
    select
      bucket.arn as id,
      bucket.name as title,
      jsonb_build_object(
        'ARN', bucket.arn,
        'Public', bucket_policy_is_public::text
      ) as properties
    from
      aws_redshift_cluster as c
      left join
        aws_s3_bucket as bucket
        on bucket.name = c.logging_status ->> 'BucketName'
        and c.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_redshift_cluster_to_s3_bucket_edge" {
  title = "logs to"

  sql = <<-EOQ
    select
      c.arn as from_id,
      bucket.arn as to_id
    from
      aws_redshift_cluster as c
      left join
        aws_s3_bucket as bucket
        on bucket.name = c.logging_status ->> 'BucketName'
        and c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_redshift_cluster_to_redshift_parameter_group_node" {
  category = category.aws_redshift_parameter_group

  sql = <<-EOQ
    select
      g.title as id,
      g.title as title,
      jsonb_build_object(
        'ARN', g.title,
        'Description', g.description,
        'Family', g.family
      ) as properties
    from
      aws_redshift_cluster as c,
      jsonb_array_elements(cluster_parameter_groups) as p
      left join
        aws_redshift_parameter_group as g
        on g.name = p ->> 'ParameterGroupName'
      where
        c.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_redshift_cluster_to_redshift_parameter_group_edge" {
  title = "configured"

  sql = <<-EOQ
    select
      c.arn as from_id,
      g.title as to_id
    from
      aws_redshift_cluster as c,
      jsonb_array_elements(cluster_parameter_groups) as p
      left join
        aws_redshift_parameter_group as g
        on g.name = p ->> 'ParameterGroupName'
      where
        c.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_redshift_cluster_from_redshift_snapshot_node" {
  category = category.aws_redshift_snapshot

  sql = <<-EOQ
    select
      snapshot.snapshot_identifier as id,
      snapshot.snapshot_identifier as title,
      jsonb_build_object(
        'Status', snapshot.status,
        'Creation Time', snapshot.snapshot_create_time,
        'Encrypted', snapshot.encrypted::text,
        'Size (MB)', snapshot.total_backup_size_in_mega_bytes
      ) as properties
    from
      aws_redshift_cluster as c
      left join
        aws_redshift_snapshot as snapshot
        on snapshot.cluster_identifier = c.cluster_identifier
        and snapshot.region = c.region
        and c.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_redshift_cluster_from_redshift_snapshot_edge" {
  title = "snapshot"

  sql = <<-EOQ
    select
      snapshot.snapshot_identifier as from_id,
      c.arn as to_id
    from
      aws_redshift_cluster as c
      left join
        aws_redshift_snapshot as snapshot
        on snapshot.cluster_identifier = c.cluster_identifier
        and snapshot.region = c.region
        and c.arn = $1;
  EOQ

  param "arn" {}
}
