
locals {
  opensearch_common_tags = {
    service = "AWS/OpenSearch"
  }
}

# dashboard.tf

dashboard "opensearch_domain_detail" {
  title         = "OpenSearch Domain Detail"

  tags = merge(local.opensearch_common_tags, {
    type = "Detail"
  })

  input "opensearch_domain_name" {
    title = "Select an OpenSearch domain:"
    query = query.opensearch_domain_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.opensearch_domain_instance_type
      args  = [self.input.opensearch_domain_name.value]
    }

    card {
      width = 2
      query = query.opensearch_domain_version
      args  = [self.input.opensearch_domain_name.value]
    }

    card {
      width = 2
      query = query.opensearch_domain_endpoint
      args  = [self.input.opensearch_domain_name.value]
    }
  }

  with "vpc_security_groups_for_opensearch" {
    query = query.vpc_security_groups_for_opensearch
    args  = [self.input.opensearch_domain_name.value]
  }

  with "vpc_subnet_for_opensearch" {
    query = query.vpc_subnet_ids_for_opensearch
    args  = [self.input.opensearch_domain_name.value]
  }
  

  container {

    graph {

      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.opensearch_domain_name
        args = {
          opensearch_domain_name = self.input.opensearch_domain_name.value
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
      edge {
        base = edge.opensearch_domain_name_to_vpc_security_group
        args = {
          opensearch_domain_name = self.input.opensearch_domain_name.value
        }
      }
      edge {
        base = edge.opensearch_domain_name_to_vpc_subnet
        args = {
          opensearch_domain_name = self.input.opensearch_domain_name.value
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
      args  = [self.input.opensearch_domain_name.value]
    }

    table {
      title = "Tags"
      width = 6
      query = query.opensearch_domain_tags
      args  = [self.input.opensearch_domain_name.value]
    }
  }


}

# queries.tf

query "opensearch_domain_input" {
  sql = <<-EOQ
    SELECT
      domain_name AS label,
      arn AS value,
      json_build_object(
        'domain_name', domain_name,
        'arn', arn
      ) AS tags
    FROM
      aws_opensearch_domain
    ORDER BY
      domain_name;
  EOQ
}

query "opensearch_domain_tags" {
  sql = <<-EOQ
    SELECT
      tags->>'Key' AS "Key",
      tags->>'Value' AS "Value"
    FROM (
      SELECT jsonb_array_elements(tags_src) AS tags
      FROM aws_opensearch_domain
      WHERE arn = $1
    ) AS subquery;
  EOQ
}


query "opensearch_domain_version" {
  sql = <<-EOQ
    SELECT
      engine_version
    FROM
      aws_opensearch_domain
    WHERE
      arn = $1;
  EOQ
}

query "opensearch_domain_instance_type" {
  sql = <<-EOQ
    SELECT
      cluster_config->>'InstanceType' AS instance_type
    FROM
      aws_opensearch_domain
    WHERE
      arn = $1;
  EOQ
}


query "opensearch_domain_overview" {
  sql = <<-EOQ
    SELECT
      domain_name AS "Domain Name",
      arn AS "ARN",
      created as "Created",
      processing as "Processing",
      region as "Region",
      account_id as "Account ID"
    FROM
      aws_opensearch_domain
    WHERE
      arn = $1;
  EOQ
}

query "opensearch_domain_endpoint" {
  sql = <<-EOQ
    SELECT
      endpoint
    FROM
      aws_opensearch_domain
    WHERE
      arn = $1;
  EOQ
}

query "vpc_security_groups_for_opensearch" {
  sql = <<-EOQ
    SELECT
      jsonb_array_elements_text(vpc_options -> 'SecurityGroupIds') AS security_group_id
    FROM
      aws_opensearch_domain
    WHERE
      arn = $1;
  EOQ
}

query "vpc_subnet_ids_for_opensearch" {
  sql = <<-EOQ
    SELECT
      jsonb_array_elements_text(vpc_options -> 'SubnetIds') AS subnet_id
    FROM
      aws_opensearch_domain
    WHERE
      arn = $1;
  EOQ
}