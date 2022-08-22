dashboard "aws_ec2_key_pair_detail" {
  title = "AWS EC2 Key Pair Detail"
  documentation = file("./dashboards/ec2/docs/ec2_key_pair_detail.md")

  tags = merge(local.ec2_common_tags, {
    type = "Detail"
  })

  input "key_name" {
    title = "Select a Key:"
    sql   = query.ec2_key_input.sql
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
      type  = "graph"
      base  = graph.aws_graph_categories
      query = query.aws_ec2_keypair_relationships
      args = {
        key_name = self.input.key_name.value
      }
      category "aws_ec2_key_pair" {
      }
    }
  }



  container {

    table {
      title = "Overview"
      type  = "line"
      width = 6
      query = query.aws_ec2_key_pair_overview
      args = {
        key_name = self.input.key_name.value
      }

    }

    table {
      title = "Tags"
      width = 6
      query = query.aws_ec2_key_pair_tags
      args = {
        key_name = self.input.key_name.value
      }
    }
  }

}

query "aws_ec2_key_pair_instances" {
  sql = <<-EOQ
    select
      'Instances using this key' as label,
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
      'Launch Configs using this key' as label,
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
      partition as "Partition",
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

query "aws_ec2_key_pair_relationships_graph" {
  sql = <<-EOQ
    with key_pair as
    (
      select
        *
      from
        aws_ec2_key_pair
      where
        key_name = $1
    )

    -- Resource (node)
    select
      null as from_id,
      null as to_id,
      key_pair_id as id,
      title as title,
      'aws_ec2_key_pair' as category,
      jsonb_build_object(
        'Name', key_pair.key_name,
        'ID', key_pair.key_pair_id,
        'Fingerprint', key_pair.key_fingerprint,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      key_pair

    -- From EC2 Instances (node)
    union all
    select
      null as from_id,
      null as to_id,
      instances.arn as id,
      instances.title as title,
      'aws_ec2_instance' as category,
      jsonb_build_object(
        'ARN', instances.arn,
        'Account ID', instances.account_id,
        'Region', instances.region
      ) as properties
    from
      aws_ec2_instance instances,
      key_pair
    where
      instances.key_name = key_pair.key_name

    -- From EC2 Instances (edges)
    union all
    select
      instances.arn as from_id,
      key_pair.key_pair_id as to_id,
      null as id,
      'has' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', instances.arn,
        'Account ID', instances.account_id,
        'Region', instances.region
      ) as properties
    from
      aws_ec2_instance instances,
      key_pair
    where
      instances.key_name = key_pair.key_name

    -- From EC2 Launch Configs (node)
    union all
    select
      null as from_id,
      null as to_id,
      launch_config.launch_configuration_arn as id,
      launch_config.title as title,
      'aws_ec2_launch_configuration' as category,
      jsonb_build_object(
        'ARN', launch_config.launch_configuration_arn,
        'Account ID', launch_config.account_id,
        'Region', launch_config.region ) as properties
    from
      aws_ec2_launch_configuration launch_config,
      key_pair
    where
      launch_config.key_name = key_pair.key_name

    -- From EC2 Launch Configs (edge)
    union all
    select
      launch_config.launch_configuration_arn as from_id,
      key_pair.key_pair_id as to_id,
      null as id,
      'launches with' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', launch_config.launch_configuration_arn,
        'Account ID', launch_config.account_id,
        'Region', launch_config.region ) as properties
    from
      aws_ec2_launch_configuration launch_config,
      key_pair
    where
      launch_config.key_name = key_pair.key_name

    order by
      category,
      from_id,
      to_id;

  EOQ

  param "key_name" {}
}

query "ec2_key_input" {
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
