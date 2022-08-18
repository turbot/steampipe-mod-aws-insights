dashboard "aws_vpc_eip_detail" {

  title         = "AWS VPC EIP Detail"
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

    graph {
      type  = "graph"
      title = "Relationships"
      query = query.aws_vpc_eip_relationships_graph
      args = {
        arn = self.input.eip_arn.value
      }

      category "aws_vpc_eip" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/vpc_eip_light.svg"))
      }

      category "aws_ec2_network_interface" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_network_interface_light.svg"))
      }

      category "aws_ec2_instance" {
        icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_instance_light.svg"))
        href = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn={{.properties.'ARN' | @uri}}"
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

  with eip as (select * from aws_vpc_eip where arn = $1)

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

    -- From ENI (node)
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

    -- From ENI (edge)
    union all
    select
      i.network_interface_id as from_id,
      e.arn as to_id,
      null as id,
      'allocated to' as title,
      'allocated to' as category,
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

    -- From ENI > EC2 Instance (node)
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

    -- From ENI > EC2 Instance (edge)
    union all
    select
      i.arn as from_id,
      e.network_interface_id as to_id,
      null as id,
      'attached to' as title,
      'attached to' as category,
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


