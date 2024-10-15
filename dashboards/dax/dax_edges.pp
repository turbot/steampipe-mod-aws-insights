edge "dax_cluster_to_dax_cluster_node" {
  title = "node"
  sql   = <<-EOQ
    select
      arn as from_id,
      n ->> 'NodeId' as to_id
    from
      aws_dax_cluster
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4),
      jsonb_array_elements(nodes) as n;
  EOQ

  param "dax_cluster_arns" {}
}

edge "dax_cluster_to_dax_parameter_group" {
  title = "parameter group"
  sql   = <<-EOQ
    select
      arn as from_id,
      parameter_group ->> 'ParameterGroupName' as to_id
    from
      aws_dax_cluster
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "dax_cluster_arns" {}
}

edge "dax_cluster_to_iam_role" {
  title = "assumes"
  sql   = <<-EOQ
    select
      arn as from_id,
      iam_role_arn as to_id
    from
      aws_dax_cluster
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "dax_cluster_arns" {}
}

edge "dax_cluster_to_sns_topic" {
  title = "notifies"
  sql   = <<-EOQ
    select
      arn as from_id,
      notification_configuration ->> 'TopicArn' as to_id
    from
      aws_dax_cluster
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4);
  EOQ

  param "dax_cluster_arns" {}
}

edge "dax_cluster_to_vpc_security_group" {
  title = "security group"
  sql   = <<-EOQ
    select
      c.arn as from_id,
      sg ->> 'SecurityGroupIdentifier' as to_id
    from
      aws_dax_cluster as c
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4),
      jsonb_array_elements(security_groups) as sg;
  EOQ

  param "dax_cluster_arns" {}
}

edge "dax_subnet_group_to_vpc_subnet" {
  title = "subnet"
  sql   = <<-EOQ
    select
      g.subnet_group_name as from_id,
      s ->> 'SubnetIdentifier' as to_id
    from
      aws_dax_cluster as c
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4),
      aws_dax_subnet_group as g,
      jsonb_array_elements(subnets) as s
    where
      g.subnet_group_name = c.subnet_group
      and c.arn = any($1);
  EOQ

  param "dax_cluster_arns" {}
}

