dashboard "aws_vpc_relationships" {

  title         = "AWS VPC Relationships"
  #documentation = file("./dashboards/vpc/docs/vpc_relationships.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })


  input "vpc_id" {
    title = "Select a VPC:"
    sql   = query.aws_vpc.sql
    width = 4
  }

   graph {
    type  = "graph"
    title = "Things I use..."
    query = query.aws_vpc_graph_from_vpc
    args = {
      vpc_id = self.input.vpc_id.value
    }

    category "aws_vpc" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_vpc.svg"))
      color = "orange"
      href  = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.'ID' | @uri}}"
    }


    }

   graph {
    type  = "graph"
    title = "Things that use me..."
    query = query.aws_vpc_graph_to_vpc
    args = {
      vpc_id = self.input.vpc_id.value
    }

    category "aws_vpc" {
      icon = format("%s,%s", "image://data:image/svg+xml;base64", filebase64("./icons/aws_vpc.svg"))
      color = "orange"
      href  = "${dashboard.aws_vpc_detail.url_path}?input.vpc_id={{.properties.'ID' | @uri}}"
    }


  }

}

query "aws_vpc" {
  sql = <<-EOQ
    select
      title as label,
      vpc_id as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'vpc_id', vpc_id
      ) as tags
    from
      aws_vpc
    order by
      title;
  EOQ
}

query "aws_vpc_graph_from_vpc" {
  sql = <<-EOQ
    with vpc as (select * from aws_vpc where vpc_id = $1)

    -- VPC node
    select
      null as from_id,
      null as to_id,
      vpc_id as id,
      title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      vpc

  EOQ
  param "vpc_id" {}
}

query "aws_vpc_graph_to_vpc" {
  sql = <<-EOQ
    with vpc as (select * from aws_vpc where vpc_id = $1)

    -- VPC node
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_vpc' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      vpc

  EOQ
  param "vpc_id" {}
}