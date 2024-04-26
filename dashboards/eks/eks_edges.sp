edge "eks_cluster_to_eks_addon" {
  title = "addon"

  sql = <<-EOQ
    with eks_addon as (
      select
        cluster_name,
        arn
      from
        aws_eks_addon
        join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    ),  eks_cluster as (
      select
        name,
        arn
      from
       aws_eks_cluster
    )
    select
      c.arn as from_id,
      a.arn as to_id
    from
      eks_cluster as c
      left join aws_eks_addon as a on a.cluster_name = c.name
  EOQ

  param "eks_addon_arns" {}
}

edge "eks_cluster_to_eks_fargate_profile" {
  title = "fargate profile"

  sql = <<-EOQ
    with eks_fargate_profile as (
      select
        cluster_name,
        fargate_profile_arn,
        region
      from
        aws_eks_fargate_profile
        join unnest($1::text[]) as a on fargate_profile_arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    ), eks_cluster as (
      select
        name,
        arn,
        region
      from
        aws_eks_cluster
    )
    select
      c.arn as from_id,
      p.fargate_profile_arn as to_id
    from
      eks_cluster as c
      left join eks_fargate_profile as p on p.cluster_name = c.name
    where
      p.region = c.region;
  EOQ

  param "eks_fargate_profile_arns" {}
}

edge "eks_cluster_to_eks_identity_provider_config" {
  title = "identity provider config"

  sql = <<-EOQ
    with eks_identity_provider_config as (
      select
        cluster_name,
        arn
      from
        aws_eks_identity_provider_config
        join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    ), eks_cluster as (
      select
        name,
        arn
      from
       aws_eks_cluster
    )
    select
      c.arn as from_id,
      i.arn as to_id
    from
      eks_cluster as c
      left join eks_identity_provider_config as i on i.cluster_name = c.name;
  EOQ

  param "eks_identity_provider_arns" {}
}

edge "eks_cluster_to_eks_node_group" {
  title = "node group"

  sql = <<-EOQ
    with eks_node_group as (
      select
        cluster_name,
        arn
      from
        aws_eks_node_group
        join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4)
    ), eks_cluster as (
      select
        name,
        arn
      from
       aws_eks_cluster
    )
    select
      c.arn as from_id,
      g.arn as to_id
    from
      eks_cluster as c
      left join eks_node_group as g on g.cluster_name = c.name;
  EOQ

  param "eks_node_group_arns" {}
}

edge "eks_cluster_to_iam_role" {
  title = "assumes"

  sql = <<-EOQ
    select
      arn as from_id,
      role_arn as to_id
    from
      aws_eks_cluster
    where
      role_arn = any($1)
  EOQ

  param "iam_role_arns" {}
}

edge "eks_cluster_to_kms_key" {
  title = "secrets encrypted with"

  sql = <<-EOQ
    select
      arn as from_id,
      e -> 'Provider' ->> 'KeyArn' as to_id
    from
      aws_eks_cluster,
      jsonb_array_elements(encryption_config) as e
    where
      e -> 'Provider' ->> 'KeyArn' = any($1);
  EOQ

  param "kms_key_arns" {}
}

edge "eks_cluster_to_vpc_security_group" {
  title = "security group"

  sql = <<-EOQ
    select
      arn as from_id,
      group_id as to_id
    from
      aws_eks_cluster as c,
      jsonb_array_elements_text(resources_vpc_config -> 'SecurityGroupIds') as group_id
    where
      group_id = any($1)
  EOQ

  param "vpc_security_group_ids" {}
}

edge "eks_cluster_to_vpc_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      group_id as from_id,
      subnet_id as to_id
    from
      aws_eks_cluster as c
      join unnest($1::text[]) as a on arn = a and account_id = split_part(a, ':', 5) and region = split_part(a, ':', 4),
      jsonb_array_elements_text(resources_vpc_config -> 'SecurityGroupIds') as group_id,
      jsonb_array_elements_text(resources_vpc_config -> 'SubnetIds') as subnet_id;
  EOQ

  param "eks_cluster_arns" {}
}
