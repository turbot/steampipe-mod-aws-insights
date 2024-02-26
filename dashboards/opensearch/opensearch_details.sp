dashboard "opensearch_domain_detail" {
  title = "AWS OpenSearch Domain Detail"
  tags = merge(local.opensearch_common_tags, {
    type = "Detail"
  })
  input "opensearch_arn" {
    title = "select a domain:"
    query = query.opensearch_domain_input
    width = 4
  }
  container {
    card {
      width = 3
      query = query.opensearch_domain_instance_type
      args  = [self.input.opensearch_arn.value]
    }
    card {
      width = 2
      query = query.opensearch_domain_version
      args  = [self.input.opensearch_arn.value]
    }
    card {
      width = 3
      query = query.opensearch_domain_endpoint
      args  = [self.input.opensearch_arn.value]
    }
  }
  with "vpc_security_groups_for_opensearch" {
    query = query.vpc_security_groups_for_opensearch
    args  = [self.input.opensearch_arn.value]
  }
  with "vpc_subnet_for_opensearch" {
    query = query.vpc_subnet_ids_for_opensearch
    args  = [self.input.opensearch_arn.value]
  }
  with "vpc_vpcs_for_opensearch" {
    query = query.vpc_vpcs_for_opensearch
    args  = [self.input.opensearch_arn.value]
  }
  container {
    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"
      node {
        base = node.opensearch_domain
        args = {
          opensearch_arns = [self.input.opensearch_arn.value]
        }
      }
      node {
        base = node.vpc_security_group
        args = {
          vpc_security_group_ids = with.vpc_security_groups_for_opensearch.rows[*].security_group_id
        }
      }
      node {
        base = node.vpc_subnet
        args = {
          vpc_subnet_ids = with.vpc_subnet_for_opensearch.rows[*].subnet_id
        }
      }
      node {
        base = node.vpc_vpc
        args = {
          vpc_vpc_ids = with.vpc_vpcs_for_opensearch.rows[*].vpc_id
        }
      }
      edge {
        base = edge.opensearch_domain_to_vpc_security_group
        args = {
          opensearch_arn = self.input.opensearch_arn.value
        }
      }
      edge {
        base = edge.opensearch_domain_to_vpc_subnet
        args = {
          opensearch_arn = self.input.opensearch_arn.value
        }
      }
      edge {
        base = edge.vpc_subnet_to_vpc_vpc
        args = {
          vpc_subnet_ids = with.vpc_subnet_for_opensearch.rows[*].subnet_id
        }
      }
    }
  }
  container {
    width = 12

    table {
      title = "Overview"
      type  = "line"
      width = 6
      query = query.opensearch_domain_overview
      args  = [self.input.opensearch_arn.value]
    }
    table {
      title = "Tags"
      width = 6
      query = query.opensearch_domain_tags
      args  = [self.input.opensearch_arn.value]
    }
  }
container {
    width = 6

    table {
      title = "Security Groups"
      query = query.opensearch_domain_security_groups
      args  = [self.input.opensearch_arn.value]

      column "Group ID" {
        // cyclic dependency prevents use of url_path, hardcode for now
        href = "/aws_insights.dashboard.vpc_security_group_detail?input.security_group_id={{.'Group ID' | @uri}}"
      }
    }

  }
  container {
    width = 6

    table {
      title = "Access Policy"
      query = query.opensearch_domain_access_policies
      args  = [self.input.opensearch_arn.value]
    }
  }
}
query "opensearch_domain_input" {
  sql = <<-EOQ
    select
      domain_name as label,
      arn as value,
      json_build_object(
        'domain_name', domain_name,
        'arn', arn
      ) as tags
    from
      aws_opensearch_domain
    order by
      domain_name;
  EOQ
}
query "opensearch_domain_tags" {
  sql = <<-EOQ
    select
      tags->>'Key' AS "Key",
      tags->>'Value' AS "Value"
    from (
      select jsonb_array_elements(tags_src) AS tags
      from aws_opensearch_domain
      where arn = $1
    ) AS subquery;
  EOQ
}
query "opensearch_domain_version" {
  sql = <<-EOQ
    select
      engine_version as "Engine Version"
    from
      aws_opensearch_domain
    where
      arn = $1;
  EOQ
}
query "opensearch_domain_instance_type" {
  sql = <<-EOQ
    select
      cluster_config->>'InstanceType' AS "Instance Type"
    from
      aws_opensearch_domain
    where
      arn = $1;
  EOQ
}
query "opensearch_domain_overview" {
  sql = <<-EOQ
    select
      domain_name AS "Domain Name",
      arn AS "ARN",
      created as "Created",
      processing as "Processing",
      region as "Region",
      account_id as "Account ID"
    from
      aws_opensearch_domain
    where
      arn = $1;
  EOQ
}
query "opensearch_domain_endpoint" {
  sql = <<-EOQ
    select
      endpoints as "VPC Endpoint"
    from
      aws_opensearch_domain
    where
      arn = $1;
  EOQ
}
query "vpc_security_groups_for_opensearch" {
  sql = <<-EOQ
    select
      jsonb_array_elements_text(vpc_options -> 'SecurityGroupIds') AS security_group_id
    from
      aws_opensearch_domain
    where
      arn = $1;
  EOQ
}
query "vpc_subnet_ids_for_opensearch" {
  sql = <<-EOQ
    select
      jsonb_array_elements_text(vpc_options -> 'SubnetIds') AS subnet_id
    from
      aws_opensearch_domain
    where
      arn = $1;
  EOQ
}
query "vpc_vpcs_for_opensearch" {
  sql = <<-EOQ
    select
      vpc_options ->> 'VPCId' AS vpc_id
    from
      aws_opensearch_domain
    where
      arn = $1;
  EOQ
}
query "opensearch_domain_security_groups" {
  sql = <<-EOQ
    select
      GroupID AS "Group ID"
    from (
      select jsonb_array_elements_text(vpc_options -> 'SecurityGroupIds') AS GroupID
      from aws_opensearch_domain
      where arn = $1
    ) AS subquery;
  EOQ
}
query "opensearch_domain_access_policies" {
  sql = <<-EOQ
    select
      access_policies as "Access Policy"
    from
      aws_opensearch_domain
    where
      arn = $1;
  EOQ
}
