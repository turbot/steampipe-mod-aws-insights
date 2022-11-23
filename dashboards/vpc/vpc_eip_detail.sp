dashboard "aws_vpc_eip_detail" {

  title         = "AWS VPC Elastic IP Detail"
  documentation = file("./dashboards/vpc/docs/vpc_eip_detail.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "eip_arn" {
    title = "Select an eip:"
    query = query.aws_vpc_eip_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_vpc_eip_association
      args = {
        arn = self.input.eip_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_vpc_eip_private_ip_address
      args = {
        arn = self.input.eip_arn.value
      }
    }

    card {
      width = 2
      query = query.aws_vpc_eip_public_ip_address
      args = {
        arn = self.input.eip_arn.value
      }
    }
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_vpc_eip_node,
        node.aws_vpc_eip_from_ec2_network_interface_node,
        node.aws_vpc_eip_from_ec2_instance_node,
        node.aws_vpc_eip_network_interface_from_nat_gateway_node
      ]

      edges = [
        edge.aws_vpc_eip_from_ec2_network_interface_edge,
        edge.aws_vpc_eip_network_interface_from_ec2_instance_edge,
        edge.aws_vpc_eip_network_interface_from_nat_gateway_edge
      ]

      args = {
        arn = self.input.eip_arn.value
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
        query = query.aws_vpc_eip_overview
        args = {
          arn = self.input.eip_arn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.aws_vpc_eip_tags
        args = {
          arn = self.input.eip_arn.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Association"
        query = query.aws_vpc_eip_association_details
        args = {
          arn = self.input.eip_arn.value
        }

        column "Instance ARN" {
          display = "none"
        }

        column "Instance ID" {
          href = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn={{.'Instance ARN' | @uri}}"
        }

        column "Network Interface ID" {
          href = "/aws_insights.dashboard.aws_ec2_network_interface_detail?input.network_interface_id={{.'Network Interface ID' | @uri}}"
        }
      }

      table {
        title = "Other IP Addresses"
        query = query.aws_vpc_eip_other_ip
        args = {
          arn = self.input.eip_arn.value
        }
      }
    }

  }
}


query "aws_vpc_eip_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_vpc_eip
    order by
      title;
  EOQ
}

node "aws_vpc_eip_node" {
  category = category.aws_vpc_eip

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Allocation Id', allocation_id,
        'Association Id', association_id,
        'Public IP', public_ip,
        'Domain', domain,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_vpc_eip
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_vpc_eip_from_ec2_network_interface_node" {
  category = category.aws_ec2_network_interface

  sql = <<-EOQ
    select
      i.network_interface_id as id,
      i.title as title,
      jsonb_build_object(
        'Interface ID', i.network_interface_id,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_vpc_eip as e
      left join aws_ec2_network_interface as i on e.network_interface_id = i.network_interface_id
    where
      e.network_interface_id is not null
      and e.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_vpc_eip_from_ec2_network_interface_edge" {
  title = "eip"

  sql = <<-EOQ
    select
      i.network_interface_id as from_id,
      e.arn as to_id
    from
      aws_vpc_eip as e
      left join aws_ec2_network_interface as i on e.network_interface_id = i.network_interface_id
    where
      e.network_interface_id is not null
      and e.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_vpc_eip_from_ec2_instance_node" {
  category = category.aws_ec2_instance
  sql      = <<-EOQ
    select
      i.arn as id,
      i.title as title,
      jsonb_build_object(
        'ARN', i.arn,
        'ID', i.instance_id,
        'State', i.instance_state,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties   
    from
      aws_vpc_eip as e
      left join aws_ec2_instance as i on e.instance_id = i.instance_id
    where
      e.network_interface_id is not null
      and e.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_vpc_eip_network_interface_from_ec2_instance_edge" {
  title = "network interface"

  sql = <<-EOQ
    select
      i.arn as from_id,
      e.network_interface_id as to_id
    from
      aws_vpc_eip as e
      left join aws_ec2_instance as i on e.instance_id = i.instance_id
    where
      e.network_interface_id is not null
      and e.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_vpc_eip_network_interface_from_nat_gateway_node" {
  category = category.aws_vpc_nat_gateway

  sql = <<-EOQ
    select
      n.arn as id,
      n.title as title,
      jsonb_build_object(
        'ARN', n.arn,
        'NAT Gateway ID', n.nat_gateway_id,
        'State', n.state,
        'Account ID', n.account_id,
        'Region', n.region
      ) as properties
    from
      aws_vpc_nat_gateway as n,
      jsonb_array_elements(nat_gateway_addresses) as a
      left join aws_vpc_eip as e on e.network_interface_id = a ->> 'NetworkInterfaceId'
    where
      e.network_interface_id is not null
      and e.arn = $1;
  EOQ

  param "arn" {}
}


edge "aws_vpc_eip_network_interface_from_nat_gateway_edge" {
  title = "network interface"

  sql = <<-EOQ
    select
      n.arn as from_id,
      e.network_interface_id as to_id
    from
      aws_vpc_nat_gateway as n,
      jsonb_array_elements(nat_gateway_addresses) as a
      left join aws_vpc_eip as e on e.network_interface_id = a ->> 'NetworkInterfaceId'
    where
      e.network_interface_id is not null
      and e.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_vpc_eip_association" {
  sql = <<-EOQ
    select
      'Association' as label,
      case when association_id is not null then 'Associated' else 'Not Associated' end as value,
      case when association_id is not null then 'ok' else 'alert' end as type
    from
      aws_vpc_eip
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_vpc_eip_private_ip_address" {
  sql = <<-EOQ
    select
      'Private IP Address' as label,
      private_ip_address as value
    from
      aws_vpc_eip
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_vpc_eip_public_ip_address" {
  sql = <<-EOQ
    select
      'Public IP Address' as label,
      public_ip as value
    from
      aws_vpc_eip
    where
      arn = $1;
  EOQ

  param "arn" {}
}


query "aws_vpc_eip_overview" {
  sql = <<-EOQ
    select
      allocation_id as "Allocation ID",
      domain as "Domain",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      arn as "ARN"
    from
      aws_vpc_eip
    where
      arn = $1
  EOQ

  param "arn" {}
}

query "aws_vpc_eip_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_vpc_eip,
      jsonb_array_elements(tags_src) as tag
    where
      arn = $1
    order by
      tag ->> 'Key';
  EOQ

  param "arn" {}
}

query "aws_vpc_eip_association_details" {
  sql = <<-EOQ
    select
      association_id as "Association ID",
      e.instance_id  as "Instance ID",
      i.arn as "Instance ARN",
      network_interface_id as "Network Interface ID"
    from
      aws_vpc_eip as e
      left join aws_ec2_instance as i on i.instance_id = e.instance_id
    where
      e.arn = $1;
  EOQ

  param "arn" {}
}

query "aws_vpc_eip_other_ip" {
  sql = <<-EOQ
    select
      carrier_ip as "Carrier IP",
      customer_owned_ip  as "Customer Owned IP"
    from
      aws_vpc_eip
    where
      arn = $1;
  EOQ

  param "arn" {}
}

