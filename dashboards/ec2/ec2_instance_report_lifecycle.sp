dashboard "aws_ec2_instance_lifecycle_report" {

  title = "AWS EC2 Instance Lifecycle Report"

  tags = merge(local.ec2_common_tags, {
    type     = "Report"
    category = "Lifecycle"
  })

  container {

    card {
      sql   = query.aws_ec2_instance_count.sql
      width = 2
    }

    card {
      sql   = query.aws_ec2_stopped_instance_count.sql
      width = 2
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    sql = query.aws_ec2_instance_lifecycle_table.sql
  }

}

query "aws_ec2_stopped_instance_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Stopped Instance' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      aws_ec2_instance
    where
      instance_state = 'stopped';
  EOQ
}

query "aws_ec2_instance_lifecycle_table" {
  sql = <<-EOQ
    select
      i.tags ->> 'Name' as "Name",
      i.instance_id as "Instance ID",
      i.instance_state as "State",
      i.instance_lifecycle as "Lifecycle",
      a.title as "Account",
      i.account_id as "Account ID",
      i.region as "Region",
      i.arn as "ARN"
    from
      aws_ec2_instance as i,
      aws_account as a
    where
      i.account_id = a.account_id
    order by
      i.tags ->> 'Name',
      i.instance_id;
  EOQ
}
