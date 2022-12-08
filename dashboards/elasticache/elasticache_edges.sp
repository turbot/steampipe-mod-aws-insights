
edge "elasticache_cluster_to_sns_topic" {
  title = "notifies"

  sql = <<-EOQ
    select
      arn as from_id,
      notification_configuration ->> 'TopicArn' as to_id
    from
      aws_elasticache_cluster as c
    where
      arn = any($1);
  EOQ

  param "elasticache_cluster_arns" {}
}
