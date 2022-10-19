dashboard "aws_ec2_key_pair_detail" {
  title         = "AWS EC2 Key Pair Detail"
  documentation = file("./dashboards/ec2/docs/ec2_key_pair_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "key_name" {
    title = "Select a Key:"
    sql   = query.ec2_key_pair_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_ec2_key_pair_instances
      args = {
        key_name = self.input.key_name.value
      }
    }

    card {
      width = 2
      query = query.aws_ec2_key_pair_launch_configs
      args = {
        key_name = self.input.key_name.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"


      nodes = [
        node.aws_ec2_key_pair_node,
        node.aws_ec2_key_pair_from_ec2_instance_node,
        node.aws_ec2_key_pair_from_ec2_launch_config_node
      ]

      edges = [
        edge.aws_ec2_key_pair_from_ec2_instance_edge,
        edge.aws_ec2_key_pair_from_ec2_launch_config_edge
      ]

      args = {
        key_name = self.input.key_name.value
      }
    }
  }

  container {

    table {
      title = "Overview"
      type  = "line"
      width = 3
      query = query.aws_ec2_key_pair_overview
      args = {
        key_name = self.input.key_name.value
      }

    }

    table {
      title = "Tags"
      width = 3
      query = query.aws_ec2_key_pair_tags
      args = {
        key_name = self.input.key_name.value
      }
    }
  }

}

query "ec2_key_pair_input" {
  sql = <<-EOQ
    select
      key_name as label,
      key_name as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_ec2_key_pair
    order by
      title;
  EOQ
}

query "aws_ec2_key_pair_instances" {
  sql = <<-EOQ
    select
      'Instances Using This Key' as label,
      count(distinct(instances)) as value
    from
      aws_ec2_instance as instances
    where
      key_name = $1
  EOQ

  param "key_name" {}

}

query "aws_ec2_key_pair_launch_configs" {
  sql = <<-EOQ
    select
      'Launch Configs Using This Key' as label,
      count(distinct(lc)) as value
    from
      aws_ec2_launch_configuration as lc
    where
      key_name = $1
  EOQ

  param "key_name" {}

}

query "aws_ec2_key_pair_overview" {
  sql = <<-EOQ
    select
      key_pair_id as "ID",
      key_name as "Name",
      key_fingerprint as "Fingerprint",
      title as "Title",
      region as "Region",
      account_id as "Account ID"
    from
      aws_ec2_key_pair
    where
      key_name = $1
  EOQ

  param "key_name" {}
}

query "aws_ec2_key_pair_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      aws_ec2_key_pair,
      jsonb_array_elements(tags_src) as tag
    where
      key_name = $1
    order by
      tag ->> 'Key';
    EOQ

  param "key_name" {}
}

node "aws_ec2_key_pair_node" {
  category = category.aws_ec2_key_pair

  sql = <<-EOQ
    select
      key_pair_id as id,
      title as title,
      jsonb_build_object(
        'Name', key_name,
        'ID', key_pair_id,
        'Fingerprint', key_fingerprint,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_ec2_key_pair
    where
      key_name = $1;
  EOQ

  param "key_name" {}
}

node "aws_ec2_key_pair_from_ec2_instance_node" {
  category = category.aws_ec2_instance

  sql = <<-EOQ
    select
      instances.arn as id,
      instances.title as title,
      jsonb_build_object(
        'ARN', instances.arn,
        'Account ID', instances.account_id,
        'Region', instances.region
      ) as properties
    from
      aws_ec2_instance instances
    where
      instances.key_name = $1;
  EOQ

  param "key_name" {}
}

edge "aws_ec2_key_pair_from_ec2_instance_edge" {
  title = "ec2 instance"

  sql = <<-EOQ
    select
      instances.arn as from_id,
      key_pair.key_pair_id as to_id,
      jsonb_build_object(
        'Account ID', instances.account_id
      ) as properties
    from
      aws_ec2_instance instances,
      aws_ec2_key_pair as key_pair
    where
      instances.key_name = $1;
  EOQ

  param "key_name" {}
}

node "aws_ec2_key_pair_from_ec2_launch_config_node" {
  category = category.aws_ec2_launch_configuration

  sql = <<-EOQ
    select
      launch_config.launch_configuration_arn as id,
      launch_config.title as title,
      jsonb_build_object(
        'ARN', launch_config.launch_configuration_arn,
        'Account ID', launch_config.account_id,
        'Region', launch_config.region ) as properties
    from
      aws_ec2_launch_configuration launch_config
    where
      launch_config.key_name = $1;
  EOQ

  param "key_name" {}
}

edge "aws_ec2_key_pair_from_ec2_launch_config_edge" {
  title = "launches with"

  sql = <<-EOQ
    select
      launch_config.launch_configuration_arn as from_id,
      key_pair.key_pair_id as to_id,
      jsonb_build_object(
        'Account ID', launch_config.account_id
      ) as properties
    from
      aws_ec2_launch_configuration launch_config,
      aws_ec2_key_pair as key_pair
    where
      launch_config.key_name = $1;
  EOQ

  param "key_name" {}
}
