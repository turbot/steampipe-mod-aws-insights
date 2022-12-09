node "eks_addon" {
  category = category.eks_addon

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Addon Version', addon_version,
        'Created At', created_at,
        'Status', status,
        'Account ID', account_id,
        'Region', region
        ) as properties
    from
      aws_eks_addon
    where
      arn = any($1)
  EOQ

  param "eks_addon_arns" {}
}

node "eks_cluster" {
  category = category.eks_cluster

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Created At', created_at,
        'Version', version,
        'Status', status,
        'Account ID', account_id,
        'Region', region ) as properties
    from
      aws_eks_cluster
    where
      arn = any($1);
  EOQ

  param "eks_cluster_arns" {}
}

node "eks_fargate_profile" {
  category = category.eks_fargate_profile

  sql = <<-EOQ
    select
      p.fargate_profile_arn as id,
      p.title as title,
      jsonb_build_object(
        'ARN', p.fargate_profile_arn,
        'Status', p.status,
        'Account ID', p.account_id,
        'Region', p.region
        ) as properties
    from
     aws_eks_cluster as c
      left join
        aws_eks_fargate_profile as p
        on p.cluster_name = c.name
    where
      p.region = c.region
      and c.arn = any($1);
  EOQ

  param "eks_fargate_profile_arns" {}
}

node "eks_identity_provider_config" {
  category = category.eks_identity_provider_config

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Type ', type,
        'Client ID', client_id,
        'Status', status,
        'Account ID', account_id,
        'Region', region
        ) as properties
    from
      aws_eks_identity_provider_config
    where
      arn = any($1)
  EOQ

  param "eks_identity_provider_arns" {}
}

node "eks_node_group" {
  category = category.eks_node_group

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'ARN', arn,
        'Capacity Type ', capacity_type,
        'Created At', created_at,
        'Status', status,
        'Account ID', account_id,
        'Region', region
        ) as properties
    from
      aws_eks_node_group
    where
      cluster_name in
      (
        select
          name
        from
          aws_eks_cluster
        where
          arn = any($1)
      )
  EOQ

  param "eks_node_group_arns" {}
}