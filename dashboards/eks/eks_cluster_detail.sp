dashboard "eks_cluster_detail" {
  title         = "AWS EKS Cluster Detail"
  documentation = file("./dashboards/eks/docs/eks_cluster_detail.md")

  tags = merge(local.eks_common_tags, {
    type = "Detail"
  })

  input "eks_cluster_arn" {
    title = "Select a cluster:"
    query = query.eks_cluster_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.eks_cluster_status
      args  = [self.input.eks_cluster_arn.value]
    }

    card {
      width = 2
      query = query.eks_cluster_kubernetes_version
      args  = [self.input.eks_cluster_arn.value]
    }

    card {
      width = 2
      query = query.eks_cluster_secrets_encryption
      args  = [self.input.eks_cluster_arn.value]
    }

    card {
      width = 2
      query = query.eks_cluster_endpoint_restrict_public_access
      args  = [self.input.eks_cluster_arn.value]
    }

    card {
      width = 2
      query = query.eks_cluster_control_plane_audit_logging
      args  = [self.input.eks_cluster_arn.value]
    }

  }

  with "eks_addons_for_eks_cluster" {
    query = query.eks_addons_for_eks_cluster
    args  = [self.input.eks_cluster_arn.value]
  }

  with "eks_fargate_profiles_for_eks_cluster" {
    query = query.eks_fargate_profiles_for_eks_cluster
    args  = [self.input.eks_cluster_arn.value]
  }

  with "eks_identity_providers_for_eks_cluster" {
    query = query.eks_identity_providers_for_eks_cluster
    args  = [self.input.eks_cluster_arn.value]
  }

  with "eks_node_groups_for_eks_cluster" {
    query = query.eks_node_groups_for_eks_cluster
    args  = [self.input.eks_cluster_arn.value]
  }

  with "iam_roles_for_eks_cluster" {
    query = query.iam_roles_for_eks_cluster
    args  = [self.input.eks_cluster_arn.value]
  }

  with "kms_keys_for_eks_cluster" {
    query = query.kms_keys_for_eks_cluster
    args  = [self.input.eks_cluster_arn.value]
  }

  with "vpc_security_groups_for_eks_cluster" {
    query = query.vpc_security_groups_for_eks_cluster
    args  = [self.input.eks_cluster_arn.value]
  }

  with "vpc_subnets_for_eks_cluster" {
    query = query.vpc_subnets_for_eks_cluster
    args  = [self.input.eks_cluster_arn.value]
  }

  with "vpc_vpcs_for_eks_cluster" {
    query = query.vpc_vpcs_for_eks_cluster
    args  = [self.input.eks_cluster_arn.value]
  }

  container {
    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.eks_addon
        args = {
          eks_addon_arns = with.eks_addons_for_eks_cluster.rows[*].eks_addon_arn
        }
      }

      node {
        base = node.eks_cluster
        args = {
          eks_cluster_arns = [self.input.eks_cluster_arn.value]
        }
      }

      node {
        base = node.eks_fargate_profile
        args = {
          eks_fargate_profile_arns = with.eks_fargate_profiles_for_eks_cluster.rows[*].eks_fargate_profile_arn
        }
      }

      node {
        base = node.eks_identity_provider_config
        args = {
          eks_identity_provider_arns = with.eks_identity_providers_for_eks_cluster.rows[*].eks_identity_provider_arn
        }
      }

      node {
        base = node.eks_node_group
        args = {
          eks_node_group_arns = with.eks_node_groups_for_eks_cluster.rows[*].eks_node_group_arn
        }
      }

      node {
        base = node.iam_role
        args = {
          iam_role_arns = with.iam_roles_for_eks_cluster.rows[*].iam_role_arn
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_arns = with.kms_keys_for_eks_cluster.rows[*].kms_key_arn
        }
      }

      node {
        base = node.vpc_security_group
        args = {
          vpc_security_group_ids = with.vpc_security_groups_for_eks_cluster.rows[*].vpc_security_group_id
        }
      }

      node {
        base = node.vpc_subnet
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_eks_cluster.rows[*].vpc_subnet_id
        }
      }

      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_eks_cluster.rows[*].vpc_vpc_id
        }
      }

      edge {
        base = edge.eks_cluster_to_eks_addon
        args = {
          eks_addon_arns = with.eks_addons_for_eks_cluster.rows[*].eks_addon_arn
        }
      }

      edge {
        base = edge.eks_cluster_to_eks_fargate_profile
        args = {
          eks_fargate_profile_arns = with.eks_fargate_profiles_for_eks_cluster.rows[*].eks_fargate_profile_arn
        }
      }

      edge {
        base = edge.eks_cluster_to_eks_identity_provider_config
        args = {
          eks_identity_provider_arns = with.eks_identity_providers_for_eks_cluster.rows[*].eks_identity_provider_arn
        }
      }

      edge {
        base = edge.eks_cluster_to_eks_node_group
        args = {
          eks_node_group_arns = with.eks_node_groups_for_eks_cluster.rows[*].eks_node_group_arn
        }
      }

      edge {
        base = edge.eks_cluster_to_iam_role
        args = {
          iam_role_arns = with.iam_roles_for_eks_cluster.rows[*].iam_role_arn
        }
      }

      edge {
        base = edge.eks_cluster_to_kms_key
        args = {
          kms_key_arns = with.kms_keys_for_eks_cluster.rows[*].kms_key_arn
        }
      }

      edge {
        base = edge.eks_cluster_to_vpc_security_group
        args = {
          vpc_security_group_ids = with.vpc_security_groups_for_eks_cluster.rows[*].vpc_security_group_id
        }
      }

      edge {
        base = edge.eks_cluster_to_vpc_subnet
        args = {
          eks_cluster_arns = [self.input.eks_cluster_arn.value]
        }
      }

      edge {
        base = edge.vpc_subnet_to_vpc_vpc
        args = {
          vpc_subnet_ids = with.vpc_subnets_for_eks_cluster.rows[*].vpc_subnet_id
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
        query = query.eks_cluster_overview
        args  = [self.input.eks_cluster_arn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.eks_cluster_tags
        args  = [self.input.eks_cluster_arn.value]
      }
    }
    container {
      width = 6

      table {
        title = "Resources VPC Config"
        query = query.eks_cluster_resources_vpc_config
        args  = [self.input.eks_cluster_arn.value]
      }

      table {
        title = "Control Plane Logging"
        query = query.eks_cluster_logging
        args  = [self.input.eks_cluster_arn.value]
      }
    }

  }

  container {

    table {
      title = "Node Groups"
      query = query.eks_cluster_node_group
      args  = [self.input.eks_cluster_arn.value]
    }

  }
}

