dashboard "rds_db_cluster_relationships" {

  title = "AWS RDS DB Cluster Relationships"
  # documentation = file("./dashboards/rds/docs/rds_db_cluster_relationships.md")

  tags = merge(local.rds_common_tags, {
    type = "Relationships"
  })

  input "db_cluster_arn" {
    title = "Select a DB Cluster:"
    query = query.aws_rds_db_cluster_input
    width = 4
  }

  graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_rds_db_cluster_graph_from_cluster
    args = {
      arn = self.input.db_cluster_arn.value
    }

    category "aws_rds_db_cluster" {
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/rds_db_cluster_dark.svg"))
    }

    category "aws_rds_db_instance" {
      href = "${dashboard.aws_rds_db_instance_detail.url_path}?input.db_instance_arn={{.properties.ARN | @uri}}"
      icon = format("%s,%s", "data:image/svg+xml;base64", filebase64("./icons/rds_db_instance_dark.svg"))
    }
  }

}


query "aws_rds_db_cluster_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      aws_rds_db_cluster
    order by
      title;
  EOQ
}


query "aws_rds_db_cluster_graph_from_cluster" {
  sql = <<-EOQ
    -- Node RDS Cluster
    select
      null as from_id,
      null as to_id,
      db_cluster_identifier as id,
      title,
      'aws_rds_db_cluster' as category,
      jsonb_build_object(
        'ARN', arn,
        'Status', status,
        'Availability Zones', availability_zones::text,
        'Create Time', create_time,
        'Is Multi AZ', multi_az::text,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_rds_db_cluster
    where
      arn = $1

    -- Node RDS Cluster Instances
    union all
    select
      null as from_id,
      null as to_id,
      i.db_instance_identifier as id,
      i.title,
      'aws_rds_db_instance' as category,
      jsonb_build_object(
        'ARN', i.arn,
        'Status', i.status,
        'Public Access', i.publicly_accessible::text,
        'Availability Zone', i.availability_zone,
        'Create Time', i.create_time,
        'Is Multi AZ', i.multi_az::text,
        'Class', i.class,
        'Account ID', i.account_id,
        'Region', i.region
      ) as properties
    from
      aws_rds_db_cluster as c
      cross join jsonb_array_elements(members) as ci
      left join aws_rds_db_instance i on i.db_cluster_identifier = c.db_cluster_identifier and i.db_instance_identifier = ci ->> 'DBInstanceIdentifier'
    where
      c.arn = $1
  EOQ

  param "arn" {}
}
