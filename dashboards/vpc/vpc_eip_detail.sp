dashboard "aws_vpc_eip_detail" {

  title         = "AWS VPC Elastic IP Detail"
  documentation = file("./dashboards/vpc/docs/vpc_eip_detail.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "eip_arn" {
    title = "Select an eip:"
    sql   = query.aws_vpc_eip_input.sql
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
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_vpc_eip_relationships_graph
      args = {
        arn = self.input.eip_arn.value
      }
      category "aws_vpc_eip" {
        icon = local.aws_vpc_eip_icon
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
        'region', region,
        'arn', arn
      ) as tags
    from
      aws_vpc_eip
    order by
      title;
  EOQ
}

query "aws_vpc_eip_relationships_graph" {
  sql = <<-EOQ
    with eip as (
      select
        *
      from
        aws_vpc_eip
      where
        arn = $1
    )
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_vpc_eip' as category,
      jsonb_build_object(
        'ARN', arn,
        'Allocation Id', allocation_id,
        'Association Id', association_id,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      eip

    -- From EC2 network interfaces (node)
    union all
    select
      null as from_id,
      null as to_id,
      i.network_interface_id as id,
      i.title as title,
      'aws_ec2_network_interface' as category,
      jsonb_build_object(
        'ID', i.network_interface_id,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      eip as e
      left join aws_ec2_network_interface as i on e.network_interface_id = i.network_interface_id
    where
      e.network_interface_id is not null

    -- From EC2 network interfaces (edge)
    union all
    select
      i.network_interface_id as from_id,
      e.arn as to_id,
      null as id,
      'eni' as title,
      'ec2_network_interface_to_vpc_eip' as category,
      jsonb_build_object(
        'ID', i.network_interface_id,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      eip as e
      left join aws_ec2_network_interface as i on e.network_interface_id = i.network_interface_id
    where
      e.network_interface_id is not null

    -- From EC2 instances (node)
    union all
    select
      null as from_id,
      null as to_id,
      i.arn as id,
      i.title as title,
      'aws_ec2_instance' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'ID', i.instance_id,
        'State', i.instance_state,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      eip as e
      left join aws_ec2_instance as i on e.instance_id = i.instance_id
    where
      e.network_interface_id is not null

    -- From EC2 instances (edge)
    union all
    select
      i.arn as from_id,
      e.network_interface_id as to_id,
      null as id,
      'ec2 instance' as title,
      'ec2_instance_to_ec2_network_interface' as category,
      jsonb_build_object(
        'ID', e.network_interface_id,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      eip as e
      left join aws_ec2_instance as i on e.instance_id = i.instance_id
    where
      e.network_interface_id is not null
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

