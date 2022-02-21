query "aws_rds_db_instance_public_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public DB Instances' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_rds_db_instance
    where
      publicly_accessible
  EOQ
}

dashboard "aws_rds_db_instance_public_access_report" {

  title = "AWS RDS DB Instance Public Access Report"

  container {

    card {
      sql = query.aws_rds_db_instance_public_count.sql
      width = 2
    }
  }

  table {
    sql = <<-EOQ
      select
        db_instance_identifier as "Instance",
        case
          when publicly_accessible then 'Public' else 'Private' end as "Public/Private",
        status as "Status",
        account_id as "Account",
        region as "Region",
        arn as "ARN"
      from
        aws_rds_db_instance
    EOQ
  }
}
