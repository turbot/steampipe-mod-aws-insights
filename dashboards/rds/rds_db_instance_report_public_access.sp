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
      sql   = query.aws_rds_db_instance_count.sql
      width = 2
    }

    card {
      sql = query.aws_rds_db_instance_public_count.sql
      width = 2
    }
  }

  table {

    column "Account ID" {
      display = "none"
    }

    sql = <<-EOQ
      select
        i.db_instance_identifier as "DB Instance Identifier",
        case
          when i.publicly_accessible then 'Public' else 'Private' end as "Public/Private",
        i.status as "Status",
        a.title as "Account",
        i.account_id as "Account ID",
        i.region as "Region",
        i.arn as "ARN"
      from
        aws_rds_db_instance as i,
        aws_account as a
      where
        i.account_id = a.account_id
    EOQ

  }

}
