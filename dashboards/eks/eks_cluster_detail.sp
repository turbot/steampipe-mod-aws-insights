dashboard "aws_eks_cluster_detail" {
  title         = "AWS EKS Cluster Detail"
  documentation = file("./dashboards/eks/docs/eks_cluster_detail.md")

  tags = merge(local.eks_common_tags, {
    type = "Detail"
  })

  input "eks_cluster_arn" {
    title = "Select a cluster:"
    query = query.aws_eks_cluster_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_eks_cluster_status
      args = {
        arn = self.input.eks_cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_eks_cluster_kubernetes_version
      args = {
        arn = self.input.eks_cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_eks_cluster_secrets_encryption
      args = {
        arn = self.input.eks_cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_eks_cluster_endpoint_restrict_public_access
      args = {
        arn = self.input.eks_cluster_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_eks_cluster_control_plane_audit_logging
      args = {
        arn = self.input.eks_cluster_arn.value
      }
    }

  }

  container {
    graph {
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_eks_cluster_relationships_graph
      args = {
        arn = self.input.eks_cluster_arn.value
      }
      category "aws_eks_cluster" {}
    }
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.aws_eks_cluster_overview
        args = {
          arn = self.input.eks_cluster_arn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_eks_cluster_tags
        args = {
          arn = self.input.eks_cluster_arn.value
        }
      }
    }
    container {
      width = 6

      table {
        title = "Resources VPC Config"
        query = query.aws_eks_cluster_resources_vpc_config
        args = {
          arn = self.input.eks_cluster_arn.value
        }
      }

      table {
        title = "Control Plane Logging"
        query = query.aws_eks_cluster_logging
        args = {
          arn = self.input.eks_cluster_arn.value
        }
      }
    }

  }

  container {

    table {
      title = "Node Groups"
      query = query.aws_eks_cluster_node_group
      args = {
        arn = self.input.eks_cluster_arn.value
      }
    }

  }
}

query "aws_eks_cluster_input" {
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

query "aws_eks_cluster_status" {
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

query "aws_eks_cluster_kubernetes_version" {
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

query "aws_eks_cluster_secrets_encryption" {
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

query "aws_eks_cluster_endpoint_restrict_public_access" {
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

query "aws_eks_cluster_control_plane_audit_logging" {
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

query "aws_eks_cluster_relationships_graph" {
  sql = <<-EOQ
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_eks_cluster' as category,
      jsonb_build_object(
        'ARN', arn,
        'Created At', created_at,
        'Version', version,
        'Status', status,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_eks_cluster
    where
      arn = $1

    -- To IAM role (node)
    union all
    select
      null as from_id,
      null as to_id,
      role_id as id,
      r.title as title,
      'aws_iam_role' as category,
      jsonb_build_object(
        'ARN', r.arn,
        'Create Date', r.create_date,
        'Max Session Duration', max_session_duration,
        'Account ID', r.account_id ) as properties
    from
      aws_iam_role as r,
      aws_eks_cluster as c
    where
      r.arn = c.role_arn and c.arn = $1

    -- To IAM roles (edge)
    union all
    select
      c.arn as from_id,
      role_id as to_id,
      null as id,
      'assumes' as title,
      'eks_cluster_to_iam_role' as category,
      jsonb_build_object(
        'Account ID', c.account_id ) as properties
    from
      aws_iam_role as r,
      aws_eks_cluster as c
    where
      r.arn = c.role_arn and c.arn = $1

    -- To KMS keys (node)
    union all
    select
      null as from_id,
      null as to_id,
      id as id,
      title as title,
      'aws_kms_key' as category,
      jsonb_build_object(
        'ARN', arn,
        'Key Manager', key_manager,
        'Creation Date', creation_date,
        'Enabled', enabled::text,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_kms_key
    where
      arn in
      (
        select
          e -> 'Provider' ->> 'KeyArn'
        from
          aws_eks_cluster,
          jsonb_array_elements(encryption_config) as e
        where
          arn = $1
      )

    -- To KMS keys (edge)
    union all
    select
      c.arn as from_id,
      k.id as to_id,
      null as id,
      'secrets encrypted with' as title,
      'eks_cluster_to_kms_key' as category,
      jsonb_build_object(
        'Account ID', c.account_id ) as properties
    from
      aws_eks_cluster as c,
      jsonb_array_elements(encryption_config) as e
      left join
        aws_kms_key as k
        on e -> 'Provider' ->> 'KeyArn' = k.arn
    where
      c.arn = $1

    -- To EKS node group (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_eks_node_group' as category,
      jsonb_build_object(
        'ARN', arn,
        'Capacity Type ', capacity_type,
        'Created At', created_at,
        'Status', status,
        'Account ID', account_id,
        'Region', region
        ) as properties
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
      )

    -- To EKS node group (edge)
    union all
    select
      c.arn as from_id,
      g.arn as to_id,
      null as id,
      'node group' as title,
      'eks_cluster_to_eks_node_group' as category,
      jsonb_build_object(
        'Account ID', c.account_id ) as properties
    from
      aws_eks_cluster as c
      left join
        aws_eks_node_group as g
        on g.cluster_name = c.name
    where
      c.arn = $1

    -- To EKS addons (node)
    union all
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_eks_addon' as category,
      jsonb_build_object(
        'ARN', arn,
        'Addon Version', addon_version,
        'Created At', created_at,
        'Status', status,
        'Account ID', account_id,
        'Region', region
        ) as properties
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
      )

    -- To EKS addons (edge)
    union all
    select
      c.arn as from_id,
      a.arn as to_id,
      null as id,
      'addon' as title,
      'eks_cluster_to_eks_addons' as category,
      jsonb_build_object(
        'Account ID', c.account_id ) as properties
    from
      aws_eks_cluster as c
      left join
        aws_eks_addon as a
        on a.cluster_name = c.name
    where
      c.arn = $1

    -- To VPC security groups (node)
    union all
    select
      null as from_id,
      null as to_id,
      group_id as id,
      title as title,
      'aws_vpc_security_group' as category,
      jsonb_build_object(
        'ARN', arn,
        'VPC ID', vpc_id,
        'Account ID', account_id,
        'Region', region ) as properties
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
      )

    -- To VPC security groups (edge)
    union all
    select
      arn as from_id,
      group_id as to_id,
      null as id,
      'security group' as title,
      'eks_cluster_to_security_group' as category,
      jsonb_build_object(
        'Account ID', c.account_id ) as properties
    from
      aws_eks_cluster as c,
      jsonb_array_elements_text(resources_vpc_config -> 'SecurityGroupIds') as group_id
    where
      arn = $1

    -- To VPC subnets (node)
    union all
    select
      null as from_id,
      null as to_id,
      subnet_id as id,
      title as title,
      'aws_vpc_subnet' as category,
      jsonb_build_object(
        'ARN', subnet_arn,
        'VPC ID', vpc_id,
        'State', state,
        'Account ID', account_id,
        'Region', region ) as properties
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
      )

    -- To VPC subnets (edge)
    union all
    select
      arn as from_id,
      subnet_id as to_id,
      null as id,
      'subnet' as title,
      'eks_cluster_to_vpc_subnet' as category,
      jsonb_build_object(
        'Account ID', c.account_id ) as properties
    from
      aws_eks_cluster as c,
      jsonb_array_elements_text(resources_vpc_config -> 'SubnetIds') as subnet_id
    where
      arn = $1

     -- To VPC (node)
    union all
    select
      null as from_id,
      null as to_id,
      vpc_id as id,
      title as title,
      'aws_vpc' as category,
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

    -- To subnets -> VPC (edge)
    union all
    select
      subnet_id as from_id,
      resources_vpc_config ->> 'VpcId' as to_id,
      null as id,
      'vpc' as title,
      'vpc_subnet_to_vpc' as category,
      jsonb_build_object(
        'Account ID', c.account_id ) as properties
    from
      aws_eks_cluster as c,
      jsonb_array_elements_text(resources_vpc_config -> 'SubnetIds') as subnet_id
    where
      arn = $1

    -- To security groups -> VPC (edge)
    union all
    select
      group_id as from_id,
      resources_vpc_config ->> 'VpcId' as to_id,
      null as id,
      'vpc' as title,
      'security_group_to_vpc' as category,
      jsonb_build_object(
        'Account ID', c.account_id ) as properties
    from
      aws_eks_cluster as c,
      jsonb_array_elements_text(resources_vpc_config -> 'SecurityGroupIds') as group_id
    where
      arn = $1

    order by
      category,
      from_id,
      to_id;
  EOQ

  param "arn" {}
}

query "aws_eks_cluster_overview" {
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

query "aws_eks_cluster_tags" {
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

query "aws_eks_cluster_logging" {
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

query "aws_eks_cluster_resources_vpc_config" {
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

query "aws_eks_cluster_node_group" {
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
