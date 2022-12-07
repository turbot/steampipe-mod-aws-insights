edge "guardduty_detector_to_iam_role" {
  title = "runs as"

  sql = <<-EOQ
    select
      detector_id as from_id,
      service_role as to_id
    from
      aws_guardduty_detector
    where
      service_role = any($1);
  EOQ

  param "iam_role_arns" {}
}