# Input queries

query "eks_cluster_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_eks_cluster
    order by
      title;
  EOQ
}

# With queries

query "eks_addons_for_eks_cluster" {
  sql = <<-EOQ
    select
      arn as eks_addon_arn
    from
      aws_eks_addon
    where
      cluster_name in
      (
        select
          name
        from
          aws_eks_cluster
        where
          arn = $1
          and account_id = split_part($1, ':', 5)
          and region = split_part($1, ':', 4)
      )
  EOQ
}

query "eks_fargate_profiles_for_eks_cluster" {
  sql = <<-EOQ
    select
      p.fargate_profile_arn as eks_fargate_profile_arn
    from
    aws_eks_cluster as c
    left join aws_eks_fargate_profile as p on p.cluster_name = c.name
    where
      p.region = c.region
      and c.arn = $1
      and c.account_id = split_part($1, ':', 5)
      and c.region = split_part($1, ':', 4);
  EOQ
}

query "eks_identity_providers_for_eks_cluster" {
  sql = <<-EOQ
    select
      arn as eks_identity_provider_arn
    from
      aws_eks_identity_provider_config
    where
      cluster_name in
      (
        select
          name
        from
          aws_eks_cluster
        where
          arn = $1
          and account_id = split_part($1, ':', 5)
          and region = split_part($1, ':', 4)
      )
  EOQ
}

query "eks_node_groups_for_eks_cluster" {
  sql = <<-EOQ
    select
      arn as eks_node_group_arn
    from
      aws_eks_node_group
    where
      cluster_name in
      (
        select
          name
        from
          aws_eks_cluster
        where
          arn = $1
          and account_id = split_part($1, ':', 5)
          and region = split_part($1, ':', 4)
      )
  EOQ
}

