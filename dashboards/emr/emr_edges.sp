edge "emr_cluster_to_iam_role" {
  title = "runs as"

  sql = <<-EOQ
    select
      c.cluster_arn as from_id,
      r.arn as to_id
    from
      aws_iam_role as r,
      aws_emr_cluster as c
    where
      c.cluster_arn = $1
      and r.name = c.service_role;
  EOQ

  param "emr_cluster_arns" {}
}