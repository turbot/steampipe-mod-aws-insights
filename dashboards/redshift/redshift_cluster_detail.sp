dashboard "aws_redshift_cluster_detail" {

  title         = "AWS Redshift Cluster Detail"
  documentation = file("./dashboards/redshift/docs/redshift_cluster_detail.md")

  tags = merge(local.redshift_common_tags, {
    type = "Detail"
  })

  input "cluster_arn" {
    title = "Select a Cluster:"
    sql   = query.aws_redshift_cluster_input.sql
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

  container {

    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_redshift_cluster_relationship_graph
      args = {
        arn = self.input.cluster_arn.value
      }
      category "aws_redshift_cluster" {}
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

query "aws_redshift_cluster_relationship_graph" {
  sql = <<-EOQ
    with cluster as
      (
        select
          *
        from
          aws_redshift_cluster
        where
          arn = $1
      )

    -- cluster (node)
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_redshift_cluster' as category,
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
      cluster

    -- Subnet group (node)
    union all
    select
      null as from_id,
      null as to_id,
      s.cluster_subnet_group_name as id,
      s.cluster_subnet_group_name as title,
      'aws_redshift_subnet_group' as category,
      jsonb_build_object(
        'AKAS', s.akas,
        'Account ID', s.account_id,
        'Region', s.region,
        'Description', s.description,
        'Status', s.subnet_group_status,
        'Vpc ID', s.vpc_id
      ) as properties
    from
      cluster as c
      left join aws_redshift_subnet_group as s
        on c.vpc_id = s.vpc_id
        and c.cluster_subnet_group_name = s.cluster_subnet_group_name

    -- Subnet group (edge)
    union all
    select
      c.arn as from_id,
      s.cluster_subnet_group_name as to_id,
      null as id,
      'subnet group' as title,
      'redshift_cluster_to_redshift_subnet_group' as category,
      jsonb_build_object(
        'AKAS', s.akas,
        'Account ID', s.account_id,
        'Region', s.region,
        'Description', s.description,
        'Status', s.subnet_group_status,
        'Vpc ID', s.vpc_id
      ) as properties
    from
      cluster as c
      left join aws_redshift_subnet_group as s
        on c.vpc_id = s.vpc_id
        and c.cluster_subnet_group_name = s.cluster_subnet_group_name

    -- VPC subnets (node)
    union all
    select
      null as from_id,
      null as to_id,
      subnet ->>  'SubnetIdentifier' as id,
      subnet ->>  'SubnetIdentifier' as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'Subnet ID', subnet ->>  'SubnetIdentifier',
        'Subnet Availability Zone', subnet -> 'SubnetAvailabilityZone' ->> 'Name',
        'Account ID', s.account_id,
        'Region', s.region,
        'Subnet Status', subnet ->> 'SubnetStatus',
        'Vpc ID', s.vpc_id
      ) as properties
    from
      cluster as c
      left join aws_redshift_subnet_group as s
        on c.vpc_id = s.vpc_id
        and c.cluster_subnet_group_name = s.cluster_subnet_group_name,
      jsonb_array_elements(s.subnets) subnet

    -- VPC subnets (edge)
    union all
    select
      s.cluster_subnet_group_name as from_id,
      subnet ->> 'SubnetIdentifier' as to_id,
      null as id,
      'subnet' as title,
      'redshift_subnet_group_to_vpc_subnet' as category,
      jsonb_build_object(
        'AKAS', s.akas,
        'Account ID', s.account_id,
        'Region', s.region,
        'Description', s.description,
        'Status', s.subnet_group_status,
        'Vpc ID', s.vpc_id
      ) as properties
    from
      cluster as c
      left join aws_redshift_subnet_group as s
        on c.vpc_id = s.vpc_id
        and c.cluster_subnet_group_name = s.cluster_subnet_group_name,
      jsonb_array_elements(s.subnets) as subnet

    -- VPC (node)
    union all
    select
      null as from_id,
      null as to_id,
      v.arn as id,
      v.title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'VPC ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region,
        'Default', is_default::text,
        'State', state
      ) as properties
    from
      cluster as c
      left join aws_vpc as v on v.vpc_id = c.vpc_id

    -- subnet - VPC (edge)
    union all
    select
      subnet ->> 'SubnetIdentifier' as from_id,
      v.arn as to_id,
      null as id,
      'vpc' as title,
      'vpc_subnet_to_vpc' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      cluster as c
      left join aws_redshift_subnet_group as s
        on c.vpc_id = s.vpc_id
        and c.cluster_subnet_group_name = s.cluster_subnet_group_name
      left join aws_vpc as v on v.vpc_id = c.vpc_id,
      jsonb_array_elements(s.subnets) as subnet


    -- security group - VPC (edge)
    union all
    select
      sg.arn as from_id,
      v.arn as to_id,
      null as id,
      'vpc' as title,
      'vpc_security_group_to_vpc' as category,
      jsonb_build_object(
        'ARN', v.arn,
        'ID', v.vpc_id,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      cluster as c
      left join aws_vpc as v on v.vpc_id = c.vpc_id,
      jsonb_array_elements(c.vpc_security_groups) as s
      left join aws_vpc_security_group as sg on sg.group_id = s ->> 'VpcSecurityGroupId'


    -- VPC security groups (node)
    union all
    select
      null as from_id,
      null as to_id,
      sg.arn as id,
      sg.group_id as title,
      'aws_vpc_security_group' as category,
      jsonb_build_object(
        'ARN', sg.arn,
        'Group ID', sg.group_id,
        'Account ID', sg.account_id,
        'Region', sg.region,
        'Status', s ->> 'Status'
      ) as properties
    from
      cluster as c,
      jsonb_array_elements(vpc_security_groups) as s
      left join aws_vpc_security_group as sg on sg.group_id = s ->> 'VpcSecurityGroupId'

    -- VPC security group (edge)
    union all
    select
      c.arn as from_id,
      sg.arn as to_id,
      null as id,
      'security group' as title,
      'redshift_cluster_to_vpc_security_group' as category,
      jsonb_build_object(
        'ARN', sg.arn,
        'ID', sg.group_id,
        'Account ID', sg.account_id,
        'Region', sg.region
      ) as properties
    from
      cluster as c,
      jsonb_array_elements(vpc_security_groups) as s
      left join aws_vpc_security_group as sg on sg.group_id = s ->> 'VpcSecurityGroupId'

    -- KMS keys (node)
    union all
    select
      null as from_id,
      null as to_id,
      k.arn as id,
      k.title as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'Account ID', k.account_id,
        'Region', k.region,
        'Key Manager', k.key_manager,
        'Enabled', enabled::text
      ) as properties
    from
      cluster as c
      left join aws_kms_key as k on k.arn = c.kms_key_id

    -- KMS keys (edge)
    union all
    select
      c.arn as from_id,
      k.arn as to_id,
      null as id,
      'encrypted With' as title,
      'redshift_cluster_to_kms_key' as category,
      jsonb_build_object(
        'ARN', k.arn,
        'Account ID', k.account_id,
        'Region', k.region
      ) as properties
    from
      cluster as c
      left join aws_kms_key as k on k.arn = c.kms_key_id

    -- IAM Roles (node)
    union all
    select
      null as from_id,
      null as to_id,
      r.arn as id,
      r.title as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'ARN', r.arn,
        'Role ID', r.role_id,
        'Account ID', r.account_id,
        'Description', r.description
      ) as properties
    from
      cluster as c,
      jsonb_array_elements(iam_roles) as ir
      left join aws_iam_role as r on r.arn = ir ->> 'IamRoleArn'

    -- IAM Roles (edge)
    union all
    select
      c.arn as from_id,
      r.arn as to_id,
      null as id,
      'assumes' as title,
      'redshift_cluster_to_iam_role' as category,
      jsonb_build_object(
        'ARN', r.arn,
        'Role ID', r.role_id,
        'Account ID', r.account_id
      ) as properties
    from
      cluster as c,
      jsonb_array_elements(iam_roles) as ir
      left join aws_iam_role as r on r.arn = ir ->> 'IamRoleArn'

    -- Elastic IP (node)
    union all
    select
      null as from_id,
      null as to_id,
      e.arn as id,
      e.title as title,
      'aws_vpc_eip' as category,
      jsonb_build_object(
        'ARN', e.arn,
        'Account ID', e.account_id,
        'Region', e.region,
        'Elastic IP', c.elastic_ip_status ->> 'ElasticIp',
        'Private IP', e.private_ip_address
      ) as properties
    from
      cluster as c
      left join aws_vpc_eip as e on e.public_ip = (c.elastic_ip_status ->> 'ElasticIp')::inet
    where
      c.elastic_ip_status is not null

    -- Elastic IP (edge)
    union all
    select
      c.arn as from_id,
      e.arn as to_id,
      null as id,
      'eip' as title,
      'redshift_cluster_to_vpc_eip' as category,
      jsonb_build_object(
        'ARN', e.arn,
        'Account ID', e.account_id,
        'Region', e.region
      ) as properties
    from
      cluster as c
      left join aws_vpc_eip as e on e.public_ip = (c.elastic_ip_status ->> 'ElasticIp')::inet
    where
      c.elastic_ip_status is not null

    -- CloudWatch log group (node)
    union all
    select
      null as from_id,
      null as to_id,
      g.arn as id,
      g.title as title,
      'aws_cloudwatch_log_group' as category,
      jsonb_build_object(
        'ARN', g.arn,
        'Account ID', g.account_id,
        'Region', g.region,
        'Retention days', g.retention_in_days
      ) as properties
    from
      cluster as c
      left join aws_cloudwatch_log_group as g on g.title like '%' || c.title || '%'

    -- CloudWatch log group (edge)
    union all
    select
      c.arn as from_id,
      g.arn as to_id,
      null as id,
      'Logs to' as title,
      'redshift_cluster_to_cloudwatch_log_group' as category,
      jsonb_build_object(
        'ARN', g.arn,
        'Account ID', g.account_id,
        'Region', g.region
      ) as properties
    from
      cluster as c
      left join aws_cloudwatch_log_group as g on g.title like '%' || c.title || '%'

    -- S3 buckets (node)
    union all
    select
      null as from_id,
      null as to_id,
      bucket.arn as id,
      bucket.name as title,
      'aws_s3_bucket' as category,
      jsonb_build_object(
        'ARN', bucket.arn,
        'Account ID', bucket.account_id,
        'Region', bucket.region,
        'Public', bucket_policy_is_public::text
      ) as properties
    from
      cluster as c
      left join aws_s3_bucket as bucket on bucket.name = c.logging_status ->> 'BucketName'

    -- S3 buckets (edge)
    union all
    select
      c.arn as from_id,
      bucket.arn as to_id,
      null as id,
      'Logs to' as title,
      'redshift_cluster_to_s3_bucket' as category,
      jsonb_build_object(
        'ARN', bucket.arn,
        'Account ID', bucket.account_id,
        'Region', bucket.region
      ) as properties
    from
      cluster as c
      left join aws_s3_bucket as bucket on bucket.name = c.logging_status ->> 'BucketName'

    -- Redshift parameter groups (node)
    union all
    select
      null as from_id,
      null as to_id,
      g.title as id,
      g.title as title,
      'aws_redshift_parameter_group' as category,
      jsonb_build_object(
        'ARN', g.title,
        'Account ID', g.account_id,
        'Region', g.region,
        'Description', g.description
      ) as properties
    from
      cluster as c,
      jsonb_array_elements(cluster_parameter_groups) as p
      left join aws_redshift_parameter_group as g on g.name = p ->> 'ParameterGroupName'

    -- Redshift parameter groups (edge)
    union all
    select
      c.arn as from_id,
      g.title as to_id,
      null as id,
      'parameter group' as title,
      'redshift_cluster_to_redshift_parameter_group' as category,
      jsonb_build_object(
        'ARN', g.title,
        'Account ID', g.account_id,
        'Region', g.region
      ) as properties
    from
      cluster as c,
      jsonb_array_elements(cluster_parameter_groups) as p
      left join aws_redshift_parameter_group as g on g.name = p ->> 'ParameterGroupName'

    -- Redshift cluster snapshots (node)
    union all
    select
      null as from_id,
      null as to_id,
      snapshot.snapshot_identifier as id,
      snapshot.snapshot_identifier as title,
      'aws_redshift_snapshot' as category,
      jsonb_build_object(
        'Account ID', snapshot.account_id,
        'Region', snapshot.region,
        'Status', snapshot.status,
        'Creation Time', snapshot.snapshot_create_time,
        'Encrypted', snapshot.encrypted::text,
        'Size (MB)', snapshot.total_backup_size_in_mega_bytes
      ) as properties
    from
      cluster as c
      left join aws_redshift_snapshot as snapshot
        on snapshot.cluster_identifier = c.cluster_identifier
        and snapshot.region = c.region

    -- Redshift cluster snapshots (edge)
    union all
    select
      snapshot.snapshot_identifier as from_id,
      c.arn as to_id,
      null as id,
      'snapshot' as title,
      'redshift_snapshot_to_redshift_cluster' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', c.account_id,
        'Region', c.region,
        'Cluster Status', c.cluster_status,
        'Cluster Version', c.cluster_version,
        'Public', c.publicly_accessible::text,
        'Encrypted', c.encrypted::text
      ) as properties
    from
      cluster as c
      left join aws_redshift_snapshot as snapshot
        on snapshot.cluster_identifier = c.cluster_identifier
        and snapshot.region = c.region

  EOQ

  param "arn" {}
}
