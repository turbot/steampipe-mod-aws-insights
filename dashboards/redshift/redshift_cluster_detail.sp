dashboard "redshift_cluster_detail" {

  title         = "AWS Redshift Cluster Detail"
  documentation = file("./dashboards/redshift/docs/redshift_cluster_detail.md")

  tags = merge(local.redshift_common_tags, {
    type = "Detail"
  })

  input "cluster_arn" {
    title = "Select a Cluster:"
    query = query.redshift_cluster_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.redshift_cluster_status
      args = {
        arn = self.input.cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.redshift_cluster_version
      args = {
        arn = self.input.cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.redshift_cluster_node_type
      args = {
        arn = self.input.cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.redshift_cluster_number_of
      args = {
        arn = self.input.cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.redshift_cluster_public
      args = {
        arn = self.input.cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.redshift_cluster_encryption
      args = {
        arn = self.input.cluster_arn.value
      }
    }

  }

  # container {

  #   graph {
  #     title     = "Relationships"
  #     type      = "graph"
  #     direction = "TD"

  #     with "cloudwatch_log_groups" {
  #       sql = <<-EOQ
  #         select
  #           g.arn as log_group_arn
  #         from
  #           aws_redshift_cluster as c,
  #           aws_cloudwatch_log_group as g
  #         where
  #           g.title like '%' || c.title || '%'
  #           and c.arn = $1;
  #       EOQ

  #       args = [self.input.cluster_arn.value]
  #     }

  #     with "iam_roles" {
  #       sql = <<-EOQ
  #         select
  #           r ->> 'IamRoleArn' as role_arn
  #         from
  #           aws_redshift_cluster,
  #           jsonb_array_elements(iam_roles) as r
  #         where
  #           arn = $1;
  #       EOQ

  #       args = [self.input.cluster_arn.value]
  #     }

  #     with "kms_keys" {
  #       sql = <<-EOQ
  #         select
  #           kms_key_id as key_arn
  #         from
  #           aws_redshift_cluster
  #         where
  #           kms_key_id is not null
  #           and arn = $1;
  #       EOQ

  #       args = [self.input.cluster_arn.value]
  #     }

  #     with "redshift_snapshots" {
  #       sql = <<-EOQ
  #         select
  #           s.akas::text as snapshot_arn
  #         from
  #           aws_redshift_snapshot as s,
  #           aws_redshift_cluster as c
  #         where
  #           s.cluster_identifier = c.cluster_identifier
  #           and c.arn = $1;
  #       EOQ

  #       args = [self.input.cluster_arn.value]
  #     }

  #     with "s3_buckets" {
  #       sql = <<-EOQ
  #         select
  #           b.arn as bucket_arn
  #         from
  #           aws_redshift_cluster as c,
  #           aws_s3_bucket as b
  #         where
  #           b.name = c.logging_status ->> 'BucketName'
  #           and c.arn = $1;
  #       EOQ

  #       args = [self.input.cluster_arn.value]
  #     }

  #     with "vpc_eips" {
  #       sql = <<-EOQ
  #         select
  #           e.arn as eip_arn
  #         from
  #           aws_redshift_cluster as c,
  #           aws_vpc_eip as e
  #         where
  #           c.elastic_ip_status is not null
  #           and e.public_ip = (c.elastic_ip_status ->> 'ElasticIp')::inet
  #           and c.arn = $1;
  #       EOQ

  #       args = [self.input.cluster_arn.value]
  #     }

  #     with "vpc_security_groups" {
  #       sql = <<-EOQ
  #         select
  #           s ->> 'VpcSecurityGroupId' as security_group_id
  #         from
  #           aws_redshift_cluster,
  #           jsonb_array_elements(vpc_security_groups) as s
  #         where
  #           arn = $1;
  #       EOQ

  #       args = [self.input.cluster_arn.value]
  #     }

  #     with "vpc_subnets" {
  #       sql = <<-EOQ
  #         select
  #           subnet ->> 'SubnetIdentifier' as subnet_id
  #         from
  #           aws_redshift_subnet_group as s
  #           cross join jsonb_array_elements(s.subnets) subnet
  #         join
  #           aws_redshift_cluster as c
  #           on c.cluster_subnet_group_name = s.cluster_subnet_group_name
  #           and c.region = s.region
  #           and c.arn = $1;
  #       EOQ

  #       args = [self.input.cluster_arn.value]
  #     }

  #     with "vpc_vpcs" {
  #       sql = <<-EOQ
  #         select
  #           vpc_id as vpc_id
  #         from
  #           aws_redshift_cluster
  #         where
  #           arn = $1;
  #       EOQ

  #       args = [self.input.cluster_arn.value]
  #     }

  #     nodes = [
  #       node.cloudwatch_log_group,
  #       node.iam_role,
  #       node.kms_key,
  #       node.redshift_cluster,
  #       node.redshift_parameter_group,
  #       node.redshift_snapshot,
  #       node.redshift_subnet_group,
  #       node.s3_bucket,
  #       node.vpc_eip,
  #       node.vpc_security_group,
  #       node.vpc_subnet,
  #       node.vpc_vpc
  #     ]

  #     edges = [
  #       edge.redshift_cluster_subnet_group_to_vpc_subnet,
  #       edge.redshift_cluster_to_cloudwatch_log_group,
  #       edge.redshift_cluster_to_iam_role,
  #       edge.redshift_cluster_to_kms_key,
  #       edge.redshift_cluster_to_redshift_parameter_group,
  #       edge.redshift_cluster_to_redshift_snapshot,
  #       edge.redshift_cluster_to_s3_bucket,
  #       edge.redshift_cluster_to_vpc_eip,
  #       edge.redshift_cluster_to_vpc_security_group,
  #       edge.vpc_security_group_to_redshift_subnet_group,
  #       edge.vpc_subnet_to_vpc_vpc
  #     ]

  #     args = {
  #       cloudwatch_log_group_arns = with.cloudwatch_log_groups.rows[*].log_group_arn
  #       iam_role_arns             = with.iam_roles.rows[*].role_arn
  #       kms_key_arns              = with.kms_keys.rows[*].key_arn
  #       redshift_cluster_arns     = [self.input.cluster_arn.value]
  #       redshift_snapshot_arns    = with.redshift_snapshots.rows[*].snapshot_arn
  #       s3_bucket_arns            = with.s3_buckets.rows[*].bucket_arn
  #       vpc_eip_arns              = with.vpc_eips.rows[*].eip_arn
  #       vpc_security_group_ids    = with.vpc_security_groups.rows[*].security_group_id
  #       vpc_subnet_ids            = with.vpc_subnets.rows[*].subnet_id
  #       vpc_vpc_ids               = with.vpc_vpcs.rows[*].vpc_id
  #     }
  #   }
  # }

  container {

    container {

      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.redshift_cluster_overview
        args = {
          arn = self.input.cluster_arn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.redshift_cluster_tags
        args = {
          arn = self.input.cluster_arn.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Cluster Nodes"
        query = query.redshift_cluster_node_details
        args = {
          arn = self.input.cluster_arn.value
        }
      }

      table {
        title = "Cluster Parameter Groups"
        query = query.redshift_cluster_parameter_groups
        args = {
          arn = self.input.cluster_arn.value
        }
      }

    }

    table {

      title = "Logging"
      query = query.redshift_cluster_logging
      args = {
        arn = self.input.cluster_arn.value
      }
    }

    table {
      title = "Scheduled Actions"
      query = query.redshift_cluster_scheduled_actions
      args = {
        arn = self.input.cluster_arn.value
      }
    }

  }

}

query "redshift_cluster_input" {
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

query "redshift_cluster_status" {
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

query "redshift_cluster_version" {
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

query "redshift_cluster_node_type" {
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

query "redshift_cluster_number_of" {
  sql = <<-EOQ
    select
      'Number Of Nodes' as label,
      number_of_nodes as value
    from
      aws_redshift_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "redshift_cluster_encryption" {
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

query "redshift_cluster_public" {
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

query "redshift_cluster_node_details" {
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

query "redshift_cluster_parameter_groups" {
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

query "redshift_cluster_scheduled_actions" {
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

query "redshift_cluster_logging" {
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

query "redshift_cluster_security_groups" {
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

query "redshift_cluster_overview" {
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

query "redshift_cluster_tags" {
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