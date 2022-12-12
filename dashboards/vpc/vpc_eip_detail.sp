dashboard "vpc_eip_detail" {

  title         = "AWS VPC Elastic IP Detail"
  documentation = file("./dashboards/vpc/docs/vpc_eip_detail.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "eip_arn" {
    title = "Select an eip:"
    query = query.vpc_eip_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.vpc_eip_association
      args = {
        arn = self.input.eip_arn.value
      }
    }

    card {
      width = 2
      query = query.vpc_eip_private_ip_address
      args = {
        arn = self.input.eip_arn.value
      }
    }

    card {
      width = 2
      query = query.vpc_eip_public_ip_address
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

      with "ec2_instances" {
        sql = <<-EOQ
          select
            i.arn as instance_arn
          from
            aws_vpc_eip as e,
            aws_ec2_instance as i
          where
            e.instance_id = i.instance_id
            and e.arn = $1;
        EOQ

        args = [self.input.eip_arn.value]
      }

      with "ec2_network_interfaces" {
        sql = <<-EOQ
          select
            network_interface_id as eni_id
          from
            aws_vpc_eip
          where
            network_interface_id is not null
            and arn = $1;
        EOQ

        args = [self.input.eip_arn.value]
      }

      with "vpc_nat_gateways" {
        sql = <<-EOQ
          select
            g.arn as gateway_arn
          from
            aws_vpc_eip as e,
            aws_vpc_nat_gateway as g,
            jsonb_array_elements(nat_gateway_addresses) as a
          where
            a ->> 'NetworkInterfaceId' = e.network_interface_id
            and e.arn = $1;
        EOQ

        args = [self.input.eip_arn.value]
      }

      nodes = [

        node.ec2_instance,
        node.ec2_network_interface,
        node.vpc_eip,
        node.vpc_nat_gateway
      ]

      edges = [

        edge.ec2_instance_to_ec2_network_interface,
        edge.ec2_network_interface_to_vpc_eip,
        edge.vpc_nat_gateway_to_ec2_network_interface
      ]

      args = {
        ec2_instance_arns         = with.ec2_instances.rows[*].instance_arn
        ec2_network_interface_ids = with.ec2_network_interfaces.rows[*].eni_id
        vpc_eip_arns              = [self.input.eip_arn.value]
        vpc_nat_gateway_arns      = with.vpc_nat_gateways.rows[*].gateway_arn
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
        query = query.vpc_eip_overview
        args = {
          arn = self.input.eip_arn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.vpc_eip_tags
        args = {
          arn = self.input.eip_arn.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Association"
        query = query.vpc_eip_association_details
        args = {
          arn = self.input.eip_arn.value
        }

        column "Instance ARN" {
          display = "none"
        }

        column "Instance ID" {
          href = "${dashboard.ec2_instance_detail.url_path}?input.instance_arn={{.'Instance ARN' | @uri}}"
        }

        column "Network Interface ID" {
          href = "/aws_insights.dashboard.ec2_network_interface_detail?input.network_interface_id={{.'Network Interface ID' | @uri}}"
        }
      }

      table {
        title = "Other IP Addresses"
        query = query.vpc_eip_other_ip
        args = {
          arn = self.input.eip_arn.value
        }
      }
    }

  }
}


query "vpc_eip_input" {
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

query "vpc_eip_association" {
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

query "vpc_eip_private_ip_address" {
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

query "vpc_eip_public_ip_address" {
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


query "vpc_eip_overview" {
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

query "vpc_eip_tags" {
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

query "vpc_eip_association_details" {
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

query "vpc_eip_other_ip" {
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

