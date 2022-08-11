dashboard "aws_ec2_keys_relationships" {
  title         = "AWS EC2 Keys Relationships"
  # documentation = file("./dashboards/ec2/docs/ec2_instance_relationships.md")
  
  tags = merge(local.ec2_common_tags, {
    type = "Relationships"
  })
  
  input "key_name" {
    title = "Select a Key:"
    sql   = query.ec2_key_input.sql
    width = 4
  }
  
  graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_ec2_ec2_keypair_graph_to_instance
    args = {
      key_name = self.input.key_name.value
    }
    
    category "aws_ec2_instance" {
      href = "${dashboard.aws_ec2_instance_detail.url_path}?input.instance_arn={{.properties.'ARN' | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/ec2_instance_light.svg"))
    }
  }
}

query "aws_ec2_ec2_keypair_graph_to_instance"{
  sql = <<-EOQ
    with keypair as (select * from aws_ec2_key_pair where key_name = $1)
    select
      null as from_id,
      null as to_id,
      key_pair_id as id,
      title as title,
      'aws_ec2_key_pair' as category,
      jsonb_build_object(
        'Name', keypair.key_name,
        'ID', keypair.key_pair_id,
        'Fingerprint', keypair.key_fingerprint,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      keypair
      
    -- Instances - nodes
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
      keypair
    where
      instances.key_name = keypair.key_name
      
    -- Instances - edges
    union all
    select
      instances.arn as from_id,
      keypair.key_pair_id as to_id,
      null as id,
      'Uses' as title,
      'uses' as category,
      jsonb_build_object(
        'ARN', instances.arn,
        'Account ID', instances.account_id,
        'Region', instances.region
      ) as properties
    from
      aws_ec2_instance instances,
      keypair
    where
      instances.key_name = keypair.key_name

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