query "iam_roles_for_eks_cluster" {
  sql = <<-EOQ
    select
      role_arn as iam_role_arn
    from
      aws_eks_cluster as c
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "kms_keys_for_eks_cluster" {
  sql = <<-EOQ
    select
      e -> 'Provider' ->> 'KeyArn' as kms_key_arn
    from
      aws_eks_cluster,
      jsonb_array_elements(encryption_config) as e
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "vpc_security_groups_for_eks_cluster" {
  sql = <<-EOQ
    select
      group_id as vpc_security_group_id
    from
      aws_vpc_security_group
    where
      group_id in
      (
        select
          s
        from
          aws_eks_cluster,
          jsonb_array_elements_text(resources_vpc_config -> 'SecurityGroupIds') as s
        where
          arn = $1
          and account_id = split_part($1, ':', 5)
          and region = split_part($1, ':', 4)
      )
  EOQ
}

query "vpc_subnets_for_eks_cluster" {
  sql = <<-EOQ
    select
      subnet_id as vpc_subnet_id
    from
      aws_vpc_subnet
    where
      subnet_id in
      (
        select
          s
        from
          aws_eks_cluster,
          jsonb_array_elements_text(resources_vpc_config -> 'SubnetIds') as s
        where
          arn = $1
          and account_id = split_part($1, ':', 5)
          and region = split_part($1, ':', 4)
      )
  EOQ
}

query "vpc_vpcs_for_eks_cluster" {
  sql = <<-EOQ
    select
      resources_vpc_config ->> 'VpcId' as vpc_vpc_id
    from
      aws_eks_cluster
    where
      resources_vpc_config ->> 'VpcId' is not null
      and arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

# Card queries

query "eks_cluster_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(status) as value
    from
      aws_eks_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "eks_cluster_kubernetes_version" {
  sql = <<-EOQ
    select
      'Version' as label,
      version as value
    from
      aws_eks_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "eks_cluster_secrets_encryption" {
  sql = <<-EOQ
    select
      'Secrets Encryption' as label,
      case when encryption_config is null then 'Disabled' else 'Enabled' end as value,
      case when encryption_config is null then 'alert' else 'ok' end as type
    from
      aws_eks_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "eks_cluster_endpoint_restrict_public_access" {
  sql = <<-EOQ
    select
      'Endpoint Public Access' as label,
      case when resources_vpc_config ->> 'EndpointPublicAccess' = 'true' then 'Enabled' else 'Disabled' end as value,
      case when resources_vpc_config ->> 'EndpointPublicAccess' = 'true' then 'alert' else 'ok' end as type
    from
      aws_eks_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "eks_cluster_control_plane_audit_logging" {
  sql = <<-EOQ
    select
      'Control Plane Audit Logging' as label,
      case when l ->> 'Enabled'::text = 'true' then 'Enabled' else 'Disabled' end as value,
      case when l ->> 'Enabled'::text = 'true' then 'ok' else 'alert' end as type
    from
      aws_eks_cluster,
      jsonb_array_elements(logging -> 'ClusterLogging') as l,
      jsonb_array_elements_text(l -> 'Types') as t
    where
      t = 'audit'
      and arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

# Other detail page queries

query "eks_cluster_overview" {
  sql = <<-EOQ
    select
      title as "Title",
      created_at as "Created At",
      endpoint as "Endpoint",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_eks_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "eks_cluster_tags" {
  sql = <<-EOQ
    with jsondata as (
    select
      tags::json as tags
    from
      aws_eks_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4)
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags);
    EOQ
}

query "eks_cluster_logging" {
  sql = <<-EOQ
    select
      t as "Type",
      l ->> 'Enabled'::text as "Enabled"
    from
      aws_eks_cluster,
      jsonb_array_elements(logging -> 'ClusterLogging') as l,
      jsonb_array_elements_text(l -> 'Types') as t
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "eks_cluster_resources_vpc_config" {
  sql = <<-EOQ
    select
      resources_vpc_config ->> 'ClusterSecurityGroupId' as "Cluster Security Group ID",
      resources_vpc_config ->> 'EndpointPrivateAccess' as "Endpoint Private Access",
      resources_vpc_config -> 'PublicAccessCidrs' as "Public Access CIDRs",
      resources_vpc_config -> 'SecurityGroupIds' as "Security Group IDs",
      resources_vpc_config -> 'SubnetIds' as "Subnet IDs",
      resources_vpc_config ->> 'VpcId' as "VPC ID"
    from
      aws_eks_cluster
    where
      arn = $1
      and account_id = split_part($1, ':', 5)
      and region = split_part($1, ':', 4);
  EOQ
}

query "eks_cluster_node_group" {
  sql = <<-EOQ
    select
      g.nodegroup_name as "Name",
      g.created_at as "Created At",
      g.status as "Status",
      g.ami_type as "AMI Type",
      g.capacity_type as "Capacity Type",
      g.disk_size as "Disk Size",
      g.health as "Health",
      g.instance_types as "Instance Types",
      g.launch_template as "Launch Template"
    from
      aws_eks_node_group as g,
      aws_eks_cluster as c
    where
      g.cluster_name = c.name
      and c.arn = $1
      and c.account_id = split_part($1, ':', 5)
      and c.region = split_part($1, ':', 4);
  EOQ
}
