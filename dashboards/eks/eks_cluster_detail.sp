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
      args = {
        arn = self.input.eks_cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.eks_cluster_kubernetes_version
      args = {
        arn = self.input.eks_cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.eks_cluster_secrets_encryption
      args = {
        arn = self.input.eks_cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.eks_cluster_endpoint_restrict_public_access
      args = {
        arn = self.input.eks_cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.eks_cluster_control_plane_audit_logging
      args = {
        arn = self.input.eks_cluster_arn.value
      }
    }

  }

  # container {
  #   graph {
  #     title     = "Relationships"
  #     type      = "graph"
  #     direction = "TD"

  #     with "eks_addons" {
  #       sql = <<-EOQ
  #         select
  #           arn as eks_addon_arn
  #         from
  #           aws_eks_addon
  #         where
  #           cluster_name in
  #           (
  #             select
  #               name
  #             from
  #               aws_eks_cluster
  #             where
  #               arn = $1
  #           )
  #       EOQ

  #       args = [self.input.eks_cluster_arn.value]
  #     }

  #     with "eks_fargate_profiles" {
  #       sql = <<-EOQ
  #         select
  #           p.fargate_profile_arn as eks_fargate_profile_arn
  #         from
  #         aws_eks_cluster as c
  #         left join aws_eks_fargate_profile as p on p.cluster_name = c.name
  #         where
  #           p.region = c.region
  #           and c.arn = $1;
  #       EOQ

  #       args = [self.input.eks_cluster_arn.value]
  #     }

  #     with "eks_identity_providers" {
  #       sql = <<-EOQ
  #         select
  #           arn as eks_identity_provider_arn
  #         from
  #           aws_eks_identity_provider_config
  #         where
  #           cluster_name in
  #           (
  #             select
  #               name
  #             from
  #               aws_eks_cluster
  #             where
  #               arn = $1
  #           )
  #       EOQ

  #       args = [self.input.eks_cluster_arn.value]
  #     }

  #     with "eks_node_groups" {
  #       sql = <<-EOQ
  #         select
  #           arn as eks_node_group_arn
  #         from
  #           aws_eks_node_group
  #         where
  #           cluster_name in
  #           (
  #             select
  #               name
  #             from
  #               aws_eks_cluster
  #             where
  #               arn = $1
  #           )
  #       EOQ

  #       args = [self.input.eks_cluster_arn.value]
  #     }

  #     with "iam_roles" {
  #       sql = <<-EOQ
  #         select
  #           role_arn as iam_role_arn
  #         from
  #           aws_eks_cluster as c
  #         where
  #           arn = $1
  #       EOQ

  #       args = [self.input.eks_cluster_arn.value]
  #     }

  #     with "kms_keys" {
  #       sql = <<-EOQ
  #         select
  #           e -> 'Provider' ->> 'KeyArn' as kms_key_arn
  #         from
  #           aws_eks_cluster,
  #           jsonb_array_elements(encryption_config) as e
  #         where
  #           arn = $1
  #       EOQ

  #       args = [self.input.eks_cluster_arn.value]
  #     }

  #     with "vpc_security_groups" {
  #       sql = <<-EOQ
  #         select
  #           group_id as vpc_security_group_id
  #         from
  #           aws_vpc_security_group
  #         where
  #           group_id in
  #           (
  #             select
  #               s
  #             from
  #               aws_eks_cluster,
  #               jsonb_array_elements_text(resources_vpc_config -> 'SecurityGroupIds') as s
  #             where
  #               arn = $1
  #           )
  #       EOQ

  #       args = [self.input.eks_cluster_arn.value]
  #     }

  #     with "vpc_subnets" {
  #       sql = <<-EOQ
  #         select
  #           subnet_id as vpc_subnet_id
  #         from
  #           aws_vpc_subnet
  #         where
  #           subnet_id in
  #           (
  #             select
  #               s
  #             from
  #               aws_eks_cluster,
  #               jsonb_array_elements_text(resources_vpc_config -> 'SubnetIds') as s
  #             where
  #               arn = $1
  #           )
  #       EOQ

  #       args = [self.input.eks_cluster_arn.value]
  #     }

  #     with "vpc_vpcs" {
  #       sql = <<-EOQ
  #         select
  #           resources_vpc_config ->> 'VpcId' as vpc_vpc_id
  #         from
  #           aws_eks_cluster
  #         where
  #           resources_vpc_config ->> 'VpcId' is not null
  #           and arn = $1
  #       EOQ

  #       args = [self.input.eks_cluster_arn.value]
  #     }

  #     nodes = [
  #       node.eks_addon,
  #       node.eks_cluster,
  #       node.eks_fargate_profile,
  #       node.eks_identity_provider_config,
  #       node.eks_node_group,
  #       node.iam_role,
  #       node.kms_key,
  #       node.vpc_security_group,
  #       node.vpc_subnet,
  #       node.vpc_vpc
  #     ]

  #     edges = [
  #       edge.eks_cluster_to_eks_addon,
  #       edge.eks_cluster_to_eks_fargate_profile,
  #       edge.eks_cluster_to_eks_identity_provider_config,
  #       edge.eks_cluster_to_eks_node_group,
  #       edge.eks_cluster_to_iam_role,
  #       edge.eks_cluster_to_kms_key,
  #       edge.eks_cluster_to_vpc_security_group,
  #       edge.eks_cluster_to_vpc_subnet,
  #       edge.vpc_subnet_to_vpc_vpc
  #     ]

  #     args = {
  #       eks_addon_arns             = with.eks_addons.rows[*].eks_addon_arn
  #       eks_cluster_arns           = [self.input.eks_cluster_arn.value]
  #       eks_fargate_profile_arns   = with.eks_fargate_profiles.rows[*].eks_fargate_profile_arn
  #       eks_identity_provider_arns = with.eks_identity_providers.rows[*].eks_identity_provider_arn
  #       eks_node_group_arns        = with.eks_node_groups.rows[*].eks_node_group_arn
  #       iam_role_arns              = with.iam_roles.rows[*].iam_role_arn
  #       kms_key_arns               = with.kms_keys.rows[*].kms_key_arn
  #       vpc_security_group_ids     = with.vpc_security_groups.rows[*].vpc_security_group_id
  #       vpc_subnet_ids             = with.vpc_subnets.rows[*].vpc_subnet_id
  #       vpc_vpc_ids                = with.vpc_vpcs.rows[*].vpc_vpc_id
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
        query = query.eks_cluster_overview
        args = {
          arn = self.input.eks_cluster_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.eks_cluster_tags
        args = {
          arn = self.input.eks_cluster_arn.value
        }
      }
    }
    container {
      width = 6

      table {
        title = "Resources VPC Config"
        query = query.eks_cluster_resources_vpc_config
        args = {
          arn = self.input.eks_cluster_arn.value
        }
      }

      table {
        title = "Control Plane Logging"
        query = query.eks_cluster_logging
        args = {
          arn = self.input.eks_cluster_arn.value
        }
      }
    }

  }

  container {

    table {
      title = "Node Groups"
      query = query.eks_cluster_node_group
      args = {
        arn = self.input.eks_cluster_arn.value
      }
    }

  }
}

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

query "eks_cluster_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(status) as value
    from
      aws_eks_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}

}

query "eks_cluster_kubernetes_version" {
  sql = <<-EOQ
    select
      'Version' as label,
      version as value
    from
      aws_eks_cluster
    where
      arn = $1;
  EOQ

  param "arn" {}

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
      arn = $1;
  EOQ

  param "arn" {}

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
      arn = $1;
  EOQ

  param "arn" {}

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
      and arn = $1;
  EOQ

  param "arn" {}

}

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
      arn = $1;
  EOQ

  param "arn" {}
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
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags);
    EOQ

  param "arn" {}
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
      arn = $1;
  EOQ

  param "arn" {}

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
      arn = $1;
  EOQ

  param "arn" {}

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
      and c.arn = $1;
  EOQ

  param "arn" {}

}

node "eks_cluster_to_vpc_node" {
  category = category.vpc_vpc

  sql = <<-EOQ
    select
      vpc_id as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'VPC ID', vpc_id,
        'Default', is_default::text,
        'State', state,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_vpc
    where
      vpc_id in
      (
        select
          resources_vpc_config ->> 'VpcId'
        from
          aws_eks_cluster
        where
          arn = $1
      )
  EOQ

  param "arn" {}
}
