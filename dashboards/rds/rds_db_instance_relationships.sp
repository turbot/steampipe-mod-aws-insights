dashboard "aws_rds_db_instance_relationships" {

  title         = "AWS RDS DB Instance Relationships"
  documentation = file("./dashboards/rds/docs/rds_db_instance_relationships.md")

  tags = merge(local.rds_common_tags, {
    type = "Relationships"
  })

  input "db_instance_arn" {
    title = "Select a DB Instance:"
    query = query.aws_rds_db_instance_input
    width = 4
  }

  graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_rds_db_instance_graph_from_instance
    args = {
      arn = self.input.db_instance_arn.value
    }
    category "aws_rds_db_instance" {
      href = "${dashboard.aws_rds_db_instance_detail.url_path}?input.db_instance_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/rds_db_instance_dark.svg"))
    }

    category "aws_vpc" {
      href = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.\"VPC ID\" | @uri}}"
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/vpc_light.svg"))
    }

    category "uses" {
      color = "green"
    }
  }
}

query "aws_rds_db_instance_graph_from_instance" {
  sql = <<-EOQ
    -- RDS DB INSTANCE NODE
    select
      null as from_id,
      null as to_id,
      db_instance_identifier as id,
      title,
      'aws_rds_db_instance' as category,
      jsonb_build_object(
        'ARN', arn,
        'DB Name', db_name,
        'Public Access', publicly_accessible::text,
        'Availability Zone', availability_zone,
        'Create Time', create_time,
        'Class', class,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_rds_db_instance
    where
      arn = $1

    -- RDS DB INSTANCE VPC NODE
    union all
    select
      null as from_id,
      null as to_id,
      v.vpc_id as id,
      v.title,
      'aws_vpc' as category,
      jsonb_build_object(
        'VPC ID', v.vpc_id,
        'ARN', v.arn,
        'Name', v.title,
        'CIDR Block', cidr_block,
        'Is Default', is_default::text,
        'Account ID', v.account_id,
        'Region', v.region
      ) as properties
    from
      aws_vpc as v,
      aws_rds_db_instance as di
    where
      di.arn = $1
      and v.vpc_id = di.vpc_id

    -- RDS DB INSTANCE VPC EDGE
    union all
    select
      di.db_instance_identifier as from_id,
      v.vpc_id as to_id,
      null as id,
      'uses' as title,
      'uses' as category,
      jsonb_build_object(
        'VPC ARN', v.arn,
        'DB ARN', di.arn
      ) as properties
    from
      aws_vpc as v,
      aws_rds_db_instance as di
    where
      di.arn = $1
      and v.vpc_id = di.vpc_id
  EOQ

  param "arn" {}
}
